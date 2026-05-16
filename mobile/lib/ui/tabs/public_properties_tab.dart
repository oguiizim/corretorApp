import 'package:flutter/material.dart';

import '../../core/utils/price_utils.dart';
import '../../data/models/property.dart';
import '../../data/services/property_service.dart';
import '../widgets/property_list_scaffold.dart';
import '../widgets/search_panel.dart';

class PublicPropertiesTab extends StatefulWidget {
  const PublicPropertiesTab({super.key, required this.propertyService});

  final PropertyService propertyService;

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
    _future = widget.propertyService.listPublicProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _future = widget.propertyService.searchPublicProperties(
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
    setState(() {
      _future = widget.propertyService.listPublicProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PropertyListScaffold(
      title: 'Vitrine de imoveis',
      subtitle: 'Busque todos os imoveis expostos pela API.',
      header: SearchPanel(
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
