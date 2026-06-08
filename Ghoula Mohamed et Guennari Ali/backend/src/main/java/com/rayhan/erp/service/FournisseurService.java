package com.rayhan.erp.service;

import com.rayhan.erp.model.Fournisseur;
import com.rayhan.erp.repository.FournisseurRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FournisseurService {

    @Autowired
    private FournisseurRepository fournisseurRepository;

    public List<Fournisseur> getAllFournisseurs() {
        return fournisseurRepository.findByActifTrue();
    }

    public List<Fournisseur> searchFournisseurs(String q) {
        return fournisseurRepository.findByRaisonSocialeContainingIgnoreCase(q);
    }

    public Fournisseur getFournisseurById(Long id) {
        return fournisseurRepository.findById(id).orElse(null);
    }

    public Fournisseur createFournisseur(@Valid Fournisseur fournisseur) {
        return fournisseurRepository.save(fournisseur);
    }

    public boolean deleteFournisseur(Long id) {
        return fournisseurRepository.findById(id).map(f -> {
            f.setActif(false);
            fournisseurRepository.save(f);
            return true;
        }).orElse(false);
    }

    public Fournisseur updateFournisseur(Long id, Fournisseur details) {
        return fournisseurRepository.findById(id).map(f -> {
            f.setRaisonSociale(details.getRaisonSociale());
            f.setMatriculeFiscal(details.getMatriculeFiscal());
            f.setAdresse(details.getAdresse());
            f.setTelephone(details.getTelephone());
            f.setEmail(details.getEmail());
            f.setVille(details.getVille());
            f.setPays(details.getPays());
            f.setCategorieProduit(details.getCategorieProduit());
            f.setDelaiLivraison(details.getDelaiLivraison());
            f.setModePaiement(details.getModePaiement());
            return fournisseurRepository.save(f);
        }).orElse(null);
    }
}
