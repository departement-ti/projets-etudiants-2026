package com.rayhan.erp.service;

import com.rayhan.erp.model.*;
import com.rayhan.erp.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class ProductionOrderService {

    @Autowired private ProductionOrderRepository productionOrderRepository;
    @Autowired private BomLineRepository bomLineRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private StockService stockService;
    @Autowired private SequenceService sequenceService;

    /**
     * Planifie un ordre de fabrication après vérification des matières premières.
     */
    @Transactional
    public ProductionOrder planifierOF(Long produitFiniId, BigDecimal quantite,
                                       LocalDate datePlanifiee, User user) {
        Article produitFini = articleRepository.findById(produitFiniId)
            .orElseThrow(() -> new RuntimeException("Produit introuvable : " + produitFiniId));

        List<BomLine> bom = bomLineRepository.findByProduitFiniId(produitFiniId);
        if (bom.isEmpty()) {
            throw new RuntimeException("Aucune nomenclature définie pour " + produitFini.getDesignation());
        }

        // Vérification du stock matières premières
        for (BomLine ligne : bom) {
            BigDecimal qteNecessaire = ligne.getQuantiteParUnite().multiply(quantite);
            Article composant = ligne.getComposant();
            if (composant.getStockActuel().compareTo(qteNecessaire) < 0) {
                throw new IllegalStateException(
                    "Stock insuffisant de " + composant.getDesignation() +
                    " : disponible " + composant.getStockActuel() +
                    ", nécessaire " + qteNecessaire);
            }
        }

        ProductionOrder of = new ProductionOrder();
        of.setReference(sequenceService.generateRef("OF"));
        of.setProduitFini(produitFini);
        of.setQuantitePlanifiee(quantite);
        of.setDatePlanifiee(datePlanifiee);
        of.setStatut(ProductionOrder.StatutOF.PLANIFIE);
        of.setCreePar(user);

        return productionOrderRepository.save(of);
    }

    /**
     * Lance un OF : consomme les matières premières du stock.
     */
    @Transactional
    public ProductionOrder lancerOF(Long ofId, User user) {
        ProductionOrder of = productionOrderRepository.findById(ofId)
            .orElseThrow(() -> new RuntimeException("OF introuvable : " + ofId));

        if (of.getStatut() != ProductionOrder.StatutOF.PLANIFIE) {
            throw new IllegalStateException("L'OF doit être à l'état PLANIFIE pour être lancé.");
        }

        List<BomLine> bom = bomLineRepository.findByProduitFiniId(of.getProduitFini().getId());

        for (BomLine ligne : bom) {
            BigDecimal qteConsommee = ligne.getQuantiteParUnite().multiply(of.getQuantitePlanifiee());
            Article composant = articleRepository.findById(ligne.getComposant().getId()).get();
            stockService.sortieStock(composant, qteConsommee,
                "ORDRE_FABRICATION", of.getReference(),
                "Lancement OF " + of.getReference(), user);
        }

        of.setStatut(ProductionOrder.StatutOF.LANCE);
        of.setDateLancement(LocalDateTime.now());
        return productionOrderRepository.save(of);
    }

    /**
     * Termine un OF : entre le produit fini en stock.
     */
    @Transactional
    public ProductionOrder terminerOF(Long ofId, BigDecimal quantiteRealisee, User user) {
        ProductionOrder of = productionOrderRepository.findById(ofId)
            .orElseThrow(() -> new RuntimeException("OF introuvable : " + ofId));

        if (of.getStatut() != ProductionOrder.StatutOF.LANCE) {
            throw new IllegalStateException("L'OF doit être à l'état LANCE pour être terminé.");
        }

        Article produitFini = articleRepository.findById(of.getProduitFini().getId()).get();
        stockService.entreeStock(produitFini, quantiteRealisee,
            "ORDRE_FABRICATION", of.getReference(),
            "Production OF " + of.getReference(), user);

        of.setQuantiteRealisee(quantiteRealisee);
        of.setStatut(ProductionOrder.StatutOF.TERMINE);
        of.setDateTerminaison(LocalDateTime.now());
        return productionOrderRepository.save(of);
    }

    public List<ProductionOrder> getAllOFs() {
        return productionOrderRepository.findAll();
    }
}
