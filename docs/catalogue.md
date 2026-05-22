# Catalogue produits

## Résumé de la page / fonctionnalité
Le catalogue présente toutes les catégories vendues par le food truck: burgers, accompagnements, boissons et desserts. Il permet une navigation rapide, une lecture claire des prix, et une entrée fluide vers la personnalisation puis l’ajout au panier.

## Objectifs
- Permettre à l’utilisateur de trouver un produit en moins de 3 interactions.
- Faciliter la comparaison des produits et des prix.
- Afficher la disponibilité en temps réel.
- Maximiser l’ajout au panier via une UX simple.

## Règles métier
- Un produit indisponible ne peut pas être ajouté au panier.
- Un produit saisonnier ne doit être visible que dans sa période active.
- Toute variation de prix doit être historisée côté admin.
- Les catégories doivent être ordonnées selon une priorité métier configurable.
- Les suppléments ne peuvent pas être commandés seuls (liés à un produit principal).

## Spécifications fonctionnelles
- Filtres par catégorie, disponibilité, prix, nouveauté.
- Recherche texte sur nom et description.
- Cartes produit avec nom, photo, prix de base, badges (épicé, veggie, best-seller).
- Entrée vers fiche produit détaillée avec options (taille, cuisson, suppléments).
- Bouton d’ajout rapide si aucune option obligatoire.

## Spécifications techniques
- API paginée pour récupération des produits.
- Endpoint de recherche avec indexation texte.
- Gestion des options via modèle produit-variantes.
- Synchronisation de stock quasi temps réel (polling ou websocket).
- Cache par catégorie avec invalidation lors des mises à jour produit.

## User flows
1. Le client ouvre le catalogue.
2. Il filtre sur « Burgers ».
3. Il consulte une fiche produit et choisit ses options.
4. Il ajoute au panier.
5. Il continue ses achats ou passe au panier.

## Cas particuliers
- Rupture au moment de l’ajout: message d’erreur et proposition d’alternative.
- Produit supprimé pendant la session: masquage immédiat et refresh de la liste.
- Option obligatoire manquante: blocage de l’ajout au panier.
- Prix modifié entre affichage et ajout: recalcul et confirmation utilisateur.

## Checklist de validation
- Les filtres renvoient des résultats cohérents.
- Les produits indisponibles sont visuellement identifiables.
- La recherche trouve correctement les produits attendus.
- L’ajout rapide fonctionne uniquement quand permis.
- Les variations de prix sont correctement appliquées.
- Le catalogue est utilisable sur mobile sans régression.
