import 'package:flutter/material.dart';

import '../../core/utils/price_utils.dart';
import '../../data/models/property.dart';
import '../../data/services/api_client.dart';
import '../../data/services/property_service.dart';
import '../widgets/property_form_sheet.dart';
import '../widgets/property_list_scaffold.dart';
import '../widgets/search_panel.dart';

class MyPropertiesTab extends StatefulWidget {
  const MyPropertiesTab({super.key, required this.propertyService});

  final PropertyService propertyService;

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
    _future = widget.propertyService.listMyProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.propertyService.listMyProperties();
    });
  }

  void _search() {
    setState(() {
      _future = widget.propertyService.searchMyProperties(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        priceMax: parsePrice(_priceController.text),
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
          propertyService: widget.propertyService,
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
      await widget.propertyService.deleteProperty(property.id);
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
          SearchPanel(
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
