import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../data/services/api_client.dart';
import '../../data/services/auth_service.dart';
import '../widgets/feedback_cards.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.authService,
    required this.user,
    required this.onUserUpdated,
    required this.onLogout,
  });

  final AuthService authService;
  final User user;
  final ValueChanged<User> onUserUpdated;
  final Future<void> Function() onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.name != widget.user.name ||
        oldWidget.user.email != widget.user.email) {
      _nameController.text = widget.user.name;
      _emailController.text = widget.user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final updated = await widget.authService.updateProfile(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onUserUpdated(updated);
      setState(() {
        _message = 'Perfil atualizado com sucesso.';
      });
    } on ApiException catch (error) {
      setState(() {
        _message = error.readableMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFDFF2FF),
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF5DADE2),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(widget.user.email),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuracoes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().length < 2) {
                        return 'Informe um nome valido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty || !text.contains('@')) {
                        return 'Informe um email valido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha atual',
                      helperText:
                          'A API exige senha no update, mesmo sem trocar a senha.',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Informe sua senha atual.';
                      }
                      return null;
                    },
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    InlineMessage(
                      icon: Icons.info_outline_rounded,
                      backgroundColor: const Color(0xFFEFF8FF),
                      foregroundColor: const Color(0xFF285D85),
                      text: _message!,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: Text(
                        _isSaving ? 'Salvando...' : 'Salvar alterações',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : widget.onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair da conta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
