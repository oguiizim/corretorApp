import 'package:flutter/material.dart';

import '../../core/utils/price_utils.dart';
import '../../data/models/property.dart';

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
                    formatPrice(property.price),
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
