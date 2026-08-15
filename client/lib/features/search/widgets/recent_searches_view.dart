import 'package:flutter/material.dart';

class RecentSearchesView extends StatelessWidget {
  const RecentSearchesView({
    super.key,
    required this.queries,
    required this.onSelectQuery,
    required this.onRemoveQuery,
    required this.onClearAll,
  });

  final List<String> queries;
  final ValueChanged<String> onSelectQuery;
  final ValueChanged<String> onRemoveQuery;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onClearAll,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: queries.length,
          itemBuilder: (context, index) {
            final query = queries[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: const Icon(Icons.history, color: Color(0xFFB3B3B3)),
              title: Text(
                query,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFB3B3B3), size: 18),
                onPressed: () => onRemoveQuery(query),
              ),
              onTap: () => onSelectQuery(query),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
