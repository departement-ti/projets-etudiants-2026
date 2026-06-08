package com.rayhan.erp.controller;

import com.rayhan.erp.model.Article;
import com.rayhan.erp.service.ArticleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/public")
public class PublicController {

    @Autowired
    private ArticleService articleService;

    @GetMapping("/articles")
    public List<Article> getCatalog() {
        return articleService.getPublicCatalog();
    }

    @GetMapping("/articles/{id}")
    public ResponseEntity<Article> getArticle(@PathVariable Long id) {
        Article article = articleService.getArticleById(id);
        return article != null && article.isActif() && article.getType() == Article.TypeArticle.PF
            ? ResponseEntity.ok(article)
            : ResponseEntity.notFound().build();
    }
}
