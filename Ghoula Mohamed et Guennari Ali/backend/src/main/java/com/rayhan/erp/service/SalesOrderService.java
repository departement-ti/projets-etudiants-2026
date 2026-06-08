package com.rayhan.erp.service;

import com.rayhan.erp.model.*;
import com.rayhan.erp.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Service
public class SalesOrderService {

    @Autowired private SalesOrderRepository salesOrderRepository;
    @Autowired private DeliveryNoteRepository deliveryNoteRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private StockService stockService;
    @Autowired private SequenceService sequenceService;
    @Autowired private NotificationService notificationService;
    @Autowired private UserRepository userRepository;
    @Autowired private ClientRepository clientRepository;

    @Transactional
    public SalesOrder createSalesOrder(SalesOrder order) {
        // Vérification du stock disponible avant validation
        for (SalesOrderLine ligne : order.getLignes()) {
            Article article = articleRepository.findById(ligne.getArticle().getId())
                .orElseThrow(() -> new RuntimeException("Article introuvable"));
            if (article.getStockActuel().compareTo(ligne.getQuantiteCommandee()) < 0) {
                throw new IllegalStateException(
                    "Stock insuffisant pour " + article.getDesignation());
            }
        }

        order.setReference(sequenceService.generateRef("CC"));
        order.setStatut(SalesOrder.StatutCommande.CONFIRMEE);

        BigDecimal totalHT = BigDecimal.ZERO;
        for (SalesOrderLine ligne : order.getLignes()) {
            ligne.setSalesOrder(order);
            BigDecimal montantHT = ligne.getPrixUnitaireHT().multiply(ligne.getQuantiteCommandee());
            ligne.setMontantHT(montantHT);
            BigDecimal tva = montantHT.multiply(ligne.getTauxTVA().divide(new BigDecimal("100")));
            ligne.setMontantTTC(montantHT.add(tva));
            totalHT = totalHT.add(montantHT);
        }

        order.setTotalHT(totalHT);
        BigDecimal tvaGlobal = totalHT.multiply(new BigDecimal("0.19"));
        order.setTotalTVA(tvaGlobal);
        order.setTotalTTC(totalHT.add(tvaGlobal));

        return salesOrderRepository.save(order);
    }

    @Transactional
    public DeliveryNote createDeliveryNote(Long salesOrderId, DeliveryNote bonLivraison, User user) {
        SalesOrder order = salesOrderRepository.findById(salesOrderId)
            .orElseThrow(() -> new RuntimeException("Commande introuvable : " + salesOrderId));

        bonLivraison.setReference(sequenceService.generateRef("BL"));
        bonLivraison.setSalesOrder(order);
        bonLivraison.setCreePar(user);

        for (DeliveryNoteLine ligne : bonLivraison.getLignes()) {
            ligne.setDeliveryNote(bonLivraison);
            Article article = articleRepository.findById(ligne.getArticle().getId())
                .orElseThrow(() -> new RuntimeException("Article introuvable"));
            ligne.setArticle(article);

            stockService.sortieStock(article, ligne.getQuantiteLivree(),
                "BON_LIVRAISON", bonLivraison.getReference(),
                "Livraison commande " + order.getReference(), user);

            ligne.getSalesOrderLine().setQuantiteLivree(
                ligne.getSalesOrderLine().getQuantiteLivree().add(ligne.getQuantiteLivree()));
        }

        order.setStatut(SalesOrder.StatutCommande.COMPLETEMENT_LIVREE);
        salesOrderRepository.save(order);

        return deliveryNoteRepository.save(bonLivraison);
    }

    public List<SalesOrder> getAllSalesOrders() {
        return salesOrderRepository.findAll();
    }

