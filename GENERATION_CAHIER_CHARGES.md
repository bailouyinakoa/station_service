# Génération du Cahier des Charges

Ce projet contient un cahier des charges complet pour l'application Station Service App.

## Méthode 1 : Génération via Script Autonome

Pour générer directement le PDF sans lancer l'application complète :

```bash
cd /home/kanidak/Bureau/station_service_app
dart run bin/generate_cahier_charges.dart
```

Le fichier PDF `Cahier_des_Charges_Station_Service.pdf` sera généré dans le répertoire courant.

## Méthode 2 : Génération via l'Application Flutter

### Option 2a : Via la Page Dédiée

L'application inclut une page dédiée pour générer le cahier des charges :

```dart
import 'package:station_service_app/presentation/pages/cahier_charges_page.dart';

// Naviguer vers la page
Navigator.push(context, MaterialPageRoute(builder: (_) => const CahierChargesPage()));
```

### Option 2b : Via Code Custom

Intégrer la génération dans n'importe quel contrôleur ou page :

```dart
import 'package:station_service_app/services/cahier_charges_generator.dart';

// Générer le PDF
await CahierChargesGenerator.generateAndSavePDF();
```

## Contenu du Cahier des Charges

Le document PDF contient :

1. **Présentation Générale** - Vue d'ensemble de l'application
2. **Fonctionnalités Principales** - Détail des 10 modules:
   - Authentification et gestion des utilisateurs
   - Gestion des pompes
   - Gestion des carburants
   - Gestion des ventes
   - Gestion des clients
   - Gestion du stock
   - Tableau de bord
   - Rapports et impression
   - Gestion des dépenses
   - Module comptabilité

3. **Interface Utilisateur** - Design responsive et features
4. **Conversion Monétaire** - Formatage en Franc CFA
5. **Moyen d'Utilisation** - Instructions d'installation et de lancement
6. **Identifiants de Test** - Crédentials pour tester l'app
7. **Plateformes Supportées** - Linux, macOS, Windows, Android, iOS
8. **Technologies Utilisées** - Stack technique complet
9. **Conclusion** - Résumé du projet

## Format du Document

- **Format** : PDF A4
- **Style** : Simple et professionnel sans embellissement
- **Pages** : 3 pages
- **Contenu** : Focus sur les fonctionnalités et moyens d'utilisation

## Fichiers Générés

- `lib/services/cahier_charges_generator.dart` - Service de génération pour l'app
- `lib/presentation/pages/cahier_charges_page.dart` - Page UI pour générer le PDF
- `bin/generate_cahier_charges.dart` - Script autonome pour CLI

## Exemple d'Utilisation CLI

```bash
# Générer le PDF
dart run bin/generate_cahier_charges.dart

# Le fichier sera créé: ./Cahier_des_Charges_Station_Service.pdf
```

## Dépendances Requises

- `pdf: ^3.11.0` - Génération de PDF
- `printing: ^5.12.0` - Support d'impression et partage
- `path: ^1.9.0` - Gestion des chemins

Ces dépendances sont déjà configurées dans `pubspec.yaml`.
