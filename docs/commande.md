# Système de commande

## Résumé de la page / fonctionnalité
Le système de commande orchestre la transformation du panier en commande confirmée, avec choix du mode de service (Click and Collect ou livraison), identification client (compte ou invité), adresse et créneau.

## Objectifs
- Finaliser une commande en moins de 2 minutes.
- Assurer un parcours fiable pour retrait et livraison.
- Limiter les erreurs de saisie et d’adresse.
- Garantir la cohérence entre panier, frais et commande finale.

## Règles métier
- Le client doit choisir un mode de service avant validation finale.
- En livraison, l’adresse doit appartenir à une zone couverte.
- En Click and Collect, le créneau de retrait doit être disponible.
- La commande invité est autorisée avec email et téléphone obligatoires.
- Une commande validée ne peut plus être modifiée par le client sans contact support.

## Spécifications fonctionnelles
- Étapes: identification, mode de service, coordonnées, récapitulatif.
- Choix entre commande connectée et invité.
- Formulaire adresse avec auto-complétion et vérification de zone.
- Sélecteur de créneau selon charge et disponibilité cuisine.
- Récapitulatif final: articles, frais, total, mode de paiement.

## Spécifications techniques
- Machine à états de commande (draft, pending_payment, confirmed, preparing, ready, completed, cancelled).
- Service de validation d’adresse et calcul de frais livraison.
- Blocage pessimiste ou réservation temporaire de stock à la validation.
- Idempotence sur création de commande pour éviter doublons.
- Traçabilité des transitions de statut avec horodatage.

## User flows
1. Le client clique sur « Continuer » depuis le panier.
2. Il choisit « Livraison » ou « Click and Collect ».
3. Il saisit ses informations (compte ou invité).
4. Il vérifie le récapitulatif.
5. Il confirme et passe à l’étape de paiement.

## Cas particuliers
- Adresse hors zone: proposition du retrait sur place.
- Créneau saturé: proposer des créneaux alternatifs.
- Perte de session: récupération du brouillon de commande si possible.
- Double clic sur validation: une seule commande créée.

## Checklist de validation
- Les deux modes de service sont opérationnels.
- Les règles de zone de livraison sont respectées.
- Les créneaux non disponibles sont correctement bloqués.
- Les commandes invitées sont bien enregistrées.
- Les statuts initiaux de commande sont cohérents.
- Les cas de doublons sont couverts par idempotence.
