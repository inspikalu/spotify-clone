import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_clone/features/search/models/browse_category.dart';
import 'package:spotify_clone/features/search/widgets/browse_category_card.dart';
import 'package:spotify_clone/features/search/widgets/recent_searches_view.dart';

void main() {
  testWidgets('BrowseCategoryCard renders title and icon', (tester) async {
    bool tapped = false;
    const cat = BrowseCategory(
      id: 'afrobeats',
      title: 'Afrobeats',
      color: Color(0xFFE91429),
      icon: Icons.album,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowseCategoryCard(
            category: cat,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Afrobeats'), findsOneWidget);
    expect(find.byIcon(Icons.album), findsOneWidget);

    await tester.tap(find.text('Afrobeats'));
    expect(tapped, isTrue);
  });

  testWidgets('RecentSearchesView renders list of queries and handles remove/clear', (tester) async {
    String? selected;
    String? removed;
    bool cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentSearchesView(
            queries: const ['Seyi Vibez', 'Asake'],
            onSelectQuery: (q) => selected = q,
            onRemoveQuery: (q) => removed = q,
            onClearAll: () => cleared = true,
          ),
        ),
      ),
    );

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Seyi Vibez'), findsOneWidget);
    expect(find.text('Asake'), findsOneWidget);

    await tester.tap(find.text('Seyi Vibez'));
    expect(selected, 'Seyi Vibez');

    await tester.tap(find.byIcon(Icons.close).first);
    expect(removed, 'Seyi Vibez');

    await tester.tap(find.text('Clear all'));
    expect(cleared, isTrue);
  });
}
