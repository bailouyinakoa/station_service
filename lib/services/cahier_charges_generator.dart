import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CahierChargesGenerator {
  static Future<void> generateAndSavePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Titre
            pw.Center(
              child: pw.Text(
                'CAHIER DES CHARGES',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'APPLICATION DE GESTION DE STATION-SERVICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // 1. Présentation générale
            pw.Text(
              '1. PRÉSENTATION GÉNÉRALE',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'L\'application Station Service App est une solution de gestion complète pour stations-services. '
              'Elle permet de gérer les ventes de carburant, le stock, les clients, les pompes et de générer des rapports détaillés. '
              'L\'application est développée en Flutter avec support multi-plateforme (mobile, desktop, web).',
              style: pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 20),

            // 2. Fonctionnalités principales
            pw.Text(
              '2. FONCTIONNALITÉS PRINCIPALES',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // 2.1 Authentification
            pw.Text(
              '2.1 Authentification et Gestion des Utilisateurs',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Connexion sécurisée avec identifiants',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Persistence de session automatique',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Rôles d\'utilisateurs : Administrateur, Caissier',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.2 Gestion des Pompes
            pw.Text(
              '2.2 Gestion des Pompes',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Inventaire complet des pompes',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Activation / Désactivation des pompes',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Suivi des relevés compteurs',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Statut en temps réel (active/inactive)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.3 Gestion des Carburants
            pw.Text(
              '2.3 Gestion des Carburants',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Catalogue des carburants disponibles',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Gestion des prix par litre',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Suivi du stock en litre',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Définition de seuils d\'alerte pour bas stocks',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Modification dynamique des prix et stocks',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.4 Gestion des Ventes
            pw.Text(
              '2.4 Gestion des Ventes de Carburant',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Enregistrement des ventes par client',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Sélection du carburant et de la quantité',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Calcul automatique du montant total',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Historique des transactions',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Mise à jour automatique du stock',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.5 Gestion des Clients
            pw.Text(
              '2.5 Gestion des Clients',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Répertoire client complet',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Suivi du solde client',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Historique des transactions par client',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Gestion des paiements',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.6 Gestion du Stock
            pw.Text(
              '2.6 Gestion du Stock',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Suivi des mouvements de stock (entrée/sortie)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Stock disponible par carburant',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Alertes pour bas stocks',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Historique des mouvements',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Deuxième page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 2.7 Tableau de bord
            pw.Text(
              '2.7 Tableau de Bord',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Résumé du chiffre d\'affaires journalier et mensuel',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Affichage du stock total en carburant',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Vue en temps réel des données',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.8 Rapports et Impression
            pw.Text(
              '2.8 Rapports et Impression',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Génération de rapports PDF',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Impression directe depuis l\'application',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Rapports détaillés des ventes',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Export des données',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.9 Gestion des Dépenses
            pw.Text(
              '2.9 Gestion des Dépenses',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Enregistrement des dépenses',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Categorisation des dépenses',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Suivi mensuel des frais',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2.10 Comptabilité
            pw.Text(
              '2.10 Module Comptabilité',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Suivi des entrées/sorties',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Génération d\'écritures comptables',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Rapports comptables détaillés',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 3. Interface Utilisateur
            pw.Text(
              '3. INTERFACE UTILISATEUR',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Design responsive (mobile, tablette, desktop)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Menu permanent sur grand écran',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Tiroir de navigation sur petit écran',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Material Design 3',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Indicateurs de chargement',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Scrolling optimisé',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 4. Fonctionnalités de Conversion Monétaire
            pw.Text(
              '4. CONVERSION MONÉTAIRE',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Formatage automatique en Franc CFA',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Affichage des montants formatés',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Troisième page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 5. Moyen d'utilisation - Installation
            pw.Text(
              '5. MOYEN D\'UTILISATION - INSTALLATION',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '1. Installer Flutter (https://docs.flutter.dev/get-started/install)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '2. Ouvrir le terminal dans le dossier du projet',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '3. Exécuter: flutter pub get',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '4. Exécuter: flutter run -d linux (ou -d android/-d ios)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // 6. Identificants de test
            pw.Text(
              '6. IDENTIFIANTS DE TEST',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Administrateur:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '  Identifiant: admin',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '  Mot de passe: admin123',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Caissier:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '  Identifiant: caissier',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '  Mot de passe: caissier123',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // 7. Platefomes supportées
            pw.Text(
              '7. PLATEFORMES SUPPORTÉES',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Linux',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• macOS',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Windows',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Android',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• iOS',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // 8. Technologies utilisées
            pw.Text(
              '8. TECHNOLOGIES UTILISÉES',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• Flutter 3.11.3 (Framework cross-platform)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Dart (Langage de programmation)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• GetX (Gestion d\'état et routing)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• SQLite/Sqflite (Base de données)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Firebase (Backend et stockage)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Material Design 3 (UI Framework)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // 9. Conclusion
            pw.Text(
              '9. CONCLUSION',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Station Service App est une solution complète et intuitive pour la gestion de stations-services. '
              'Avec son interface responsive, ses fonctionnalités robustes et son support multi-plateforme, '
              'elle permet une gestion efficace et professionnelle des opérations quotidiennes.',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    // Sauvegarde du PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Cahier_des_Charges_Station_Service.pdf',
    );
  }
}
