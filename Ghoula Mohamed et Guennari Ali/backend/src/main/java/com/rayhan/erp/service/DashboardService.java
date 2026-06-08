package com.rayhan.erp.service;

import com.rayhan.erp.model.Article;
import com.rayhan.erp.model.ProductionOrder;
import com.rayhan.erp.model.PurchaseOrder;
import com.rayhan.erp.model.SalesOrder;
import com.rayhan.erp.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DashboardService {

    @Autowired
    private SalesOrderRepository salesOrderRepository;
    @Autowired
    private PurchaseOrderRepository purchaseOrderRepository;
    @Autowired
    private ProductionOrderRepository productionOrderRepository;
    @Autowired
    private ArticleRepository articleRepository;

    public Map<String, Object> getDashboard() {
        Map<String, Object> dashboard = new HashMap<>();

        LocalDate debutMois = LocalDate.now().withDayOfMonth(1);
        LocalDate finMois = LocalDate.now();

        dashboard.put("ventes", getVentesKpis(debutMois, finMois));
        dashboard.put("achats", getAchatsKpis());
        dashboard.put("production", getProductionKpis());
        dashboard.put("stock", getStockKpis());

        return dashboard;
    }

    private Map<String, Object> getVentesKpis(LocalDate debutMois, LocalDate finMois) {
        BigDecimal caMois = salesOrderRepository.sumTotalTTCByDateCommandeBetween(debutMois, finMois);
        long nbCommandesMois = salesOrderRepository.countByDateCommandeBetween(debutMois, finMois);

        Map<String, Object> ventes = new HashMap<>();
        ventes.put("chiffreAffairesMois", caMois != null ? caMois : BigDecimal.ZERO);
        ventes.put("nbCommandesMois", nbCommandesMois);
        ventes.put("commandesEnCours",
            salesOrderRepository.findByStatutOrderByDateCommandeDesc(SalesOrder.StatutCommande.CONFIRMEE).size());
        return ventes;
    }

    private Map<String, Object> getAchatsKpis() {
        Map<String, Object> achats = new HashMap<>();
        achats.put("commandesEnAttente",
            purchaseOrderRepository.countByStatutIn(
                List.of(PurchaseOrder.StatutCommande.CONFIRMEE,
                        PurchaseOrder.StatutCommande.PARTIELLEMENT_RECUE)));
        return achats;
    }

    private Map<String, Object> getProductionKpis() {
        Map<String, Object> production = new HashMap<>();
        production.put("ofPlanifies",
            productionOrderRepository.countByStatut(ProductionOrder.StatutOF.PLANIFIE));
        production.put("ofEnCours",
            productionOrderRepository.countByStatut(ProductionOrder.StatutOF.LANCE));
        return production;
    }

    private Map<String, Object> getStockKpis() {
        List<Article> alertesStock = articleRepository.findByStockActuelLessThanEqualAndActifTrue(BigDecimal.ZERO);
        Map<String, Object> stock = new HashMap<>();
        stock.put("articlesEnAlerte", alertesStock.size());
        stock.put("articlesEnAlerteDetails", alertesStock.stream()
            .map(a -> Map.of("reference", a.getReference(),
                             "designation", a.getDesignation(),
                             "stockActuel", a.getStockActuel(),
                             "stockMinimum", a.getStockMinimum()))
            .toList());
        return stock;
    }
}
