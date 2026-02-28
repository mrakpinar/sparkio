import '../models/task.dart';
import 'locale_service.dart';

class TaskLocalizer {
  TaskLocalizer._();

  static final Map<String, Map<String, String>> _titleMap = {
    'Take 3 deep breaths': {
      'tr': '3 derin nefes al',
      'es': 'Haz 3 respiraciones profundas',
      'de': 'Nimm 3 tiefe Atemzüge',
    },
    'Drink a glass of water': {
      'tr': 'Bir bardak su iç',
      'es': 'Bebe un vaso de agua',
      'de': 'Trink ein Glas Wasser',
    },
    'Stretch your shoulders': {
      'tr': 'Omuzlarını esnet',
      'es': 'Estira tus hombros',
      'de': 'Dehne deine Schultern',
    },
    'Write one priority for today': {
      'tr': 'Bugün için tek bir öncelik yaz',
      'es': 'Escribe una prioridad para hoy',
      'de': 'Schreibe eine Priorität für heute auf',
    },
    'Tidy a tiny space': {
      'tr': 'Küçük bir alanı toparla',
      'es': 'Ordena un espacio pequeño',
      'de': 'Räume einen kleinen Bereich auf',
    },
    'Take 3 slow breaths': {
      'tr': '3 yavaş nefes al',
      'es': 'Haz 3 respiraciones lentas',
      'de': 'Nimm 3 langsame Atemzüge',
    },
    'Write one clear priority for today': {
      'tr': 'Bugün için net bir öncelik yaz',
      'es': 'Escribe una prioridad clara para hoy',
      'de': 'Schreibe eine klare Priorität für heute auf',
    },
    'Clear one distraction from your desk': {
      'tr': 'Masandaki bir dikkat dağıtıcıyı kaldır',
      'es': 'Quita una distracción de tu escritorio',
      'de': 'Entferne eine Ablenkung von deinem Schreibtisch',
    },
    'Close extra tabs and focus for 3 minutes': {
      'tr': 'Fazla sekmeleri kapat ve 3 dakika odaklan',
      'es': 'Cierra pestañas extra y concéntrate 3 minutos',
      'de': 'Schließe zusätzliche Tabs und fokussiere dich 3 Minuten',
    },
    'Name one thing you can control today': {
      'tr': 'Bugün kontrol edebileceğin bir şeyi yaz',
      'es': 'Nombra una cosa que puedas controlar hoy',
      'de': 'Nenne eine Sache, die du heute kontrollieren kannst',
    },
    'Write one win from your day': {
      'tr': 'Gününden tek bir kazanım yaz',
      'es': 'Escribe una victoria de tu día',
      'de': 'Schreibe einen Erfolg deines Tages auf',
    },
    'Stand up and stretch your neck and shoulders': {
      'tr': 'Ayağa kalk ve boynunu, omuzlarını esnet',
      'es': 'Levántate y estira cuello y hombros',
      'de': 'Steh auf und dehne Nacken und Schultern',
    },
    'Do 10 squats at your own pace': {
      'tr': 'Kendi temponda 10 squat yap',
      'es': 'Haz 10 sentadillas a tu ritmo',
      'de': 'Mache 10 Kniebeugen in deinem Tempo',
    },
    'Walk for 4 minutes': {
      'tr': '4 dakika yürü',
      'es': 'Camina durante 4 minutos',
      'de': 'Gehe 4 Minuten spazieren',
    },
    'Roll your shoulders for 60 seconds': {
      'tr': 'Omuzlarını 60 saniye çevir',
      'es': 'Rota tus hombros durante 60 segundos',
      'de': 'Kreise deine Schultern 60 Sekunden lang',
    },
    'Do 8 wall push-ups': {
      'tr': 'Duvara karşı 8 şınav yap',
      'es': 'Haz 8 flexiones en la pared',
      'de': 'Mache 8 Liegestütze an der Wand',
    },
    'Stretch your calves for 2 minutes': {
      'tr': 'Baldırlarını 2 dakika esnet',
      'es': 'Estira tus pantorrillas durante 2 minutos',
      'de': 'Dehne deine Waden 2 Minuten lang',
    },
    'Read one page of something useful': {
      'tr': 'Faydalı bir şeyden bir sayfa oku',
      'es': 'Lee una página de algo útil',
      'de': 'Lies eine Seite von etwas Nützlichem',
    },
    'Learn one new word and use it in a sentence': {
      'tr': 'Yeni bir kelime öğren ve cümlede kullan',
      'es': 'Aprende una palabra nueva y úsala en una frase',
      'de': 'Lerne ein neues Wort und benutze es in einem Satz',
    },
    'Plan tomorrow in three bullet points': {
      'tr': 'Yarını üç maddeyle planla',
      'es': 'Planifica mañana en tres puntos',
      'de': 'Plane morgen in drei Stichpunkten',
    },
    'Organize one small area around you': {
      'tr': 'Etrafındaki küçük bir alanı düzenle',
      'es': 'Organiza un área pequeña a tu alrededor',
      'de': 'Ordne einen kleinen Bereich um dich herum',
    },
    'Write one idea to improve your routine': {
      'tr': 'Rutinini geliştirmek için bir fikir yaz',
      'es': 'Escribe una idea para mejorar tu rutina',
      'de': 'Schreibe eine Idee auf, um deine Routine zu verbessern',
    },
    'Start a task you avoid for just 2 minutes': {
      'tr': 'Ertelediğin bir göreve sadece 2 dakika başla',
      'es': 'Empieza durante 2 minutos una tarea que evitas',
      'de': 'Beginne eine aufgeschobene Aufgabe nur für 2 Minuten',
    },
    'Breathe in for 4 and out for 6 for 2 minutes': {
      'tr': '2 dakika boyunca 4 sayıda al, 6 sayıda ver',
      'es': 'Inhala 4 y exhala 6 durante 2 minutos',
      'de': 'Atme 2 Minuten lang 4 ein und 6 aus',
    },
    'Sit quietly and notice sounds for 2 minutes': {
      'tr': '2 dakika sessizce otur ve sesleri fark et',
      'es': 'Siéntate en silencio y nota los sonidos por 2 minutos',
      'de': 'Sitze 2 Minuten still und nimm Geräusche wahr',
    },
    'Relax your jaw and shoulders': {
      'tr': 'Çeneni ve omuzlarını gevşet',
      'es': 'Relaja tu mandíbula y tus hombros',
      'de': 'Entspanne Kiefer und Schultern',
    },
    'Do a short body scan for 3 minutes': {
      'tr': '3 dakikalık kısa bir beden taraması yap',
      'es': 'Haz un escaneo corporal corto durante 3 minutos',
      'de': 'Mache 3 Minuten lang einen kurzen Body-Scan',
    },
    'Step away from your screen for 2 minutes': {
      'tr': '2 dakika ekranından uzaklaş',
      'es': 'Aléjate de tu pantalla durante 2 minutos',
      'de': 'Geh 2 Minuten von deinem Bildschirm weg',
    },
    'Put your phone down and breathe for 60 seconds': {
      'tr': 'Telefonunu bırak ve 60 saniye nefes al',
      'es': 'Deja tu teléfono y respira 60 segundos',
      'de': 'Lege dein Handy weg und atme 60 Sekunden',
    },
    'Drink one full glass of water': {
      'tr': 'Bir tam bardak su iç',
      'es': 'Bebe un vaso entero de agua',
      'de': 'Trink ein volles Glas Wasser',
    },
    'Refill your water bottle now': {
      'tr': 'Su şişeni şimdi doldur',
      'es': 'Rellena tu botella de agua ahora',
      'de': 'Fülle jetzt deine Wasserflasche nach',
    },
    'Eat one healthy snack': {
      'tr': 'Sağlıklı bir atıştırmalık ye',
      'es': 'Come un snack saludable',
      'de': 'Iss einen gesunden Snack',
    },
    'Step outside for fresh air for 3 minutes': {
      'tr': '3 dakika temiz hava için dışarı çık',
      'es': 'Sal afuera 3 minutos a tomar aire fresco',
      'de': 'Geh 3 Minuten an die frische Luft',
    },
    'Reset your posture for 2 minutes': {
      'tr': 'Duruşunu 2 dakika düzelt',
      'es': 'Reinicia tu postura durante 2 minutos',
      'de': 'Korrigiere 2 Minuten lang deine Haltung',
    },
    'Do a 20-20-20 eye break': {
      'tr': '20-20-20 göz molası ver',
      'es': 'Haz una pausa visual 20-20-20',
      'de': 'Mach eine 20-20-20 Augenpause',
    },
    'Move your shoulders for 60 seconds': {
      'tr': 'Omuzlarını 60 saniye hareket ettir',
      'es': 'Mueve tus hombros durante 60 segundos',
      'de': 'Bewege deine Schultern 60 Sekunden lang',
    },
    'Stretch for 1 minute': {
      'tr': '1 dakika esne',
      'es': 'Estira durante 1 minuto',
      'de': 'Dehne dich 1 Minute lang',
    },
    'Clear distractions for 2 minutes': {
      'tr': '2 dakika dikkat dağıtıcıları temizle',
      'es': 'Elimina distracciones durante 2 minutos',
      'de': 'Beseitige 2 Minuten lang Ablenkungen',
    },
    'Write one tiny next step in 60 seconds': {
      'tr': '60 saniyede bir sonraki küçük adımı yaz',
      'es': 'Escribe un pequeño siguiente paso en 60 segundos',
      'de': 'Schreibe in 60 Sekunden den nächsten kleinen Schritt auf',
    },
    'Breathe slowly for 60 seconds': {
      'tr': '60 saniye yavaş nefes al',
      'es': 'Respira lentamente durante 60 segundos',
      'de': 'Atme 60 Sekunden lang langsam',
    },
    'Drink water mindfully for 60 seconds': {
      'tr': '60 saniye farkındalıkla su iç',
      'es': 'Bebe agua con atención durante 60 segundos',
      'de': 'Trink 60 Sekunden lang achtsam Wasser',
    },
    'Notice your breath for 60 seconds': {
      'tr': '60 saniye nefesine dikkat et',
      'es': 'Observa tu respiración durante 60 segundos',
      'de': 'Nimm deinen Atem 60 Sekunden lang wahr',
    },
    'AI pick: write one clear priority': {
      'tr': 'AI önerisi: tek bir net öncelik yaz',
      'es': 'Sugerencia IA: escribe una prioridad clara',
      'de': 'KI-Vorschlag: schreibe eine klare Priorität auf',
    },
    'AI pick: tidy one tiny space': {
      'tr': 'AI önerisi: küçük bir alanı toparla',
      'es': 'Sugerencia IA: ordena un espacio pequeño',
      'de': 'KI-Vorschlag: räume einen kleinen Bereich auf',
    },
    'AI pick: send a kind message': {
      'tr': 'AI önerisi: nazik bir mesaj gönder',
      'es': 'Sugerencia IA: envía un mensaje amable',
      'de': 'KI-Vorschlag: sende eine freundliche Nachricht',
    },
    'AI pick: 12 squats + stretch': {
      'tr': 'AI önerisi: 12 squat + esneme',
      'es': 'Sugerencia IA: 12 sentadillas + estiramiento',
      'de': 'KI-Vorschlag: 12 Kniebeugen + Dehnen',
    },
    'AI pick: 2 minutes of mobility': {
      'tr': 'AI önerisi: 2 dakika mobilite',
      'es': 'Sugerencia IA: 2 minutos de movilidad',
      'de': 'KI-Vorschlag: 2 Minuten Mobilität',
    },
    'AI pick: 15 wall push-ups': {
      'tr': 'AI önerisi: 15 duvar şınavı',
      'es': 'Sugerencia IA: 15 flexiones en la pared',
      'de': 'KI-Vorschlag: 15 Liegestütze an der Wand',
    },
    'AI pick: learn one quick fact': {
      'tr': 'AI önerisi: kısa bir bilgi öğren',
      'es': 'Sugerencia IA: aprende un dato rápido',
      'de': 'KI-Vorschlag: lerne eine kurze Tatsache',
    },
    'AI pick: 10-minute focused read': {
      'tr': 'AI önerisi: 10 dakikalık odaklı okuma',
      'es': 'Sugerencia IA: lectura enfocada de 10 minutos',
      'de': 'KI-Vorschlag: 10 Minuten fokussiert lesen',
    },
    'AI pick: note one improvement idea': {
      'tr': 'AI önerisi: bir gelişim fikri not et',
      'es': 'Sugerencia IA: anota una idea de mejora',
      'de': 'KI-Vorschlag: notiere eine Verbesserungsidee',
    },
    'AI pick: 2-minute breath reset': {
      'tr': 'AI önerisi: 2 dakikalık nefes reseti',
      'es': 'Sugerencia IA: reinicio de respiración de 2 minutos',
      'de': 'KI-Vorschlag: 2-Minuten-Atemreset',
    },
    'AI pick: 60 seconds of stillness': {
      'tr': 'AI önerisi: 60 saniye durgunluk',
      'es': 'Sugerencia IA: 60 segundos de quietud',
      'de': 'KI-Vorschlag: 60 Sekunden Stille',
    },
    'AI pick: soften shoulders and jaw': {
      'tr': 'AI önerisi: omuzlarını ve çeneni yumuşat',
      'es': 'Sugerencia IA: suaviza hombros y mandíbula',
      'de': 'KI-Vorschlag: lockere Schultern und Kiefer',
    },
    'AI pick: drink water mindfully': {
      'tr': 'AI önerisi: suyu farkındalıkla iç',
      'es': 'Sugerencia IA: bebe agua con atención',
      'de': 'KI-Vorschlag: trink Wasser achtsam',
    },
    'AI pick: stand and breathe deeply': {
      'tr': 'AI önerisi: ayağa kalk ve derin nefes al',
      'es': 'Sugerencia IA: ponte de pie y respira profundo',
      'de': 'KI-Vorschlag: steh auf und atme tief ein',
    },
    'AI pick: short screen break': {
      'tr': 'AI önerisi: kısa ekran molası',
      'es': 'Sugerencia IA: pequeña pausa de pantalla',
      'de': 'KI-Vorschlag: kurze Bildschirm-Pause',
    },
    'AI pick: relax jaw and shoulders': {
      'tr': 'AI önerisi: çeneni ve omuzlarını gevşet',
      'es': 'Sugerencia IA: relaja mandíbula y hombros',
      'de': 'KI-Vorschlag: entspanne Kiefer und Schultern',
    },
    'AI pick: short gratitude note': {
      'tr': 'AI önerisi: kısa bir şükran notu',
      'es': 'Sugerencia IA: breve nota de gratitud',
      'de': 'KI-Vorschlag: kurze Dankbarkeitsnotiz',
    },
    'AI pick: quick posture reset': {
      'tr': 'AI önerisi: hızlı duruş reseti',
      'es': 'Sugerencia IA: reinicio rápido de postura',
      'de': 'KI-Vorschlag: schnelles Haltungs-Reset',
    },
    'AI pick: 10-minute focus sprint': {
      'tr': 'AI önerisi: 10 dakikalık odak sprinti',
      'es': 'Sugerencia IA: sprint de enfoque de 10 minutos',
      'de': 'KI-Vorschlag: 10-Minuten-Fokussprint',
    },
    'Set one clear focus outcome': {
      'tr': 'Tek bir net odak sonucu belirle',
      'es': 'Define un resultado de enfoque claro',
      'de': 'Lege ein klares Fokusziel fest',
    },
    'Do a 12-minute deep work sprint': {
      'tr': '12 dakikalık derin çalışma sprinti yap',
      'es': 'Haz un sprint de trabajo profundo de 12 minutos',
      'de': 'Mache einen 12-minütigen Deep-Work-Sprint',
    },
    'Write one distraction to avoid': {
      'tr': 'Kaçınacağın bir dikkat dağıtıcı yaz',
      'es': 'Escribe una distracción que evitarás',
      'de': 'Schreibe eine Ablenkung auf, die du vermeiden willst',
    },
    'Dim lights and reduce noise for 5 minutes': {
      'tr': 'Işıkları kıs ve 5 dakika gürültüyü azalt',
      'es': 'Atenúa las luces y reduce el ruido durante 5 minutos',
      'de': 'Dimme das Licht und reduziere 5 Minuten lang Geräusche',
    },
    'Write tomorrow first task': {
      'tr': 'Yarının ilk görevini yaz',
      'es': 'Escribe la primera tarea de mañana',
      'de': 'Schreibe die erste Aufgabe für morgen auf',
    },
    'No phone and breathe for 4 minutes': {
      'tr': 'Telefon yok, 4 dakika nefes al',
      'es': 'Sin teléfono y respira durante 4 minutos',
      'de': 'Kein Handy und 4 Minuten atmen',
    },
    'Slow exhale breathing for 2 minutes': {
      'tr': '2 dakika yavaş veriş nefesi yap',
      'es': 'Haz respiración con exhalación lenta durante 2 minutos',
      'de': 'Atme 2 Minuten lang mit langsamer Ausatmung',
    },
    'Neck and shoulder release for 3 minutes': {
      'tr': '3 dakika boyun ve omuz gevşetme yap',
      'es': 'Haz una liberación de cuello y hombros durante 3 minutos',
      'de': 'Mache 3 Minuten Nacken- und Schulterlockerung',
    },
    'Note one pressure you can postpone': {
      'tr': 'Erteleyebileceğin bir baskıyı not et',
      'es': 'Anota una presión que puedas posponer',
      'de': 'Notiere einen Druck, den du verschieben kannst',
    },
    'Open curtains and take 5 deep breaths': {
      'tr': 'Perdeleri aç ve 5 derin nefes al',
      'es': 'Abre las cortinas y toma 5 respiraciones profundas',
      'de': 'Öffne die Vorhänge und nimm 5 tiefe Atemzüge',
    },
    'Write one tiny win target for today': {
      'tr': 'Bugün için küçük bir kazanım hedefi yaz',
      'es': 'Escribe un pequeño objetivo de victoria para hoy',
      'de': 'Schreibe ein kleines Erfolgsziel für heute auf',
    },
    'Do a 4-minute start sprint on your top task': {
      'tr': 'En önemli görevinde 4 dakikalık başlangıç sprinti yap',
      'es': 'Haz un sprint inicial de 4 minutos en tu tarea principal',
      'de': 'Mache einen 4-minütigen Start-Sprint bei deiner wichtigsten Aufgabe',
    },
    'Walk for 4 minutes without your phone': {
      'tr': 'Telefon olmadan 4 dakika yürü',
      'es': 'Camina 4 minutos sin tu teléfono',
      'de': 'Gehe 4 Minuten ohne dein Handy',
    },
    'Drink water and relax jaw tension': {
      'tr': 'Su iç ve çene gerginliğini gevşet',
      'es': 'Bebe agua y relaja la tensión de la mandíbula',
      'de': 'Trink Wasser und löse die Kieferspannung',
    },
    'Take 90-second long exhales': {
      'tr': '90 saniye uzun verişler yap',
      'es': 'Haz exhalaciones largas durante 90 segundos',
      'de': 'Mache 90 Sekunden lange Ausatmungen',
    },
    'Write tomorrow top priority in one line': {
      'tr': 'Yarının en önemli işini tek satırda yaz',
      'es': 'Escribe la prioridad principal de mañana en una línea',
      'de': 'Schreibe die wichtigste Aufgabe für morgen in einer Zeile auf',
    },
    'Do gentle neck release for 2 minutes': {
      'tr': '2 dakika nazik boyun gevşetme yap',
      'es': 'Haz una suave liberación de cuello durante 2 minutos',
      'de': 'Mache 2 Minuten sanfte Nackenlockerung',
    },
    'Sit quietly with slow breathing for 3 minutes': {
      'tr': '3 dakika yavaş nefesle sessizce otur',
      'es': 'Siéntate en silencio con respiración lenta durante 3 minutos',
      'de': 'Sitze 3 Minuten ruhig mit langsamer Atmung',
    },  };

