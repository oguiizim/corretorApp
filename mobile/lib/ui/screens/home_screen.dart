import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../data/services/api_client.dart';
import '../../data/services/app_session_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/property_service.dart';
import '../tabs/my_properties_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/public_properties_tab.dart';
import '../widgets/connection_error_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    required this.propertyService,
    required this.appSessionService,
    required this.initialUser,
    required this.onLogout,
  });

  final AuthService authService;
  final PropertyService propertyService;
  final AppSessionService appSessionService;
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
    await widget.appSessionService.logout();
    if (!mounted) {
      return;
    }
    widget.onLogout();
  }

  Future<void> _refreshUser() async {
    try {
      final user = await widget.authService.getCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {
        _user = user;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _logout();
        return;
      }
      await showConnectionErrorDialog(context, message: error.readableMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PublicPropertiesTab(propertyService: widget.propertyService),
      MyPropertiesTab(propertyService: widget.propertyService),
      ProfileTab(
        authService: widget.authService,
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
