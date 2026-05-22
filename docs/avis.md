# Page avis

## Résumé de la page / fonctionnalité
La page avis permet aux clients de publier une note, un commentaire et des photos, avec un processus de modération administrateur avant publication si nécessaire.

## Objectifs
- Valoriser la preuve sociale.
- Recueillir des retours utiles pour améliorer le service.
- Prévenir les abus via modération.
- Encourager les clients satisfaits à partager leur expérience.

## Règles métier
- Un avis est lié à une commande réelle ou à un client authentifié selon politique choisie.
- Les contenus offensants, diffamatoires ou hors sujet sont rejetés.
- Les photos doivent respecter des contraintes de format et taille.
- Un même client ne peut pas publier plusieurs avis sur la même commande.
- Les avis peuvent être masqués par l’admin sans suppression définitive.

## Spécifications fonctionnelles
- Formulaire d’avis: note, commentaire, photos.
- Affichage des avis publiés avec tri (récent, note, utile).
- Badge « avis vérifié » pour avis liés à une commande.
- Signalement d’un avis par un utilisateur.
- Module admin de modération (approuver, rejeter, masquer).

## Spécifications techniques
- Modèle Review avec statut (pending, approved, rejected, hidden).
- Upload image sécurisé avec scan antivirus et compression.
- Filtrage automatique premier niveau (mots interdits, spam scoring).
- API de modération protégée par rôle admin.
- Journal des actions de modération pour audit.

## User flows
1. Le client ouvre la page avis.
2. Il soumet une note, un commentaire et des photos.
3. L’avis passe en attente de modération.
4. L’admin approuve l’avis.
5. L’avis devient visible publiquement.

## Cas particuliers
- Photo trop lourde: compression ou refus avec message explicatif.
- Avis potentiellement frauduleux: statut en revue manuelle prolongée.
- Compte supprimé: anonymisation de l’auteur des anciens avis.
- Signalements multiples: masquage temporaire automatique.

## Checklist de validation
- Le formulaire d’avis est opérationnel.
- Les contraintes upload photo sont appliquées.
- La modération admin fonctionne de bout en bout.
- Les avis approuvés s’affichent correctement.
- Les signalements déclenchent les actions prévues.
- Les avis liés à commande sont marqués comme vérifiés.
