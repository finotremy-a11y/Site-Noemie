# Emails transactionnels

## Résumé de la page / fonctionnalité
Le système d’emails couvre les notifications automatiques liées aux commandes, paiements, factures, demandes de devis et événements de compte client.

## Objectifs
- Informer le client en temps réel des étapes clés.
- Notifier le gérant des actions nécessitant intervention.
- Assurer la délivrabilité et la traçabilité des envois.
- Réduire les demandes support liées au manque d’information.

## Règles métier
- Chaque email transactionnel doit être déclenché par un événement explicite.
- Les emails critiques (commande confirmée, facture) doivent être réessayés en cas d’échec.
- Le client peut gérer ses préférences pour emails non obligatoires.
- Les templates doivent rester cohérents avec la charte de marque.
- Les preuves d’envoi doivent être journalisées.

## Spécifications fonctionnelles
- Templates pour: confirmation commande, changement statut, facture, devis reçu, réinitialisation mot de passe.
- Variables dynamiques: nom client, numéro commande, montant, lien de suivi.
- Envoi immédiat ou différé selon criticité.
- Historique d’envoi visible côté admin.
- Bouton de renvoi manuel pour certains emails.

## Spécifications techniques
- Provider email transactionnel: Resend (API) avec monitoring.
- Moteur de templates avec prévisualisation admin.
- Queue d’envoi et politique de retry exponentiel.
- Webhooks de délivrabilité (delivered, bounced, complained).
- Table EmailLog avec statut, destinataire, timestamp, message-id.

## User flows
1. Un événement métier se produit (commande confirmée).
2. Le système construit l’email depuis un template.
3. L’email est envoyé via le provider.
4. Le statut d’envoi est journalisé.
5. L’admin consulte ou renvoie si nécessaire.

## Cas particuliers
- Adresse email invalide: marquage bounced et alerte.
- Provider indisponible: bascule sur file d’attente.
- Double envoi suite à retry tardif: contrôle d’idempotence.
- Désabonnement marketing: ne pas impacter les emails transactionnels obligatoires.

## Checklist de validation
- Tous les templates requis existent et sont testés.
- Les déclencheurs envoient les bons emails.
- Les retries fonctionnent en cas d’échec.
- Les logs de délivrabilité sont exploitables.
- Le renvoi manuel fonctionne depuis l’admin.
- Le rendu email est correct sur mobile et desktop.
