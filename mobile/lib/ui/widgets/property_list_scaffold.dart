import 'package:flutter/material.dart';

import '../../core/utils/error_formatter.dart';
import '../../data/models/property.dart';
import 'feedback_cards.dart';
import 'property_card.dart';

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
              ErrorCard(message: readFutureError(snapshot.error))
            else if ((snapshot.data ?? []).isEmpty)
              EmptyCard(message: emptyMessage)
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