    @Transactional
    public SalesOrder createClientOrder(Long clientId, List<SalesOrderLine> lignes,
                                         String notes, LocalDate dateLivraisonSouhaitee, User creePar) {
        Client client = clientRepository.findById(clientId)
            .orElseThrow(() -> new RuntimeException("Client introuvable"));

        SalesOrder order = new SalesOrder();
        order.setClient(client);
        order.setCreePar(creePar);
        order.setDateCommande(LocalDate.now());
        order.setDateLivraisonSouhaitee(dateLivraisonSouhaitee);
        order.setNotes(notes);
        order.setStatut(SalesOrder.StatutCommande.EN_ATTENTE);
        order.setReference(sequenceService.generateRef("CC"));

        BigDecimal totalHT = BigDecimal.ZERO;
        for (SalesOrderLine ligne : lignes) {
            Article article = articleRepository.findById(ligne.getArticle().getId())
                .orElseThrow(() -> new RuntimeException("Article introuvable"));
            ligne.setSalesOrder(order);
            ligne.setArticle(article);
            ligne.setPrixUnitaireHT(article.getPrixUnitaire());
            ligne.setTauxTVA(new BigDecimal("19"));
            BigDecimal montantHT = article.getPrixUnitaire().multiply(ligne.getQuantiteCommandee());
            ligne.setMontantHT(montantHT);
            BigDecimal tva = montantHT.multiply(ligne.getTauxTVA().divide(new BigDecimal("100")));
            ligne.setMontantTTC(montantHT.add(tva));
            totalHT = totalHT.add(montantHT);
        }

        order.setTotalHT(totalHT);
        BigDecimal tvaGlobal = totalHT.multiply(new BigDecimal("0.19"));
        order.setTotalTVA(tvaGlobal);
        order.setTotalTTC(totalHT.add(tvaGlobal));
        order.setLignes(lignes);

        SalesOrder saved = salesOrderRepository.save(order);

        notificationService.notifyStaff(ERole.ROLE_RESPONSABLE_VENTE,
            Notification.TypeNotif.NEW_ORDER_PENDING, saved.getId(),
            "Nouvelle commande en attente: " + saved.getReference());
        notificationService.notifyStaff(ERole.ROLE_PDG,
            Notification.TypeNotif.NEW_ORDER_PENDING, saved.getId(),
            "Nouvelle commande en attente: " + saved.getReference());

        return saved;
    }

    public List<SalesOrder> getOrdersByClient(Long clientId) {
        return salesOrderRepository.findByClientIdOrderByDateCommandeDesc(clientId);
    }

    @Transactional
    public void cancelClientOrder(Long orderId, Long clientId) {
        SalesOrder order = salesOrderRepository.findById(orderId)
            .orElseThrow(() -> new RuntimeException("Commande introuvable"));
        if (!order.getClient().getId().equals(clientId)) {
            throw new RuntimeException("Cette commande ne vous appartient pas");
        }
        if (order.getStatut() != SalesOrder.StatutCommande.EN_ATTENTE) {
            throw new IllegalStateException("Seules les commandes en attente peuvent être annulées");
        }
        order.setStatut(SalesOrder.StatutCommande.ANNULEE);
        salesOrderRepository.save(order);
    }

    public List<SalesOrder> getPendingOrders() {
        return salesOrderRepository.findByStatut(SalesOrder.StatutCommande.EN_ATTENTE);
    }

    @Transactional
    public void approveOrder(Long orderId) {
        SalesOrder order = salesOrderRepository.findById(orderId)
            .orElseThrow(() -> new RuntimeException("Commande introuvable"));
        if (order.getStatut() != SalesOrder.StatutCommande.EN_ATTENTE) {
            throw new IllegalStateException("La commande n'est plus en attente");
        }

        for (SalesOrderLine ligne : order.getLignes()) {
            Article article = ligne.getArticle();
            if (article.getStockActuel().compareTo(ligne.getQuantiteCommandee()) < 0) {
                throw new IllegalStateException(
                    "Stock insuffisant pour " + article.getDesignation() +
                    " (demandé: " + ligne.getQuantiteCommandee() +
                    ", disponible: " + article.getStockActuel() + ")");
            }
        }

        order.setStatut(SalesOrder.StatutCommande.CONFIRMEE);
        salesOrderRepository.save(order);

        if (order.getClient().getUser() != null) {
            notificationService.create(order.getClient().getUser().getId(),
                Notification.TypeNotif.ORDER_STATUS_CHANGED, order.getId(),
                "Votre commande " + order.getReference() + " a été confirmée.");
        }
    }

    @Transactional
    public void rejectOrder(Long orderId) {
        SalesOrder order = salesOrderRepository.findById(orderId)
            .orElseThrow(() -> new RuntimeException("Commande introuvable"));
        if (order.getStatut() != SalesOrder.StatutCommande.EN_ATTENTE) {
            throw new IllegalStateException("La commande n'est plus en attente");
        }

        order.setStatut(SalesOrder.StatutCommande.ANNULEE);
        salesOrderRepository.save(order);

        if (order.getClient().getUser() != null) {
            notificationService.create(order.getClient().getUser().getId(),
                Notification.TypeNotif.ORDER_STATUS_CHANGED, order.getId(),
                "Votre commande " + order.getReference() + " a été refusée.");
        }
    }
}
