# Compte client

## Résumé de la page / fonctionnalité
L’espace client permet de gérer le profil, l’historique des commandes, les paramètres de sécurité, les adresses et les moyens de paiement, avec possibilité de suppression du compte.

## Objectifs
- Fidéliser les clients grâce à une expérience personnalisée.
- Simplifier les commandes récurrentes.
- Garantir la sécurité des données personnelles.
- Respecter les obligations RGPD.

## Règles métier
- L’email est unique par compte.
- Les mots de passe doivent respecter une politique de complexité minimale.
- La suppression de compte nécessite confirmation forte.
- Les commandes passées restent conservées selon obligations légales.
- Un client peut enregistrer plusieurs adresses, avec une adresse par défaut.

## Spécifications fonctionnelles
- Onglets: Profil, Commandes, Paramètres, Paiements, Suppression.
- Historique des commandes avec statut, montant, date et facture.
- Mise à jour email/mot de passe avec vérification.
- Gestion des adresses de livraison.
- Gestion des moyens de paiement tokenisés.

## Spécifications techniques
- Authentification sécurisée (JWT/session + refresh + protection brute force).
- Hashage mot de passe fort (Argon2 ou équivalent).
- Vérification email via lien de confirmation.
- API dédiée compte avec contrôles d’accès par utilisateur.
- Workflow RGPD: export de données et suppression logique/anonymisation.

## User flows
1. Le client se connecte à son compte.
2. Il consulte l’historique de ses commandes.
3. Il modifie son adresse par défaut.
4. Il ajoute un moyen de paiement.
5. Il télécharge une facture depuis une commande passée.

## Cas particuliers
- Email déjà utilisé: blocage et message explicite.
- Session expirée pendant édition: sauvegarde brouillon et reconnexion.
- Compte inactif long terme: politique d’archivage.
- Suppression demandée avec commandes en cours: suppression différée.

## Checklist de validation
- Les écrans compte sont accessibles sur mobile.
- Les changements de profil sont persistés correctement.
- Les factures sont téléchargeables depuis l’historique.
- Les règles de sécurité mot de passe sont respectées.
- La suppression de compte suit le processus RGPD.
- Les permissions empêchent l’accès aux données d’un autre client.
