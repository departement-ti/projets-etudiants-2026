package com.rayhan.erp.service;

import com.rayhan.erp.dto.request.ClientWithUserRequest;
import com.rayhan.erp.model.Client;
import com.rayhan.erp.model.ERole;
import com.rayhan.erp.model.Role;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.ClientRepository;
import com.rayhan.erp.repository.RoleRepository;
import com.rayhan.erp.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

@Service
public class ClientService {

    @Autowired
    private ClientRepository clientRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public List<Client> getAllClients() {
        return clientRepository.findByActifTrue();
    }

    public List<Client> searchClients(String q) {
        return clientRepository.findByRaisonSocialeContainingIgnoreCase(q);
    }

    public Client getClientById(Long id) {
        return clientRepository.findById(id).orElse(null);
    }

    public Client createClient(@Valid Client client) {
        return clientRepository.save(client);
    }

    public Client updateClient(Long id, Client details) {
        return clientRepository.findById(id).map(client -> {
            client.setRaisonSociale(details.getRaisonSociale());
            client.setMatriculeFiscal(details.getMatriculeFiscal());
            client.setAdresse(details.getAdresse());
            client.setTelephone(details.getTelephone());
            client.setEmail(details.getEmail());
            client.setVille(details.getVille());
            client.setTypeClient(details.getTypeClient());
            client.setPlafondCredit(details.getPlafondCredit());
            client.setDelaiPaiement(details.getDelaiPaiement());
            client.setRepresentantNom(details.getRepresentantNom());
            client.setRepresentantTelephone(details.getRepresentantTelephone());
            client.setActif(details.isActif());
            Client saved = clientRepository.save(client);
            userRepository.findByClient_Id(saved.getId()).ifPresent(u -> {
                u.setEnabled(saved.isActif());
                userRepository.save(u);
            });
            return saved;
        }).orElse(null);
    }

    @Transactional
    public Client createClientWithUser(ClientWithUserRequest req) {
        Client client = new Client(
            req.getRaisonSociale(),
            req.getMatriculeFiscal(),
            req.getTelephone()
        );
        client.setAdresse(req.getAdresse());
        client.setEmail(req.getEmail());
        client.setVille(req.getVille());
        client.setTypeClient(req.getTypeClient());
        client.setPlafondCredit(req.getPlafondCredit());
        client.setDelaiPaiement(req.getDelaiPaiement());
        client.setRepresentantNom(req.getRepresentantNom());
        client.setRepresentantTelephone(req.getRepresentantTelephone());
        client = clientRepository.save(client);

        Role clientRole = roleRepository.findByName(ERole.ROLE_CLIENT)
            .orElseThrow(() -> new RuntimeException("Rôle ROLE_CLIENT introuvable"));

        User user = new User(
            req.getEmail(),
            req.getEmail(),
            passwordEncoder.encode(req.getPassword()),
            req.getFirstName(),
            req.getLastName()
        );
        user.setClient(client);
        user.setRoles(Set.of(clientRole));
        userRepository.save(user);

        return client;
    }
}
