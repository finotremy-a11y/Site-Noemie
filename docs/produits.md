# Gestion des produits

## Résumé de la page / fonctionnalité
Cette documentation couvre la gestion complète des produits côté administration: création, modification, suppression, prix, options, disponibilité et saisonnalité.

## Objectifs
- Garantir un référentiel produit fiable et à jour.
- Réduire le temps de mise en ligne d’un nouveau produit.
- Encadrer les changements de prix et de disponibilité.
- Limiter les erreurs de configuration impactant la commande.

## Règles métier
- Chaque produit doit appartenir à une catégorie unique.
- Le prix de base est obligatoire et strictement positif.
- Un produit en rupture reste visible mais non commandable.
- La suppression logique est préférée à la suppression physique.
- Les options obligatoires doivent être clairement marquées.
- Les allergènes doivent être renseignés avant publication.

## Spécifications fonctionnelles
- CRUD produit avec champs: nom, description, catégorie, image, prix, disponibilité.
- Gestion des options: taille, cuisson, suppléments, choix multiples ou uniques.
- Gestion des variantes et impacts prix.
- Planification saisonnière (date début/fin de disponibilité).
- Duplication d’un produit existant pour accélérer les créations.

## Spécifications techniques
- Modèle de données: Product, ProductOption, ProductOptionValue, ProductAvailability.
- Versioning léger des fiches produit (audit trail admin).
- Validation serveur stricte des montants et des options.
- Stockage d’images sur objet storage + URL CDN.
- Permissions RBAC: admin, manager, opérateur (droits différents).

## User flows
1. L’admin ouvre le module Produits.
2. Il crée un burger avec options de cuisson et suppléments.
3. Il définit prix de base et majorations par option.
4. Il publie le produit.
5. Le produit devient visible dans le catalogue client.

## Cas particuliers
- Produit référencé dans des commandes passées: suppression physique interdite.
- Image invalide: fallback image et message d’erreur.
- Option supprimée alors présente dans un panier actif: revalidation du panier.
- Conflit de mise à jour concurrente: verrouillage optimiste et résolution.

## Checklist de validation
- Tous les champs obligatoires sont validés.
- Les règles de prix par option sont correctement calculées.
- La saisonnalité active/désactive le produit aux bonnes dates.
- Les actions admin sont tracées dans l’audit.
- Les droits d’accès empêchent les opérations non autorisées.
- Le produit apparaît correctement côté catalogue.
