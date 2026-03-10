import '../app_strings.dart';
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
    'Close your eyes and relax your jaw': {
      'tr': 'Gözlerini kapat ve çeneni gevşet',
      'es': 'Cierra los ojos y relaja la mandíbula',
      'de': 'Schließe die Augen und entspanne deinen Kiefer',
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
    'Write your top focus target': {
      'tr': 'En önemli odak hedefini yaz',
      'es': 'Escribe tu objetivo principal de enfoque',
      'de': 'Schreibe dein wichtigstes Fokusziel auf',
    },
    'Run a 5-minute deep focus sprint': {
      'tr': '5 dakikalık derin odak sprinti yap',
      'es': 'Haz un sprint de enfoque profundo de 5 minutos',
      'de': 'Mache einen 5-minütigen Tiefenfokus-Sprint',
    },
    'No screens for the next 10 minutes': {
      'tr': 'Önümüzdeki 10 dakika ekran yok',
      'es': 'Sin pantallas durante los próximos 10 minutos',
      'de': 'Für die nächsten 10 Minuten keine Bildschirme',
    },
    'Do 4-7-8 breathing for 3 minutes': {
      'tr': '3 dakika 4-7-8 nefesi yap',
      'es': 'Haz respiración 4-7-8 durante 3 minutos',
      'de': 'Mache 3 Minuten lang 4-7-8-Atmung',
    },
    'Prepare tomorrow with 2 bullet points': {
      'tr': 'Yarını 2 maddeyle hazırla',
      'es': 'Prepara mañana con 2 puntos',
      'de': 'Bereite morgen mit 2 Stichpunkten vor',
    },
    'Box breathe for 2 minutes': {
      'tr': '2 dakika kutu nefesi yap',
      'es': 'Haz respiración en caja durante 2 minutos',
      'de': 'Mache 2 Minuten Box-Atmung',
    },
    'Release shoulder tension for 90 seconds': {
      'tr': '90 saniye omuz gerginliğini bırak',
      'es': 'Libera la tensión de los hombros durante 90 segundos',
      'de': 'Löse 90 Sekunden lang Schulterspannung',
    },
    'Write one thing you can control': {
      'tr': 'Kontrol edebileceğin bir şeyi yaz',
      'es': 'Escribe una cosa que puedas controlar',
      'de': 'Schreibe eine Sache auf, die du kontrollieren kannst',
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
    'Write one tiny intention for today': {
      'tr': 'Bugün için küçük bir niyet yaz',
      'es': 'Escribe una pequeña intención para hoy',
      'de': 'Schreibe eine kleine Absicht für heute auf',
    },
    'Take 5 slow breaths and reset': {
      'tr': '5 yavaş nefes al ve resetlen',
      'es': 'Haz 5 respiraciones lentas y reiníciate',
      'de': 'Nimm 5 langsame Atemzüge und setze neu an',
    },
    'Write one priority and start for 2 minutes': {
      'tr': 'Bir öncelik yaz ve 2 dakika başla',
      'es': 'Escribe una prioridad y empieza durante 2 minutos',
      'de': 'Schreibe eine Priorität auf und starte für 2 Minuten',
    },
    'Write one line about your day': {
      'tr': 'Günün hakkında tek bir satır yaz',
      'es': 'Escribe una línea sobre tu día',
      'de': 'Schreibe eine Zeile über deinen Tag',
    },
    'Pause for 1 minute and breathe': {
      'tr': '1 dakika dur ve nefes al',
      'es': 'Pausa durante 1 minuto y respira',
      'de': 'Halte 1 Minute inne und atme',
    },
    'Stand up and move for 2 minutes': {
      'tr': 'Ayağa kalk ve 2 dakika hareket et',
      'es': 'Ponte de pie y muévete durante 2 minutos',
      'de': 'Steh auf und bewege dich 2 Minuten lang',
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
      'de':
          'Mache einen 4-minütigen Start-Sprint bei deiner wichtigsten Aufgabe',
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
    },
  };

  static const List<String> _appStringTaskTitles = [
    'Write your top focus target',
    'Run a 5-minute deep focus sprint',
    'No screens for the next 10 minutes',
    'Do 4-7-8 breathing for 3 minutes',
    'Prepare tomorrow with 2 bullet points',
    'Box breathe for 2 minutes',
    'Release shoulder tension for 90 seconds',
    'Write one thing you can control',
  ];

  static const Map<String, Map<String, String>> _fallbackTitleTranslations = {
    '2-minute reset: breathe slowly and relax your shoulders': {
      'tr':
          '2 dakikal\u0131k reset: yava\u015f nefes al ve omuzlar\u0131n\u0131 gev\u015fet',
      'es': 'Reinicio de 2 minutos: respira despacio y relaja tus hombros',
      'de': '2-Minuten-Reset: Atme langsam und entspanne deine Schultern',
    },
    'Write one tiny intention for today': {
      'tr': 'Bug\u00fcn i\u00e7in k\u00fc\u00e7\u00fck bir niyet yaz',
      'es': 'Escribe una peque\u00f1a intenci\u00f3n para hoy',
      'de': 'Schreibe eine kleine Absicht f\u00fcr heute auf',
    },
    'Take 5 slow breaths and reset': {
      'tr': '5 yava\u015f nefes al ve resetlen',
      'es': 'Haz 5 respiraciones lentas y rein\u00edciate',
      'de': 'Nimm 5 langsame Atemz\u00fcge und setze neu an',
    },
    'Write one priority and start for 2 minutes': {
      'tr': 'Bir \u00f6ncelik yaz ve 2 dakika ba\u015fla',
      'es': 'Escribe una prioridad y empieza durante 2 minutos',
      'de': 'Schreibe eine Priorit\u00e4t auf und starte f\u00fcr 2 Minuten',
    },
    'Write one line about your day': {
      'tr': 'G\u00fcn\u00fcn hakk\u0131nda tek bir sat\u0131r yaz',
      'es': 'Escribe una l\u00ednea sobre tu d\u00eda',
      'de': 'Schreibe eine Zeile \u00fcber deinen Tag',
    },
    'Pause for 1 minute and breathe': {
      'tr': '1 dakika dur ve nefes al',
      'es': 'Pausa durante 1 minuto y respira',
      'de': 'Halte 1 Minute inne und atme',
    },
    'Stand up and move for 2 minutes': {
      'tr': 'Aya\u011fa kalk ve 2 dakika hareket et',
      'es': 'Ponte de pie y mu\u00e9vete durante 2 minutos',
      'de': 'Steh auf und bewege dich 2 Minuten lang',
    },
    'Read a short inspirational quote': {
      'tr': 'K\u0131sa bir ilham verici s\u00f6z oku',
      'es': 'Lee una cita inspiradora corta',
      'de': 'Lies ein kurzes inspirierendes Zitat',
    },
    'Special Spark: try something new today': {
      'tr': '\u00d6zel Spark: bug\u00fcn yeni bir \u015fey dene',
      'es': 'Spark especial: prueba algo nuevo hoy',
      'de': 'Spezial-Spark: Probiere heute etwas Neues aus',
    },
    'AI pick: organize one tiny space': {
      'tr': 'AI \u00f6nerisi: k\u00fc\u00e7\u00fck bir alan\u0131 d\u00fczenle',
    },
    'AI pick: short posture reset': {
      'tr': 'AI \u00f6nerisi: h\u0131zl\u0131 duru\u015f reseti',
    },
    'Blink slowly 10 times': {
      'tr': '10 kez yava\u015f\u00e7a g\u00f6z k\u0131rp',
    },
    'Breathe deeply for 2 minutes': {'tr': '2 dakika derin nefes al'},
    'Breathe in for 4, out for 6': {
      'tr': '4 say\u0131da al, 6 say\u0131da ver',
    },
    'Clean one small surface': {
      'tr': 'K\u00fc\u00e7\u00fck bir y\u00fczeyi temizle',
    },
    'Declutter one digital file or photo': {
      'tr': 'Bir dijital dosya veya foto\u011fraf\u0131 d\u00fczenle',
    },
    'Do 10 squats': {'tr': '10 squat yap'},
    'Do 10 wall push-ups': {
      'tr': 'Duvara kar\u015f\u0131 10 \u015f\u0131nav yap',
    },
    'Do 15 jumping jacks': {'tr': '15 jumping jack yap'},
    'Do 5 push-ups (or try)': {'tr': '5 \u015f\u0131nav yap (veya dene)'},
    'Do a quick posture check': {
      'tr': 'Duru\u015funu h\u0131zl\u0131ca kontrol et',
    },
    'Drink a full glass of water slowly': {
      'tr': 'Bir tam bardak suyu yava\u015f\u00e7a i\u00e7',
    },
    'Drink a warm or cold beverage mindfully': {
      'tr':
          'S\u0131cak veya so\u011fuk bir i\u00e7ece\u011fi fark\u0131ndal\u0131kla i\u00e7',
    },
    'Drink water after sitting for long': {
      'tr': 'Uzun s\u00fcre oturduktan sonra su i\u00e7',
    },
    'Drink water before coffee or tea': {
      'tr': 'Kahve veya \u00e7aydan \u00f6nce su i\u00e7',
    },
    'Drink water slowly and mindfully': {
      'tr': 'Suyu yava\u015f ve fark\u0131ndal\u0131kla i\u00e7',
    },
    'Eat a piece of fruit': {'tr': 'Bir par\u00e7a meyve ye'},
    'Focus on your breathing for 60 seconds': {
      'tr': '60 saniye nefesine odaklan',
    },
    'Forgive yourself for one small thing': {
      'tr': 'K\u00fc\u00e7\u00fck bir \u015fey i\u00e7in kendini affet',
    },
    'Learn 3 new words': {'tr': '3 yeni kelime \u00f6\u011fren'},
    'Learn one keyboard shortcut': {
      'tr': 'Bir klavye k\u0131sayolu \u00f6\u011fren',
    },
    'Learn one new word meaning': {
      'tr': 'Yeni bir kelimenin anlam\u0131n\u0131 \u00f6\u011fren',
    },
    'Learn one small improvement idea': {
      'tr': 'K\u00fc\u00e7\u00fck bir geli\u015fim fikri \u00f6\u011fren',
    },
    'Learn one small thing (quick read)': {
      'tr':
          'K\u00fc\u00e7\u00fck bir \u015fey \u00f6\u011fren (h\u0131zl\u0131 okuma)',
    },
    'Learn one tiny habit idea': {
      'tr':
          'K\u00fc\u00e7\u00fck bir al\u0131\u015fkanl\u0131k fikri \u00f6\u011fren',
    },
    'Look away from the screen for 1 minute': {
      'tr': '1 dakika ekrandan uza\u011fa bak',
    },
    'Meditate for 2 minutes': {'tr': '2 dakika meditasyon yap'},
    'Notice 3 things you can hear right now': {
      'tr': '\u015eu an duyabildi\u011fin 3 \u015feyi fark et',
    },
    'Pause and take a deep breath': {'tr': 'Dur ve derin bir nefes al'},
    'Plan one thing for tomorrow': {
      'tr': 'Yar\u0131n i\u00e7in bir \u015fey planla',
    },
    'Premium body boost: 3 rounds of 12 squats': {
      'tr': 'Premium v\u00fccut deste\u011fi: 12 squat x 3 tur',
    },
    'Premium calm reset: 5-minute box breathing': {
      'tr': 'Premium sakinlik reseti: 5 dakikal\u0131k kutu nefesi',
    },
    'Premium focus sprint: 15 minutes deep work': {
      'tr': 'Premium odak sprinti: 15 dakika derin \u00e7al\u0131\u015fma',
    },
    'Put your phone away for 5 minutes': {
      'tr': 'Telefonunu 5 dakika uza\u011fa koy',
    },
    'Read 1 page of a book': {
      'tr': 'Bir kitab\u0131n 1 sayfas\u0131n\u0131 oku',
    },
    'Read one interesting fact': {'tr': '\u0130lgin\u00e7 bir bilgi oku'},
    'Read one paragraph you enjoy': {'tr': 'Sevdi\u011fin bir paragraf oku'},
    'Read one productivity tip': {'tr': 'Bir verimlilik ipucu oku'},
    'Relax your shoulders and drop tension': {
      'tr': 'Omuzlar\u0131n\u0131 gev\u015fet ve gerginli\u011fi b\u0131rak',
    },
    'Rest your eyes for 20 seconds': {
      'tr': 'G\u00f6zlerini 20 saniye dinlendir',
    },
    'Roll your shoulders 10 times': {
      'tr': 'Omuzlar\u0131n\u0131 10 kez \u00e7evir',
    },
    'Say no to one distraction today': {
      'tr':
          'Bug\u00fcn bir dikkat da\u011f\u0131t\u0131c\u0131ya hay\u0131r de',
    },
    'Send a quick thank-you message': {
      'tr': 'H\u0131zl\u0131 bir te\u015fekk\u00fcr mesaj\u0131 g\u00f6nder',
    },
    'Sit quietly and do nothing for 1 minute': {
      'tr': '1 dakika sessizce otur ve hi\u00e7bir \u015fey yapma',
    },
    'Smile for 10 seconds': {'tr': '10 saniye g\u00fcl\u00fcmse'},
    'Stand on one foot for 30 seconds': {
      'tr': '30 saniye tek ayak \u00fcst\u00fcnde dur',
    },
    'Stand up and straighten your posture': {
      'tr': 'Aya\u011fa kalk ve duru\u015funu d\u00fczelt',
    },
    'Stretch your arms overhead': {
      'tr':
          'Kollar\u0131n\u0131 ba\u015f\u0131n\u0131n \u00fcst\u00fcnde esnet',
    },
    'Stretch your neck gently': {'tr': 'Boynunu nazik\u00e7e esnet'},
    'Take 5 deep belly breaths': {'tr': '5 derin kar\u0131n nefesi al'},
    'Think of one thing you\u2019re thankful for': {
      'tr': 'Minnettar oldu\u011fun bir \u015feyi d\u00fc\u015f\u00fcn',
    },
    'Tidy up for 2 minutes': {'tr': '2 dakika toparlan'},
    'Unclench your teeth and relax your face': {
      'tr':
          'Di\u015flerini s\u0131kmay\u0131 b\u0131rak ve y\u00fcz\u00fcn\u00fc gev\u015fet',
    },
    'Walk around the room once': {
      'tr': 'Odan\u0131n i\u00e7inde bir tur y\u00fcr\u00fc',
    },
    'Walk for 5 minutes': {'tr': '5 dakika y\u00fcr\u00fc'},
    'Write one positive thought': {
      'tr': 'Olumlu bir d\u00fc\u015f\u00fcnce yaz',
    },
    'Write one sentence about your mood': {
      'tr': 'Ruh halin hakk\u0131nda bir c\u00fcmle yaz',
    },
    'Write one small goal for today': {
      'tr': 'Bug\u00fcn i\u00e7in k\u00fc\u00e7\u00fck bir hedef yaz',
    },
    'Write one thing you did well today': {
      'tr': 'Bug\u00fcn iyi yapt\u0131\u011f\u0131n bir \u015feyi yaz',
    },
    'Write one thing you want less of': {
      'tr': 'Hayat\u0131nda daha az istedi\u011fin bir \u015feyi yaz',
    },
    'Write one thing you\u2019re grateful for': {
      'tr': 'Minnettar oldu\u011fun bir \u015feyi yaz',
    },
  };

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
    final canonical = _resolveCanonicalTitle(
      title,
      category: category,
      taskId: taskId,
    );
    if (canonical != null) {
      if (targetCode == 'en') return canonical;

      final appStringValue = AppLocalizations.lookup(targetCode, canonical);
      if (appStringValue != canonical) return appStringValue;

      final staticValue = _fallbackTitleTranslations[canonical]?[targetCode];
      if (staticValue != null) return staticValue;

      return _titleMap[canonical]?[targetCode] ?? canonical;
    }

    if (targetCode != 'en') {
      final appStringValue = AppLocalizations.lookup(targetCode, title);
      if (appStringValue != title) return appStringValue;
    }

    final generated = _localizeGeneratedTitle(title, targetCode: targetCode);
    return generated ?? title;
  }

  static List<Task> localizeTasks(List<Task> tasks, {String? localeCode}) {
    return tasks
        .map((task) => localizeTask(task, localeCode: localeCode))
        .toList();
  }

  static Task localizeTask(Task task, {String? localeCode}) {
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
    final normalized = _normalize(title);
    final canonical = _aliasToCanonical[normalized];
    if (canonical != null) return canonical;
    final appStringCanonical = _resolveAppStringCanonicalTitle(normalized);
    if (appStringCanonical != null) return appStringCanonical;
    final staticCanonical = _resolveStaticCanonicalTitle(normalized);
    if (staticCanonical != null) return staticCanonical;
    final legacyCanonical = _resolveLegacyCanonicalTitle(normalized);
    if (legacyCanonical != null) return legacyCanonical;
    if (normalized.contains('close your eyes') &&
        normalized.contains('relax your jaw')) {
      return 'Close your eyes and relax your jaw';
    }
    if (normalized.contains('relax your jaw') &&
        normalized.contains('shoulder')) {
      return 'Relax your jaw and shoulders';
    }
    return null;
  }

  static String? _resolveAppStringCanonicalTitle(String normalizedTitle) {
    for (final title in _appStringTaskTitles) {
      for (final code in const ['tr', 'es', 'de']) {
        if (_normalize(AppLocalizations.lookup(code, title)) ==
            normalizedTitle) {
          return title;
        }
      }
    }
    return null;
  }

  static String? _resolveStaticCanonicalTitle(String normalizedTitle) {
    for (final entry in _fallbackTitleTranslations.entries) {
      if (_normalize(entry.key) == normalizedTitle) return entry.key;
      for (final translated in entry.value.values) {
        if (_normalize(translated) == normalizedTitle) return entry.key;
      }
    }
    return null;
  }

  static String? _resolveLegacyCanonicalTitle(String normalizedTitle) {
    final normalizedNoDiacritics = _removeBasicDiacritics(normalizedTitle);

    if ((normalizedTitle.contains('healthy snack') ||
            normalizedNoDiacritics.contains('saglikli bir atistirmalik') ||
            normalizedNoDiacritics.contains('saglikli bir alistirmalik')) &&
        (normalizedTitle.contains('eat') ||
            normalizedNoDiacritics.contains('ye'))) {
      return 'Eat one healthy snack';
    }

    final hasInspirational =
        normalizedTitle.contains('inspirational') ||
        normalizedTitle.contains('inspiring') ||
        normalizedTitle.contains('motivation') ||
        normalizedNoDiacritics.contains('ilham verici');
    final hasQuote =
        normalizedTitle.contains('quote') ||
        normalizedNoDiacritics.contains('soz');
    if (hasInspirational && hasQuote) {
      return 'Read a short inspirational quote';
    }

    if (normalizedTitle.startsWith('special spark:') &&
        normalizedNoDiacritics.contains('try something new today')) {
      return 'Special Spark: try something new today';
    }

    return null;
  }

  static String? _localizeGeneratedTitle(
    String title, {
    required String targetCode,
  }) {
    final generated = _matchGeneratedTitle(title);
    if (generated == null) return null;
    return _buildGeneratedTitle(
      generated.kind,
      generated.durationSeconds,
      targetCode: targetCode,
    );
  }

  static _GeneratedTitleMatch? _matchGeneratedTitle(String title) {
    final normalized = _normalize(title);
    final durationSeconds = _extractDurationSeconds(title);
    if (durationSeconds == null) return null;

    final hasBodyPrompt =
        normalized.contains('move your body') ||
        normalized.startsWith('move your body for ') ||
        (normalized.startsWith('v\u00fccudunu ') &&
            normalized.endsWith(' hareket ettir')) ||
        normalized.startsWith('mueve tu cuerpo durante ') ||
        normalized.startsWith('bewege deinen k\u00f6rper f\u00fcr ');
    if (hasBodyPrompt) {
      return _GeneratedTitleMatch('body', durationSeconds);
    }

    final hasGrowthPrompt =
        normalized.contains('start one small improvement') ||
        normalized.startsWith('start one small improvement for ') ||
        normalized.endsWith(
          ' boyunca k\u00fc\u00e7\u00fck bir geli\u015fim ba\u015flat',
        ) ||
        normalized.startsWith('empieza una peque\u00f1a mejora durante ') ||
        normalized.startsWith('beginne f\u00fcr ');
    if (hasGrowthPrompt) {
      return _GeneratedTitleMatch('growth', durationSeconds);
    }

    final hasCalmPrompt =
        (normalized.contains('breathe slowly') &&
            normalized.contains('relax your shoulders')) ||
        (normalized.startsWith('breathe slowly for ') &&
            normalized.endsWith(' and relax your shoulders')) ||
        normalized.endsWith(
          ' yava\u015f nefes al ve omuzlar\u0131n\u0131 gev\u015fet',
        ) ||
        (normalized.startsWith('respira despacio durante ') &&
            normalized.endsWith(' y relaja tus hombros')) ||
        (normalized.startsWith('atme f\u00fcr ') &&
            normalized.endsWith(' langsam und entspanne deine schultern'));
    if (hasCalmPrompt) {
      return _GeneratedTitleMatch('calm', durationSeconds);
    }

    final hasHealthPrompt =
        (normalized.contains('drink water') &&
            normalized.contains('reset posture')) ||
        normalized.startsWith('drink water and reset posture for ') ||
        normalized.endsWith(' su i\u00e7 ve duru\u015funu d\u00fczelt') ||
        normalized.startsWith('bebe agua y corrige tu postura durante ') ||
        normalized.startsWith(
          'trink wasser und korrigiere deine haltung f\u00fcr ',
        );
    if (hasHealthPrompt) {
      return _GeneratedTitleMatch('health', durationSeconds);
    }

    final hasMindPrompt =
        (normalized.contains('write one clear priority') &&
            normalized.contains('focus')) ||
        normalized.startsWith('write one clear priority and focus for ') ||
        normalized.endsWith(' tek bir net \u00f6ncelik yaz ve odaklan') ||
        normalized.startsWith(
          'escribe una prioridad clara y conc\u00e9ntrate durante ',
        ) ||
        normalized.startsWith(
          'schreibe eine klare priorit\u00e4t und fokussiere dich f\u00fcr ',
        );
    if (hasMindPrompt) {
      return _GeneratedTitleMatch('mind', durationSeconds);
    }

    return null;
  }

  static String _buildGeneratedTitle(
    String kind,
    int durationSeconds, {
    required String targetCode,
  }) {
    final duration = _localizedGeneratedDuration(
      durationSeconds,
      code: targetCode,
    );

    switch (targetCode) {
      case 'tr':
        switch (kind) {
          case 'body':
            return 'V\u00fccudunu $duration hareket ettir';
          case 'growth':
            return '$duration boyunca k\u00fc\u00e7\u00fck bir geli\u015fim ba\u015flat';
          case 'calm':
            return '$duration yava\u015f nefes al ve omuzlar\u0131n\u0131 gev\u015fet';
          case 'health':
            return '$duration su i\u00e7 ve duru\u015funu d\u00fczelt';
          case 'mind':
          default:
            return '$duration tek bir net \u00f6ncelik yaz ve odaklan';
        }
      case 'es':
        switch (kind) {
          case 'body':
            return 'Mueve tu cuerpo durante $duration';
          case 'growth':
            return 'Empieza una peque\u00f1a mejora durante $duration';
          case 'calm':
            return 'Respira despacio durante $duration y relaja tus hombros';
          case 'health':
            return 'Bebe agua y corrige tu postura durante $duration';
          case 'mind':
          default:
            return 'Escribe una prioridad clara y conc\u00e9ntrate durante $duration';
        }
      case 'de':
        switch (kind) {
          case 'body':
            return 'Bewege deinen K\u00f6rper f\u00fcr $duration';
          case 'growth':
            return 'Beginne f\u00fcr $duration eine kleine Verbesserung';
          case 'calm':
            return 'Atme f\u00fcr $duration langsam und entspanne deine Schultern';
          case 'health':
            return 'Trink Wasser und korrigiere deine Haltung f\u00fcr $duration';
          case 'mind':
          default:
            return 'Schreibe eine klare Priorit\u00e4t und fokussiere dich f\u00fcr $duration';
        }
      case 'en':
      default:
        switch (kind) {
          case 'body':
            return 'Move your body for $duration';
          case 'growth':
            return 'Start one small improvement for $duration';
          case 'calm':
            return 'Breathe slowly for $duration and relax your shoulders';
          case 'health':
            return 'Drink water and reset posture for $duration';
          case 'mind':
          default:
            return 'Write one clear priority and focus for $duration';
        }
    }
  }

  static String _localizedGeneratedDuration(
    int durationSeconds, {
    required String code,
  }) {
    final safe = durationSeconds.clamp(1, 360000);
    if (safe < 60) {
      switch (code) {
        case 'tr':
          return '$safe saniye';
        case 'es':
          return '$safe segundos';
        case 'de':
          return '$safe Sekunden';
        case 'en':
        default:
          return '$safe seconds';
      }
    }

    if (safe % 60 == 0) {
      final minutes = safe ~/ 60;
      switch (code) {
        case 'tr':
          return '$minutes dakika';
        case 'es':
          return '$minutes minutos';
        case 'de':
          return '$minutes Minuten';
        case 'en':
        default:
          return minutes == 1 ? '1 minute' : '$minutes minutes';
      }
    }

    final minutes = safe ~/ 60;
    final seconds = safe % 60;
    switch (code) {
      case 'tr':
        return '$minutes dk $seconds saniye';
      case 'es':
        return '$minutes min $seconds segundos';
      case 'de':
        return '$minutes Min $seconds Sekunden';
      case 'en':
      default:
        return '$minutes min $seconds sec';
    }
  }

  static int? _extractDurationSeconds(String value) {
    final matches = RegExp(
      '(\\d+)(?:\\s*-\\s*|\\s+)(seconds?|secs?|sec|minutes?|mins?|min|saniye|dakika(?:l\u0131k)?|segundos?|minutos?|sekunden|minute?n?)',
      caseSensitive: false,
    ).allMatches(value);

    if (matches.isEmpty) return null;

    var total = 0;
    for (final match in matches) {
      final rawValue = int.tryParse(match.group(1) ?? '');
      final unit = (match.group(2) ?? '').toLowerCase();
      if (rawValue == null || rawValue <= 0) continue;
      if (unit.startsWith('min') || unit.startsWith('dakika')) {
        total += rawValue * 60;
      } else {
        total += rawValue;
      }
    }
    return total <= 0 ? null : total.clamp(1, 360000);
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('\u2019', "'")
        .replaceAll('\u2018', "'")
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _removeBasicDiacritics(String value) {
    return value
        .replaceAll('\u0131', 'i')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u011f', 'g')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u015f', 's')
        .replaceAll('\u00fc', 'u');
  }
}

class _GeneratedTitleMatch {
  const _GeneratedTitleMatch(this.kind, this.durationSeconds);

  final String kind;
  final int durationSeconds;
}
