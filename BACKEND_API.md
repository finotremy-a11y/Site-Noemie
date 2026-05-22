# N&L Cuisinent — Rails Backend API

## Stack technique

- **Rails 8** avec API-only, PostgreSQL
- **Authentification**: tokens API client/admin
- **Paiement**: Stripe (checkout session + webhooks)
- **Stockage**: Cloudinary (images, factures PDF)
- **Email**: Rails Mailer + job queue
- **Observabilité**: Sentry (errors + business context)
- **Audit**: AuditLog avec traçabilité complète

## Architecture API v1

### Endpoints client (avec X-Customer-Token)

- `POST /api/v1/auth/session` — Créer une session client
- `GET /api/v1/me` — Profil client
- `PATCH /api/v1/me` — Modifier profil
- `DELETE /api/v1/me` — Supprimer compte
- `GET /api/v1/me/addresses` — Adresses du client
- `POST /api/v1/me/addresses` — Ajouter adresse
- `GET /api/v1/me/preferences` — Préférences client
- `PATCH /api/v1/me/preferences` — Modifier préférences
- `GET /api/v1/me/invoices` — Factures du client
- `GET /api/v1/me/invoices/:id/download` — Télécharger facture PDF

### Endpoints produits/catalogue public

- `GET /api/v1/catalog/categories` — Lister catégories
- `GET /api/v1/catalog/products` — Produits (pagination, filtres, recherche)
- `GET /api/v1/catalog/products/:id` — Détail produit

### Endpoints panier/commande

- `GET /api/v1/cart` — Afficher panier
- `POST /api/v1/cart/items` — Ajouter au panier
- `PATCH /api/v1/cart/items/:id` — Modifier quantité
- `DELETE /api/v1/cart/items/:id` — Retirer du panier
- `POST /api/v1/orders` — Créer commande depuis panier (idempotent)
- `GET /api/v1/orders/:id` — Détail commande
- `GET /api/v1/orders/:id/status` — Statut commande

### Endpoints paiement

- `POST /api/v1/payments/session` — Créer session Stripe
- `POST /api/v1/payments/:order_id/retry` — Relancer paiement
- `POST /api/v1/payments/webhook` — Webhook Stripe signé

### Endpoints contact/devis

- `POST /api/v1/contact` — Créer demande contact
- `POST /api/v1/quotes` — Demander devis
- `GET /api/v1/reviews` — Avis approuvés
- `POST /api/v1/reviews` — Créer avis
- `POST /api/v1/reviews/:id/report` — Signaler avis

### Endpoints admin (avec X-Admin-Token)

- `GET /api/v1/admin/audit_logs` — Logs d'audit
- `GET /api/v1/admin/audit_logs/:id` — Détail audit log
- `GET /api/v1/admin/dashboard/summary` — KPI dashboard
- `GET /api/v1/admin/orders` — Lister commandes
- `PATCH /api/v1/admin/orders/:id/status` — Changer statut commande
- `GET /api/v1/admin/reviews` — Modérer avis
- `PATCH /api/v1/admin/reviews/:id/status` — Approuver/rejeter avis
- `GET /api/v1/admin/invoices` — Lister factures
- `GET /api/v1/admin/invoices/:id` — Détail facture
- `GET /api/v1/admin/quotes` — Lister devis
- `GET /api/v1/admin/quotes/:id` — Détail devis
- `PATCH /api/v1/admin/quotes/:id/status` — Changer statut devis
- `GET /api/v1/admin/products` — Produits (CRUD)
- `POST /api/v1/admin/products` — Créer produit
- `GET /api/v1/admin/exports/orders` — Export CSV commandes
- `GET /api/v1/admin/exports/invoices` — Export CSV factures
- `GET /api/v1/admin/exports/products` — Export CSV produits

## Modèles de données

### User
- Identifiant client unique par email
- Token API séparé client/admin
- Adresses multiples (delivery/billing)
- Préférences de notification

### Product
- SKU, nom, descriptions
- Catégorie, prix, stock
- Options (tailles, couleurs)
- Historique des changements de prix

### Order
- Numéro unique, statut (pending→prepared→delivered)
- Cliente lié, articles avec quantités/prix capturés
- Total, frais de livraison, fiscalité
- Paiement lié, facture générée

### Payment
- Provider (Stripe), session ID, statut
- Montant, devise, date de paiement
- Événements (webhooks) tracés avec déduplication

### Invoice
- Généré automatiquement à la confirmation de paiement
- PDF uploadé async sur Cloudinary
- Numéro unique, date d'émission
- Lien paiement/commande

### Quote
- Demande de devis client (email + détails)
- Statut (draft→sent→accepted/rejected)
- Notifications client sur changement de statut

### AuditLog
- Traçabilité complète: create/update/destroy
- User, action, ressource, changements
- Timestamps, métadonnées contextuelles

## Workflows critiques

### 1. Cycle commande-paiement

1. Client -> `POST /api/v1/orders` avec panier
2. Commande créée, statut `pending`
3. Client -> `POST /api/v1/payments/session` → URL Stripe
4. Client paie sur Stripe
5. Webhook Stripe -> `POST /api/v1/payments/webhook`
6. Facture générée, PDF en queue
7. Notifications emails async
8. Admin monitore depuis `/admin/dashboard` et peut changer statut

### 2. Gestion des adresses

- Client peut créer N adresses (delivery/billing)
- Marquer une par type comme "par défaut"
- Utilisée auto au checkout

### 3. Facturation

- Facture générée dès paiement confirmé
- PDF généré async via Prawn
- Upload Cloudinary en job avec retries
- Client télécharge via `/me/invoices/:id/download`
- Admin exporte CSV `/admin/exports/invoices`

## Sécurité

- **Rate limiting**: Rack::Attack sur endpoints sensibles
- **Idempotence**: Cache + clés client pour ordres, webhooks Stripe signés
- **Auth**: Tokens API sécurisés, pas de sessions
- **HTTPS only**: Redirect automatique en production
- **CORS**: Restreint aux domaines N&L Cuisinent

## Observabilité

- **Logs**: Rails standard + contexte métier via Sentry
- **Sentry**: Erreurs, warnings (ex: échec paiement), user context (role, orders_count)
- **Audit**: AuditLog pour chaque mutation

## Notes sur la migration de l'existant

Ce socle a été créé de zéro pour garantir une qualité production. L'ancien code Rails a été conservé en docs et mockups pour référence.

## Démarrage local

```bash
bundle install
rails db:create db:migrate
STRIPE_SECRET_KEY=sk_test_... rails s
```

Variables d'env requises: `.env.example`

## Déploiement

- Render.com avec PostgreSQL
- Build: `bundle install && rails db:migrate`
- Env: SENTRY_DSN_BACKEND, STRIPE_SECRET_KEY, etc.
