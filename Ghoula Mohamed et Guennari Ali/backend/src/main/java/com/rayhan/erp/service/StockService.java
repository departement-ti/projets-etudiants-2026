package com.rayhan.erp.service;

import com.rayhan.erp.model.Article;
import com.rayhan.erp.model.StockMovement;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.ArticleRepository;
import com.rayhan.erp.repository.StockMovementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class StockService {

    @Autowired
    private ArticleRepository articleRepository;

    @Autowired
    private StockMovementRepository stockMovementRepository;

    /**
     * Effectue une entrée en stock (réception achat, production terminée, ajustement +)
     */
    @Transactional
    public StockMovement entreeStock(Article article, BigDecimal quantite,
                                     String sourceDocument, String referenceDocument,
                                     String motif, User user) {
        if (quantite.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("La quantité doit être positive.");
        }

        BigDecimal stockAvant = article.getStockActuel();
        BigDecimal stockApres = stockAvant.add(quantite);

        article.setStockActuel(stockApres);
        articleRepository.save(article);

        StockMovement mouvement = new StockMovement();
        mouvement.setArticle(article);
        mouvement.setType(StockMovement.TypeMouvement.IN);
        mouvement.setQuantite(quantite);
        mouvement.setStockAvant(stockAvant);
        mouvement.setStockApres(stockApres);
        mouvement.setSourceDocument(sourceDocument);
        mouvement.setReferenceDocument(referenceDocument);
        mouvement.setMotif(motif);
        mouvement.setCreePar(user);

        return stockMovementRepository.save(mouvement);
    }

    /**
     * Effectue une sortie de stock (livraison client, lancement OF, ajustement -)
     * Lance une exception si stock insuffisant.
     */
    @Transactional
    public StockMovement sortieStock(Article article, BigDecimal quantite,
                                     String sourceDocument, String referenceDocument,
                                     String motif, User user) {
        if (quantite.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("La quantité doit être positive.");
        }
        if (article.getStockActuel().compareTo(quantite) < 0) {
            throw new IllegalStateException(
                "Stock insuffisant pour " + article.getDesignation() +
                " : disponible " + article.getStockActuel() + ", demandé " + quantite);
        }

        BigDecimal stockAvant = article.getStockActuel();
        BigDecimal stockApres = stockAvant.subtract(quantite);

        article.setStockActuel(stockApres);
        articleRepository.save(article);

        StockMovement mouvement = new StockMovement();
        mouvement.setArticle(article);
        mouvement.setType(StockMovement.TypeMouvement.OUT);
        mouvement.setQuantite(quantite);
        mouvement.setStockAvant(stockAvant);
        mouvement.setStockApres(stockApres);
        mouvement.setSourceDocument(sourceDocument);
        mouvement.setReferenceDocument(referenceDocument);
        mouvement.setMotif(motif);
        mouvement.setCreePar(user);

        return stockMovementRepository.save(mouvement);
    }

    public List<StockMovement> getHistoriqueArticle(Long articleId) {
        return stockMovementRepository.findByArticleIdOrderByDateHeureDesc(articleId);
    }
}
