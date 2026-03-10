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
        '2 dakikal\u0131k reset: yava\u015f nefes al ve omuzlar\u0131n\u0131 gev\u015fet',
      );
    });

    test('localizes additional remote titles to Turkish', () {
      expect(
        TaskLocalizer.localizeTitle(
          'Clean one small surface',
          localeCode: 'tr',
          category: 'growth',
        ),
        'K\u00fc\u00e7\u00fck bir y\u00fczeyi temizle',
      );
      expect(
        TaskLocalizer.localizeTitle(
          'Do 10 wall push-ups',
          localeCode: 'tr',
          category: 'body',
        ),
        'Duvara kar\u015f\u0131 10 \u015f\u0131nav yap',
      );
      expect(
        TaskLocalizer.localizeTitle(
          'Learn one tiny habit idea',
          localeCode: 'tr',
          category: 'growth',
        ),
        'K\u00fc\u00e7\u00fck bir al\u0131\u015fkanl\u0131k fikri \u00f6\u011fren',
      );
    });

    test('localizes generated calm prompts with duration to Turkish', () {
      expect(
        TaskLocalizer.localizeTitle(
          'Breathe slowly for 90 seconds and relax your shoulders',
          localeCode: 'tr',
          category: 'calm',
        ),
        '90 saniye yava\u015f nefes al ve omuzlar\u0131n\u0131 gev\u015fet',
      );
    });
  });
}
