# Architecture technique

## Résumé de la page / fonctionnalité
Ce document décrit l’architecture cible du site food truck: couches frontend/backend, services transverses, sécurité, observabilité et déploiement.

Nom de l’entreprise: N&L Cuisinent (mentions légales détaillées à compléter ultérieurement).

## Objectifs
- Fournir un cadre technique clair pour le développement.
- Faciliter la maintenabilité et l’évolutivité.
- Assurer performance, sécurité et disponibilité.
- Aligner les choix techniques avec les besoins métier.

## Règles métier
- Les règles critiques (prix, disponibilité, statuts commande) sont exécutées côté backend.
- Les données sensibles clients doivent être protégées et minimisées.
- Les événements critiques doivent être traçables.
- Les traitements asynchrones doivent être idempotents.
- Les environnements (dev, staging, prod) doivent être séparés.

## Spécifications fonctionnelles
- Frontend web responsive pour client et back-office admin.
- Backend API centralisant logique métier et accès données.
- Services transverses: paiement, email, génération PDF, stockage médias.
- Gestion de l’authentification client et admin.
- Reporting opérationnel et financier.

## Spécifications techniques
- Frontend: framework moderne web (SSR recommandé pour SEO).
- Backend: API REST structurée par domaines (catalogue, commande, paiement, compte, admin).
- Supabase pour base relationnelle et authentification.
- Cloudinary pour stockage et transformation des médias.
- Stripe pour paiements en ligne et webhooks de confirmation.
- Resend pour l’envoi d’emails transactionnels.
- Render pour l’hébergement et le déploiement des services.
- Sentry pour le suivi d’erreurs et la supervision applicative.
- Queue asynchrone pour emails, factures et notifications.
- Observabilité: logs structurés, métriques, traces, alertes.

## User flows
1. Le client navigue sur le frontend.
2. Le frontend appelle l’API backend sécurisée.
3. Le backend applique les règles métier et persiste les données.
4. Les événements déclenchent des traitements asynchrones (emails, factures).
5. L’admin supervise via dashboard et indicateurs.

## Cas particuliers
- Défaillance du PSP: dégradation contrôlée et reprise.
- Montée en charge ponctuelle: autoscaling des composants critiques.
- Erreur queue asynchrone: retry, DLQ, alerte exploitation.
- Incident base de données: procédure de sauvegarde/restauration.

## Checklist de validation
- Les responsabilités frontend/backend sont claires.
- Les composants transverses sont identifiés.
- Les exigences sécurité sont couvertes.
- Les flux asynchrones sont documentés.
- Les mécanismes d’observabilité sont définis.
- Le plan de déploiement multi-environnements est établi.

## Documents de pilotage associés
- Plan d'exécution: docs/plan-technique-v1.md
- Quality gates et Definition of Done: docs/quality-gates.md
- Checklist de démarrage: docs/checklist-demarrage-dev.md
