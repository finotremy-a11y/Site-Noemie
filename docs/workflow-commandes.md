# Workflow commandes

## Résumé de la page / fonctionnalité
Ce document formalise le cycle de vie d’une commande, des actions client jusqu’à la clôture opérationnelle et comptable côté admin.

## Objectifs
- Harmoniser la gestion des statuts de commande.
- Réduire les erreurs opérationnelles en cuisine et livraison.
- Améliorer la visibilité client sur l’avancement.
- Assurer une traçabilité complète des transitions.

## Règles métier
- Une commande suit une progression de statuts autorisés.
- Les transitions arrière sont limitées et tracées.
- Le passage en terminée nécessite une commande remise ou livrée.
- Les annulations doivent avoir un motif obligatoire.
- Toute transition doit être horodatée et associée à un acteur.

## Spécifications fonctionnelles
- Statuts proposés:
  - brouillon
  - en attente de paiement
  - confirmée
  - en préparation
  - prête (retrait) / en livraison
  - terminée
  - annulée
- Notifications client à chaque étape clé.
- Tableau admin avec filtres par statut et priorité temporelle.
- Délai estimé recalculé selon charge en cours.
- Historique des transitions consultable.

## Spécifications techniques
- Machine à états implémentée au backend.
- Vérifications de préconditions avant transition.
- Événements de domaine publiés sur chaque changement.
- Envoi notifications via worker asynchrone.
- Stockage des motifs d’annulation et éventuels remboursements.

## User flows
1. Le client valide sa commande.
2. La commande passe en confirmée après paiement valide.
3. L’équipe la fait passer en préparation.
4. Elle passe en prête ou en livraison.
5. L’admin clôture en terminée.

## Cas particuliers
- Paiement tardif après annulation: flux de régularisation manuel.
- Retard cuisine: mise à jour ETA client.
- Échec livraison: retour statut à incident puis résolution.
- Annulation client tardive: règles de remboursement partielles.

## Checklist de validation
- Les statuts et transitions sont exhaustifs.
- Les préconditions de transition sont appliquées.
- Les notifications sont envoyées au bon moment.
- Les motifs d’annulation sont tracés.
- Les rapports admin reflètent l’état réel.
- Les cas incident sont documentés et testés.
