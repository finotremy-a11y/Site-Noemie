# N&L Cuisinent - Rails Application

Application web Rails 8 pour le food truck N&L Cuisinent.

## Stack technique
- Rails 8.1 + PostgreSQL
- Stripe (paiement + webhook)
- Supabase (BDD/Auth en integration)
- Cloudinary (media)
- Resend (emails transactionnels)
- Sentry (observabilite erreurs)
- Render (hebergement cible)

## Pre-requis
- Ruby 3.4+
- PostgreSQL 14+

## Installation locale
1. Copier les variables d'environnement:

	cp .env.example .env

2. Installer les dependances:

	bundle install

3. Creer et migrer la base:

	bin/rails db:create
	bin/rails db:migrate

4. Lancer l'application:

	bin/rails server

## Endpoints de base
- `GET /up` (healthcheck Rails)
- `GET /api/v1/health` (healthcheck API)
- `POST /api/v1/payments/session` (creation session Stripe)
- `POST /api/v1/payments/webhook` (webhook Stripe signe)

## Notes demarrage
- La homepage est en Style A Dark Premium.
- La section hero supporte deja un media de fond via:
  - HERO_MEDIA_URL
  - HERO_MEDIA_MODE (`fixed` ou `slider`)
- Les pages legales sont disponibles sur le site et doivent etre relues avant mise en production.
- En production mono-service, les jobs Solid Queue doivent etre actives via `SOLID_QUEUE_IN_PUMA=true` ou via un worker dedie.

## Tests
Lancer tous les tests:

bin/rails test
