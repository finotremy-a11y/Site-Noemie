# Checklist Go-Live Minute Par Minute

Date: 2026-04-07
Reference: docs/plan-finalisation-production.md

Cette checklist est operationnelle, chronologique, et separe staging puis production.

## A. Staging - Preparation (T-60 a T-0)

T-60
- Verifier que la branche cible est a jour et stable.
- Verifier que toutes les variables d'environnement staging sont renseignees.
- Confirmer que les cles Stripe sont en mode test pour staging.

T-50
- Executer validation locale complete:
  - `bin/ci`
- Confirmer que la step system test passe dans la CI.

T-40
- Verifier disponibilite des services tiers (Stripe, Resend, Cloudinary, Sentry).
- Verifier acces dashboard Render et base PostgreSQL staging.

T-30
- Lancer deploy staging.
- Verifier la fin de build sans erreurs.

T-25
- Verifier health checks:
  - `/up`
  - `/api/v1/health`

T-20
- Parcours client mobile smoke:
  - home
  - catalogue
  - panier
  - checkout
  - confirmation

T-15
- Parcours paiement test Stripe:
  - session checkout
  - webhook
  - statut commande

T-10
- Verifier envoi email confirmation.
- Verifier generation facture PDF.

T-5
- Verifier dashboard admin:
  - consultation commandes
  - changement statut
  - moderation avis
  - export CSV

T-0
- Decision GO staging.
- Si KO: corriger, redeployer, rejouer checklist a partir de T-30.

## B. Production - Pre-Go (T-45 a T-0)

T-45
- Geler les changements non critiques.
- Confirmer fenetre de mise en ligne et responsable monitoring.

T-35
- Remplacer les cles Stripe test par cles live.
- Verifier `STRIPE_WEBHOOK_SECRET` live.
- Verifier `FORCE_SSL=true` et cookies securises.

T-30
- Verifier backup/rollback:
  - commit de rollback connu
  - acces logs Render

T-25
- Lancer deploy production.

T-20
- Verifier boot, migration et health checks.

T-15
- Smoke mobile production:
  - home responsive + hero neon violet
  - menu mobile burger
  - parcours catalogue -> panier -> checkout

T-10
- Test commande reelle faible montant.
- Verifier webhook, email, facture.

T-7
- Test operationnel food truck:
  - changement statut commande
  - verif coherence client/admin

T-5
- Verifier Sentry et taux erreur 5xx.
- Verifier absence d'erreurs bloquantes dans logs.

T-0
- Decision GO production.
- Annonce mise en ligne.

## C. Monitoring Renforce - H+0 a H+48

H+0 a H+1
- Suivre logs applicatifs en temps reel.
- Surveiller paiements Stripe et erreurs webhook.

H+1 a H+6
- Verifier periodicite jobs emails/factures.
- Controle manuel de 2 a 3 commandes supplementaires.

H+6 a H+24
- Suivre erreurs Sentry (priorite erreurs checkout/paiement).
- Verifier performances mobiles sur pages critiques.

H+24 a H+48
- Confirmer stabilite globale.
- Cloturer la phase go-live si aucun incident P0/P1.

## D. Criteres No-Go immediats

- Erreur 500 sur home, catalogue, panier, checkout.
- Paiement Stripe non confirme ou webhook non recu.
- Email de confirmation absent sur commande test.
- Facture PDF non generee.
- Dashboard admin inutilisable pour suivre les commandes.

## E. Trace de validation (a remplir)

- Date/heure deploy staging:
- Date/heure deploy production:
- Responsable go-live:
- Resultat smoke tests:
- Resultat test paiement:
- Incident(s) rencontre(s):
- Decision finale:
