import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparkio/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskRepository in-app nudges', () {
    test('stores and reads dismissed nudge ids for same day', () async {
      final repo = TaskRepository();
      const dateKey = '2026-02-25';

      await repo.dismissInAppNudge(dateKey: dateKey, nudgeId: 'n1');
      await repo.dismissInAppNudge(dateKey: dateKey, nudgeId: 'n2');

      final dismissed = await repo.getDismissedInAppNudges(dateKey);
      expect(dismissed.contains('n1'), isTrue);
      expect(dismissed.contains('n2'), isTrue);
      expect(dismissed.length, 2);
    });

    test('does not carry dismissed nudge ids to another day', () async {
      final repo = TaskRepository();
      await repo.dismissInAppNudge(dateKey: '2026-02-25', nudgeId: 'n1');

      final nextDay = await repo.getDismissedInAppNudges('2026-02-26');
      expect(nextDay, isEmpty);
    });
  });
}
