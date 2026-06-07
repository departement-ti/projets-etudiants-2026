# Clinova — Mohamed Karrab

## Projet

Plateforme hospitalière **Clinova** : gestion clinique multi-rôles (admin, médecin, infirmier, laboratoire, comptable, secrétaire, patient).

## Technologies

| Composant | Stack |
|-----------|--------|
| API | Laravel (PHP), JWT |
| Web staff | Angular 19, i18n FR/EN/AR |
| Mobile patient | Flutter |

## Dépôt principal

**https://github.com/karrab309-maker/clinova**

Le code source complet (Laravel + Angular + Flutter) se trouve dans ce dépôt.

## Installation rapide

```bash
# API
cp .env.example .env
composer install
php artisan key:generate
php artisan jwt:secret
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000

# Angular (dossier angular-app)
npm install
npm start

# Flutter (dossier flutter_patient_app)
flutter pub get
flutter run
```

Scripts Windows : `demarrer-api.bat`, `demarrer.bat`

## Comptes démo

Après `php artisan db:seed`, mot de passe : **password123**

Voir `docs/CLINOVA_SCENARIOS.md` pour les scénarios par rôle.

## Auteur

- **Étudiant** : Mohamed Karrab
- **Compte GitHub** : karrab309-maker
- **Session** : 2026
