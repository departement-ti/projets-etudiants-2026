package com.rayhan.erp.controller;

import com.rayhan.erp.model.Article;
import com.rayhan.erp.model.StockMovement;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.ArticleRepository;
import com.rayhan.erp.repository.UserRepository;
import com.rayhan.erp.security.services.UserDetailsImpl;
import com.rayhan.erp.service.StockService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/stock")
public class StockController {

    @Autowired private StockService stockService;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private UserRepository userRepository;

    @GetMapping("/historique/{articleId}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_MAGASINIER', 'ROLE_RESPONSABLE_PRODUCTION')")
    public List<StockMovement> getHistorique(@PathVariable Long articleId) {
        return stockService.getHistoriqueArticle(articleId);
    }

    @PostMapping("/adjust")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_MAGASINIER')")
    public ResponseEntity<StockMovement> adjustStock(@RequestBody Map<String, Object> request,
                                                      @AuthenticationPrincipal UserDetailsImpl userDetails) {
        Long articleId = Long.valueOf(request.get("articleId").toString());
        BigDecimal quantite = new BigDecimal(request.get("quantite").toString());
        String type = request.get("type").toString(); // "IN" ou "OUT"
        String motif = request.getOrDefault("motif", "Ajustement manuel").toString();

        Article article = articleRepository.findById(articleId)
            .orElseThrow(() -> new RuntimeException("Article introuvable"));
        User user = userRepository.findById(userDetails.getId()).orElse(null);

        StockMovement mouvement;
        if ("IN".equals(type)) {
            mouvement = stockService.entreeStock(article, quantite, "AJUSTEMENT", "ADJ", motif, user);
        } else {
            mouvement = stockService.sortieStock(article, quantite, "AJUSTEMENT", "ADJ", motif, user);
        }

        return ResponseEntity.ok(mouvement);
    }
}
