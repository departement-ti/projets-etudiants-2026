package com.rayhan.erp.service;

import com.rayhan.erp.model.Article;
import com.rayhan.erp.repository.ArticleRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ArticleService {

    @Autowired
    private ArticleRepository articleRepository;

    public List<Article> getAllArticles() {
        return articleRepository.findByActifTrue();
    }

    public List<Article> getPublicCatalog() {
        return articleRepository.findByTypeAndActifTrue(Article.TypeArticle.PF);
    }

    public List<Article> getArticlesByType(Article.TypeArticle type) {
        return articleRepository.findByType(type);
    }

    public List<Article> getArticlesEnAlerte() {
        return articleRepository.findByStockActuelLessThanEqualAndActifTrue(java.math.BigDecimal.ZERO);
    }

    public Article getArticleById(Long id) {
        return articleRepository.findById(id).orElse(null);
    }

    public Article createArticle(@Valid Article article) {
        return articleRepository.save(article);
    }

    public Article updateArticle(Long id, Article details) {
        return articleRepository.findById(id).map(article -> {
            article.setDesignation(details.getDesignation());
            article.setType(details.getType());
            article.setUniteMesure(details.getUniteMesure());
            article.setPrixUnitaire(details.getPrixUnitaire());
            article.setStockMinimum(details.getStockMinimum());
            article.setAssetImage(details.getAssetImage());
            return articleRepository.save(article);
        }).orElse(null);
    }

    public boolean deleteArticle(Long id) {
        return articleRepository.findById(id).map(article -> {
            article.setActif(false);
            articleRepository.save(article);
            return true;
        }).orElse(false);
    }

    public boolean existsById(Long id) {
        return articleRepository.existsById(id);
    }
}
