import 'package:flutter/material.dart';

import '../../core/utils/price_utils.dart';
import '../../data/models/property.dart';
import '../../data/services/api_client.dart';
import '../../data/services/property_service.dart';
import 'feedback_cards.dart';

class PropertyFormSheet extends StatefulWidget {
  const PropertyFormSheet({
    super.key,
    required this.propertyService,
    this.property,
  });

  final PropertyService propertyService;
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
          : formatPriceInput(widget.property!.price),
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
        await widget.propertyService.updateProperty(
          id: widget.property!.id,
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          price: parsePrice(_priceController.text)!,
        );
      } else {
        await widget.propertyService.createProperty(
          title: _titleController.text.trim(),
          address: _addressController.text.trim(),
          price: parsePrice(_priceController.text)!,
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
                  labelText: 'Endereço',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Informe o endereço.';
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
                  labelText: 'Preço',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  final price = parsePrice(value ?? '');
                  if (price == null || price <= 0) {
                    return 'Informe um preco valido.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                InlineMessage(
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
