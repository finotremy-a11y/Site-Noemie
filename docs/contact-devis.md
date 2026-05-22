# Contact et demande de devis

## Résumé de la page / fonctionnalité
La page contact permet aux clients de poser des questions générales et de soumettre une demande de devis pour événements (privé, entreprise, festival), avec enregistrement côté admin et notification au gérant.

## Objectifs
- Centraliser les demandes entrantes.
- Structurer les demandes de devis pour faciliter le traitement.
- Réduire le délai de réponse du gérant.
- Assurer la traçabilité des échanges.

## Règles métier
- Les champs essentiels du devis sont obligatoires (date, lieu, nombre de personnes).
- Chaque demande reçoit un identifiant unique.
- Les messages sont conservés dans l’interface admin.
- Une notification email est envoyée au gérant à chaque nouvelle demande.
- Le statut d’une demande (nouvelle, en cours, traitée, refusée) doit être suivi.

## Spécifications fonctionnelles
- Formulaire contact simple: nom, email, message.
- Formulaire devis enrichi: type d’événement, date, lieu, effectif, budget, contraintes.
- Validation en ligne des champs.
- Message de confirmation après soumission.
- Espace admin pour consulter et traiter les demandes.

## Spécifications techniques
- Endpoint API pour création de contact et création de devis.
- Protection anti-spam (captcha, rate limit, honeypot).
- Stockage en base avec index sur statut et date d’événement.
- Envoi email transactionnel au gérant via provider SMTP/API.
- Historique des changements de statut et des notes admin.

## User flows
1. Le visiteur ouvre la page contact/devis.
2. Il remplit le formulaire devis.
3. Il soumet la demande et reçoit une confirmation.
4. Le gérant reçoit un email de notification.
5. L’admin traite la demande depuis le dashboard.

## Cas particuliers
- Date d’événement passée: blocage de soumission.
- Données incohérentes (effectif très élevé sans budget): alerte admin.
- Email de notification en échec: mise en file de réessai.
- Doublon de demande: suggestion de fusion dans l’admin.

## Checklist de validation
- Les formulaires sont fonctionnels et validés.
- Les demandes sont visibles dans l’admin.
- Les emails de notification sont reçus par le gérant.
- Les protections anti-spam sont actives.
- Les statuts de traitement sont modifiables.
- Le parcours mobile est fluide.
