package com.rayhan.erp.controller;

import com.rayhan.erp.model.BomLine;
import com.rayhan.erp.model.ProductionOrder;
import com.rayhan.erp.model.User;
import com.rayhan.erp.repository.BomLineRepository;
import com.rayhan.erp.repository.UserRepository;
import com.rayhan.erp.security.services.UserDetailsImpl;
import com.rayhan.erp.service.ProductionOrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/production")
public class ProductionOrderController {

    @Autowired private ProductionOrderService productionOrderService;
    @Autowired private BomLineRepository bomLineRepository;
    @Autowired private UserRepository userRepository;

    // --- BOM (Nomenclatures) ---

    @GetMapping("/bom/{produitFiniId}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public List<BomLine> getBom(@PathVariable Long produitFiniId) {
        return bomLineRepository.findByProduitFiniId(produitFiniId);
    }

    @PostMapping("/bom")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public BomLine addBomLine(@RequestBody BomLine bomLine) {
        return bomLineRepository.save(bomLine);
    }

    @DeleteMapping("/bom/{id}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public ResponseEntity<?> deleteBomLine(@PathVariable Long id) {
        bomLineRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- Ordres de Fabrication ---

    @GetMapping("/orders")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public List<ProductionOrder> getAllOFs() {
        return productionOrderService.getAllOFs();
    }

    @PostMapping("/orders/plan")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public ResponseEntity<ProductionOrder> planOF(@RequestBody Map<String, Object> request,
                                                   @AuthenticationPrincipal UserDetailsImpl userDetails) {
        Long produitId = Long.valueOf(request.get("produitFiniId").toString());
        BigDecimal quantite = new BigDecimal(request.get("quantite").toString());
        LocalDate date = LocalDate.parse(request.get("datePlanifiee").toString());
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        return ResponseEntity.ok(productionOrderService.planifierOF(produitId, quantite, date, user));
    }

    @PostMapping("/orders/{id}/launch")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public ResponseEntity<ProductionOrder> launchOF(@PathVariable Long id,
                                                     @AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        return ResponseEntity.ok(productionOrderService.lancerOF(id, user));
    }

    @PostMapping("/orders/{id}/complete")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_PRODUCTION')")
    public ResponseEntity<ProductionOrder> completeOF(@PathVariable Long id,
                                                       @RequestBody Map<String, Object> request,
                                                       @AuthenticationPrincipal UserDetailsImpl userDetails) {
        BigDecimal quantiteRealisee = new BigDecimal(request.get("quantiteRealisee").toString());
        User user = userRepository.findById(userDetails.getId()).orElse(null);
        return ResponseEntity.ok(productionOrderService.terminerOF(id, quantiteRealisee, user));
    }
}
