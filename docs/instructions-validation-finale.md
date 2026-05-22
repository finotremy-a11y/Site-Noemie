# Instructions Validation Finale - Go Live

Date: 2026-04-07
Projet: N&L Cuisinent

Objectif:
Valider de facon complete que l application est prete pour la production, sans angle mort.

---

## 1. Gate technique locale

Executer ces commandes dans l ordre:

1. bin/rubocop
2. bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
3. bin/bundler-audit
4. bin/importmap audit
5. bin/rails test
6. bin/rails test:system
7. bin/ci

Critere de validation:
- Tout est vert
- 0 failure
- 0 error
- 0 warning de securite bloquante

---

## 2. Verification config production (Render)

Verifier les variables obligatoires:

- RAILS_ENV=production
- RAILS_LOG_TO_STDOUT=true
- SECRET_KEY_BASE
- RAILS_MASTER_KEY
- DATABASE_URL
- REDIS_URL
- STRIPE_SECRET_KEY (live)
- STRIPE_PUBLIC_KEY (live)
- STRIPE_WEBHOOK_SECRET (live)
- RESEND_API_KEY
- CLOUDINARY_CLOUD_NAME
- CLOUDINARY_API_KEY
- CLOUDINARY_API_SECRET
- SENTRY_DSN_BACKEND
- APP_HOST
- APP_PROTOCOL=https
- FORCE_SSL=true
- ADMIN_API_TOKEN

Critere de validation:
- aucune valeur dummy
- aucune cle test en production

---

## 3. Verification metier admin (nouveau)

Dans admin > Parametres metier:

- minimum commande livraison
- distance max palier 1
- tarif palier 1
- distance max palier 2
- tarif palier 2
- taux TVA

Checks:
1. Modifier une valeur
2. Sauvegarder
3. Recharger la page
4. Verifier persistance
5. Verifier impact checkout (frais, message distance, total)

Critere de validation:
- les reglages sont bien appliques sans redemarrage

---

## 4. Health checks et boot

Apres deploy staging puis prod:

1. GET /up
2. GET /api/v1/health

Critere de validation:
- HTTP 200
- pas d erreur boot/migration dans logs

---

## 5. Parcours client web complet (mobile prioritaire)

Scenario nominal:

1. Ouvrir home (mobile)
2. Ouvrir catalogue
3. Ajouter produit au panier
4. Ouvrir panier
5. Ouvrir checkout
6. Choisir pickup puis delivery
7. Verifier recalcul total selon distance
8. Passer commande (cash puis stripe)
9. Verifier page success
10. Verifier historique commande dans espace client

Critere de validation:
- aucun 500
- totals coherents
- UX fluide mobile

---

## 6. Stripe live (critique)

1. Configurer webhook Stripe vers /api/v1/payments/webhook
2. Faire un paiement reel faible montant
3. Verifier webhook recu
4. Verifier commande en pending_validation
5. Depuis admin, confirmer commande
6. Verifier capture d autorisation

Scenario echec:
1. Simuler annulation/erreur paiement
2. Verifier payment_status failed
3. Verifier bouton retry paiement
4. Refaire paiement

Critere de validation:
- pas de double traitement webhook
- transitions paiement et commande correctes

---

## 7. Back office food truck

Verifier:

1. Liste commandes
2. Changement statut unitaire
3. Changement statut en masse
4. Filtrage et tri
5. Produits CRUD
6. Devis
7. Avis moderation
8. Factures
9. Audit logs

Critere de validation:
- operations admin fonctionnelles
- droits admin respectes

---

## 8. Emails et factures

Verifier:

1. Email confirmation commande
2. Email changement statut
3. Generation facture PDF
4. Upload facture
5. Email facture prete
6. Telechargement facture client

Critere de validation:
- emails recus avec contenu correct
- facture disponible et lisible

---

## 9. Securite et acces

Verifier:

1. API admin requiert X-Admin-Token + utilisateur admin actif
2. Web admin reserve au role admin actif
3. API orders show/status requiert client authentifie
4. Aucun secret expose dans logs
5. Rate limit endpoints sensibles

Critere de validation:
- refus d acces non autorise
- traçabilite correcte

---

## 10. Monitoring H+48

H+0 a H+2:
- surveiller logs Render
- surveiller Sentry
- surveiller Stripe events

H+2 a H+24:
- verifier jobs async (emails, factures)
- verifier taux erreurs 5xx

H+24 a H+48:
- confirmer stabilite
- cloturer go-live

Critere de validation:
- aucun incident P0/P1

---

## 11. Decision finale GO / NO GO

GO si:
- gates techniques verts
- parcours commande complet valide
- paiement live valide
- admin operationnel
- monitoring stable

NO GO si:
- paiement ou webhook instable
- erreur 500 sur parcours critique
- incoherence montant ou statut

---

## 12. Trace de validation (a remplir)

- Date validation:
- Environnement valide:
- Responsable validation:
- Resultat rubocop:
- Resultat securite:
- Resultat tests:
- Resultat stripe live:
- Resultat admin:
- Resultat emails/factures:
- Decision GO/NO GO:
- Commentaires:
