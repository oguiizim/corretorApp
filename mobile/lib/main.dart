import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CorretorApp());
}

class CorretorApp extends StatelessWidget {
  const CorretorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF6FBFF);
    const primary = Color(0xFF5DADE2);
    const primarySoft = Color(0xFFDFF2FF);

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF184A73),
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCAE6FA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCAE6FA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: primary.withValues(alpha: 0.10),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );

    return MaterialApp(
      title: 'Corretor de Imoveis',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          bodyColor: const Color(0xFF184A73),
          displayColor: const Color(0xFF184A73),
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          backgroundColor: primarySoft,
          selectedColor: primary,
          side: BorderSide.none,
          labelStyle: const TextStyle(color: Color(0xFF184A73)),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
        ),
      ),
      home: const AppBootstrapper(),
    );
  }
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  late final SessionStore _sessionStore;
  late final ApiClient _apiClient;
  Future<SessionSnapshot>? _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _sessionStore = SessionStore();
    _apiClient = ApiClient(_sessionStore);
    _bootstrapFuture = _bootstrap();
  }

  Future<SessionSnapshot> _bootstrap() async {
    await _sessionStore.init();
    final token = _sessionStore.token;
    User? user;

    if (token != null && token.isNotEmpty) {
      try {
        user = await _apiClient.getCurrentUser();
      } on ApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await _sessionStore.clearToken();
        } else {
          rethrow;
        }
      }
    }

    return SessionSnapshot(user: user);
  }

  void _reload() {
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionSnapshot>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return StartupErrorScreen(
            error: snapshot.error.toString(),
            onRetry: _reload,
          );
        }

        final data = snapshot.data!;
        if (data.user == null) {
          return AuthScreen(
            apiClient: _apiClient,
            sessionStore: _sessionStore,
            onAuthenticated: _reload,
          );
        }

        return HomeScreen(
          apiClient: _apiClient,
          sessionStore: _sessionStore,
          initialUser: data.user!,
          onLogout: _reload,
        );
      },
    );
  }
}

class SessionSnapshot {
  const SessionSnapshot({required this.user});

  final User? user;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Conectando ao sistema...'),
          ],
        ),
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: Color(0xFF5DADE2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nao foi possivel inicializar o app.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.apiClient,
    required this.sessionStore,
    required this.onAuthenticated,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback onAuthenticated;

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        await widget.apiClient.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.apiClient.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await widget.apiClient.login(
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
                            _InlineMessage(
                              icon: Icons.info_rounded,
                              backgroundColor: const Color(0xFFFFF4E9),
                              foregroundColor: const Color(0xFF946200),
                              text: _errorMessage!,
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiClient,
    required this.sessionStore,
    required this.initialUser,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final User initialUser;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
  }

  Future<void> _logout() async {
    await widget.sessionStore.clearToken();
    if (!mounted) {
      return;
    }
    widget.onLogout();
  }

  Future<void> _refreshUser() async {
    final user = await widget.apiClient.getCurrentUser();
    if (!mounted) {
      return;
    }
    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PublicPropertiesTab(apiClient: widget.apiClient),
      MyPropertiesTab(apiClient: widget.apiClient),
      ProfileTab(
        apiClient: widget.apiClient,
        user: _user,
        onUserUpdated: (user) {
          setState(() {
            _user = user;
          });
        },
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Corretor'),
        actions: [
          IconButton(
            onPressed: _refreshUser,
            tooltip: 'Atualizar usuario',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore_rounded),
            label: 'Publicos',
          ),
          NavigationDestination(
            icon: Icon(Icons.domain_add_rounded),
            label: 'Meus imoveis',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class PublicPropertiesTab extends StatefulWidget {
  const PublicPropertiesTab({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PublicPropertiesTab> createState() => _PublicPropertiesTabState();
}

class _PublicPropertiesTabState extends State<PublicPropertiesTab> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  late Future<List<Property>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.listPublicProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _future = widget.apiClient.searchPublicProperties(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        priceMax: _parsePrice(_priceController.text),
      );
    });
  }

  void _clear() {
    _titleController.clear();
    _priceController.clear();
    setState(() {
      _future = widget.apiClient.listPublicProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PropertyListScaffold(
      title: 'Vitrine de imoveis',
      subtitle: 'Busque todos os imoveis expostos pela API.',
      header: _SearchPanel(
        titleController: _titleController,
        priceController: _priceController,
        onSearch: _search,
        onClear: _clear,
      ),
      future: _future,
      emptyMessage: 'Nenhum imovel encontrado na busca publica.',
    );
  }
}

class MyPropertiesTab extends StatefulWidget {
  const MyPropertiesTab({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MyPropertiesTab> createState() => _MyPropertiesTabState();
}

class _MyPropertiesTabState extends State<MyPropertiesTab> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  late Future<List<Property>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.listMyProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.apiClient.listMyProperties();
    });
  }

  void _search() {
    setState(() {
      _future = widget.apiClient.searchMyProperties(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        priceMax: _parsePrice(_priceController.text),
      );
    });
  }

  void _clear() {
    _titleController.clear();
    _priceController.clear();
    _reload();
  }

  Future<void> _openEditor([Property? property]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return PropertyFormSheet(
          apiClient: widget.apiClient,
          property: property,
        );
      },
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _delete(Property property) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir imovel'),
          content: Text('Deseja remover "${property.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await widget.apiClient.deleteProperty(property.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imovel removido.')));
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.readableMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PropertyListScaffold(
      title: 'Minha carteira',
      subtitle: 'Cadastre, edite e filtre os imoveis do corretor logado.',
      header: Column(
        children: [
          _SearchPanel(
            titleController: _titleController,
            priceController: _priceController,
            onSearch: _search,
            onClear: _clear,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_home_work_rounded),
              label: const Text('Novo imovel'),
            ),
          ),
        ],
      ),
      future: _future,
      emptyMessage: 'Voce ainda nao cadastrou imoveis.',
      onEdit: _openEditor,
      onDelete: _delete,
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.apiClient,
    required this.user,
    required this.onUserUpdated,
    required this.onLogout,
  });

  final ApiClient apiClient;
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
      final updated = await widget.apiClient.updateUser(
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
                    _InlineMessage(
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
                        _isSaving ? 'Salvando...' : 'Salvar alteracoes',
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

class PropertyListScaffold extends StatelessWidget {
  const PropertyListScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.header,
    required this.future,
    required this.emptyMessage,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final Widget header;
  final Future<List<Property>> future;
  final String emptyMessage;
  final Future<void> Function(Property property)? onEdit;
  final Future<void> Function(Property property)? onDelete;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Property>>(
      future: future,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF6D8AA3)),
                    ),
                    const SizedBox(height: 16),
                    header,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              _ErrorCard(message: _readFutureError(snapshot.error))
            else if ((snapshot.data ?? []).isEmpty)
              _EmptyCard(message: emptyMessage)
            else
              ...snapshot.data!.map(
                (property) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PropertyCard(
                    property: property,
                    onEdit: onEdit == null ? null : () => onEdit!(property),
                    onDelete: onDelete == null
                        ? null
                        : () => onDelete!(property),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onEdit,
    this.onDelete,
  });

  final Property property;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property.address,
                        style: const TextStyle(color: Color(0xFF6D8AA3)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    property.formattedPrice,
                    style: const TextStyle(
                      color: Color(0xFF285D85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PropertyFormSheet extends StatefulWidget {
  const PropertyFormSheet({super.key, required this.apiClient, this.property});

  final ApiClient apiClient;
  final Property? property;

  @override
  State<PropertyFormSheet> createState() => _PropertyFormSheetState();
}

class _PropertyFormSheetState extends State<PropertyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.property != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.property?.title ?? '',
    );
    _addressController = TextEditingController(
      text: widget.property?.address ?? '',
    );
    _priceController = TextEditingController(
      text: widget.property == null
          ? ''
          : _formatPriceInput(widget.property!.price),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await widget.apiClient.updateProperty(
          id: widget.property!.id,
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          price: _parsePrice(_priceController.text)!,
        );
      } else {
        await widget.apiClient.createProperty(
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          price: _parsePrice(_priceController.text)!,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.readableMessage;
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Editar imovel' : 'Novo imovel',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titulo',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe o titulo do imovel.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereco',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe o endereco.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preco',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  final price = _parsePrice(value ?? '');
                  if (price == null || price <= 0) {
                    return 'Informe um preco valido.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _InlineMessage(
                  icon: Icons.error_outline_rounded,
                  backgroundColor: const Color(0xFFFFF4E9),
                  foregroundColor: const Color(0xFF946200),
                  text: _errorMessage!,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Salvando...' : 'Salvar imovel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.titleController,
    required this.priceController,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController titleController;
  final TextEditingController priceController;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([titleController, priceController]),
      builder: (context, _) {
        final hasFilters =
            titleController.text.trim().isNotEmpty ||
            priceController.text.trim().isNotEmpty;

        return Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Buscar por titulo',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Preco maximo',
                prefixIcon: Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSearch,
                    icon: const Icon(Icons.filter_alt_rounded),
                    label: const Text('Filtrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClear,
                    icon: Icon(
                      hasFilters
                          ? Icons.restart_alt_rounded
                          : Icons.refresh_rounded,
                    ),
                    label: Text(hasFilters ? 'Limpar' : 'Atualizar'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.text,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: foregroundColor)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.home_outlined, color: Color(0xFF5DADE2), size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ApiClient {
  ApiClient(this._sessionStore, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SessionStore _sessionStore;
  final http.Client _http;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _post('/usuarios', {'nome': name, 'email': email, 'senha': password});
  }

  Future<void> login({required String email, required String password}) async {
    final data =
        await _post('/usuarios/login', {'email': email, 'senha': password})
            as Map<String, dynamic>;

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        readableMessage: 'A API nao retornou token de acesso.',
      );
    }

    await _sessionStore.saveToken(token);
  }

  Future<User> getCurrentUser() async {
    final data = await _get('/usuarios/me', auth: true) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<User> updateUser({
    required int id,
    required String name,
    required String email,
    required String password,
  }) async {
    final data =
        await _put('/usuarios/$id', {
              'nome': name,
              'email': email,
              'senha': password,
            }, auth: true)
            as Map<String, dynamic>;

    return User.fromJson(data);
  }

  Future<List<Property>> listPublicProperties() async {
    final data = await _get('/imoveis/publicos') as List<dynamic>;
    return data
        .map((item) => Property.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Property>> searchPublicProperties({
    String? title,
    double? priceMax,
  }) async {
    final query = <String, String>{};
    if (title != null && title.isNotEmpty) {
      query['titulo'] = title;
    } else if (priceMax != null) {
      query['precoMax'] = priceMax.toString();
    }
    final data =
        await _getUri(
              _buildUri(
                '/imoveis/publicos/buscar',
              ).replace(queryParameters: query.isEmpty ? null : query),
            )
            as List<dynamic>;
    return data
        .map((item) => Property.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Property>> listMyProperties() async {
    final data = await _get('/imoveis/meus', auth: true) as List<dynamic>;
    return data
        .map((item) => Property.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Property>> searchMyProperties({
    String? title,
    double? priceMax,
  }) async {
    final query = <String, String>{};
    if (title != null && title.isNotEmpty) {
      query['titulo'] = title;
    } else if (priceMax != null) {
      query['precoMax'] = priceMax.toString();
    }
    final data =
        await _getUri(
              _buildUri(
                '/imoveis/buscar',
              ).replace(queryParameters: query.isEmpty ? null : query),
              auth: true,
            )
            as List<dynamic>;
    return data
        .map((item) => Property.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Property> createProperty({
    required String title,
    required String address,
    required double price,
  }) async {
    final data =
        await _post('/imoveis', {
              'titulo': title,
              'endereco': address,
              'preco': price,
            }, auth: true)
            as Map<String, dynamic>;

    return Property.fromJson(data);
  }

  Future<Property> updateProperty({
    required int id,
    required String title,
    required String address,
    required double price,
  }) async {
    final data =
        await _put('/imoveis/$id', {
              'titulo': title,
              'endereco': address,
              'preco': price,
            }, auth: true)
            as Map<String, dynamic>;

    return Property.fromJson(data);
  }

  Future<void> deleteProperty(int id) async {
    await _delete('/imoveis/$id', auth: true);
  }

  Future<dynamic> _get(String path, {bool auth = false}) async {
    return _getUri(_buildUri(path), auth: auth);
  }

  Future<dynamic> _getUri(Uri uri, {bool auth = false}) async {
    final response = await _http.get(uri, headers: await _headers(auth: auth));
    return _handleResponse(response);
  }

  Future<dynamic> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await _http.post(
      _buildUri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await _http.put(
      _buildUri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _delete(String path, {bool auth = false}) async {
    final response = await _http.delete(
      _buildUri(path),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  Uri _buildUri(String path) {
    final base = _sessionStore.baseUrl;
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (auth) {
      final token = _sessionStore.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final bodyText = response.body.trim();
    final data = bodyText.isEmpty ? null : jsonDecode(bodyText);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw ApiException.fromResponse(response.statusCode, data);
  }
}

class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _baseUrlKey = 'api_base_url';

  SharedPreferences? _prefs;
  String _baseUrl = _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8081';
      default:
        return 'http://localhost:8081';
    }
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _baseUrl = _prefs!.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  String get baseUrl => _baseUrl;

  String? get token => _prefs?.getString(_tokenKey);

  Future<void> saveToken(String token) async {
    await _prefs!.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs!.remove(_tokenKey);
  }

  Future<void> setBaseUrl(String value) async {
    _baseUrl = value;
    await _prefs!.setString(_baseUrlKey, value);
  }
}

class User {
  const User({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
  });

  final int id;
  final String title;
  final String address;
  final double price;

  String get formattedPrice => _currencyFormatter.format(price);

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      title: json['titulo']?.toString() ?? '',
      address: json['endereco']?.toString() ?? '',
      price: (json['preco'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.readableMessage});

  final int statusCode;
  final String readableMessage;

  factory ApiException.fromResponse(int statusCode, dynamic data) {
    if (data is Map<String, dynamic>) {
      final fields = data['fields'];
      if (fields is Map) {
        final joined = fields.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
        if (joined.isNotEmpty) {
          return ApiException(statusCode: statusCode, readableMessage: joined);
        }
      }

      final errorText = data['error']?.toString();
      if (errorText != null && errorText.isNotEmpty) {
        return ApiException(statusCode: statusCode, readableMessage: errorText);
      }
    }

    return ApiException(
      statusCode: statusCode,
      readableMessage: 'Erro HTTP $statusCode',
    );
  }

  @override
  String toString() => readableMessage;
}

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

double? _parsePrice(String raw) {
  final cleaned = raw.replaceAll('R\$', '').replaceAll(' ', '').trim();
  if (cleaned.isEmpty) {
    return null;
  }

  final normalized = cleaned.contains(',')
      ? cleaned.replaceAll('.', '').replaceAll(',', '.')
      : cleaned;
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

String _formatPriceInput(double value) {
  final currency = _currencyFormatter.format(value);
  return currency.replaceAll('R\$', '').trim();
}

String _readFutureError(Object? error) {
  if (error is ApiException) {
    return error.readableMessage;
  }
  return 'Falha ao carregar dados: $error';
}
