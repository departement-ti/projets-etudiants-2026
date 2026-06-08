package com.rayhan.erp.controller;

import com.rayhan.erp.model.GoodsReceipt;
import com.rayhan.erp.model.PurchaseOrder;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.UserRepository;
import com.rayhan.erp.security.services.UserDetailsImpl;
import com.rayhan.erp.service.PurchaseOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/purchase-orders")
public class PurchaseOrderController {

    @Autowired private PurchaseOrderService purchaseOrderService;
    @Autowired private UserRepository userRepository;

    @GetMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public List<PurchaseOrder> getAllOrders() {
        return purchaseOrderService.getAllPurchaseOrders();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT')")
    public ResponseEntity<PurchaseOrder> createOrder(@RequestBody PurchaseOrder order,
                                                      @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        order.setCreePar(user);
        return ResponseEntity.ok(purchaseOrderService.createPurchaseOrder(order));
    }

    @PostMapping("/{id}/receive")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_ACHAT', 'ROLE_MAGASINIER')")
    public ResponseEntity<GoodsReceipt> receiveGoods(@PathVariable Long id,
                                                      @RequestBody GoodsReceipt reception,
                                                      @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        return ResponseEntity.ok(purchaseOrderService.receiveGoods(id, reception, user));
    }
}
