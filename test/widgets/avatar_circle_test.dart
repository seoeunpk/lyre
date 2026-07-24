import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyre/widgets/avatar_circle.dart';
import 'package:lyre/widgets/empty_state_card.dart';

void main() {
  test('builds initials from the first two name parts', () {
    expect(initialsFor('  Ada Lovelace Byron '), 'AL');
    expect(initialsFor(''), '?');
  });

  testWidgets('AvatarCircle shows initials at the requested size',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
          body: AvatarCircle(id: 'user-1', name: 'Ada Lovelace', size: 56)),
    ));

    expect(find.text('AL'), findsOneWidget);
    expect(tester.getSize(find.byType(AvatarCircle)), const Size(56, 56));
  });

  testWidgets('EmptyStateCard renders its message', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EmptyStateCard('Nothing saved yet')),
    ));

    expect(find.text('Nothing saved yet'), findsOneWidget);
  });
}
