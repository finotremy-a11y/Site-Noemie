# Facturation

## Résumé de la page / fonctionnalité
Le système de facturation génère automatiquement une facture PDF pour chaque commande éligible, la rend disponible dans l’admin et dans l’espace client, et permet son envoi par email.

## Objectifs
- Assurer la conformité légale de facturation.
- Automatiser la production des factures.
- Simplifier l’accès aux factures pour clients et gérant.
- Garantir l’intégrité des données financières.

## Règles métier
- Une facture est générée uniquement pour une commande confirmée.
- Le numéro de facture suit une séquence unique et non réutilisable.
- Toute correction passe par une procédure d’avoir selon réglementation.
- Les montants facturés doivent correspondre au paiement validé.
- Les factures doivent rester archivées sur la durée légale requise.

## Spécifications fonctionnelles
- Génération PDF automatique après confirmation de commande.
- Affichage et téléchargement depuis compte client et dashboard admin.
- Renvoi manuel de la facture par email.
- Recherche de facture par numéro, date, client, commande.
- Export mensuel des factures pour comptabilité.

## Spécifications techniques
- Service de template PDF avec rendu serveur.
- Stockage immuable des PDF générés (version figée).
- Modèle Invoice lié à Order et Payment.
- File d’attente asynchrone pour génération en masse.
- Signature ou checksum de contrôle d’intégrité.

## User flows
1. La commande est confirmée et payée.
2. Le système génère la facture PDF.
3. La facture est stockée et indexée.
4. Le client la retrouve dans son historique.
5. L’admin peut l’exporter ou la renvoyer par email.

## Cas particuliers
- Échec de génération PDF: tâche de retry automatique.
- Données de facturation incomplètes: alerte admin et mise en attente.
- Annulation après facturation: création d’un avoir.
- Changement d’email client après commande: facture toujours rattachée au compte.

## Checklist de validation
- Les factures sont générées pour toutes les commandes éligibles.
- Le numéro de facture est unique et séquentiel.
- Les montants PDF correspondent aux montants commande.
- Le téléchargement fonctionne côté client et admin.
- Les renvois email sont tracés.
- L’archivage respecte la politique de conservation.
