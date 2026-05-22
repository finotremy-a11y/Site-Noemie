# Panier

## Résumé de la page / fonctionnalité
Le panier centralise les articles sélectionnés, permet la modification des quantités et options, calcule automatiquement les sous-totaux et prépare le passage à la commande.

## Objectifs
- Offrir une vue claire des articles avant validation.
- Permettre des modifications rapides sans friction.
- Afficher un total fiable en temps réel.
- Réduire l’abandon de panier.

## Règles métier
- Le panier est lié à une session, puis fusionné au compte lors de la connexion.
- Les prix sont recalculés côté serveur à chaque étape critique.
- Un produit indisponible ne peut pas rester validable dans le panier.
- Les coupons éventuels respectent des conditions d’éligibilité.
- Le montant minimum de commande peut être requis pour la livraison.

## Spécifications fonctionnelles
- Liste des lignes panier: produit, options, quantité, prix unitaire, total ligne.
- Actions: modifier options, changer quantité, supprimer ligne, vider panier.
- Affichage du sous-total, frais éventuels, total TTC.
- Indication estimée du délai selon mode (retrait/livraison).
- CTA « Continuer » vers commande.

## Spécifications techniques
- Persistance du panier en base pour utilisateurs connectés.
- Persistance locale (cookie/local storage) pour invités.
- Endpoint de recalcul panier avec règles centralisées.
- Contrôles anti-incohérence entre prix affichés et prix facturés.
- Journalisation des erreurs de recalcul et conflits de stock.

## User flows
1. Le client ajoute plusieurs produits depuis le catalogue.
2. Il ouvre le panier.
3. Il modifie une quantité et retire un article.
4. Le total est recalculé automatiquement.
5. Il clique sur « Continuer » pour passer commande.

## Cas particuliers
- Produit devenu indisponible: ligne signalée et non validable.
- Changement de zone de livraison: frais recalculés.
- Panier expiré après longue inactivité: restauration partielle si possible.
- Quantité demandée supérieure au stock: ajustement automatique avec notification.

## Checklist de validation
- Les montants sont exacts après chaque modification.
- La fusion panier invité/compte fonctionne.
- Les erreurs de stock sont correctement gérées.
- Le CTA vers commande est bloqué en cas d’incohérence.
- Le panier reste utilisable sur mobile.
- Les performances restent correctes avec plusieurs lignes.
