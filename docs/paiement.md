# Paiement

## Résumé de la page / fonctionnalité
Le module de paiement gère le règlement des commandes en ligne par carte bancaire ou en main à main (livraison/retrait), puis déclenche la confirmation de commande.

## Objectifs
- Sécuriser les transactions.
- Proposer des moyens de paiement adaptés au contexte food truck.
- Réduire le taux d’échec paiement.
- Garantir la traçabilité comptable.

## Règles métier
- Le paiement en ligne doit être autorisé via Stripe (prestataire certifié PCI-DSS).
- Le paiement en main à main doit être explicitement choisi avant confirmation.
- Une commande payée en ligne passe directement en statut confirmée.
- Une commande en main à main passe en statut paiement_en_attente.
- Toute tentative de paiement expirée doit pouvoir être relancée.

## Spécifications fonctionnelles
- Choix du mode de paiement: carte bancaire ou paiement à la remise.
- Gestion des erreurs de paiement (carte refusée, 3DS échoué, timeout).
- Écran de confirmation avec numéro de commande.
- Historique du statut de paiement visible côté client et admin.
- Lien de reprise de paiement pour commandes non réglées en ligne.

## Spécifications techniques
- Intégration Stripe via API sécurisée (Stripe Checkout ou Payment Intents, tokenisation, 3DS2).
- Webhooks Stripe pour confirmation asynchrone de transaction.
- Signature et vérification des callbacks Stripe (en-tête Stripe-Signature).
- Stockage minimal des données paiement (jamais de PAN complet).
- Utilisation de clés d’idempotence pour création session/tentative de paiement.
- Journal de rapprochement commande/paiement.

## User flows
1. Le client arrive à l’étape paiement.
2. Il choisit carte bancaire ou paiement à la remise.
3. En carte bancaire, il finalise la transaction via PSP.
4. Le système reçoit la confirmation et valide la commande.
5. Le client voit l’écran de confirmation.

## Cas particuliers
- Webhook PSP reçu en retard: synchronisation différée du statut.
- Paiement accepté mais réseau coupé côté client: reprise sur page statut commande.
- Paiement à la remise refusé sur place: passage manuel en impayé par admin.
- Commande annulée après paiement: déclenchement du flux de remboursement.

## Checklist de validation
- Les paiements CB passent en environnement de test puis production.
- Les erreurs PSP sont correctement affichées côté client.
- Les statuts paiement/commande sont cohérents.
- Les webhooks non signés sont rejetés.
- Le mode paiement à la remise est traçable.
- La relance de paiement fonctionne.
