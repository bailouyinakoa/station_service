// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_service_app/core/constants/app_colors.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/licence/deviceId.dart';
import 'package:station_service_app/licence/licenceservice.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _deviceId = "unknown";
  @override
  void initState() {
    super.initState();
    _fetchDeviceId();
  }

  Future<void> _fetchDeviceId() async {
    final deviceId = await DeviceId.getDeviceId();

    setState(() {
      _deviceId = deviceId;
    });
  }

  Future<void> _contactPhone(String phoneNumber) async {
    String message =
        "Bonjour, je souhaite activer ma licence pour l'application de gestion de station-service. Mon ID d'appareil est : $_deviceId. Merci de me fournir les instructions pour l'activation et les frais d'abonnement.";

    final cleanNumber = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    final encodedMessage = Uri.encodeComponent(message);

    // Liste des URL à essayer par ordre de préférence
    final whatsappUrls = [
      "https://wa.me/$cleanNumber?text=$encodedMessage",
      "whatsapp://send?phone=$cleanNumber&text=$encodedMessage",
      "whatsapp://send?abid=$cleanNumber&text=$encodedMessage",
      "whatsapp-business://send?phone=$cleanNumber&text=$encodedMessage",
    ];

    // Essayer chaque URL
    for (final url in whatsappUrls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Erreur pour $url: $e');
      }
    }

    // Essayer directement avec launchUrl sans canLaunchUrl (parfois ça marche)
    try {
      await launchUrl(
        Uri.parse("https://wa.me/$cleanNumber?text=$encodedMessage"),
        mode: LaunchMode.externalApplication,
      );
      return;
    } catch (e) {
      debugPrint('Impossible d\'ouvrir WhatsApp: $e');
    }

    // Si WhatsApp n'est pas disponible, proposer des alternatives
    if (mounted) {
      showAdaptiveModal(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Contactez-nous'),
          content: const Text(
            'WhatsApp n\'est pas disponible. Choisissez une option :',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final callUrl = Uri(scheme: 'tel', path: cleanNumber);
                try {
                  if (await canLaunchUrl(callUrl)) {
                    await launchUrl(callUrl);
                  }
                } catch (e) {
                  debugPrint('Erreur appel: $e');
                }
              },
              child: const Text('Appeler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final smsUrl = Uri(
                  scheme: 'sms',
                  path: cleanNumber,
                  queryParameters: {'body': message},
                );
                try {
                  if (await canLaunchUrl(smsUrl)) {
                    await launchUrl(smsUrl);
                  }
                } catch (e) {
                  debugPrint('Erreur SMS: $e');
                }
              },
              child: const Text('SMS'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Numéro copié avec succès")),
                );
              },
              child: const Text('Copier le numéro'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    final keyController = TextEditingController();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.loginTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Pas de Licene ou Licence expirée",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'Ma clé de licence',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => Text(
                        authController.error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                    Container(
                      child: const Text(
                        "Contactez le concepteur et lui envoyer l'ID de votre appareil et les frais de votre abonnement pour activer votre licence",
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        TextButton(
                          onPressed: () => _contactPhone("+22666934191"),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline),
                              const SizedBox(width: 5),
                              const Text("+22666934191"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _contactPhone("+22660460626"),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline),
                              const SizedBox(width: 5),
                              const Text("+22660460626"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                child: SelectableText(_deviceId),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _deviceId),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("ID copié avec succès"),
                                  ),
                                );
                              },
                              icon: Icon(Icons.copy, size: 30),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      if (authController.isLoading) {
                        return const CircularProgressIndicator();
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final result = Licenceservice.verifierCle(
                              keyController.text.trim(),
                              _deviceId,
                            );
                            if (result.valide) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                "licence_key",
                                keyController.text.trim(),
                              );
                              await prefs.setString(
                                "licence_expiry",
                                result.dateExpiration!.toIso8601String(),
                              );
                              await authController.refreshLicenseStatus();
                              Get.snackbar(
                                "merci",
                                "vous avez ${result.joursRestants} jours d'utilisation, ca s'expire le ${result.dateExpiration}",
                              );
                              Get.offAllNamed(AppRoutes.onboardingUsers);
                            } else {
                              Get.snackbar('Licence requise', result.message);
                            }
                          },
                          child: const Text('Se connecter'),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
