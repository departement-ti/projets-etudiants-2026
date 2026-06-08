# RayhanERP
**CAD_PFE_2026 — Solution ERP intégrée pour gérer l'ensemble des processus d'une entreprise**

### **Encadrante :** Mme Bourkhis Dalel
### **Étudiants :** Ali Guennari & Ghoula Mohamed
### **Technologies :** Java Spring Boot (backend), Flutter Web (frontend), MySQL, Docker

## Build & Run

### Full stack (backend + frontend + MySQL)
```bash
docker compose up -d --build
```
Puis accéder à `http://localhost:3013`


### Frontend only (données non réels pour presentation)
```bash
docker compose -f docker-compose.mock.yml up -d --build
```
Accéder à `http://localhost:3013` — aucun backend ni base de données requis.