  static final Map<String, String> _aliasToCanonical = () {
    final aliasMap = <String, String>{};
    for (final entry in _titleMap.entries) {
      aliasMap[_normalize(entry.key)] = entry.key;
      for (final translated in entry.value.values) {
        aliasMap[_normalize(translated)] = entry.key;
      }
    }
    return aliasMap;
  }();

  static String currentLanguageCode() {
    return LocaleService.instance.effectiveLanguageCode;
  }

  static String localizeTitle(
    String title, {
    String? localeCode,
    String? category,
    String? taskId,
  }) {
    final targetCode = (localeCode ?? currentLanguageCode()).toLowerCase();
    if (targetCode == 'en') {
      final canonical = _resolveCanonicalTitle(title, category: category, taskId: taskId);
      return canonical ?? title;
    }
    final canonical = _resolveCanonicalTitle(title, category: category, taskId: taskId);
    if (canonical == null) return title;
    return _titleMap[canonical]?[targetCode] ?? canonical;
  }

  static List<Task> localizeTasks(
    List<Task> tasks, {
    String? localeCode,
  }) {
    return tasks.map((task) => localizeTask(task, localeCode: localeCode)).toList();
  }

  static Task localizeTask(
    Task task, {
    String? localeCode,
  }) {
    if (task.isCustom && !task.aiSuggested && !task.id.startsWith('starter_')) {
      return task;
    }
    final localizedTitle = localizeTitle(
      task.title,
      localeCode: localeCode,
      category: task.category,
      taskId: task.id,
    );
    if (localizedTitle == task.title) return task;
    return Task(
      id: task.id,
      title: localizedTitle,
      category: task.category,
      isCustom: task.isCustom,
      difficulty: task.difficulty,
      durationMinutes: task.durationMinutes,
      durationSeconds: task.durationSeconds,
      aiSuggested: task.aiSuggested,
      premiumOnly: task.premiumOnly,
      isSpecial: task.isSpecial,
    );
  }

  static String? _resolveCanonicalTitle(
    String title, {
    String? category,
    String? taskId,
  }) {
    if (taskId != null && taskId.startsWith('starter_')) {
      switch ((category ?? 'mind').toLowerCase()) {
        case 'body':
          return 'Move your shoulders for 60 seconds';
        case 'growth':
          return 'Write one tiny next step in 60 seconds';
        case 'calm':
          return 'Breathe slowly for 60 seconds';
        case 'health':
          return 'Drink water mindfully for 60 seconds';
        case 'mind':
        default:
          return 'Notice your breath for 60 seconds';
      }
    }
    return _aliasToCanonical[_normalize(title)];
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

