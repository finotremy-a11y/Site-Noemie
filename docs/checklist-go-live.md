# Checklist Go-Live

Checklist operationnelle pour passer le projet de "pret techniquement" a "pret a deployer en production".

## 1. Prerequis immediats

- [ ] Verifier l'acces Render, Stripe, Resend, Sentry et Cloudinary.
- [ ] Verifier que PostgreSQL et Redis sont provisionnes sur Render.
- [ ] Verifier que les domaines et URLs finales sont connus.
- [ ] Verifier que la branche a deployer contient les derniers correctifs valides.
- [ ] Verifier que la suite de tests est verte en local:

```bash
bin/rails test
```

Critere de validation:
- Le retour doit etre a 0 echec et 0 erreur.

## 2. Variables d'environnement de production

Variables minimales a renseigner dans Render:

- [ ] `RAILS_ENV=production`
- [ ] `RAILS_LOG_TO_STDOUT=true`
- [ ] `SECRET_KEY_BASE`
- [ ] `ADMIN_API_TOKEN`
- [ ] `DATABASE_URL`
- [ ] `REDIS_URL`
- [ ] `STRIPE_SECRET_KEY`
- [ ] `STRIPE_PUBLIC_KEY`
- [ ] `STRIPE_WEBHOOK_SECRET`
- [ ] `RESEND_API_KEY`
- [ ] `CLOUDINARY_CLOUD_NAME`
- [ ] `CLOUDINARY_API_KEY`
- [ ] `CLOUDINARY_API_SECRET`
- [ ] `SENTRY_DSN_BACKEND`
- [ ] `SENTRY_TRACES_SAMPLE_RATE`
- [ ] `APP_HOST`
- [ ] `APP_PROTOCOL=https`
- [ ] `FORCE_SSL=true`

