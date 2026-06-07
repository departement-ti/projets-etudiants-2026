package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.RecruiterCompanyProfileRequest;
import com.recrutement.recrutement.dto.RecruiterCompanyProfileResponse;
import com.recrutement.recrutement.entities.Entreprise;
import com.recrutement.recrutement.entities.Recruiter;
import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import com.recrutement.recrutement.repositories.EntrepriseRepository;
import com.recrutement.recrutement.repositories.RecruiterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RecruiterCompanyProfileService {
    private final RecruiterRepository recruiterRepository;
    private final EntrepriseRepository entrepriseRepository;

    public RecruiterCompanyProfileService(
            RecruiterRepository recruiterRepository,
            EntrepriseRepository entrepriseRepository
    ) {
        this.recruiterRepository = recruiterRepository;
        this.entrepriseRepository = entrepriseRepository;
    }

    public RecruiterCompanyProfileResponse getCurrentCompanyProfile(User currentUser) {
        Recruiter recruiter = getCurrentRecruiter(currentUser);
        return buildResponse(recruiter);
    }

    @Transactional
    public RecruiterCompanyProfileResponse saveCurrentCompanyProfile(User currentUser, RecruiterCompanyProfileRequest request) {
        if (request == null) {
            throw new RuntimeException("Les informations de l'entreprise sont obligatoires.");
        }

        Recruiter recruiter = getCurrentRecruiter(currentUser);
        Entreprise entreprise = recruiter.getEntreprise();

        if (entreprise == null) {
            entreprise = entrepriseRepository.findByEmailIgnoreCase(clean(recruiter.getEmail()))
                    .orElseGet(() -> createEntrepriseSkeleton(recruiter));
        }

        String requestedEmail = requireValue(request.getEmail(), "L'email de l'entreprise est obligatoire.");
        long currentEntrepriseId = entreprise.getIdEntreprise();
        entrepriseRepository.findByEmailIgnoreCase(requestedEmail)
                .filter(existing -> currentEntrepriseId == 0 || existing.getIdEntreprise() != currentEntrepriseId)
                .ifPresent(existing -> {
                    throw new RuntimeException("Une entreprise existe deja avec cet email.");
                });

        entreprise.setNomEntreprise(requireValue(request.getNomEntreprise(), "Le nom de l'entreprise est obligatoire."));
        entreprise.setSecteur(requireValue(request.getSecteur(), "Le secteur de l'entreprise est obligatoire."));
        entreprise.setAdresse(requireValue(request.getAdresse(), "L'adresse de l'entreprise est obligatoire."));
        entreprise.setEmail(requestedEmail);
        entreprise.setAbonnementActif(requireValue(request.getAbonnementActif(), "Le statut d'abonnement est obligatoire."));
        entreprise.setDescription(requireValue(request.getDescription(), "La description de l'entreprise est obligatoire."));
        entreprise.setSiteWeb(clean(request.getSiteWeb()));

        Entreprise savedEntreprise = entrepriseRepository.save(entreprise);
        recruiter.setEntreprise(savedEntreprise);
        recruiterRepository.save(recruiter);

        return buildResponse(recruiter);
    }

    private RecruiterCompanyProfileResponse buildResponse(Recruiter recruiter) {
        Entreprise entreprise = recruiter.getEntreprise();
        RecruiterCompanyProfileResponse response = new RecruiterCompanyProfileResponse();
        response.setIdEntreprise(entreprise == null ? null : entreprise.getIdEntreprise());
        response.setNomEntreprise(entreprise == null ? recruiter.getNom() : entreprise.getNomEntreprise());
        response.setEmail(entreprise == null ? recruiter.getEmail() : entreprise.getEmail());
        response.setSecteur(entreprise == null ? "" : defaultValue(entreprise.getSecteur(), ""));
        response.setDescription(entreprise == null ? "" : defaultValue(entreprise.getDescription(), ""));
        response.setAdresse(entreprise == null ? "" : defaultValue(entreprise.getAdresse(), ""));
        response.setAbonnementActif(entreprise == null ? "NON" : defaultValue(entreprise.getAbonnementActif(), "NON"));
        response.setSiteWeb(entreprise == null ? "" : defaultValue(entreprise.getSiteWeb(), ""));
        response.setProfileCompleted(
                entreprise != null
                        && hasText(entreprise.getNomEntreprise())
                        && hasText(entreprise.getSecteur())
                        && hasText(entreprise.getAdresse())
                        && hasText(entreprise.getEmail())
                        && hasText(entreprise.getAbonnementActif())
                        && hasText(entreprise.getDescription())
        );
        return response;
    }

    private Entreprise createEntrepriseSkeleton(Recruiter recruiter) {
        Entreprise entreprise = new Entreprise();
        entreprise.setNomEntreprise(defaultValue(recruiter.getNom(), "Entreprise recruteur"));
        entreprise.setSecteur("A completer");
        entreprise.setAdresse("Adresse a completer");
        entreprise.setEmail(requireValue(recruiter.getEmail(), "L'adresse e-mail du recruteur est obligatoire."));
        entreprise.setAbonnementActif("NON");
        entreprise.setDescription("Description a completer");
        entreprise.setSiteWeb("");
        return entreprise;
    }

    private Recruiter getCurrentRecruiter(User currentUser) {
        Recruiter recruiter = currentUser != null && currentUser.getId() != null
                ? recruiterRepository.findById(currentUser.getId()).orElse(null)
                : null;

        if (recruiter == null && currentUser != null) {
            recruiter = recruiterRepository.findByEmail(currentUser.getEmail());
        }

        if (recruiter == null) {
            recruiter = createMissingRecruiterProfile(currentUser);
        }

        if (recruiter == null) {
            throw new RuntimeException("Profil recruteur introuvable.");
        }

        return recruiter;
    }

    private Recruiter createMissingRecruiterProfile(User authenticatedUser) {
        if (authenticatedUser == null) {
            return null;
        }

        if (authenticatedUser.getRole() != Role.RECRUITER) {
            throw new RuntimeException("Seuls les comptes recruteurs peuvent modifier une entreprise.");
        }

        Recruiter recruiter = new Recruiter();
        recruiter.setId(authenticatedUser.getId());
        recruiter.setEmail(authenticatedUser.getEmail());
        recruiter.setNom(authenticatedUser.getNom());
        recruiter.setPassword(authenticatedUser.getPassword());
        recruiter.setRole(authenticatedUser.getRole());
        recruiter.setStatutCompte(authenticatedUser.getStatutCompte());
        recruiter.setApprovalStatus(authenticatedUser.getApprovalStatus());
        recruiter.setEmailVerified(authenticatedUser.getEmailverified());
        recruiter.setActivationToken(authenticatedUser.getActivationToken());
        recruiter.setResetPasswordToken(authenticatedUser.getResetPasswordToken());
        recruiter.setResetPasswordTokenExpiresAt(authenticatedUser.getResetPasswordTokenExpiresAt());
        recruiter.setFonction("");
        recruiter.setPoste("");
        recruiter.setDepartement("");
        return recruiterRepository.save(recruiter);
    }

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private String requireValue(String value, String message) {
        String cleaned = clean(value);
        if (cleaned.isEmpty()) {
            throw new RuntimeException(message);
        }
        return cleaned;
    }

    private String defaultValue(String value, String fallback) {
        String cleaned = clean(value);
        return cleaned.isEmpty() ? fallback : cleaned;
    }

    private boolean hasText(String value) {
        return !clean(value).isEmpty();
    }
}
