package com.recrutement.recrutement.service.Impl;

import com.recrutement.recrutement.dto.AdminRegisterRequest;
import com.recrutement.recrutement.dto.CandidateRegisterRequest;
import com.recrutement.recrutement.dto.ChangePasswordRequest;
import com.recrutement.recrutement.dto.ForgotPasswordRequest;
import com.recrutement.recrutement.dto.LoginRequest;
import com.recrutement.recrutement.dto.LoginResponse;
import com.recrutement.recrutement.dto.MessageResponse;
import com.recrutement.recrutement.dto.RecruiterRegisterRequest;
import com.recrutement.recrutement.dto.RegisterResponse;
import com.recrutement.recrutement.dto.ResetPasswordRequest;
import com.recrutement.recrutement.dto.UserProfileResponse;
import com.recrutement.recrutement.dto.UserSummaryResponse;
import com.recrutement.recrutement.entities.AccountApprovalStatus;
import com.recrutement.recrutement.entities.Candidate;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.CVRepository;
import com.recrutement.recrutement.repositories.AiTestRepository;
import com.recrutement.recrutement.repositories.AiAnswerRepository;
import com.recrutement.recrutement.repositories.AiQuestionRepository;
import com.recrutement.recrutement.repositories.AiTestResultRepository;
import com.recrutement.recrutement.repositories.CandidateRepository;
import com.recrutement.recrutement.repositories.CandidatureRepository;
import com.recrutement.recrutement.repositories.ConversationMessageRepository;
import com.recrutement.recrutement.repositories.InterviewRepository;
import com.recrutement.recrutement.repositories.OffreRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import com.recrutement.recrutement.repositories.UserRepository;
import com.recrutement.recrutement.security.JwtUtils;
import com.recrutement.recrutement.service.AuthService;
import com.recrutement.recrutement.service.EmailService;
import com.recrutement.recrutement.service.NotificationService;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthServiceImpl implements AuthService {
    private static final Logger logger = LoggerFactory.getLogger(AuthServiceImpl.class);

    private final UserRepository userRepository;
    private final CandidateRepository candidateRepository;
    private final RecruiterRepository recruiterRepository;
    private final CVRepository cvRepository;
    private final AiTestRepository aiTestRepository;
    private final AiAnswerRepository aiAnswerRepository;
    private final AiQuestionRepository aiQuestionRepository;
    private final AiTestResultRepository aiTestResultRepository;
    private final InterviewRepository interviewRepository;
    private final OffreRepository offreRepository;
    private final CandidatureRepository candidatureRepository;
    private final ConversationMessageRepository conversationMessageRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final EmailService emailService;
    private final NotificationService notificationService;

    public AuthServiceImpl(
            UserRepository userRepository,
            CandidateRepository candidateRepository,
            RecruiterRepository recruiterRepository,
            CVRepository cvRepository,
            AiTestRepository aiTestRepository,
            AiAnswerRepository aiAnswerRepository,
            AiQuestionRepository aiQuestionRepository,
            AiTestResultRepository aiTestResultRepository,
            InterviewRepository interviewRepository,
            OffreRepository offreRepository,
            CandidatureRepository candidatureRepository,
            ConversationMessageRepository conversationMessageRepository,
            PasswordEncoder passwordEncoder,
            JwtUtils jwtUtils,
            EmailService emailService,
            NotificationService notificationService
    ) {
        this.userRepository = userRepository;
        this.candidateRepository = candidateRepository;
        this.recruiterRepository = recruiterRepository;
        this.cvRepository = cvRepository;
        this.aiTestRepository = aiTestRepository;
        this.aiAnswerRepository = aiAnswerRepository;
        this.aiQuestionRepository = aiQuestionRepository;
        this.aiTestResultRepository = aiTestResultRepository;
        this.interviewRepository = interviewRepository;
        this.offreRepository = offreRepository;
        this.candidatureRepository = candidatureRepository;
        this.conversationMessageRepository = conversationMessageRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtils = jwtUtils;
        this.emailService = emailService;
        this.notificationService = notificationService;
    }

    @Override
    public RegisterResponse registerCandidate(CandidateRegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            return RegisterResponse.builder().success(false).message("Email existe deja").build();
        }

        String activationToken = UUID.randomUUID().toString();

        Candidate candidate = new Candidate();
        candidate.setEmail(request.getEmail());
        candidate.setNom(request.getUsername());
        candidate.setPassword(passwordEncoder.encode(request.getPassword()));
        candidate.setRole(Role.CANDIDATE);
        candidate.setStatutCompte(true);
        candidate.setApprovalStatus(AccountApprovalStatus.APPROVED);
        candidate.setEmailVerified(false);
        candidate.setActivationToken(activationToken);
        candidate.setNumTelephone(request.getPhoneNumber());

        Candidate savedCandidate = candidateRepository.save(candidate);
        emailService.sendActivationEmail(savedCandidate.getEmail(), savedCandidate.getNom(), activationToken);

        return RegisterResponse.builder()
                .id(savedCandidate.getId())
                .email(savedCandidate.getEmail())
                .nom(savedCandidate.getNom())
                .role(savedCandidate.getRole())
                .approvalStatus(AccountApprovalStatus.APPROVED.name())
                .statutCompte(Boolean.TRUE.equals(savedCandidate.getStatutCompte()))
                .success(true)
                .message("Candidat enregistre avec succes. Veuillez verifier votre email pour activer votre compte.")
                .build();
    }

    @Override
    public RegisterResponse registerRecruiter(RecruiterRegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            return RegisterResponse.builder()
                    .success(false)
                    .message("Email existe deja")
                    .build();
        }

        Recruiter recruiter = new Recruiter();
        recruiter.setEmail(request.getEmail());
        recruiter.setNom(request.getUsername());
        recruiter.setPassword(passwordEncoder.encode(request.getPassword()));
        recruiter.setRole(Role.RECRUITER);
        recruiter.setStatutCompte(false);
        recruiter.setApprovalStatus(AccountApprovalStatus.PENDING);
        recruiter.setEmailVerified(false);
        recruiter.setFonction(request.getFonction());
        recruiter.setPoste(request.getPoste());
        recruiter.setDepartement(request.getDepartement());

        Recruiter savedRecruiter = recruiterRepository.save(recruiter);
        notifyAdminsForRecruiterApproval(savedRecruiter);
        notificationService.notifyAdmins("Nouveau recruteur en attente : " + savedRecruiter.getNom());
        notificationService.notifyUser(savedRecruiter, "Votre compte recruteur est en attente d'approbation par l'administrateur.");

        return RegisterResponse.builder()
                .id(savedRecruiter.getId())
                .email(savedRecruiter.getEmail())
                .nom(savedRecruiter.getNom())
                .role(savedRecruiter.getRole())
                .approvalStatus(AccountApprovalStatus.PENDING.name())
                .statutCompte(Boolean.TRUE.equals(savedRecruiter.getStatutCompte()))
                .success(true)
                .message("Recruteur enregistre avec succes. Votre compte est en attente d'approbation par l'administrateur.")
                .build();
    }

    @Override
    public RegisterResponse registerAdmin(AdminRegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            return RegisterResponse.builder()
                    .success(false)
                    .message("Email existe deja")
                    .build();
        }

        User admin = new User();
        admin.setEmail(request.getEmail());
        admin.setNom(request.getNom());
        admin.setPassword(passwordEncoder.encode(request.getPassword()));
        admin.setRole(Role.ADMIN);
        admin.setStatutCompte(true);
        admin.setApprovalStatus(AccountApprovalStatus.APPROVED);
        admin.setEmailVerified(true);

        User savedAdmin = userRepository.save(admin);

        return RegisterResponse.builder()
                .id(savedAdmin.getId())
                .email(savedAdmin.getEmail())
                .nom(savedAdmin.getNom())
                .role(savedAdmin.getRole())
                .approvalStatus(AccountApprovalStatus.APPROVED.name())
                .statutCompte(Boolean.TRUE.equals(savedAdmin.getStatutCompte()))
                .success(true)
                .message("Admin enregistre avec succes")
                .build();
    }

    @Override
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email ou mot de passe invalide."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Email ou mot de passe invalide.");
        }

        String roleValue = user.getRole() == null ? "" : user.getRole().toString().toUpperCase();
        boolean isAdmin = "ADMIN".equals(roleValue) || "ROLE_ADMIN".equals(roleValue);

        if (user.getRole() == Role.RECRUITER) {
            AccountApprovalStatus approvalStatus = resolveApprovalStatus(user);
            if (approvalStatus == AccountApprovalStatus.REFUSED) {
                throw new RuntimeException("Votre demande de compte recruteur a ete refusee par l'administrateur.");
            }
            if (approvalStatus != AccountApprovalStatus.APPROVED) {
                throw new RuntimeException("Votre compte est en attente d'approbation par l'administrateur.");
            }
            if (!Boolean.TRUE.equals(user.getStatutCompte())) {
                throw new RuntimeException("Votre compte recruteur est suspendu. Contactez l'administrateur.");
            }
            if (!Boolean.TRUE.equals(user.getEmailverified())) {
                throw new RuntimeException("Veuillez verifier votre email avant de vous connecter.");
            }
        } else if (!isAdmin && !Boolean.TRUE.equals(user.getEmailverified())) {
            throw new RuntimeException("Veuillez verifier votre email avant de vous connecter.");
        } else if (user.getStatutCompte() == null || !user.getStatutCompte()) {
            throw new RuntimeException("Votre compte n'est pas actif.");
        }

        return buildLoginResponse(user, "Login reussi");
    }

    @Override
    public String activateAccount(String token) {
        User user = userRepository.findByactivationToken(token)
                .orElseThrow(() -> new RuntimeException("Token d'activation invalide"));

        if (Boolean.TRUE.equals(user.getEmailverified())) {
            return "Ce compte est deja active.";
        }

        user.setEmailVerified(true);
        user.setActivationToken(null);
        userRepository.save(user);

        emailService.sendWelcomeEmail(user.getEmail(), user.getNom());

        return "Votre compte a ete active avec succes. Vous pouvez maintenant vous connecter.";
    }

    @Override
    public RegisterResponse approveRecruiter(Long recruiterId) {
        User user = userRepository.findById(recruiterId)
                .orElseThrow(() -> new RuntimeException("Recruteur non trouve"));

        if (user.getRole() != Role.RECRUITER) {
            return RegisterResponse.builder()
                    .success(false)
                    .message("Cet utilisateur n'est pas un recruteur")
                    .build();
        }

        user.setStatutCompte(true);
        user.setApprovalStatus(AccountApprovalStatus.APPROVED);
        user.setEmailVerified(true);
        user.setActivationToken(null);
        userRepository.save(user);

        boolean emailSent = true;

        try {
            notificationService.notifyUser(user, "Votre compte recruteur est maintenant active.");
        } catch (RuntimeException ex) {
            logger.warn("Echec de creation de la notification d'activation pour {}", user.getEmail(), ex);
        }

        try {
            emailService.sendRecruiterApprovedEmail(user.getEmail(), user.getNom());
        } catch (Exception ex) {
            emailSent = false;
            logger.error("Echec d'envoi de l'email d'approbation au recruteur {}: {}", user.getEmail(), ex.getMessage(), ex);
        }

        return RegisterResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .nom(user.getNom())
                .role(user.getRole())
                .approvalStatus(AccountApprovalStatus.APPROVED.name())
                .statutCompte(Boolean.TRUE.equals(user.getStatutCompte()))
                .success(true)
                .message(emailSent
                        ? "Recruteur active avec succes. Un email de confirmation a ete envoye."
                        : "Recruteur active avec succes. Le compte est mis a jour, mais l'email de confirmation n'a pas pu etre envoye."
                )
                .build();
    }

    @Override
    public MessageResponse rejectRecruiter(Long recruiterId) {
        User user = userRepository.findById(recruiterId)
                .orElseThrow(() -> new RuntimeException("Recruteur non trouve"));

        if (user.getRole() != Role.RECRUITER) {
            return new MessageResponse(false, "Cet utilisateur n'est pas un recruteur");
        }

        user.setStatutCompte(false);
        user.setApprovalStatus(AccountApprovalStatus.REFUSED);
        userRepository.save(user);

        boolean emailSent = true;

        try {
            notificationService.notifyUser(user, "Votre demande de compte recruteur a ete refusee par l'administrateur.");
        } catch (RuntimeException ex) {
            logger.warn("Echec de creation de la notification de refus pour {}", user.getEmail(), ex);
        }

        try {
            emailService.sendRecruiterRejectedEmail(user.getEmail(), user.getNom());
        } catch (Exception ex) {
            emailSent = false;
            logger.error("Echec d'envoi de l'email de refus au recruteur {}: {}", user.getEmail(), ex.getMessage(), ex);
        }

        return new MessageResponse(
                true,
                emailSent
                        ? "Compte recruteur refuse. Un email de refus a ete envoye."
                        : "Compte recruteur refuse. Le statut est mis a jour, mais l'email de refus n'a pas pu etre envoye."
        );
    }

    @Override
    public List<RegisterResponse> getRecruiterAccounts() {
        return userRepository.findAllByRole(Role.RECRUITER).stream()
                .sorted(
                        Comparator
                                .comparing((User user) -> getApprovalStatusOrder(resolveApprovalStatus(user)))
                                .thenComparing(User::getId, Comparator.reverseOrder())
                )
                .map(user -> RegisterResponse.builder()
                        .id(user.getId())
                        .nom(user.getNom())
                        .email(user.getEmail())
                        .role(user.getRole())
                        .approvalStatus(resolveDisplayApprovalStatus(user))
                        .statutCompte(Boolean.TRUE.equals(user.getStatutCompte()))
                        .entrepriseName(getRecruiterCompanyName(user))
                        .entreprise(getRecruiterCompanyName(user))
                        .secteurActivite(getRecruiterCompanySector(user))
                        .dateInscription(formatRegistrationDate(user.getCreatedAt()))
                        .publishedOffersCount(offreRepository.countByRecruiter_IdAndStatutIgnoreCase(user.getId(), "PUBLIEE"))
                        .success(true)
                        .build()
                )
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void deleteRecruiterAccount(Long recruiterId) {
        User user = userRepository.findById(recruiterId)
                .orElseThrow(() -> new RuntimeException("Recruteur non trouve"));

        if (user.getRole() != Role.RECRUITER) {
            throw new RuntimeException("Cet utilisateur n'est pas un recruteur");
        }

        clearMessagingForRecruiter(recruiterId, user);
        deleteAiTestsByIds(aiTestRepository.findIdsByRecruiterId(recruiterId));
        interviewRepository.deleteByRecruiterId(recruiterId);
        candidatureRepository.deleteAllForRecruiter(recruiterId);
        offreRepository.deleteByRecruiter_Id(recruiterId);
        notificationService.clearNotificationsForUser(user);
        recruiterRepository.deleteById(recruiterId);
    }

    @Override
    @Transactional
    public MessageResponse suspendRecruiterAccount(Long recruiterId) {
        User user = userRepository.findById(recruiterId)
                .orElseThrow(() -> new RuntimeException("Recruteur non trouve"));

        if (user.getRole() != Role.RECRUITER) {
            return new MessageResponse(false, "Cet utilisateur n'est pas un recruteur.");
        }

        user.setStatutCompte(false);
        if (user.getApprovalStatus() == null) {
            user.setApprovalStatus(AccountApprovalStatus.APPROVED);
        }
        userRepository.save(user);

        try {
            notificationService.notifyUser(user, "Votre compte recruteur a ete suspendu par l'administrateur.");
        } catch (RuntimeException ex) {
            logger.warn("Echec de creation de la notification de suspension pour {}", user.getEmail(), ex);
        }

        return new MessageResponse(true, "Compte recruteur desactive. Les offres, candidatures et historiques sont conserves.");
    }

    @Override
    public List<UserSummaryResponse> getUsers(String query) {
        Map<Long, User> allUsers = new LinkedHashMap<>();
        userRepository.findAll().forEach(user -> allUsers.put(user.getId(), user));
        userRepository.findAllByRole(Role.ADMIN).forEach(user -> allUsers.put(user.getId(), user));

        String trimmedQuery = query == null ? "" : query.trim();

        return allUsers.values().stream()
                .filter(user -> user.getRole() != Role.ADMIN)
                .filter(user -> matchesUserQuery(user, trimmedQuery))
                .sorted(Comparator.comparing(User::getId).reversed())
                .map(user -> new UserSummaryResponse(
                        user.getId(),
                        user.getNom(),
                        user.getEmail(),
                        user.getRole(),
                        Boolean.TRUE.equals(user.getStatutCompte()),
                        resolveDisplayApprovalStatus(user)
                ))
                .collect(Collectors.toList());
    }

    @Override
    public UserProfileResponse getUserById(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable."));
        UserProfileResponse response = new UserProfileResponse();
        response.setId(user.getId());
        response.setNom(user.getNom());
        response.setEmail(user.getEmail());
        response.setRole(user.getRole());
        response.setStatutCompte(Boolean.TRUE.equals(user.getStatutCompte()));
        response.setEmailVerified(Boolean.TRUE.equals(user.getEmailverified()));

        if (user instanceof Candidate candidate) {
            response.setNumTelephone(candidate.getNumTelephone());
            response.setPosteRecherche(candidate.getPosteRecherche());
            response.setLocalisation(candidate.getLocalisation());
            response.setExperience(candidate.getExperience());

            boolean profileExists = hasText(candidate.getNumTelephone())
                    || hasText(candidate.getPosteRecherche())
                    || hasText(candidate.getLocalisation())
                    || candidate.getExperience() > 0;

            response.setProfileExists(profileExists);
            if (!profileExists) {
                response.setProfileMessage("Ce candidat n'a pas encore cree son profil detaille.");
            }
            return response;
        }

        if (user instanceof Recruiter recruiter) {
            response.setFonction(recruiter.getFonction());
            response.setPoste(recruiter.getPoste());
            response.setDepartement(recruiter.getDepartement());
            if (recruiter.getEntreprise() != null) {
                response.setEntreprise(recruiter.getEntreprise().getNomEntreprise());
            }

            boolean profileExists = hasText(recruiter.getFonction())
                    || hasText(recruiter.getPoste())
                    || hasText(recruiter.getDepartement())
                    || recruiter.getEntreprise() != null;

            response.setProfileExists(profileExists);
            if (!profileExists) {
                response.setProfileMessage("Ce recruteur n'a pas encore complete son profil detaille.");
            }
            return response;
        }

        response.setProfileExists(false);
        response.setProfileMessage("Aucun profil detaille n'est disponible pour cet utilisateur.");
        return response;
    }

    @Override
    @Transactional
    public MessageResponse deleteUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable."));

        if (user.getRole() == Role.ADMIN) {
            throw new RuntimeException("La suppression d'un administrateur n'est pas autorisee.");
        }

        if (user instanceof Recruiter) {
            clearMessagingForRecruiter(userId, user);
            deleteAiTestsByIds(aiTestRepository.findIdsByRecruiterId(userId));
            interviewRepository.deleteByRecruiterId(userId);
            candidatureRepository.deleteAllForRecruiter(userId);
            offreRepository.deleteByRecruiter_Id(userId);
            notificationService.clearNotificationsForUser(user);
            recruiterRepository.deleteById(userId);
            return new MessageResponse(true, "Recruteur supprime avec succes.");
        }

        if (user instanceof Candidate) {
            clearMessagingForCandidate(userId, user);
            deleteAiTestsByIds(aiTestRepository.findIdsByCandidateId(userId));
            interviewRepository.deleteByCandidateId(userId);
            cvRepository.deleteAllForCandidate(userId);
            candidatureRepository.deleteAllForCandidate(userId);
            notificationService.clearNotificationsForUser(user);
            candidateRepository.deleteById(userId);
            return new MessageResponse(true, "Candidat supprime avec succes.");
        }

        notificationService.clearNotificationsForUser(user);
        userRepository.deleteById(userId);
        return new MessageResponse(true, "Utilisateur supprime avec succes.");
    }

    @Override
    @Transactional
    public MessageResponse suspendUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable."));

        if (user.getRole() == Role.ADMIN) {
            throw new RuntimeException("La desactivation d'un administrateur n'est pas autorisee.");
        }

        user.setStatutCompte(false);
        if (user.getApprovalStatus() == null) {
            user.setApprovalStatus(AccountApprovalStatus.APPROVED);
        }
        userRepository.save(user);

        try {
            notificationService.notifyUser(user, "Votre compte a ete desactive par l'administrateur.");
        } catch (RuntimeException ex) {
            logger.warn("Echec de creation de la notification de desactivation pour {}", user.getEmail(), ex);
        }

        String roleLabel = user.getRole() == Role.RECRUITER ? "recruteur" : "utilisateur";
        return new MessageResponse(true, "Compte " + roleLabel + " desactive. Les donnees et l'historique sont conserves.");
    }

    @Override
    @Transactional
    public MessageResponse activateUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable."));

        if (user.getRole() == Role.ADMIN) {
            throw new RuntimeException("L'activation d'un administrateur depuis cette page n'est pas autorisee.");
        }

        user.setStatutCompte(true);
        if (user.getApprovalStatus() == null || user.getApprovalStatus() == AccountApprovalStatus.REFUSED) {
            user.setApprovalStatus(AccountApprovalStatus.APPROVED);
        }
        user.setEmailVerified(true);
        user.setActivationToken(null);
        userRepository.save(user);

        try {
            notificationService.notifyUser(user, "Votre compte a ete reactive par l'administrateur.");
        } catch (RuntimeException ex) {
            logger.warn("Echec de creation de la notification de reactivation pour {}", user.getEmail(), ex);
        }

        String roleLabel = user.getRole() == Role.RECRUITER ? "recruteur" : "utilisateur";
        return new MessageResponse(true, "Compte " + roleLabel + " active avec succes.");
    }

    @Override
    public MessageResponse forgotPassword(ForgotPasswordRequest request) {
        String genericMessage = "Si un compte existe avec cette adresse e-mail, un lien de reinitialisation a ete envoye.";

        if (request == null || request.getEmail() == null || request.getEmail().isBlank()) {
            return new MessageResponse(true, genericMessage);
        }

        userRepository.findByEmail(request.getEmail().trim()).ifPresent(user -> {
            String resetToken = UUID.randomUUID().toString();
            user.setResetPasswordToken(resetToken);
            user.setResetPasswordTokenExpiresAt(LocalDateTime.now().plusMinutes(30));
            userRepository.save(user);
            emailService.sendPasswordResetEmail(user.getEmail(), user.getNom(), resetToken);
        });

        return new MessageResponse(true, genericMessage);
    }

    @Override
    public MessageResponse resetPassword(ResetPasswordRequest request) {
        if (request == null || request.getToken() == null || request.getToken().isBlank()) {
            return new MessageResponse(false, "Le lien de reinitialisation est invalide.");
        }

        if (request.getNewPassword() == null || request.getNewPassword().isBlank()) {
            return new MessageResponse(false, "Le nouveau mot de passe est obligatoire.");
        }

        if (request.getNewPassword().length() < 6) {
            return new MessageResponse(false, "Le mot de passe doit contenir au moins 6 caracteres.");
        }

        User user = userRepository.findByResetPasswordToken(request.getToken()).orElse(null);
        if (user == null) {
            return new MessageResponse(false, "Le lien de reinitialisation est invalide ou a deja ete utilise.");
        }

        if (user.getResetPasswordTokenExpiresAt() == null
                || user.getResetPasswordTokenExpiresAt().isBefore(LocalDateTime.now())) {
            user.setResetPasswordToken(null);
            user.setResetPasswordTokenExpiresAt(null);
            userRepository.save(user);
            return new MessageResponse(false, "Le lien de reinitialisation a expire. Veuillez en demander un nouveau.");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setResetPasswordToken(null);
        user.setResetPasswordTokenExpiresAt(null);
        userRepository.save(user);

        return new MessageResponse(true, "Votre mot de passe a ete reinitialise avec succes.");
    }

    @Override
    public MessageResponse changePassword(User currentUser, ChangePasswordRequest request) {
        if (currentUser == null || currentUser.getId() == null) {
            return new MessageResponse(false, "Utilisateur non authentifie.");
        }

        if (request == null) {
            return new MessageResponse(false, "La demande de changement de mot de passe est invalide.");
        }

        String currentPassword = request.getCurrentPassword() == null ? "" : request.getCurrentPassword().trim();
        String newPassword = request.getNewPassword() == null ? "" : request.getNewPassword().trim();

        if (currentPassword.isEmpty()) {
            return new MessageResponse(false, "Le mot de passe actuel est obligatoire.");
        }

        if (newPassword.isEmpty()) {
            return new MessageResponse(false, "Le nouveau mot de passe est obligatoire.");
        }

        if (newPassword.length() < 6) {
            return new MessageResponse(false, "Le nouveau mot de passe doit contenir au moins 6 caracteres.");
        }

        User persistedUser = userRepository.findById(currentUser.getId()).orElse(null);
        if (persistedUser == null) {
            return new MessageResponse(false, "Utilisateur introuvable.");
        }

        if (!passwordEncoder.matches(currentPassword, persistedUser.getPassword())) {
            return new MessageResponse(false, "Le mot de passe actuel est incorrect.");
        }

        if (passwordEncoder.matches(newPassword, persistedUser.getPassword())) {
            return new MessageResponse(false, "Le nouveau mot de passe doit etre different de l'ancien.");
        }

        persistedUser.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(persistedUser);

        return new MessageResponse(true, "Votre mot de passe a ete modifie avec succes.");
    }

    private LoginResponse buildLoginResponse(User user, String message) {
        String token = jwtUtils.generateToken(user);
        return LoginResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getNom())
                .role(user.getRole())
                .token(token)
                .message(message)
                .build();
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private boolean matchesUserQuery(User user, String query) {
        if (query == null || query.isBlank()) {
            return true;
        }

        String normalizedQuery = query.toLowerCase();
        if (user.getNom() != null && user.getNom().toLowerCase().contains(normalizedQuery)) {
            return true;
        }
        if (user.getEmail() != null && user.getEmail().toLowerCase().contains(normalizedQuery)) {
            return true;
        }

        try {
            Long id = Long.parseLong(query);
            return user.getId() != null && user.getId().equals(id);
        } catch (NumberFormatException ex) {
            return false;
        }
    }

    private AccountApprovalStatus resolveApprovalStatus(User user) {
        if (user == null) {
            return AccountApprovalStatus.PENDING;
        }

        if (user.getApprovalStatus() != null) {
            return user.getApprovalStatus();
        }

        if (Boolean.TRUE.equals(user.getStatutCompte())) {
            return AccountApprovalStatus.APPROVED;
        }

        return AccountApprovalStatus.PENDING;
    }

    private String resolveDisplayApprovalStatus(User user) {
        AccountApprovalStatus status = resolveApprovalStatus(user);
        if (status == AccountApprovalStatus.APPROVED && !Boolean.TRUE.equals(user.getStatutCompte())) {
            return "SUSPENDED";
        }
        return status.name();
    }

    private String getRecruiterCompanyName(User user) {
        if (user instanceof Recruiter recruiter
                && recruiter.getEntreprise() != null
                && hasText(recruiter.getEntreprise().getNomEntreprise())) {
            return recruiter.getEntreprise().getNomEntreprise();
        }
        return "Non disponible";
    }

    private String getRecruiterCompanySector(User user) {
        if (user instanceof Recruiter recruiter
                && recruiter.getEntreprise() != null
                && hasText(recruiter.getEntreprise().getSecteur())) {
            return recruiter.getEntreprise().getSecteur();
        }
        return "Non disponible";
    }

    private String formatRegistrationDate(LocalDateTime createdAt) {
        return createdAt == null ? "Compte existant" : createdAt.toString();
    }

    private int getApprovalStatusOrder(AccountApprovalStatus status) {
        if (status == AccountApprovalStatus.PENDING) {
            return 0;
        }
        if (status == AccountApprovalStatus.APPROVED) {
            return 1;
        }
        return 2;
    }

    private void sendWelcomeEmailSafely(User user) {
        try {
            emailService.sendWelcomeEmail(user.getEmail(), user.getNom());
        } catch (RuntimeException ex) {
            logger.warn("Echec de l'envoi de l'email de bienvenue pour {}", user.getEmail(), ex);
        }
    }

    private void notifyAdminsSafely(String message) {
        try {
            notificationService.notifyAdmins(message);
        } catch (RuntimeException ex) {
            logger.warn("Echec de creation de la notification admin: {}", message, ex);
        }
    }

    private void notifyAdminsForRecruiterApproval(Recruiter recruiter) {
        List<User> admins = userRepository.findAllByRole(Role.ADMIN);

        if (admins.isEmpty()) {
            logger.warn("Aucun administrateur trouve pour notifier la creation du recruteur {}", recruiter.getEmail());
            return;
        }

        for (User admin : admins) {
            try {
                emailService.sendRecruiterPendingApprovalEmail(
                        admin.getEmail(),
                        admin.getNom(),
                        recruiter.getNom(),
                        recruiter.getEmail()
                );
            } catch (RuntimeException ex) {
                logger.error(
                        "Echec de notification admin {} pour le recruteur {}",
                        admin.getEmail(),
                        recruiter.getEmail(),
                        ex
                );
            }
        }
    }

    private List<Long> clearMessagingForRecruiter(Long recruiterId, User user) {
        List<Long> candidatureIds = candidatureRepository.findIdsByRecruiterId(recruiterId);

        if (!candidatureIds.isEmpty()) {
            conversationMessageRepository.deleteAllByCandidatureIds(candidatureIds);
        }

        conversationMessageRepository.deleteAllByUserId(user.getId());
        return candidatureIds;
    }

    private List<Long> clearMessagingForCandidate(Long candidateId, User user) {
        List<Long> candidatureIds = candidatureRepository.findIdsByCandidateId(candidateId);

        if (!candidatureIds.isEmpty()) {
            conversationMessageRepository.deleteAllByCandidatureIds(candidatureIds);
        }

        conversationMessageRepository.deleteAllByUserId(user.getId());
        return candidatureIds;
    }

    private void deleteAiTestsByIds(List<Long> aiTestIds) {
        if (aiTestIds == null || aiTestIds.isEmpty()) {
            return;
        }

        aiAnswerRepository.deleteByAiTestIds(aiTestIds);
        aiQuestionRepository.deleteByAiTestIds(aiTestIds);
        aiTestResultRepository.deleteByAiTestIds(aiTestIds);
        aiTestRepository.deleteByIds(aiTestIds);
    }
}
