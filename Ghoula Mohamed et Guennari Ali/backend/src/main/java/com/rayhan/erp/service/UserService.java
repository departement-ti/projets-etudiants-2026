package com.rayhan.erp.service;

import com.rayhan.erp.dto.request.StaffRequest;
import com.rayhan.erp.dto.response.UserResponse;
import com.rayhan.erp.model.ERole;
import com.rayhan.erp.model.Role;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.RoleRepository;
import com.rayhan.erp.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder encoder;

    private static final Set<ERole> STAFF_ROLES = Set.of(
        ERole.ROLE_PDG,
        ERole.ROLE_RESPONSABLE_VENTE,
        ERole.ROLE_RESPONSABLE_ACHAT,
        ERole.ROLE_RESPONSABLE_PRODUCTION,
        ERole.ROLE_MAGASINIER
    );

    public UserService(UserRepository userRepository,
                       RoleRepository roleRepository,
                       PasswordEncoder encoder) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.encoder = encoder;
    }

    public List<UserResponse> getAllStaff() {
        return userRepository.findAllStaff().stream()
            .filter(u -> u.getRoles().stream().anyMatch(r -> STAFF_ROLES.contains(r.getName())))
            .map(this::toResponse)
            .collect(Collectors.toList());
    }

    public UserResponse getById(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Utilisateur introuvable : " + id));
        return toResponse(user);
    }

    @Transactional
    public UserResponse create(StaffRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Ce nom d'utilisateur est déjà pris.");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Cet email est déjà utilisé.");
        }
        if (request.getPassword() == null || request.getPassword().isBlank()) {
            throw new RuntimeException("Le mot de passe est obligatoire.");
        }

        Set<Role> roles = resolveRoles(request.getRoles());
        enforceSinglePdg(roles, null);

        User user = new User(
            request.getUsername(),
            request.getEmail(),
            encoder.encode(request.getPassword()),
            request.getFirstName(),
            request.getLastName()
        );
        user.setRoles(roles);
        user.setEnabled(request.getEnabled() != null ? request.getEnabled() : true);

        return toResponse(userRepository.save(user));
    }

    @Transactional
    public UserResponse update(Long id, StaffRequest request) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Utilisateur introuvable : " + id));

        if (request.getFirstName() != null) user.setFirstName(request.getFirstName());
        if (request.getLastName() != null) user.setLastName(request.getLastName());
        if (request.getEmail() != null) {
            if (!user.getEmail().equals(request.getEmail()) && userRepository.existsByEmail(request.getEmail())) {
                throw new RuntimeException("Cet email est déjà utilisé.");
            }
            user.setEmail(request.getEmail());
        }
        if (request.getEnabled() != null) user.setEnabled(request.getEnabled());
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            user.setPassword(encoder.encode(request.getPassword()));
        }
        if (request.getRoles() != null) {
            Set<Role> roles = resolveRoles(request.getRoles());
            enforceSinglePdg(roles, id);
            user.setRoles(roles);
        }

        return toResponse(userRepository.save(user));
    }

    @Transactional
    public void setPassword(Long id, String password) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Utilisateur introuvable : " + id));
        user.setPassword(encoder.encode(password));
        userRepository.save(user);
    }

    @Transactional
    public void disable(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Utilisateur introuvable : " + id));
        user.setEnabled(false);
        userRepository.save(user);
    }

    @Transactional
    public void enable(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Utilisateur introuvable : " + id));
        user.setEnabled(true);
        userRepository.save(user);
    }

    private Set<Role> resolveRoles(Set<String> strRoles) {
        if (strRoles == null || strRoles.isEmpty()) {
            throw new RuntimeException("Au moins un rôle est requis.");
        }
        Set<Role> roles = new HashSet<>();
        strRoles.forEach(role -> {
            ERole eRole = switch (role.toLowerCase()) {
                case "pdg" -> ERole.ROLE_PDG;
                case "vente" -> ERole.ROLE_RESPONSABLE_VENTE;
                case "achat" -> ERole.ROLE_RESPONSABLE_ACHAT;
                case "production" -> ERole.ROLE_RESPONSABLE_PRODUCTION;
                case "magasinier" -> ERole.ROLE_MAGASINIER;
                default -> throw new RuntimeException("Rôle invalide : " + role);
            };
            Role found = roleRepository.findByName(eRole)
                .orElseThrow(() -> new RuntimeException("Rôle introuvable : " + role));
            roles.add(found);
        });
        return roles;
    }

    private void enforceSinglePdg(Set<Role> newRoles, Long excludeUserId) {
        boolean hasPdg = newRoles.stream().anyMatch(r -> r.getName() == ERole.ROLE_PDG);
        if (hasPdg) {
            long existingPdgCount = userRepository.findAllStaff().stream()
                .filter(u -> !u.getId().equals(excludeUserId))
                .filter(u -> u.getRoles().stream().anyMatch(r -> r.getName() == ERole.ROLE_PDG))
                .count();
            if (existingPdgCount >= 1) {
                throw new RuntimeException("Un compte PDG existe déjà. Un seul PDG est autorisé.");
            }
        }
    }

    private UserResponse toResponse(User user) {
        List<String> roleNames = user.getRoles().stream()
            .map(r -> r.getName().name())
            .collect(Collectors.toList());
        return new UserResponse(
            user.getId(),
            user.getUsername(),
            user.getEmail(),
            user.getFirstName(),
            user.getLastName(),
            user.isEnabled(),
            roleNames
        );
    }
}