Critere de validation:
- Aucune variable critique ne doit conserver une valeur d'exemple.
- Les noms de variables Stripe doivent etre homogenes avec [render.yaml](render.yaml), [.env.production.example](.env.production.example) et [config/initializers/stripe.rb](config/initializers/stripe.rb#L1).

## 3. Base de donnees et migrations

- [ ] Verifier que la base Render PostgreSQL est creee.
- [ ] Verifier que `DATABASE_URL` pointe vers la base Render.
- [ ] Executer les migrations au deploy.
- [ ] Verifier que les schemas secondaires Rails 8 sont bien pris en compte si utilises en production: cache, queue, cable.

Commandes utiles:

```bash
bin/rails db:migrate
bin/rails db:schema:dump
```

Critere de validation:
- L'application boote sans erreur de connexion DB.
- Les tables metier et tables de queue/cache/cable attendues existent.

## 4. Jobs asynchrones

Le projet utilise `solid_queue` en production.

- [ ] Verifier qu'un worker de jobs existe en production, ou qu'une strategie explicite de traitement des jobs est en place.
- [ ] Verifier le traitement des emails de confirmation.
- [ ] Verifier le traitement de generation/upload des factures.
- [ ] Verifier qu'aucun job ne reste bloque en file.

Critere de validation:
- Un email de confirmation part bien apres une commande test.
- Une facture PDF est generee et accessible.
- La file de jobs se vide normalement.

## 5. Deploiement Render

- [ ] Verifier le service web dans [render.yaml](render.yaml).
- [ ] Verifier si un service worker supplementaire doit etre ajoute pour les jobs.
- [ ] Verifier `healthCheckPath` sur `/api/v1/health`.
- [ ] Lancer un deploy de staging ou de production controle.
- [ ] Verifier les logs de boot juste apres deploy.

Critere de validation:
- Le healthcheck repond en HTTP 200.
- Aucun crash boot, migration ou secret manquant dans les logs.

## 6. Smoke tests web et API

Parcours minimum a tester apres deploy:

- [ ] Charger la page d'accueil.
- [ ] Ouvrir le catalogue.
- [ ] Ajouter un produit au panier.
- [ ] Creer un compte client.
- [ ] Passer une commande test.
- [ ] Verifier la page succes commande.
- [ ] Verifier l'historique de commandes dans l'espace client.
- [ ] Verifier le telechargement d'une facture.
- [ ] Verifier le formulaire de contact.
- [ ] Verifier la publication d'un avis.

Critere de validation:
- Aucun parcours critique ne doit produire d'erreur 500.
- Les donnees doivent etre coherentes entre interface web et back-office.

## 7. Validation Stripe

- [ ] Configurer le webhook Stripe vers `/api/v1/payments/webhook`.
- [ ] Faire un paiement test en environnement cible.
- [ ] Verifier la creation de la session Stripe.
- [ ] Verifier la reception du webhook.
- [ ] Verifier la confirmation unique de la commande.
- [ ] Rejouer un webhook deja traite pour verifier l'idempotence.
- [ ] Verifier le parcours de retry paiement apres echec.

Critere de validation:
- Une commande payee ne doit etre confirmee qu'une seule fois.
- Un double envoi webhook ne doit pas dupliquer paiement ou facture.

## 8. Validation emails et documents

- [ ] Verifier l'envoi Resend pour confirmation commande.
- [ ] Verifier l'envoi Resend pour mise a jour de statut.
- [ ] Verifier la generation PDF de facture.
- [ ] Verifier l'upload Cloudinary de la facture si active.
- [ ] Verifier le lien de telechargement client.

Critere de validation:
- Les emails arrivent avec des liens valides.
- Le PDF est lisible et correspond a la commande.

## 9. Validation admin

- [ ] Ouvrir le dashboard admin.
- [ ] Verifier la liste des commandes.
- [ ] Changer un statut de commande.
- [ ] Verifier la moderation d'un avis.
- [ ] Verifier les exports CSV admin.
- [ ] Verifier la consultation des audit logs.

Critere de validation:
- Les transitions de statuts sont persistantes.
- Les CSV sont telechargeables.
- Les audit logs enregistrent les actions sensibles.

## 10. Securite et observabilite

- [ ] Verifier `FORCE_SSL=true` en production.
- [ ] Verifier que Sentry recoit bien les erreurs serveur.
- [ ] Verifier le filtrage des parametres sensibles dans les logs.
- [ ] Verifier Rack::Attack sur les endpoints sensibles.
- [ ] Verifier qu'aucun secret de test ou compte de demo n'est expose en production.

Critere de validation:
- Une erreur test apparait dans Sentry.
- Le rate limiting repond comme attendu.
- Les credentials de demo dans [db/seeds.rb](db/seeds.rb) ne sont pas utilises en production.

## 11. Relecture documentaire minimale

- [ ] Aligner le nom de la variable Stripe publique entre [.env.example](.env.example), [docs/checklist-demarrage-dev.md](docs/checklist-demarrage-dev.md), [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) et [PRODUCTION_READY.md](PRODUCTION_READY.md).
- [ ] Mettre a jour [README.md](README.md) pour supprimer les notes devenues fausses ou incomplètes.
- [ ] Verifier que la doc de deploiement ne contredit pas le runtime reel.

Critere de validation:
- Un nouveau developpeur peut configurer le projet sans ambiguite.

## 12. Rollback et decision de mise en ligne

- [ ] Definir la version ou le commit de rollback.
- [ ] Verifier l'acces aux logs Render.
- [ ] Definir qui surveille les 15 premieres minutes apres mise en ligne.
- [ ] Verifier les parcours critiques juste apres deploy.

Decision de go-live:

- [ ] GO si tous les points P0 suivants sont valides: boot, login, panier, commande, paiement, webhook, email, facture, admin, logs.
- [ ] NO GO si un parcours critique produit une erreur bloquante ou un etat incoherent.

## Check rapide 30 minutes

Si le temps est contraint, executer au minimum cet ordre:

1. Renseigner toutes les variables Render critiques.
2. Verifier boot + healthcheck.
3. Passer une commande test Stripe.
4. Verifier webhook, email et facture.
5. Verifier dashboard admin + changement de statut.
6. Verifier Sentry et logs Render.

## Resultat attendu

Le projet peut etre considere comme pret production quand:

- les tests automatiques sont verts,
- le deploy Render boote sans erreur,
- le parcours commande complet est valide en reel,
- les jobs async sont traites,
- les preuves d'observabilite existent,
- la documentation de runbook n'est pas contradictoire.