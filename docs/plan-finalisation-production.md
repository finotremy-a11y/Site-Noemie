# Plan de Finalisation Produit - Mise en Production

Date: 2026-04-07
Role: Architecture produit / technique

## 1) Etat actuel

- Application Rails 8 fonctionnelle avec parcours principal: catalogue, panier, checkout, compte client, avis, back-office.
- Socle qualite et securite present: RuboCop, Brakeman, bundler-audit, CI scriptable via `bin/ci`.
- Deploiement cible deja prepare (Render, variables d'environnement, health checks).
- Avancement global estime: 88%.

## 2) Vision de livraison

Objectif: livrer une application production-ready orientee usage mobile (majoritaire), avec une UX premium cote client et un back-office fluide cote food truck.

Critere principal de succes:

- Parcours mobile commande complete sans friction en moins de 2 minutes.
- Taux d'erreur 5xx < 0.5% en production.
- Validation qualite: lint, securite, tests, smoke tests de bout en bout.

## 3) Exigences produit non negociables

- Mobile-first: chaque ecran critique (home, catalogue, panier, checkout, compte, admin essentiel) doit etre lisible et operable au pouce.
- Hero homepage: image pleine largeur + effet cadre neon.
- Polish UI/UX global: typographie, hierarchie visuelle, contrastes, feedbacks d'action, micro-animations utiles.
- Validation finale complete: RuboCop, Brakeman, audits, tests unitaires/integration, tests de parcours e2e.

## 4) Plan en 3 phases

## Phase A - Stabilisation technique (J1-J4)

1. Verrouiller configuration de production
- Verifier toutes les variables critiques: `SECRET_KEY_BASE`, `RAILS_MASTER_KEY`, `STRIPE_*`, `RESEND_API_KEY`, `CLOUDINARY_*`, `SENTRY_DSN_BACKEND`, `ADMIN_API_TOKEN`, `FORCE_SSL`, `SECURE_COOKIES`.
- Controler la separation claire des cles test/live Stripe.

2. Renforcer la qualite de base
- Executer et stabiliser `bin/ci`.
- Corriger tous les ecarts RuboCop/Brakeman/audits avant phase UX finale.

3. Traiter les risques bloquants
- Completer contenu legal final (mentions, CGV, politique).
- Verifier monitoring erreurs et alertes.

Livrable: build stable pre-polish, deployable en staging.

## Phase B - UX Mobile-First et Polish visuel (J5-J10)

1. Navigation mobile premium
- Menu burger accessible (ouverture/fermeture, clavier, focus visible).
- Touch targets >= 44px sur actions principales.

2. Hero premium
- Hero full-width reelle (bleed horizontal) avec cadre neon credible.
- Lisibilite du contenu sur image (overlay et contrastes).

3. Polish transversal
- Harmoniser espacements, elevations cartes, etats hover/focus.
- Ajuster typographie mobile (lisibilite, line-height, tailles mini iOS).
- Uniformiser styles CTA primaires/secondaires et champs formulaire.

4. Validation UX
- Revue visuelle ecrans principaux mobile/tablette/desktop.
- Smoke manuel commande sur mobile (home -> catalogue -> panier -> checkout).

Livrable: UI/UX finale candidate production.

## Phase C - Validation complete et Go-Live (J11-J14)

1. Validation qualite complete
- RuboCop, Brakeman, bundler-audit, importmap audit, tests Rails.
- Ajout/activation e2e de parcours critique (commande + paiement + confirmation).

2. Validation metier
- Test paiement complet (session checkout -> webhook -> facture -> email).
- Test operationnel food truck sur back-office (changement statuts, exports, moderation avis).

3. Mise en production
- Deploy Render, migrations, health checks.
- Smoke test post-deploy.
- Monitoring intensif 48h (Sentry, logs app, incidents paiements).

Livrable: application en production avec runbook de suivi.

## 5) Definition of Done Go-Live

- 0 offense RuboCop.
- 0 warning Brakeman bloquante.
- 0 vuln critique via audits.
- 100% tests green (unitaire/integration) + parcours e2e critique green.
- UX mobile validee sur ecrans iOS/Android representatifs.
- Paiement live et notifications verifies.
- Donnees legales completes et publiees.

## 6) Checklist execution finale

1. `bin/ci`
2. `bin/rails test:system` (ou suite e2e equivalente)
3. `bin/rails zeitwerk:check`
4. Deploy staging + smoke tests
5. Validation paiement Stripe live keys
6. Deploy production + smoke tests + monitoring 48h

Runbook operationnel minute par minute:
- `docs/checklist-go-live-minute-par-minute.md`

## 7) Priorites immediates (ce sprint)

- Finaliser polish mobile et hero neon.
- Ajouter au moins un scenario e2e checkout.
- Executer la validation qualite complete.
- Corriger tout ecart bloquant avant go-live.
