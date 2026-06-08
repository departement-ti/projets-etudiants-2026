package com.rayhan.erp.controller;

import com.rayhan.erp.dto.request.ClientOrderRequest;
import com.rayhan.erp.model.*;
import com.rayhan.erp.repository.UserRepository;
import com.rayhan.erp.security.services.UserDetailsImpl;
import com.rayhan.erp.service.SalesOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/sales-orders")
public class SalesOrderController {

    @Autowired private SalesOrderService salesOrderService;
    @Autowired private UserRepository userRepository;

    @GetMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public List<SalesOrder> getAllOrders() {
        return salesOrderService.getAllSalesOrders();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public ResponseEntity<SalesOrder> createOrder(@RequestBody SalesOrder order,
                                                   @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        order.setCreePar(user);
        return ResponseEntity.ok(salesOrderService.createSalesOrder(order));
    }

    @PostMapping("/{id}/deliver")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE', 'ROLE_MAGASINIER')")
    public ResponseEntity<DeliveryNote> createDelivery(@PathVariable Long id,
                                                        @RequestBody DeliveryNote bonLivraison,
                                                        @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        return ResponseEntity.ok(salesOrderService.createDeliveryNote(id, bonLivraison, user));
    }

    @PostMapping("/client")
    @PreAuthorize("hasRole('ROLE_CLIENT')")
    public ResponseEntity<SalesOrder> createClientOrder(@RequestBody ClientOrderRequest req,
                                                         @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        if (user == null || user.getClient() == null) {
            return ResponseEntity.badRequest().build();
        }

        List<SalesOrderLine> lignes = new ArrayList<>();
        for (ClientOrderRequest.OrderLine ol : req.getLignes()) {
            Article article = new Article();
            article.setId(ol.getArticleId());
            SalesOrderLine ligne = new SalesOrderLine();
            ligne.setArticle(article);
            ligne.setQuantiteCommandee(java.math.BigDecimal.valueOf(ol.getQuantite()));
            lignes.add(ligne);
        }

        LocalDate dateLivr = req.getDateLivraisonSouhaitee() != null
            ? LocalDate.parse(req.getDateLivraisonSouhaitee())
            : null;

        SalesOrder saved = salesOrderService.createClientOrder(
            user.getClient().getId(), lignes, req.getNotes(), dateLivr, user);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/client/mine")
    @PreAuthorize("hasRole('ROLE_CLIENT')")
    public ResponseEntity<List<SalesOrder>> getMyOrders(
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        if (user == null || user.getClient() == null) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(salesOrderService.getOrdersByClient(user.getClient().getId()));
    }

    @PutMapping("/client/{id}/cancel")
    @PreAuthorize("hasRole('ROLE_CLIENT')")
    public ResponseEntity<?> cancelMyOrder(@PathVariable Long id,
                                            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        if (user == null || user.getClient() == null) {
            return ResponseEntity.badRequest().build();
        }
        try {
            salesOrderService.cancelClientOrder(id, user.getClient().getId());
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public List<SalesOrder> getPendingOrders() {
        return salesOrderService.getPendingOrders();
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public ResponseEntity<?> approveOrder(@PathVariable Long id) {
        try {
            salesOrderService.approveOrder(id);
            return ResponseEntity.ok().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public ResponseEntity<?> rejectOrder(@PathVariable Long id) {
        try {
            salesOrderService.rejectOrder(id);
            return ResponseEntity.ok().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }
}
