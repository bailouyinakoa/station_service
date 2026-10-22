# Station Service App

Gestionnaire de station-service développé en Flutter avec prise en charge desktop.

## Présentation

Application de gestion de station-service pour suivre :
- les ventes de carburant,
- l'état des pompes,
- le stock de carburants,
- les clients et leurs paiements,
- la génération et l'impression de rapports.

## Fonctionnalités principales

- Authentification utilisateur avec session persistante
- Interface responsive : menu permanent sur grand écran, tiroir sur petit écran
- Gestion des pompes et du statut (active/inactive)
- Gestion des carburants, des prix et des stocks
- Enregistrement des ventes avec client associé
- Suivi des mouvements de stock (entrée / sortie)
- Rapports PDF et impression directe
- Conversion des montants en Franc CFA
- Scrolling automatique sur les pages à contenu long

## Identifiants de test

- Administrateur : `admin` / `admin123`
- Caissier : `caissier` / `caissier123`

## Installation

1. Assurez-vous d'avoir Flutter installé :
   - https://docs.flutter.dev/get-started/install
2. Ouvrez un terminal dans le dossier du projet :
   ```bash
   cd /home/kanidak/Bureau/station_service_app
   flutter pub get
   ```

## Technologies utilisées

- **Flutter** ^3.11.3 : Framework de développement cross-platform
- **GetX** ^4.6.5 : Gestion d'état, routing et programmation réactive
- **Sqflite** ^2.4.0 avec **sqflite_common_ffi** ^2.4.0 : Base de données SQLite avec support desktop
- **Shared_preferences** ^2.2.0 : Persistance des données locales pour les sessions
- **PDF** ^3.11.0 et **Printing** ^5.12.0 : Génération et impression de documents
- **Intl** ^0.18.1 : Internationalisation et formatage monétaire
- **Material Design 3** : Composants UI modernes et thème

## Améliorations récentes

- **États de chargement unifiés** : Indicateur de chargement unique pendant le chargement des données dans les dialogues, évitant les indicateurs multiples simultanés
- **Menus déroulants intelligents** : Remplacement des champs ID par des sélections déroulantes pour une meilleure UX (pompes, carburants)
- **Formatage CFA automatique** : Affichage des montants en Franc CFA avec formatage approprié
- **Export PDF et impression** : Génération de rapports PDF et impression directe
- **Design responsive** : Sidebar permanent sur écrans larges, tiroir sur mobiles
- **Session persistante** : Connexion automatique au redémarrage si session active
- **Scrolling optimisé** : Gestion automatique du défilement sur les pages longues

## Lancement

Pour lancer l'application sur Linux :

```bash
flutter run -d linux
```

Sur d'autres plateformes, utilisez le bon device ou exécutez depuis un IDE compatible.

## Structure du projet

- `lib/main.dart` : point d'entrée de l'application et initialisation de la base de données desktop
- `lib/app.dart` : configuration principale de GetMaterialApp
- `lib/domain/entities/pompiste.dart` : entité Pompiste
- `lib/data/models/pompiste_model.dart` : modèle de données Pompiste
- `lib/data/repositories/pompiste_repository_impl.dart` : implémentation repository Pompiste
- `lib/presentation/controllers/pompiste_controller.dart` : contrôleur Pompiste

## Pages et fonctionnalités détaillées

### Tableau de bord

- Résumé du chiffre d'affaires journalier et mensuel
- Affichage du stock carburant total
- Liste du stock de carburants en temps réel
- Section adaptative et scrollable sur grand ou petit écran

### Pompes

- Liste des pompes existantes
- Statut actif / inactif
- Mise à jour du relevé compteur

### Carburants

- Liste des carburants
- Prix par litre et stock disponible
- Seuil d'alerte pour les bas stocks
- Modification des prix, du stock et du seuil depuis un dialogue

### Ventes

- Liste des ventes enregistrées
- Ajout d'une vente avec **sélection de pompe et carburant** depuis des menus déroulants
- **Indicateur de chargement** pendant l'enregistrement pour éviter les doubles clics
- Association possible à un client
- Affichage des montants en Franc CFA
- Mise à jour automatique du stock lors de l'enregistrement

### Clients

- Liste des clients
- Détails de compte, solde et crédit
- Édition du solde et du crédit

### Stock

- Suivi des mouvements de stock (entrée / sortie)
- Ajout d'un mouvement avec **sélection du carburant** depuis un menu déroulant
- **Indicateur de chargement** pendant l'ajout pour éviter les doubles clics
- Affichage historique des changements de stock

### Rapports

- Création de rapports de ventes
- Export PDF des rapports
- Impression directe depuis l'application
- Contenu scrollable pour les longs rapports

### Paramètres

- Informations de la station
- Téléphone et chemin de sauvegarde
- Sauvegarde des paramètres dans la base
- **Gestion complète des carburants** : ajout, modification, suppression avec interface moderne
- **Gestion complète des pompes** : ajout, modification, suppression avec association aux carburants
- **Gestion des pompistes** : ajout, suivi des employés avec informations détaillées
- **Interface moderne** : onglets avec icônes en gradient, design Material Design 3

## Authentification et session

- Le login est requis au démarrage
- La session est enregistrée localement en utilisant `shared_preferences`
- Une fois connecté, l'utilisateur reste connecté après le redémarrage de l'application
- Déconnexion disponible depuis le menu

## Dépendances principales

- `flutter` : framework principal
- `get` : gestion d'état et navigation
- `sqflite` / `sqflite_common_ffi` : base de données SQLite locale (desktop compatible)
- `shared_preferences` : persistance des sessions
- `pdf` : génération de documents PDF
- `printing` : impression et partage PDF
- `intl` : formatage des nombres et devises

## Notes supplémentaires

- La base de données est initialisée automatiquement au premier lancement.
- Les données de test sont insérées si la table `users` est vide.
- Le design adaptatif donne une meilleure expérience sur grand écran et tablette.

## Conseils de test

1. Connectez-vous avec un des comptes de test.
2. Naviguez dans le menu pour ajouter/modifier des données.
3. Vérifiez l'affichage responsive sur différents formats d'écran.
4. Générer un rapport PDF et tester l'impression.
5. Fermez l'application puis relancez-la : la connexion doit être restaurée automatiquement.
