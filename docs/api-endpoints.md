# API endpoints

## Résumé de la page / fonctionnalité
Ce document recense les endpoints API principaux nécessaires au fonctionnement du site food truck, avec leur finalité, contraintes métier et exigences techniques.

## Objectifs
- Donner une vue unifiée des contrats d’échange frontend/backend.
- Clarifier les endpoints publics, authentifiés et administrateur.
- Réduire les ambiguïtés d’implémentation.
- Faciliter les tests d’intégration.

## Règles métier
- Les endpoints admin nécessitent un rôle autorisé.
- Les opérations critiques doivent être idempotentes si relançables.
- Les validations d’entrée sont obligatoires côté serveur.
- Les erreurs doivent être explicites sans exposer d’informations sensibles.
- Les timestamps sont normalisés en UTC.

## Spécifications fonctionnelles
- Catalogue:
  - GET /api/catalog/categories
  - GET /api/catalog/products
  - GET /api/catalog/products/{id}
- Panier:
  - GET /api/cart
  - POST /api/cart/items
  - PATCH /api/cart/items/{id}
  - DELETE /api/cart/items/{id}
- Commande:
  - POST /api/orders
  - GET /api/orders/{id}
  - GET /api/orders/{id}/status
- Paiement:
  - POST /api/payments/session
  - POST /api/payments/webhook
  - POST /api/payments/{orderId}/retry
- Compte client:
  - GET /api/me
  - PATCH /api/me
  - GET /api/me/orders
  - DELETE /api/me
- Contact et devis:
  - POST /api/contact
  - POST /api/quotes
- Avis:
  - GET /api/reviews
  - POST /api/reviews
  - POST /api/reviews/{id}/report
- Admin:
  - GET /api/admin/orders
  - PATCH /api/admin/orders/{id}/status
  - CRUD /api/admin/products
  - GET /api/admin/quotes
  - GET /api/admin/invoices

## Spécifications techniques
- Versionnement API (exemple: /api/v1).
- Authentification JWT/session selon endpoint.
- Pagination standard (page, limit, total).
- Filtrage et tri via query params contrôlés.
- Endpoint webhook paiement compatible signature Stripe (validation stricte avant traitement).
- Idempotence obligatoire sur création de session de paiement et relance.
- Codes HTTP cohérents (200, 201, 400, 401, 403, 404, 409, 422, 500).

## User flows
1. Le frontend charge le catalogue via API.
2. Le client construit son panier via endpoints panier.
3. La commande est créée puis payée via endpoints commande/paiement.
4. Le backend notifie les statuts.
5. L’admin pilote l’activité via endpoints admin.

## Cas particuliers
- Endpoint appelé en double: réponse idempotente pour création commande/paiement.
- Conflit de statut commande: retour 409 avec état courant.
- Limite de requêtes atteinte: retour 429 et délai conseillé.
- Schéma invalide: retour 422 avec détails de validation.

## Checklist de validation
- Tous les endpoints critiques sont documentés.
- Les droits d’accès sont définis par endpoint.
- Les formats d’erreur sont unifiés.
- Les conventions pagination/tri sont stables.
- Les webhooks sont sécurisés et testés.
- Les scénarios d’échec sont couverts.
