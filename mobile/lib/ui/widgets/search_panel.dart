import 'package:flutter/material.dart';

class SearchPanel extends StatelessWidget {
  const SearchPanel({
    super.key,
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
                labelText: 'Buscar por título',
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
                labelText: 'Preço maximo',
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
