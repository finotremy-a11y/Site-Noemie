# Dashboard administrateur

## Résumé de la page / fonctionnalité
Le dashboard admin centralise la gestion opérationnelle: produits, commandes, devis, chiffre d’affaires, factures PDF et envois email automatiques.

## Objectifs
- Donner une vue temps réel de l’activité.
- Permettre des actions rapides sur les commandes.
- Fiabiliser la gestion documentaire (factures).
- Suivre les indicateurs business clés.

## Règles métier
- Les rôles définissent les permissions (admin, manager, opérateur).
- Les statuts de commande suivent un cycle contrôlé.
- Les factures doivent être accessibles pour chaque commande confirmée.
- Le chiffre d’affaires se base sur les commandes payées.
- Les actions sensibles doivent être tracées.

## Spécifications fonctionnelles
- Tableau de bord avec KPIs: commandes du jour, CA, panier moyen, taux conversion.
- Module Produits: CRUD complet.
- Module Commandes: filtres par statut (en attente, en cours, terminées).
- Module Devis: gestion et suivi des demandes.
- Module Factures: recherche, export, téléchargement, renvoi par email.

## Spécifications techniques
- Back-office SPA avec API sécurisée et authentification forte.
- Websocket ou polling pour rafraîchir les commandes en temps réel.
- Tables d’audit pour actions administratives.
- Export CSV/PDF selon droits utilisateur.
- Monitoring d’erreurs et alerting opérationnel.

## User flows
1. L’admin se connecte au dashboard.
2. Il consulte les commandes en attente.
3. Il passe une commande en cours puis terminée.
4. Il télécharge la facture associée.
5. Il consulte le CA de la journée.

## Cas particuliers
- Double traitement de commande par deux admins: verrouillage de statut.
- Échec de génération PDF: relance manuelle possible.
- Pic d’activité: passage automatique en rafraîchissement dégradé.
- Tentative d’accès non autorisée: blocage et log sécurité.

## Checklist de validation
- Les modules clés sont accessibles selon rôle.
- Les statuts commande évoluent correctement.
- Les exports factures sont valides.
- Les KPI affichent des données cohérentes.
- Les logs d’audit enregistrent les actions sensibles.
- Le dashboard reste performant en charge.
