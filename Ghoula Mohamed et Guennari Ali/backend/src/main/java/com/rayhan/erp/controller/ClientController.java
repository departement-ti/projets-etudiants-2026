package com.rayhan.erp.controller;

import com.rayhan.erp.dto.request.ClientWithUserRequest;
import com.rayhan.erp.model.Client;
import com.rayhan.erp.service.ClientService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/clients")
public class ClientController {

    @Autowired
    private ClientService clientService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public List<Client> getAllClients() {
        return clientService.getAllClients();
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public List<Client> searchClients(@RequestParam String q) {
        return clientService.searchClients(q);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public ResponseEntity<Client> getClientById(@PathVariable Long id) {
        Client client = clientService.getClientById(id);
        return client != null ? ResponseEntity.ok(client) : ResponseEntity.notFound().build();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public Client createClient(@Valid @RequestBody Client client) {
        return clientService.createClient(client);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public ResponseEntity<Client> updateClient(@PathVariable Long id, @Valid @RequestBody Client details) {
        Client updated = clientService.updateClient(id, details);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @PostMapping("/with-user")
    @PreAuthorize("hasAnyRole('ROLE_PDG', 'ROLE_RESPONSABLE_VENTE')")
    public Client createClientWithUser(@Valid @RequestBody ClientWithUserRequest request) {
        return clientService.createClientWithUser(request);
    }
}
