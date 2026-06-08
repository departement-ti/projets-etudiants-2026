package com.rayhan.erp.controller;

import com.rayhan.erp.model.Article;
import com.rayhan.erp.service.ArticleService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/articles")
public class ArticleController {

    @Autowired
    private ArticleService articleService;

    @GetMapping
    @PreAuthorize("hasRole('ROLE_PDG')")
    public List<Article> getAllArticles() {
        return articleService.getAllArticles();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<Article> getArticleById(@PathVariable Long id) {
        Article article = articleService.getArticleById(id);
        return article != null ? ResponseEntity.ok(article) : ResponseEntity.notFound().build();
    }

    @GetMapping("/type/{type}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public List<Article> getArticlesByType(@PathVariable Article.TypeArticle type) {
        return articleService.getArticlesByType(type);
    }

    @GetMapping("/alertes-stock")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_MAGASINIER', 'ROLE_RESPONSABLE_PRODUCTION')")
    public List<Article> getArticlesEnAlerte() {
        return articleService.getArticlesEnAlerte();
    }

    @PostMapping
    @PreAuthorize("hasRole('ROLE_PDG')")
    public Article createArticle(@Valid @RequestBody Article article) {
        return articleService.createArticle(article);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<Article> updateArticle(@PathVariable Long id, @Valid @RequestBody Article details) {
        Article updated = articleService.updateArticle(id, details);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ROLE_PDG')")
    public ResponseEntity<?> deleteArticle(@PathVariable Long id) {
        boolean deleted = articleService.deleteArticle(id);
        return deleted ? ResponseEntity.ok().build() : ResponseEntity.notFound().build();
    }
}
