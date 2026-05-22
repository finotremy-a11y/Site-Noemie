# N&L Cuisinent — Frontend + Backend Rails

Application web complète pour food truck premium N&L Cuisinent avec intégration Stripe, notifications Resend et observabilité Sentry.

## 🚀 Stack Technique

- **Framework**: Rails 8 (API + Views)
- **Database**: PostgreSQL
- **Cache/Queue**: Redis
- **Paiement**: Stripe
- **Emails**: Resend (transactionnel)
- **Stockage**: Cloudinary
- **Monitoring**: Sentry
- **Frontend**: Stimulus JS, CSS3 (Style A Dark Premium)
- **Déploiement**: Render.com

## 📋 Démarrage Local

### Prérequis

```bash
ruby 3.3.0
postgres 15+
redis 7+
```

### Installation

```bash
# Cloner le repo
git clone <repo>
cd site_noemie

# Dependencies
bundle install

# Configuration
cp .env.example .env
# Éditer .env avec vos clés

# Database
rails db:create
rails db:migrate
rails db:seed  # Optionnel: données de démo

# Démarrer
rails s
# Aller à http://localhost:3000
```

## 🏗️ Architecture

### API v1 (87 endpoints)

```
/api/v1/
  ├─ health                    # Health check
  ├─ auth/session              # Login client
  ├─ me                        # Profil client
  ├─ me/addresses              # Adresses (multi)
  ├─ me/preferences            # Préférences client
  ├─ me/orders                 # Historique commandes
  ├─ me/invoices               # Téléchargement factures
  ├─ catalog/categories        # Catégories produits
  ├─ catalog/products          # Produits (filtres, pagination)
  ├─ cart                      # Gestion panier
  ├─ orders                    # Commandes client
  ├─ reviews                   # Avis (public create, list approved)
  ├─ contact                   # Formulaire contact
  ├─ payments/...              # Stripe session + webhook
  └─ admin/                    # [Protected by X-Admin-Token]
      ├─ orders                # Gestion commandes
      ├─ products              # CRUD produits
      ├─ reviews               # Modération avis
      ├─ quotes                # Devis admin
      ├─ invoices              # Factures
      ├─ exports/{orders,invoices,products} # CSV export
      ├─ audit_logs            # Traçabilité
      └─ dashboard/summary     # KPI dashboard
```

### Web Views (Style A Dark Premium)

```
/                   # Accueil (hero + présentation)
/catalog            # Catalogue produits
/cart               # Panier
/checkout           # Tunnel commande
/login              # Authentification
/register           # Inscription
/me                 # Profil client
/me/orders          # Mes commandes
/me/addresses       # Mes adresses
/reviews            # Avis client
/contact            # Contact/devis
```

## 🔐 Sécurité

- **Auth Client**: Token API par session
- **Auth Admin**: X-Admin-Token header + IP whitelist (Rack::Attack)
- **Stripe**: Signature webhook validée
- **CORS**: Activé pour frontend
- **Rate Limit**: Rack::Attack (100 req/min par IP)
- **CSRF**: Activé par défaut Rails

## 📝 Database Schema

### Tables cœur
- **users** (id, email, api_token, password_digest, addresses, preferences)
- **products** (id, name, description, sku, price, category_id, available)
- **categories** (id, name, slug)
- **carts** (id, session_id, user_id, subtotal, delivery_fee, total)
- **cart_items** (id, cart_id, product_id, quantity, unit_price)
- **orders** (id, user_id, status, total, delivery_mode, address_id)
- **order_items** (id, order_id, product_id, quantity, unit_price)
- **payments** (id, order_id, stripe_session_id, status, amount)
- **payment_events** (id, payment_id, stripe_event_id, event_type, data)
- **invoices** (id, order_id, number, pdf_url, issued_at)
- **reviews** (id, user_id, product_id, rating, title, comment, status)
- **contact_requests** (id, name, email, subject, message)
- **quotes** (id, contact_request_id, price, status)
- **addresses** (id, user_id, street, zip_code, city, is_default)
- **user_preferences** (id, user_id, newsletter_opt_in, sms_notifications)
- **audit_logs** (id, resource_type, resource_id, action, user_id, changes)

## 🎯 Workflows Clés

### Commande client
1. Client browse catalogue + ajoute panier
2. Panier → checkout (adresse + livraison)
3. POST /orders → crée Order (pending_payment)
4. Redirect vers Stripe checkout via /payments/session
5. Client paye
6. Webhook Stripe → PaymentEvent → Order.confirmed
7. Facture auto-générée
8. Email Resend client + admin

### Admin commande
1. GET /admin/orders (liste)
2. PATCH /admin/orders/:id/status (pending → preparing → ready → delivered)
3. Audit trail logged
4. Email client sur transition

### Avis modération
1. Client POST /reviews (status: pending)
2. Admin GET /admin/reviews (list pending)
3. Admin PATCH /admin/reviews/:id/status (approve/reject)
4. Admin peut poster response

## 📦 Services clés

### Payments
- `CreateCheckoutSession` → crée session Stripe
- `HandleStripeWebhook` → déduplication events, idempotence

### Orders
- `CreateFromCart` → crée Order + OrderItems
- `TransitionStatus` → valide transitions, audit trail
- `IssueInvoice` → génère facture PDF

### Notifications
- `SendOrderConfirmationEmailJob` → Resend
- `SendCustomerNotificationJob` → async dispatch

### Documents
- `InvoiceGenerator` → PDF via Prawn

## 🔌 Webhooks

### Stripe
```
POST /api/v1/payments/webhook
  - charge.succeeded → Payment.confirmed
  - charge.failed → Payment.failed
  - payment_intent.canceled → Order.cancelled
```

## 📊 Admin Dashboard KPI

```json
GET /api/v1/admin/dashboard/summary
{
  "today_orders": 15,
  "today_revenue": 450.50,
  "pending_orders": 5,
  "pending_reviews": 3,
  "avg_order_value": 30.03,
  "monthly_revenue": 8920.25
}
```

## 🚀 Déploiement Render.com

```bash
# Push vers Render (git-configured)
git push render main

# ou via render.yaml config:
# - Crée PostgreSQL + Redis
# - Build: bundle install, assets:precompile, db:migrate
# - Start: puma
# - Health: /api/v1/health

# Variables d'env à setter:
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
ADMIN_API_TOKEN=xxx
SECRET_KEY_BASE=xxx
RESEND_API_KEY=re_xxx
SENTRY_DSN_BACKEND=xxx
CLOUDINARY_*=xxx
```

## 📚 Documentation

- [`docs/plan-technique-v1.md`](docs/plan-technique-v1.md) — Plan phase réalisé
- [`docs/architecture-technique.md`](docs/architecture-technique.md) — Architecture complète
- [`docs/quality-gates.md`](docs/quality-gates.md) — Checklist qualité
- [`docs/paiement.md`](docs/paiement.md) — Détails intégration Stripe

## 🧪 Tests

```bash
rails test                                   # All
rails test test/controllers/api/v1/health_controller_test.rb  # Specific
```

## 🎨 Maquettes

Voir [`mockups/`](mockups/) pour Style A Dark Premium (proto HTML).

## 📞 Support

- Email admin: gerant@nlcuisinent.fr
- Contact form: /contact
- Issues: tracker interne

---

**🎉 N&L Cuisinent is ready to serve!**
