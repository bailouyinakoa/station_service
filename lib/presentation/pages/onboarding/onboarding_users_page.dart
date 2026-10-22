import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_colors.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';

class OnboardingUsersPage extends StatefulWidget {
  const OnboardingUsersPage({super.key});

  @override
  State<OnboardingUsersPage> createState() => _OnboardingUsersPageState();
}

class _OnboardingUsersPageState extends State<OnboardingUsersPage> {
  final _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _adminNameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminPasswordConfirmController = TextEditingController();
  final _managers = <_ManagerFormControllers>[_ManagerFormControllers()];

  @override
  void dispose() {
    _adminNameController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _adminPasswordConfirmController.dispose();
    for (final manager in _managers) {
      manager.dispose();
    }
    super.dispose();
  }

  void _addManager() {
    setState(() {
      _managers.add(_ManagerFormControllers());
    });
  }

  void _removeManager(int index) {
    if (_managers.length == 1) {
      Get.snackbar('Gérant requis', 'Ajoutez au moins un gérant.');
      return;
    }

    setState(() {
      _managers.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final usernames = <String>[
      _adminUsernameController.text.trim().toLowerCase(),
      ..._managers.map((manager) => manager.username.text.trim().toLowerCase()),
    ];
    if (usernames.toSet().length != usernames.length) {
      Get.snackbar(
        'Identifiant déjà utilisé',
        'Chaque utilisateur doit avoir un identifiant unique.',
      );
      return;
    }

    try {
      await _authController.completeInitialUsersSetup(
        adminName: _adminNameController.text,
        adminUsername: _adminUsernameController.text,
        adminPassword: _adminPasswordController.text,
        managers: _managers
            .map(
              (manager) => (
                name: manager.name.text,
                username: manager.username.text,
                password: manager.password.text,
              ),
            )
            .toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est requis';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 4) {
      return 'Minimum 4 caractères';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final maxWidth = isMobile ? double.infinity : 760.0;
    final padding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Création des utilisateurs'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            width: maxWidth,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StepHeader(isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _SectionCard(
                    title: 'Administrateur',
                    icon: Icons.admin_panel_settings_outlined,
                    children: [
                      _ResponsiveFields(
                        isMobile: isMobile,
                        children: [
                          TextFormField(
                            controller: _adminNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet *',
                              border: OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                          TextFormField(
                            controller: _adminUsernameController,
                            decoration: const InputDecoration(
                              labelText: 'Identifiant *',
                              border: OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ResponsiveFields(
                        isMobile: isMobile,
                        children: [
                          TextFormField(
                            controller: _adminPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe *',
                              border: OutlineInputBorder(),
                            ),
                            validator: _passwordValidator,
                          ),
                          TextFormField(
                            controller: _adminPasswordConfirmController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmer le mot de passe *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final error = _passwordValidator(value);
                              if (error != null) return error;
                              if (value != _adminPasswordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Gérants',
                    icon: Icons.groups_outlined,
                    trailing: IconButton(
                      tooltip: 'Ajouter un gérant',
                      onPressed: _addManager,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    children: [
                      for (var i = 0; i < _managers.length; i++) ...[
                        _ManagerFields(
                          index: i,
                          controllers: _managers[i],
                          isMobile: isMobile,
                          onRemove: () => _removeManager(i),
                          requiredValidator: _required,
                          passwordValidator: _passwordValidator,
                        ),
                        if (i != _managers.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (_authController.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuer vers la configuration'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerFormControllers {
  final name = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();

  void dispose() {
    name.dispose();
    username.dispose();
    password.dispose();
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape 1 sur 6',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Créez le compte administrateur et les comptes des gérants avant de configurer la station.',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.isMobile, required this.children});

  final bool isMobile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _ManagerFields extends StatelessWidget {
  const _ManagerFields({
    required this.index,
    required this.controllers,
    required this.isMobile,
    required this.onRemove,
    required this.requiredValidator,
    required this.passwordValidator,
  });

  final int index;
  final _ManagerFormControllers controllers;
  final bool isMobile;
  final VoidCallback onRemove;
  final String? Function(String?) requiredValidator;
  final String? Function(String?) passwordValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Gérant ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Supprimer ce gérant',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResponsiveFields(
          isMobile: isMobile,
          children: [
            TextFormField(
              controller: controllers.name,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                border: OutlineInputBorder(),
              ),
              validator: requiredValidator,
            ),
            TextFormField(
              controller: controllers.username,
              decoration: const InputDecoration(
                labelText: 'Identifiant *',
                border: OutlineInputBorder(),
              ),
              validator: requiredValidator,
            ),
            TextFormField(
              controller: controllers.password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe *',
                border: OutlineInputBorder(),
              ),
              validator: passwordValidator,
            ),
          ],
        ),
      ],
    );
  }
}
