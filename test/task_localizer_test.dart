import 'package:flutter_test/flutter_test.dart';
import 'package:sparkio/services/task_localizer.dart';

void main() {
  group('TaskLocalizer', () {
    test('localizes hyphenated reset titles to Turkish', () {
      final localized = TaskLocalizer.localizeTitle(
        '2-minute reset: breathe slowly and relax your shoulders',
        localeCode: 'tr',
        category: 'calm',
      );

      expect(
        localized,
        '2 dakikalık reset: yavaş nefes al ve omuzlarını gevşet',
      );
    });

    test('localizes additional remote titles to Turkish', () {
      expect(
        TaskLocalizer.localizeTitle(
          'Clean one small surface',
          localeCode: 'tr',
          category: 'growth',
        ),
        'Küçük bir yüzeyi temizle',
      );
      expect(
        TaskLocalizer.localizeTitle(
          'Do 10 wall push-ups',
          localeCode: 'tr',
          category: 'body',
        ),
        'Duvara karşı 10 şınav yap',
      );
      expect(
        TaskLocalizer.localizeTitle(
          'Learn one tiny habit idea',
          localeCode: 'tr',
          category: 'growth',
        ),
        'Küçük bir alışkanlık fikri öğren',
      );
    });
  });
}
