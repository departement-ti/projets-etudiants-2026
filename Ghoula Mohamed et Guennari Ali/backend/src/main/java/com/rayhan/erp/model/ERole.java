package com.rayhan.erp.model;

public enum ERole {
    ROLE_PDG,                    // Gérant (accès complet)
    ROLE_RESPONSABLE_VENTE,      // Responsable Commercial
    ROLE_RESPONSABLE_ACHAT,      // Responsable Achats
    ROLE_RESPONSABLE_PRODUCTION, // Responsable Production
    ROLE_MAGASINIER,             // Magasinier
    ROLE_CLIENT,                 // Client (accès portail)
    ROLE_FOURNISSEUR             // Fournisseur (accès portail)
}
