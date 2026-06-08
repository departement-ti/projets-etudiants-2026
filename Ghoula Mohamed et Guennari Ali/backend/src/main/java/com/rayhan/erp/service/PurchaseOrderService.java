package com.rayhan.erp.service;

import com.rayhan.erp.model.*;
import com.rayhan.erp.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class PurchaseOrderService {

    @Autowired private PurchaseOrderRepository purchaseOrderRepository;
    @Autowired private GoodsReceiptRepository goodsReceiptRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private StockService stockService;
    @Autowired private SequenceService sequenceService;

    @Transactional
    public PurchaseOrder createPurchaseOrder(PurchaseOrder order) {
        order.setReference(sequenceService.generateRef("BC"));
        order.setStatut(PurchaseOrder.StatutCommande.CONFIRMEE);

        BigDecimal totalHT = BigDecimal.ZERO;
        for (PurchaseOrderLine ligne : order.getLignes()) {
            ligne.setPurchaseOrder(order);
            BigDecimal montantHT = ligne.getPrixUnitaireHT()
                .multiply(ligne.getQuantiteCommandee());
            ligne.setMontantHT(montantHT);
            BigDecimal tva = montantHT.multiply(ligne.getTauxTVA().divide(new BigDecimal("100")));
            ligne.setMontantTTC(montantHT.add(tva));
            totalHT = totalHT.add(montantHT);
        }

        order.setTotalHT(totalHT);
        BigDecimal tvaGlobal = totalHT.multiply(new BigDecimal("0.19"));
        order.setTotalTVA(tvaGlobal);
        order.setTotalTTC(totalHT.add(tvaGlobal));

        return purchaseOrderRepository.save(order);
    }

    @Transactional
    public GoodsReceipt receiveGoods(Long purchaseOrderId, GoodsReceipt reception, User user) {
        PurchaseOrder order = purchaseOrderRepository.findById(purchaseOrderId)
            .orElseThrow(() -> new RuntimeException("Commande introuvable : " + purchaseOrderId));

        reception.setReference(sequenceService.generateRef("BR"));
        reception.setPurchaseOrder(order);
        reception.setCreePar(user);

        for (GoodsReceiptLine ligne : reception.getLignes()) {
            ligne.setGoodsReceipt(reception);
            Article article = articleRepository.findById(ligne.getArticle().getId())
                .orElseThrow(() -> new RuntimeException("Article introuvable"));
            ligne.setArticle(article);

            stockService.entreeStock(article, ligne.getQuantiteRecue(),
                "BON_RECEPTION", reception.getReference(),
                "Réception commande " + order.getReference(), user);

            ligne.getPurchaseOrderLine().setQuantiteRecue(
                ligne.getPurchaseOrderLine().getQuantiteRecue().add(ligne.getQuantiteRecue()));
        }

        order.setStatut(PurchaseOrder.StatutCommande.COMPLETEMENT_RECUE);
        purchaseOrderRepository.save(order);

        return goodsReceiptRepository.save(reception);
    }

    public List<PurchaseOrder> getAllPurchaseOrders() {
        return purchaseOrderRepository.findAll();
    }
}
