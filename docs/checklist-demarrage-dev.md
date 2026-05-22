# Checklist demarrage developpement

## 1. Comptes et acces
- Supabase: projet cree, roles et acces admin limites.
- Stripe: mode test actif, webhook endpoint configure.
- Cloudinary: dossier media produit structure.
- Resend: domaine d'envoi valide (ou sandbox initiale).
- Render: environnements staging/prod prepares.
- Sentry: projets frontend/backend crees.

## 2. Variables d'environnement minimales
- Supabase:
  - SUPABASE_URL
  - SUPABASE_ANON_KEY
  - SUPABASE_SERVICE_ROLE_KEY
- Stripe:
  - STRIPE_SECRET_KEY
  - STRIPE_WEBHOOK_SECRET
  - STRIPE_PUBLIC_KEY
- Cloudinary:
  - CLOUDINARY_CLOUD_NAME
  - CLOUDINARY_API_KEY
  - CLOUDINARY_API_SECRET
- Resend:
  - RESEND_API_KEY
  - EMAIL_FROM
- Sentry:
  - SENTRY_DSN_FRONTEND
  - SENTRY_DSN_BACKEND
- App:
  - APP_BASE_URL
  - NODE_ENV

## 3. Securite immediate
- Fichier .env jamais commit.
- Rotation clefs si fuite suspectee.
- Permissions minimales pour chaque service.
- CORS strict vers domaines attendus.

## 4. Base de donnees - tables de depart
- users
- products
- product_options
- carts
- cart_items
- orders
- order_items
- payments
- payment_events
- reviews
- quotes
- invoices
- audit_logs

## 5. Conventions API des le jour 1
- Prefixe /api/v1
- Reponses erreur homogenes (code, message, details)
- Pagination standard
- Timestamps UTC
- Idempotency-Key sur routes sensibles

## 6. Scenarios a valider avant premiere demo
- Navigation accueil -> catalogue -> panier.
- Creation commande sans paiement online.
- Creation paiement Stripe test et webhook valide.
- Reprise paiement apres echec.
- Changement statut commande cote admin.

## 7. Elements en attente de votre part
- Informations legales completes de N&L Cuisinent.
- Media hero final (photo fixe ou defilement).
- Eventuelle politique commerciale (minimum commande, rayon livraison, frais).
