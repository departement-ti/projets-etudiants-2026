package com.rayhan.erp.repository;

import com.rayhan.erp.model.Article;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ArticleRepository extends JpaRepository<Article, Long> {
    Optional<Article> findByReference(String reference);
    Boolean existsByReference(String reference);
    List<Article> findByType(Article.TypeArticle type);
    List<Article> findByActifTrue();
    List<Article> findByStockActuelLessThanEqualAndActifTrue(java.math.BigDecimal seuil);
    List<Article> findByTypeAndActifTrue(Article.TypeArticle type);
}
