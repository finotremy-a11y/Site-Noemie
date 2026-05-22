# Quality Gates - Reduction maximale des erreurs

## Regle generale
Aucune fonctionnalite critique ne passe en staging/prod si un gate est rouge.

## Gate 1 - Conception
- User story claire avec criteres d'acceptation testables.
- Impacts securite et donnees identifies.
- Impacts API et migration documentes.

## Gate 2 - Implementation
- Typage/validation des entrees en backend.
- Gestion erreurs explicite (pas de fail silencieux).
- Logs metier sur evenements critiques.
- Idempotence implementee si endpoint relancable.

## Gate 3 - Tests developpeur
- Tests unitaires sur regles metier sensibles.
- Tests integration sur endpoints modifies.
- Cas limites couverts (doublons, concurrence, retries).

## Gate 4 - Revue
- Relecture orientee risques: paiement, statuts, auth, permissions.
- Aucun secret en clair dans code ou logs.
- Compatibilite retroactive verifiee pour contrats API.

## Gate 5 - CI
- Lint: OK
- Tests: OK
- Build: OK
- Verification migration: OK

## Gate 6 - Staging
- Smoke test complet parcours client et admin.
- Test webhook Stripe en double envoi.
- Test resilence: service email indisponible (retry + trace).
- Verification monitoring Sentry et alertes minimales.

## Gate 7 - Production
- Deploiement avec rollback prepare.
- Verifications post-deploy (checklist 15 min).
- Aucune erreur bloquante dans logs et Sentry.

## Definition of Done par fonctionnalite
- Fonctionnel conforme aux criteres.
- Cas d'erreur geres et testes.
- Observabilite en place (logs, traces, erreurs).
- Documentation API/produit mise a jour.

## Matrice priorite de test
- P0: Auth, commande, paiement, webhooks, admin statuts.
- P1: Catalogue, panier, compte client, emails transactionnels.
- P2: Pages contenu, preferences non critiques.

## Scenarios anti-regression minimaux
1. Paiement Stripe accepte -> commande confirmee une seule fois.
2. Webhook recu 2 fois -> etat final unique.
3. Admin annule une commande payee -> remboursement declenche selon regle.
4. Produit hors stock -> impossible d'ajouter ou de valider.
5. Client non connecte sur endpoint protege -> 401/403 correct.
