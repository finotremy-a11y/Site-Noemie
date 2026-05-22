# Plan technique v1 - N&L Cuisinent

## Objectif
Livrer un socle web fiable (client + admin + API) avec le moins d'erreurs possible, en priorisant les parcours critiques: consultation catalogue, panier, commande, paiement Stripe, suivi commande, back-office.

## Pile technique cible (figee)
- Frontend web: framework SSR moderne
- Backend API: REST versionnee par domaine
- Base de donnees + auth: Supabase
- Paiement: Stripe
- Medias: Cloudinary
- Emails transactionnels: Resend
- Hebergement: Render
- Observabilite et erreurs: Sentry

## Principes anti-erreur
- Pas de logique metier critique uniquement en frontend.
- Idempotence obligatoire sur commande/paiement/webhooks.
- Regles de transition de statut centralisees au backend.
- Une feature n'est mergee que si ses tests critiques passent.
- Feature flags pour activer progressivement les parties sensibles.

## Macro-phases d'execution

### Phase 0 - Cadrage et standards (0.5 a 1 jour)
- Figer conventions de code, structure dossiers, nommage, strategie branche.
- Definir Definition of Done, quality gates, et conventions API.
- Declarer les environnements: dev, staging, prod.

Sortie attendue:
- Structure projet stable.
- Standards ecrits et valides.

### Phase 1 - Fondation projet (1 jour)
- Initialiser frontend, backend, configuration Supabase.
- Mettre en place auth de base (client/admin) et roles.
- Integrer Sentry dans frontend + backend.
- Pipeline CI minimum: lint + tests + build.

Sortie attendue:
- Build local et CI green.
- Auth minimale fonctionnelle.

### Phase 2 - Domaine catalogue et produits (1 a 2 jours)
- Modele categories/produits/options/prix/disponibilite.
- Endpoints catalogue (lecture) + cache.
- Ecran catalogue connecte API.
- Upload images produits via Cloudinary.

Sortie attendue:
- Catalogue fonctionnel, rapide, et coherent avec disponibilite.

### Phase 3 - Panier et commande (1 a 2 jours)
- Endpoints panier: ajouter/modifier/supprimer/recalculer.
- Creation commande avec snapshot prix (anti-derives).
- Machine a etats commande + historique des transitions.
- Tests des conflits de statut (retour 409).

Sortie attendue:
- Flux panier -> commande robuste.

### Phase 4 - Paiement Stripe (1 a 2 jours)
- Creation session/intention Stripe avec cle idempotence.
- Webhook Stripe verifie par signature.
- Reconciliation paiement <-> commande.
- Relance paiement et gestion echecs.

Sortie attendue:
- Paiement en test mode fiable, sans double debit.

### Phase 5 - Emails et facturation (1 jour)
- Templates transactionnels via Resend.
- Envoi asynchrone confirmation commande et statut.
- Generation facture (PDF ou equivalent) et stockage.

Sortie attendue:
- Emails critiques envoyes et tracables.

### Phase 6 - Admin dashboard (1 a 2 jours)
- Vue commandes temps reel, filtres, priorisation.
- Changement de statut avec preconditions et journalisation.
- Gestion produits/stock/disponibilite.

Sortie attendue:
- Admin operationnel pour piloter le service.

### Phase 7 - Stabilisation et pre-prod (1 a 2 jours)
- Tests e2e des parcours critiques.
- Tests de charge legers sur endpoints sensibles.
- Hardening securite, revue permissions, rate limits.
- Verification deploiement Render + rollback.

Sortie attendue:
- Version prete staging/prod avec checklist complete.

## Parcours critiques a proteger en priorite
1. Visiteur -> catalogue -> panier -> commande -> paiement confirme.
2. Echec paiement -> relance -> confirmation.
3. Admin -> changement statut commande -> notification client.
4. Webhook Stripe recu en double -> pas de duplication d'effet.
5. Produit indisponible -> blocage commande + message explicite.

## Decoupage des sprints recommande
- Sprint 1: Phases 0-1
- Sprint 2: Phase 2
- Sprint 3: Phase 3
- Sprint 4: Phase 4
- Sprint 5: Phases 5-6
- Sprint 6: Phase 7 + go-live

## KPI de pilotage
- Taux de succes paiement.
- Temps moyen creation commande.
- Taux d'erreurs API 4xx/5xx.
- Temps de traitement webhook Stripe.
- Delai moyen entre commande et statut terminee.

## Prerequis avant demarrage developpement
- Nom legal complet et infos legales a integrer (a venir).
- Contenu media hero (photo fixe ou defilement) a fournir.
- Comptes services crees: Supabase, Stripe, Cloudinary, Resend, Render, Sentry.
