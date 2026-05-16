import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/services/api_client.dart';
import '../../data/services/app_session_service.dart';
import '../../data/services/auth_service.dart';
import '../widgets/connection_error_dialog.dart';
import '../widgets/feedback_cards.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authService,
    required this.appSessionService,
    required this.onAuthenticated,
    this.initialErrorMessage,
    this.showInitialConnectionDialog = false,
    this.shouldAttemptSessionRestore = false,
  });

  final AuthService authService;
  final AppSessionService appSessionService;
  final VoidCallback onAuthenticated;
  final String? initialErrorMessage;
  final bool showInitialConnectionDialog;
  final bool shouldAttemptSessionRestore;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  Timer? _restoreTimer;
  bool _isRestoringSession = false;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialErrorMessage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.showInitialConnectionDialog &&
          widget.initialErrorMessage != null &&
          widget.initialErrorMessage!.isNotEmpty) {
        showConnectionErrorDialog(
          context,
          message: widget.initialErrorMessage!,
        );
      }
    });
    if (widget.shouldAttemptSessionRestore) {
      _startSessionRestorePolling();
    }
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startSessionRestorePolling() {
    _restoreTimer?.cancel();
    _attemptSessionRestore();
    _restoreTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _attemptSessionRestore();
    });
  }

  Future<void> _attemptSessionRestore() async {
    if (_isRestoringSession || !widget.appSessionService.hasSavedSession) {
      if (!widget.appSessionService.hasSavedSession) {
        _restoreTimer?.cancel();
      }
      return;
    }

    _isRestoringSession = true;
    try {
      final user = await widget.appSessionService.tryRestoreSavedSession();
      if (!mounted) {
        return;
      }
      if (user != null) {
        _restoreTimer?.cancel();
        widget.onAuthenticated();
      }
    } finally {
      _isRestoringSession = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await widget.authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.authService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await widget.authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) {
        return;
      }
      widget.onAuthenticated();
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.readableMessage;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Falha inesperada: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleMode(bool login) {
    setState(() {
      _isLogin = login;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF7FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF2FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.home_work_rounded,
                              color: Color(0xFF5DADE2),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Corretor de Imoveis',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acesse sua conta e gerencie imoveis da sua carteira com uma interface simples.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5A7B94),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Entrar'),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Cadastrar'),
                              ),
                            ],
                            selected: {_isLogin},
                            onSelectionChanged: (selection) {
                              _toggleMode(selection.first);
                            },
                          ),
                          const SizedBox(height: 20),
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                              validator: (value) {
                                if (_isLogin) {
                                  return null;
                                }
                                if ((value ?? '').trim().length < 2) {
                                  return 'Informe um nome valido.';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_rounded),
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
                              labelText: 'Senha',
                              prefixIcon: Icon(Icons.lock_rounded),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 6) {
                                return 'A senha deve ter ao menos 6 caracteres.';
                              }
                              return null;
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            InlineMessage(
                              icon: Icons.info_rounded,
                              backgroundColor: const Color(0xFFFFF4E9),
                              foregroundColor: const Color(0xFF946200),
                              text: _errorMessage!,
                            ),
                          ],
                          if (widget.shouldAttemptSessionRestore &&
                              widget.appSessionService.hasSavedSession) ...[
                            const SizedBox(height: 16),
                            const InlineMessage(
                              icon: Icons.sync_rounded,
                              backgroundColor: Color(0xFFEFF8FF),
                              foregroundColor: Color(0xFF285D85),
                              text:
                                  'Tentando restabelecer sua sessao automaticamente assim que o servidor responder.',
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF5DADE2),
                              ),
                              child: Text(
                                _isSubmitting
                                    ? 'Processando...'
                                    : _isLogin
                                    ? 'Entrar'
                                    : 'Criar conta',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
