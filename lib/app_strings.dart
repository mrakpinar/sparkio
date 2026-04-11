import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('tr'),
    Locale('es'),
    Locale('de'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context.');
    return value!;
  }

  String get _code {
    final code = locale.languageCode.toLowerCase();
    return supportedLocales.any((item) => item.languageCode == code)
        ? code
        : 'en';
  }

  String get friend {
    switch (_code) {
      case 'tr':
        return 'Arkadaş';
      case 'es':
        return 'Amigo';
      case 'de':
        return 'Freund';
      default:
        return 'Friend';
    }
  }

  String greetingForHour(int hour) {
    switch (_code) {
      case 'tr':
        if (hour < 12) return 'Günaydın';
        if (hour < 18) return 'Tünaydın';
        return 'İyi akşamlar';
      case 'es':
        if (hour < 12) return 'Buenos días';
        if (hour < 18) return 'Buenas tardes';
        return 'Buenas noches';
      case 'de':
        if (hour < 12) return 'Guten Morgen';
        if (hour < 18) return 'Guten Tag';
        return 'Guten Abend';
      default:
        if (hour < 12) return 'Good morning';
        if (hour < 18) return 'Good afternoon';
        return 'Good evening';
    }
  }

  String get stats {
    switch (_code) {
      case 'tr':
        return 'İstatistikler';
      case 'es':
        return 'Estadísticas';
      case 'de':
        return 'Statistiken';
      default:
        return 'Stats';
    }
  }

  String get menu {
    switch (_code) {
      case 'tr':
        return 'Menü';
      case 'es':
        return 'Menú';
      case 'de':
        return 'Menü';
      default:
        return 'Menu';
    }
  }

  String get yourSpace {
    switch (_code) {
      case 'tr':
        return 'Senin alanın';
      case 'es':
        return 'Tu espacio';
      case 'de':
        return 'Dein Bereich';
      default:
        return 'Your space';
    }
  }

  String get thingsYouCanDo {
    switch (_code) {
      case 'tr':
        return 'Yapabileceklerin';
      case 'es':
        return 'Lo que puedes hacer';
      case 'de':
        return 'Was du tun kannst';
      default:
        return 'Things you can do';
    }
  }

  String get yourJourney {
    switch (_code) {
      case 'tr':
        return 'Yolculuğun';
      case 'es':
        return 'Tu camino';
      case 'de':
        return 'Deine Reise';
      default:
        return 'Your journey';
    }
  }

  String get needHelp {
    switch (_code) {
      case 'tr':
        return 'Yardım mı lazım?';
      case 'es':
        return '¿Necesitas ayuda?';
      case 'de':
        return 'Brauchst du Hilfe?';
      default:
        return 'Need help?';
    }
  }

  String get appLanguage {
    switch (_code) {
      case 'tr':
        return 'Uygulama dili';
      case 'es':
        return 'Idioma de la app';
      case 'de':
        return 'App-Sprache';
      default:
        return 'App language';
    }
  }

  String get chooseLanguage {
    switch (_code) {
      case 'tr':
        return 'Dil seç';
      case 'es':
        return 'Elige un idioma';
      case 'de':
        return 'Sprache wählen';
      default:
        return 'Choose language';
    }
  }

  String get chooseLanguageSubtitle {
    switch (_code) {
      case 'tr':
        return 'Sparkio anında bu dile geçecek.';
      case 'es':
        return 'Sparkio cambiará al instante.';
      case 'de':
        return 'Sparkio wechselt sofort zu dieser Sprache.';
      default:
        return 'Sparkio will switch to this language right away.';
    }
  }

  String get followSystem {
    switch (_code) {
      case 'tr':
        return 'Sistemi takip et';
      case 'es':
        return 'Seguir el sistema';
      case 'de':
        return 'Systemsprache';
      default:
        return 'Follow system';
    }
  }

  String languageDisplayName(String code) {
    switch (_code) {
      case 'tr':
        switch (code) {
          case 'tr':
            return 'Türkçe';
          case 'es':
            return 'İspanyolca';
          case 'de':
            return 'Almanca';
          default:
            return 'İngilizce';
        }
      case 'es':
        switch (code) {
          case 'tr':
            return 'Turco';
          case 'es':
            return 'Español';
          case 'de':
            return 'Alemán';
          default:
            return 'Inglés';
        }
      case 'de':
        switch (code) {
          case 'tr':
            return 'Türkisch';
          case 'es':
            return 'Spanisch';
          case 'de':
            return 'Deutsch';
          default:
            return 'Englisch';
        }
      default:
        switch (code) {
          case 'tr':
            return 'Turkish';
          case 'es':
            return 'Spanish';
          case 'de':
            return 'German';
          default:
            return 'English';
        }
    }
  }

  String get createMySpark {
    switch (_code) {
      case 'tr':
        return 'Spark oluştur';
      case 'es':
        return 'Crear mi spark';
      case 'de':
        return 'Meinen Spark erstellen';
      default:
        return 'Create my spark';
    }
  }

  String get addACustomHabit {
    switch (_code) {
      case 'tr':
        return 'Özel bir alışkanlık ekle';
      case 'es':
        return 'Añade un hábito personalizado';
      case 'de':
        return 'Füge eine eigene Gewohnheit hinzu';
      default:
        return 'Add a custom habit';
    }
  }

  String get refreshTasks {
    switch (_code) {
      case 'tr':
        return 'Görevleri yenile';
      case 'es':
        return 'Actualizar tareas';
      case 'de':
        return 'Aufgaben erneuern';
      default:
        return 'Refresh tasks';
    }
  }

  String get loadANewTaskSet {
    switch (_code) {
      case 'tr':
        return 'Yeni bir görev seti yükle';
      case 'es':
        return 'Cargar un nuevo grupo de tareas';
      case 'de':
        return 'Neues Aufgaben-Set laden';
      default:
        return 'Load a new task set';
    }
  }

  String get achievements {
    switch (_code) {
      case 'tr':
        return 'Başarılar';
      case 'es':
        return 'Logros';
      case 'de':
        return 'Erfolge';
      default:
        return 'Achievements';
    }
  }

  String unlockedCount(int earned, int total) {
    switch (_code) {
      case 'tr':
        return '$earned/$total açıldı';
      case 'es':
        return '$earned/$total desbloqueados';
      case 'de':
        return '$earned/$total freigeschaltet';
      default:
        return '$earned/$total unlocked';
    }
  }

  String get challenges {
    switch (_code) {
      case 'tr':
        return 'Meydan okumalar';
      case 'es':
        return 'Desafíos';
      case 'de':
        return 'Challenges';
      default:
        return 'Challenges';
    }
  }

  String get challengeSubtitle {
    switch (_code) {
      case 'tr':
        return 'Meydan okuma modunu başlat veya yönet';
      case 'es':
        return 'Inicia o gestiona el modo desafío';
      case 'de':
        return 'Challenge-Modus starten oder verwalten';
      default:
        return 'Start or manage challenge mode';
    }
  }

  String get premium {
    return 'Premium';
  }

  String get premiumSubtitle {
    switch (_code) {
      case 'tr':
        return 'Sınırsız spark için yükselt';
      case 'es':
        return 'Mejora para obtener sparks ilimitados';
      case 'de':
        return 'Upgrade für unbegrenzte Sparks';
      default:
        return 'Upgrade for unlimited sparks';
    }
  }

  String get weeklyPlan {
    switch (_code) {
      case 'tr':
        return 'Haftalık plan';
      case 'es':
        return 'Plan semanal';
      case 'de':
        return 'Wochenplan';
      default:
        return 'Weekly plan';
    }
  }

  String goalsCount(int done, int total) {
    switch (_code) {
      case 'tr':
        return '$done/$total hedef';
      case 'es':
        return '$done/$total metas';
      case 'de':
        return '$done/$total Ziele';
      default:
        return '$done/$total goals';
    }
  }

  String get setGoalsForThisWeek {
    switch (_code) {
      case 'tr':
        return 'Bu hafta için hedef belirle';
      case 'es':
        return 'Define objetivos para esta semana';
      case 'de':
        return 'Ziele für diese Woche festlegen';
      default:
        return 'Set goals for this week';
    }
  }

  String get noGoals {
    switch (_code) {
      case 'tr':
        return 'Hedef yok';
      case 'es':
        return 'Sin objetivos';
      case 'de':
        return 'Keine Ziele';
      default:
        return 'No goals';
    }
  }

  String get talkToUs {
    switch (_code) {
      case 'tr':
        return 'Bize yaz';
      case 'es':
        return 'Habla con nosotros';
      case 'de':
        return 'Schreib uns';
      default:
        return 'Talk to us';
    }
  }

  String get supportReplyTime {
    switch (_code) {
      case 'tr':
        return '<24 saat içinde döneriz';
      case 'es':
        return 'Respondemos en menos de 24 h';
      case 'de':
        return 'Antwort in unter 24 Std.';
      default:
        return 'We reply in <24h';
    }
  }

  String levelTitle(int level) {
    switch (_code) {
      case 'tr':
        if (level >= 20) return 'Akış Ustası';
        if (level >= 14) return 'Momentum Kurucu';
        if (level >= 9) return 'Tutarlılık Kurucu';
        if (level >= 5) return 'Alışkanlık Başlatıcı';
        return 'İlk Spark';
      case 'es':
        if (level >= 20) return 'Maestro del flujo';
        if (level >= 14) return 'Creador de impulso';
        if (level >= 9) return 'Constructor de constancia';
        if (level >= 5) return 'Iniciador de hábitos';
        return 'Primer spark';
      case 'de':
        if (level >= 20) return 'Flow-Meister';
        if (level >= 14) return 'Momentum-Macher';
        if (level >= 9) return 'Konstanz-Bauer';
        if (level >= 5) return 'Gewohnheitsstarter';
        return 'Erster Spark';
      default:
        if (level >= 20) return 'Flow Master';
        if (level >= 14) return 'Momentum Maker';
        if (level >= 9) return 'Consistency Builder';
        if (level >= 5) return 'Habit Starter';
        return 'First Spark';
    }
  }

  String get startYourStreakToday {
    switch (_code) {
      case 'tr':
        return 'Serini bugün başlat';
      case 'es':
        return 'Empieza tu racha hoy';
      case 'de':
        return 'Starte deine Serie heute';
      default:
        return 'Start your streak today';
    }
  }

  String dayStreak(int count) {
    switch (_code) {
      case 'tr':
        return count == 1 ? '1 gün seri' : '$count gün seri';
      case 'es':
        return count == 1 ? 'racha de 1 día' : 'racha de $count días';
      case 'de':
        return count == 1 ? '1 Tag Serie' : '$count Tage Serie';
      default:
        return count == 1 ? '1 day streak' : '$count day streak';
    }
  }

  String sparksLitCount(int count) {
    switch (_code) {
      case 'tr':
        return count == 1 ? '1 spark yakıldı' : '$count spark yakıldı';
      case 'es':
        return count == 1 ? '1 spark encendido' : '$count sparks encendidos';
      case 'de':
        return count == 1 ? '1 Spark entfacht' : '$count Sparks entfacht';
      default:
        return count == 1 ? '1 spark lit' : '$count sparks lit';
    }
  }

  String levelLabel(int level, String title) {
    switch (_code) {
      case 'tr':
        return 'Seviye $level - $title';
      case 'es':
        return 'Nivel $level - $title';
      case 'de':
        return 'Level $level - $title';
      default:
        return 'Level $level - $title';
    }
  }

  String unlocksAtLevel(int level) {
    switch (_code) {
      case 'tr':
        return 'Seviye $level açılır';
      case 'es':
        return 'Se desbloquea en nivel $level';
      case 'de':
        return 'Wird auf Level $level freigeschaltet';
      default:
        return 'Unlocks at Level $level';
    }
  }

  String get darkMode {
    switch (_code) {
      case 'tr':
        return 'Koyu mod';
      case 'es':
        return 'Modo oscuro';
      case 'de':
        return 'Dunkelmodus';
      default:
        return 'Dark Mode';
    }
  }

  String get tapOrSwipeToggle {
    switch (_code) {
      case 'tr':
        return 'Değiştirmek için dokun veya yatay kaydır';
      case 'es':
        return 'Toca o desliza horizontalmente para cambiar';
      case 'de':
        return 'Tippe oder wische horizontal zum Wechseln';
      default:
        return 'Tap or swipe horizontally to toggle';
    }
  }

  String get referralRewards {
    switch (_code) {
      case 'tr':
        return 'Davet ödülleri';
      case 'es':
        return 'Recompensas por referidos';
      case 'de':
        return 'Empfehlungsbelohnungen';
      default:
        return 'Referral rewards';
    }
  }

  String get referralBenefit {
    switch (_code) {
      case 'tr':
        return '+1 spark slotu + 1 gün premium';
      case 'es':
        return '+1 espacio de spark + 1 día premium';
      case 'de':
        return '+1 Spark-Slot + 1 Tag Premium';
      default:
        return '+1 spark slot + 1 day premium';
    }
  }

  String get openProfileToCopyCode {
    switch (_code) {
      case 'tr':
        return 'Kodu kopyalamak veya daveti almak için Profili aç.';
      case 'es':
        return 'Abre el perfil para copiar el código o reclamar la invitación.';
      case 'de':
        return 'Öffne das Profil, um den Code zu kopieren oder die Einladung anzunehmen.';
      default:
        return 'Open Profile to copy code or claim invite.';
    }
  }

  String get open {
    switch (_code) {
      case 'tr':
        return 'Aç';
      case 'es':
        return 'Abrir';
      case 'de':
        return 'Öffnen';
      default:
        return 'Open';
    }
  }

  String get quickSettingsCaption {
    switch (_code) {
      case 'tr':
        return 'Hızlı ayarlar ve ilerleme kontrolleri.';
      case 'es':
        return 'Ajustes rápidos y controles de progreso.';
      case 'de':
        return 'Schnelle Einstellungen und Fortschrittskontrollen.';
      default:
        return 'Quick settings and progress controls.';
    }
  }

  String get homeHeroTitle {
    switch (_code) {
      case 'tr':
        return 'Buradasın. Momentumunu kur.';
      case 'es':
        return 'Ya estás aquí. Construye impulso.';
      case 'de':
        return 'Du bist da. Baue Momentum auf.';
      default:
        return 'You arrived. Build momentum.';
    }
  }

  String todaySparks(int done, int total) {
    switch (_code) {
      case 'tr':
        return 'Bugün: $done/$total spark';
      case 'es':
        return 'Hoy: $done/$total sparks';
      case 'de':
        return 'Heute: $done/$total Sparks';
      default:
        return 'Today: $done/$total sparks';
    }
  }

  String dayCount(int count) {
    switch (_code) {
      case 'tr':
        return 'Gün $count';
      case 'es':
        return 'Día $count';
      case 'de':
        return 'Tag $count';
      default:
        return 'Day $count';
    }
  }

  String get oneTinyStepIsEnough {
    switch (_code) {
      case 'tr':
        return 'Tek bir küçük adım yeterli.';
      case 'es':
        return 'Un pequeño paso es suficiente.';
      case 'de':
        return 'Ein kleiner Schritt reicht.';
      default:
        return 'One tiny step is enough.';
    }
  }

  String get weekly {
    switch (_code) {
      case 'tr':
        return 'Haftalık';
      case 'es':
        return 'Semanal';
      case 'de':
        return 'Woche';
      default:
        return 'Weekly';
    }
  }

  String get yourNextTinyStep {
    switch (_code) {
      case 'tr':
        return 'Sıradaki küçük adımın';
      case 'es':
        return 'Tu siguiente pequeño paso';
      case 'de':
        return 'Dein nächster kleiner Schritt';
      default:
        return 'Your next tiny step';
    }
  }

  String get nice {
    switch (_code) {
      case 'tr':
        return 'Harika.';
      case 'es':
        return 'Bien.';
      case 'de':
        return 'Gut.';
      default:
        return 'Nice.';
    }
  }

  String get youDidIt {
    switch (_code) {
      case 'tr':
        return 'Bunu yaptın.';
      case 'es':
        return 'Lo hiciste.';
      case 'de':
        return 'Du hast es geschafft.';
      default:
        return 'You did it.';
    }
  }

  String get takeOneEasyBreath {
    switch (_code) {
      case 'tr':
        return 'Bir rahat nefes al';
      case 'es':
        return 'Toma una respiración suave';
      case 'de':
        return 'Nimm einen ruhigen Atemzug';
      default:
        return 'Take one easy breath';
    }
  }

  String secondsLabel(int seconds) {
    switch (_code) {
      case 'tr':
        return '$seconds saniye';
      case 'es':
        return '$seconds segundos';
      case 'de':
        return '$seconds Sekunden';
      default:
        return '$seconds seconds';
    }
  }

  String minutesLabel(int minutes) {
    switch (_code) {
      case 'tr':
        return '$minutes dakika';
      case 'es':
        return '$minutes minutos';
      case 'de':
        return '$minutes Minuten';
      default:
        return '$minutes minutes';
    }
  }

  String minuteShortLabel(int minutes) {
    switch (_code) {
      case 'tr':
        return '$minutes dk';
      case 'es':
        return '$minutes min';
      case 'de':
        return '$minutes Min';
      default:
        return '$minutes min';
    }
  }

  String approxNoPressure(String duration) {
    switch (_code) {
      case 'tr':
        return '~$duration - baskı yok';
      case 'es':
        return '~$duration - sin presión';
      case 'de':
        return '~$duration - ohne Druck';
      default:
        return '~$duration - no pressure';
    }
  }

  String timeLeft(String value) {
    switch (_code) {
      case 'tr':
        return '$value kaldı';
      case 'es':
        return '$value restantes';
      case 'de':
        return '$value übrig';
      default:
        return '$value left';
    }
  }

  String startSparkNumber(int number) {
    switch (_code) {
      case 'tr':
        return 'Spark #$number başlat';
      case 'es':
        return 'Iniciar spark #$number';
      case 'de':
        return 'Spark #$number starten';
      default:
        return 'Start spark #$number';
    }
  }

  String get beginNow {
    switch (_code) {
      case 'tr':
        return 'Şimdi başla';
      case 'es':
        return 'Empieza ahora';
      case 'de':
        return 'Jetzt beginnen';
      default:
        return 'Begin now';
    }
  }

  String get noPressureJustMomentum {
    switch (_code) {
      case 'tr':
        return 'Baskı yok.\nSadece momentum.';
      case 'es':
        return 'Sin presión.\nSolo impulso.';
      case 'de':
        return 'Kein Druck.\nNur Momentum.';
      default:
        return 'No pressure.\nJust momentum.';
    }
  }

  String get keepYourRhythm {
    switch (_code) {
      case 'tr':
        return 'Ritmini koru.';
      case 'es':
        return 'Mantén tu ritmo.';
      case 'de':
        return 'Halte deinen Rhythmus.';
      default:
        return 'Keep your rhythm.';
    }
  }

  String get paused {
    switch (_code) {
      case 'tr':
        return 'Duraklatıldı';
      case 'es':
        return 'En pausa';
      case 'de':
        return 'Pausiert';
      default:
        return 'Paused';
    }
  }

  String get niceYouShowedUp {
    switch (_code) {
      case 'tr':
        return 'Harika. Geldin.';
      case 'es':
        return 'Bien. Te presentaste.';
      case 'de':
        return 'Gut. Du warst da.';
      default:
        return 'Nice. You showed up.';
    }
  }

  String sparksToday(int done, int total) {
    switch (_code) {
      case 'tr':
        return '$done/$total spark bugün';
      case 'es':
        return '$done/$total sparks hoy';
      case 'de':
        return '$done/$total Sparks heute';
      default:
        return '$done/$total sparks today';
    }
  }

  String get oneSmallWinAdded {
    switch (_code) {
      case 'tr':
        return 'Bir küçük kazanım eklendi.';
      case 'es':
        return 'Se sumó una pequeña victoria.';
      case 'de':
        return 'Ein kleiner Erfolg wurde hinzugefügt.';
      default:
        return 'One small win added.';
    }
  }

  String weeklyConsistency(int done, int total) {
    switch (_code) {
      case 'tr':
        return 'Haftalık tutarlılık: $done/$total';
      case 'es':
        return 'Constancia semanal: $done/$total';
      case 'de':
        return 'Wöchentliche Konstanz: $done/$total';
      default:
        return 'Weekly consistency: $done/$total';
    }
  }

  String get iAmDoneForToday {
    switch (_code) {
      case 'tr':
        return 'Bugünlük bu kadar';
      case 'es':
        return 'He terminado por hoy';
      case 'de':
        return 'Für heute bin ich fertig';
      default:
        return "I'm done for today";
    }
  }

  String get youreInMotion {
    switch (_code) {
      case 'tr':
        return 'Harekettesin.';
      case 'es':
        return 'Ya estás en movimiento.';
      case 'de':
        return 'Du bist in Bewegung.';
      default:
        return "You're in motion.";
    }
  }

  String get todaysRhythm {
    switch (_code) {
      case 'tr':
        return 'Bugünün ritmi';
      case 'es':
        return 'Ritmo de hoy';
      case 'de':
        return 'Dein Rhythmus heute';
      default:
        return "Today's rhythm";
    }
  }

  String get done {
    switch (_code) {
      case 'tr':
        return 'Bitti';
      case 'es':
        return 'Hecho';
      case 'de':
        return 'Erledigt';
      default:
        return 'Done';
    }
  }

  String get now {
    switch (_code) {
      case 'tr':
        return 'Şimdi';
      case 'es':
        return 'Ahora';
      case 'de':
        return 'Jetzt';
      default:
        return 'Now';
    }
  }

  String get later {
    switch (_code) {
      case 'tr':
        return 'Sonra';
      case 'es':
        return 'Después';
      case 'de':
        return 'Später';
      default:
        return 'Later';
    }
  }

  String get justGettingStarted {
    switch (_code) {
      case 'tr':
        return 'Yeni başlıyorsun.';
      case 'es':
        return 'Estás empezando.';
      case 'de':
        return 'Du fängst gerade erst an.';
      default:
        return "You're just getting started.";
    }
  }

  String stepCount(int count) {
    switch (_code) {
      case 'tr':
        return count == 1 ? '1 adım' : '$count adım';
      case 'es':
        return count == 1 ? '1 paso' : '$count pasos';
      case 'de':
        return count == 1 ? '1 Schritt' : '$count Schritte';
      default:
        return count == 1 ? '1 step' : '$count steps';
    }
  }

  String get nothingWaitingRightNow {
    switch (_code) {
      case 'tr':
        return 'Şu an bekleyen bir şey yok';
      case 'es':
        return 'No hay nada esperando ahora';
      case 'de':
        return 'Gerade wartet nichts auf dich';
      default:
        return 'Nothing waiting right now';
    }
  }

  String get optionalNoPressure {
    switch (_code) {
      case 'tr':
        return 'Opsiyonel\nBaskı yok.';
      case 'es':
        return 'Opcional\nSin presión.';
      case 'de':
        return 'Optional\nKein Druck.';
      default:
        return 'Optional\nNo pressure.';
    }
  }

  String tr(String key) => _lookup(_code, key);

  String trf(String key, Map<String, Object> values) {
    var text = _lookup(_code, key);
    values.forEach((placeholder, value) {
      text = text.replaceAll('{$placeholder}', '$value');
    });
    return text;
  }

  static String lookup(String languageCode, String key) {
    return _lookup(languageCode, key);
  }

  static String _lookup(String languageCode, String key) {
    final normalized = languageCode.toLowerCase();
    final variants = _textMap[key];
    if (variants == null) return key;
    return variants[normalized] ?? variants['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _textMap = {
    'Milestones': {
      'tr': 'Kilometre taşları',
      'es': 'Hitos',
      'de': 'Meilensteine',
      'en': 'Milestones',
    },
    'Unable to load badges right now.': {
      'tr': 'Rozetler şu anda yüklenemiyor.',
      'es': 'No se pueden cargar los logros ahora mismo.',
      'de': 'Abzeichen können gerade nicht geladen werden.',
      'en': 'Unable to load badges right now.',
    },
    'Completed milestones': {
      'tr': 'Tamamlanan kilometre taşları',
      'es': 'Hitos completados',
      'de': 'Abgeschlossene Meilensteine',
      'en': 'Completed milestones',
    },
    'Complete tasks to unlock your first milestone.': {
      'tr': 'İlk kilometre taşını açmak için görevleri tamamla.',
      'es': 'Completa tareas para desbloquear tu primer hito.',
      'de': 'Erledige Aufgaben, um deinen ersten Meilenstein freizuschalten.',
      'en': 'Complete tasks to unlock your first milestone.',
    },
    'Next milestones': {
      'tr': 'Sıradaki kilometre taşları',
      'es': 'Próximos hitos',
      'de': 'Nächste Meilensteine',
      'en': 'Next milestones',
    },
    'All milestones unlocked!': {
      'tr': 'Tüm kilometre taşları açıldı!',
      'es': '¡Todos los hitos desbloqueados!',
      'de': 'Alle Meilensteine freigeschaltet!',
      'en': 'All milestones unlocked!',
    },
    '{earned} of {total} milestones': {
      'tr': '{earned}/{total} kilometre taşı',
      'es': '{earned} de {total} hitos',
      'de': '{earned} von {total} Meilensteinen',
      'en': '{earned} of {total} milestones',
    },
    'Complete 10 sparks': {
      'tr': '10 spark tamamla',
      'es': 'Completa 10 sparks',
      'de': '10 Sparks abschließen',
      'en': 'Complete 10 sparks',
    },
    'Build momentum with 10 completed sparks.': {
      'tr': '10 tamamlanan spark ile momentum oluştur.',
      'es': 'Construye impulso con 10 sparks completados.',
      'de': 'Baue Momentum mit 10 abgeschlossenen Sparks auf.',
      'en': 'Build momentum with 10 completed sparks.',
    },
    'Build 50 sparks': {
      'tr': '50 spark oluştur',
      'es': 'Construye 50 sparks',
      'de': '50 Sparks aufbauen',
      'en': 'Build 50 sparks',
    },
    'Keep showing up and reach 50 sparks.': {
      'tr': 'Gelmeye devam et ve 50 sparka ulaş.',
      'es': 'Sigue apareciendo y llega a 50 sparks.',
      'de': 'Bleib dran und erreiche 50 Sparks.',
      'en': 'Keep showing up and reach 50 sparks.',
    },
    'Complete 100 sparks': {
      'tr': '100 spark tamamla',
      'es': 'Completa 100 sparks',
      'de': '100 Sparks abschließen',
      'en': 'Complete 100 sparks',
    },
    'Turn consistency into a 100 spark streak of effort.': {
      'tr': 'Tutarlılığı 100 sparklık bir çabaya dönüştür.',
      'es': 'Convierte la constancia en una racha de 100 sparks.',
      'de': 'Verwandle Konstanz in eine 100-Spark-Serie.',
      'en': 'Turn consistency into a 100 spark streak of effort.',
    },
    'Keep rhythm for 3 days': {
      'tr': 'Ritmi 3 gün koru',
      'es': 'Mantén el ritmo 3 días',
      'de': 'Halte den Rhythmus 3 Tage',
      'en': 'Keep rhythm for 3 days',
    },
    'Show up three days in a row.': {
      'tr': 'Üç gün üst üste görün.',
      'es': 'Preséntate tres días seguidos.',
      'de': 'Sei drei Tage in Folge da.',
      'en': 'Show up three days in a row.',
    },
    'Hold a 7-day flow': {
      'tr': '7 günlük akışı koru',
      'es': 'Mantén un flujo de 7 días',
      'de': 'Halte einen 7-Tage-Flow',
      'en': 'Hold a 7-day flow',
    },
    'Keep your rhythm for seven days.': {
      'tr': 'Ritmini yedi gün koru.',
      'es': 'Mantén tu ritmo durante siete días.',
      'de': 'Halte deinen Rhythmus sieben Tage lang.',
      'en': 'Keep your rhythm for seven days.',
    },
    'Complete 10 Mind sparks': {
      'tr': '10 Zihin sparkı tamamla',
      'es': 'Completa 10 sparks de Mente',
      'de': '10 Geist-Sparks abschließen',
      'en': 'Complete 10 Mind sparks',
    },
    'Give your mind ten focused resets.': {
      'tr': 'Zihnine on odaklı reset ver.',
      'es': 'Dale a tu mente diez reinicios enfocados.',
      'de': 'Gib deinem Geist zehn fokussierte Resets.',
      'en': 'Give your mind ten focused resets.',
    },
    'Complete 10 Body sparks': {
      'tr': '10 Vücut sparkı tamamla',
      'es': 'Completa 10 sparks de Cuerpo',
      'de': '10 Körper-Sparks abschließen',
      'en': 'Complete 10 Body sparks',
    },
    'Move and recharge with ten body sparks.': {
      'tr': 'On vücut sparkı ile hareket et ve yenilen.',
      'es': 'Muévete y recárgate con diez sparks de cuerpo.',
      'de': 'Bewege dich und lade dich mit zehn Körper-Sparks auf.',
      'en': 'Move and recharge with ten body sparks.',
    },
    'Complete 10 Growth sparks': {
      'tr': '10 Gelişim sparkı tamamla',
      'es': 'Completa 10 sparks de Crecimiento',
      'de': '10 Wachstum-Sparks abschließen',
      'en': 'Complete 10 Growth sparks',
    },
    'Create progress with ten growth sparks.': {
      'tr': 'On gelişim sparkı ile ilerleme oluştur.',
      'es': 'Crea progreso con diez sparks de crecimiento.',
      'de': 'Erzeuge Fortschritt mit zehn Wachstum-Sparks.',
      'en': 'Create progress with ten growth sparks.',
    },
    'Complete 10 Calm sparks': {
      'tr': '10 Sakin sparkı tamamla',
      'es': 'Completa 10 sparks de Calma',
      'de': '10 Ruhe-Sparks abschließen',
      'en': 'Complete 10 Calm sparks',
    },
    'Protect calm moments with ten calm sparks.': {
      'tr': 'On sakin spark ile sakin anları koru.',
      'es': 'Protege momentos de calma con diez sparks calmados.',
      'de': 'Schütze ruhige Momente mit zehn Ruhe-Sparks.',
      'en': 'Protect calm moments with ten calm sparks.',
    },
    'Complete 10 Health sparks': {
      'tr': '10 Sağlık sparkı tamamla',
      'es': 'Completa 10 sparks de Salud',
      'de': '10 Gesundheits-Sparks abschließen',
      'en': 'Complete 10 Health sparks',
    },
    'Support your energy with ten health sparks.': {
      'tr': 'Enerjini on sağlık sparkı ile destekle.',
      'es': 'Apoya tu energía con diez sparks de salud.',
      'de': 'Unterstütze deine Energie mit zehn Gesundheits-Sparks.',
      'en': 'Support your energy with ten health sparks.',
    },
    'Your Stats': {
      'tr': 'İstatistiklerin',
      'es': 'Tus estadísticas',
      'de': 'Deine Statistiken',
      'en': 'Your Stats',
    },
    'Sparks lit': {
      'tr': 'Yakılan sparks',
      'es': 'Sparks encendidos',
      'de': 'Entfachte Sparks',
      'en': 'Sparks lit',
    },
    'Your rhythm': {
      'tr': 'Ritmin',
      'es': 'Tu ritmo',
      'de': 'Dein Rhythmus',
      'en': 'Your rhythm',
    },
    'day streak': {
      'tr': 'gün seri',
      'es': 'días de racha',
      'de': 'Tage Serie',
      'en': 'day streak',
    },
    'Favorite category': {
      'tr': 'Favori kategori',
      'es': 'Categoría favorita',
      'de': 'Lieblingskategorie',
      'en': 'Favorite category',
    },
    'This week': {
      'tr': 'Bu hafta',
      'es': 'Esta semana',
      'de': 'Diese Woche',
      'en': 'This week',
    },
    'sparks': {'tr': 'spark', 'es': 'sparks', 'de': 'Sparks', 'en': 'sparks'},
    'Weekly Activity': {
      'tr': 'Haftalık aktivite',
      'es': 'Actividad semanal',
      'de': 'Wöchentliche Aktivität',
      'en': 'Weekly Activity',
    },
    'Consistency': {
      'tr': 'Tutarlılık',
      'es': 'Constancia',
      'de': 'Konstanz',
      'en': 'Consistency',
    },
    'Personal Insights': {
      'tr': 'Kişisel içgörüler',
      'es': 'Insights personales',
      'de': 'Persönliche Einblicke',
      'en': 'Personal Insights',
    },
    'Category Focus': {
      'tr': 'Kategori odağı',
      'es': 'Enfoque por categoría',
      'de': 'Kategorie-Fokus',
      'en': 'Category Focus',
    },
    'Your patterns will appear here.': {
      'tr': 'Desenlerin burada görünecek.',
      'es': 'Tus patrones aparecerán aquí.',
      'de': 'Deine Muster werden hier erscheinen.',
      'en': 'Your patterns will appear here.',
    },
    'Recent Win': {
      'tr': 'Son kazanım',
      'es': 'Última victoria',
      'de': 'Letzter Erfolg',
      'en': 'Recent Win',
    },
    'Badges': {
      'tr': 'Rozetler',
      'es': 'Insignias',
      'de': 'Abzeichen',
      'en': 'Badges',
    },
    'Your first milestone is closer than you think.': {
      'tr': 'İlk kilometre taşın sandığından daha yakın.',
      'es': 'Tu primer hito está más cerca de lo que crees.',
      'de': 'Dein erster Meilenstein ist näher, als du denkst.',
      'en': 'Your first milestone is closer than you think.',
    },
    'Weekly progress': {
      'tr': 'Haftalık ilerleme',
      'es': 'Progreso semanal',
      'de': 'Wöchentlicher Fortschritt',
      'en': 'Weekly progress',
    },
    'Personal Insights locked': {
      'tr': 'Kişisel içgörüler kilitli',
      'es': 'Insights personales bloqueados',
      'de': 'Persönliche Einblicke gesperrt',
      'en': 'Personal Insights locked',
    },
    'Reach Level {level} to unlock this module.': {
      'tr': 'Bu modülü açmak için Seviye {level}\'e ulaş.',
      'es': 'Alcanza el nivel {level} para desbloquear este módulo.',
      'de': 'Erreiche Level {level}, um dieses Modul freizuschalten.',
      'en': 'Reach Level {level} to unlock this module.',
    },
    'First spark': {
      'tr': 'İlk spark',
      'es': 'Primer spark',
      'de': 'Erster Spark',
      'en': 'First spark',
    },
    '3-day rhythm': {
      'tr': '3 günlük ritim',
      'es': 'Ritmo de 3 días',
      'de': '3-Tage-Rhythmus',
      'en': '3-day rhythm',
    },
    '10 sparks': {
      'tr': '10 spark',
      'es': '10 sparks',
      'de': '10 Sparks',
      'en': '10 sparks',
    },
    'Momentum': {
      'tr': 'Momentum',
      'es': 'Impulso',
      'de': 'Momentum',
      'en': 'Momentum',
    },
    'Morning': {'tr': 'Sabah', 'es': 'Mañana', 'de': 'Morgen', 'en': 'Morning'},
    'Afternoon': {
      'tr': 'Öğleden sonra',
      'es': 'Tarde',
      'de': 'Nachmittag',
      'en': 'Afternoon',
    },
    'Evening': {'tr': 'Akşam', 'es': 'Noche', 'de': 'Abend', 'en': 'Evening'},
    'Night': {'tr': 'Gece', 'es': 'Noche', 'de': 'Nacht', 'en': 'Night'},
    'Mind': {'tr': 'Zihin', 'es': 'Mente', 'de': 'Geist', 'en': 'Mind'},
    'Body': {'tr': 'Vücut', 'es': 'Cuerpo', 'de': 'Körper', 'en': 'Body'},
    'Growth': {
      'tr': 'Gelişim',
      'es': 'Crecimiento',
      'de': 'Wachstum',
      'en': 'Growth',
    },
    'Calm': {'tr': 'Sakin', 'es': 'Calma', 'de': 'Ruhe', 'en': 'Calm'},
    'Health': {
      'tr': 'Sağlık',
      'es': 'Salud',
      'de': 'Gesundheit',
      'en': 'Health',
    },
    'Complete more sparks to unlock personal insights.': {
      'tr': 'Kişisel içgörüleri açmak için daha fazla spark tamamla.',
      'es': 'Completa más sparks para desbloquear insights personales.',
      'de': 'Schließe mehr Sparks ab, um persönliche Einblicke freizuschalten.',
      'en': 'Complete more sparks to unlock personal insights.',
    },
    'Best completion time': {
      'tr': 'En iyi tamamlama zamanı',
      'es': 'Mejor hora para completar',
      'de': 'Beste Abschlusszeit',
      'en': 'Best completion time',
    },
    'We need a few more completions to detect your peak hour.': {
      'tr': 'En verimli saatini bulmak için birkaç tamamlama daha gerekiyor.',
      'es':
          'Necesitamos algunas completaciones más para detectar tu hora pico.',
      'de':
          'Wir brauchen noch ein paar Abschlüsse, um deine Spitzenzeit zu erkennen.',
      'en': 'We need a few more completions to detect your peak hour.',
    },
    'Skip': {'tr': 'Geç', 'es': 'Saltar', 'de': 'Überspringen', 'en': 'Skip'},
    'Continue': {
      'tr': 'Devam et',
      'es': 'Continuar',
      'de': 'Weiter',
      'en': 'Continue',
    },
    'Get started': {
      'tr': 'Başla',
      'es': 'Comenzar',
      'de': 'Loslegen',
      'en': 'Get started',
    },
    'Daily Momentum': {
      'tr': 'Günlük momentum',
      'es': 'Impulso diario',
      'de': 'Tägliches Momentum',
      'en': 'Daily Momentum',
    },
    'Small actions. Real change.': {
      'tr': 'Küçük adımlar. Gerçek değişim.',
      'es': 'Pequeñas acciones. Cambio real.',
      'de': 'Kleine Schritte. Echter Wandel.',
      'en': 'Small actions. Real change.',
    },
    '3 quick tasks a day to build momentum.': {
      'tr': 'Momentum kurmak için günde 3 kısa görev.',
      'es': '3 tareas rápidas al día para crear impulso.',
      'de': '3 kurze Aufgaben pro Tag, um Momentum aufzubauen.',
      'en': '3 quick tasks a day to build momentum.',
    },
    '3 focused tasks': {
      'tr': '3 odaklı görev',
      'es': '3 tareas enfocadas',
      'de': '3 fokussierte Aufgaben',
      'en': '3 focused tasks',
    },
    'Streak + XP motivation': {
      'tr': 'Seri + XP motivasyonu',
      'es': 'Motivación con racha + XP',
      'de': 'Serien- und XP-Motivation',
      'en': 'Streak + XP motivation',
    },
    'Quick daily wins': {
      'tr': 'Hızlı günlük kazanımlar',
      'es': 'Pequeñas victorias diarias',
      'de': 'Schnelle tägliche Erfolge',
      'en': 'Quick daily wins',
    },
    'Focus Engine': {
      'tr': 'Odak motoru',
      'es': 'Motor de enfoque',
      'de': 'Fokusmotor',
      'en': 'Focus Engine',
    },
    'Build your daily rhythm': {
      'tr': 'Günlük ritmini kur',
      'es': 'Construye tu ritmo diario',
      'de': 'Baue deinen Tagesrhythmus auf',
      'en': 'Build your daily rhythm',
    },
    'A few minutes a day is enough to keep moving forward.': {
      'tr': 'İlerlemeyi sürdürmek için günde birkaç dakika yeter.',
      'es': 'Unos minutos al día bastan para seguir avanzando.',
      'de': 'Ein paar Minuten am Tag reichen, um weiterzukommen.',
      'en': 'A few minutes a day is enough to keep moving forward.',
    },
    'Stay focused for a few minutes': {
      'tr': 'Birkaç dakika odakta kal',
      'es': 'Mantén el foco unos minutos',
      'de': 'Bleib ein paar Minuten fokussiert',
      'en': 'Stay focused for a few minutes',
    },
    'See your progress grow daily': {
      'tr': 'İlerlemeni her gün büyürken gör',
      'es': 'Mira cómo tu progreso crece cada día',
      'de': 'Sieh, wie dein Fortschritt täglich wächst',
      'en': 'See your progress grow daily',
    },
    'Keep your routine on track': {
      'tr': 'Rutinini rayında tut',
      'es': 'Mantén tu rutina en camino',
      'de': 'Halte deine Routine im Takt',
      'en': 'Keep your routine on track',
    },
    'Progress Clarity': {
      'tr': 'İlerleme netliği',
      'es': 'Claridad del progreso',
      'de': 'Klarer Fortschritt',
      'en': 'Progress Clarity',
    },
    'Watch your momentum grow': {
      'tr': 'Momentumunun büyümesini izle',
      'es': 'Mira crecer tu impulso',
      'de': 'Sieh dein Momentum wachsen',
      'en': 'Watch your momentum grow',
    },
    'Small actions add up faster than you think.': {
      'tr': 'Küçük adımlar sandığından daha hızlı birikir.',
      'es': 'Las pequeñas acciones suman más rápido de lo que crees.',
      'de': 'Kleine Schritte summieren sich schneller, als du denkst.',
      'en': 'Small actions add up faster than you think.',
    },
    'Notice your consistency build': {
      'tr': 'Tutarlılığının oluştuğunu fark et',
      'es': 'Nota cómo se construye tu constancia',
      'de': 'Spüre, wie deine Konstanz entsteht',
      'en': 'Notice your consistency build',
    },
    'Feel the progress over time': {
      'tr': 'Zamanla ilerlemeyi hisset',
      'es': 'Siente el progreso con el tiempo',
      'de': 'Spüre den Fortschritt mit der Zeit',
      'en': 'Feel the progress over time',
    },
    'Turn effort into momentum': {
      'tr': 'Çabayı momentuma dönüştür',
      'es': 'Convierte el esfuerzo en impulso',
      'de': 'Verwandle Einsatz in Momentum',
      'en': 'Turn effort into momentum',
    },
    'Suggested for you': {
      'tr': 'Senin için önerildi',
      'es': 'Sugerido para ti',
      'de': 'Für dich empfohlen',
      'en': 'Suggested for you',
    },
    '1 quick action': {
      'tr': '1 hızlı aksiyon',
      'es': '1 acción rápida',
      'de': '1 schnelle Aktion',
      'en': '1 quick action',
    },
    'No setup needed': {
      'tr': 'Kurulum gerektirmez',
      'es': 'No requiere preparación',
      'de': 'Keine Vorbereitung nötig',
      'en': 'No setup needed',
    },
    'Store not available': {
      'tr': 'Mağaza kullanılamıyor',
      'es': 'Tienda no disponible',
      'de': 'Store nicht verfügbar',
      'en': 'Store not available',
    },
    'Please try again later.': {
      'tr': 'Lütfen daha sonra tekrar dene.',
      'es': 'Inténtalo de nuevo más tarde.',
      'de': 'Bitte versuche es später erneut.',
      'en': 'Please try again later.',
    },
    'No subscriptions found': {
      'tr': 'Abonelik bulunamadı',
      'es': 'No se encontraron suscripciones',
      'de': 'Keine Abonnements gefunden',
      'en': 'No subscriptions found',
    },
    'Create subscriptions in Play Console.': {
      'tr': 'Play Console içinde abonelik oluştur.',
      'es': 'Crea suscripciones en Play Console.',
      'de': 'Erstelle Abos in der Play Console.',
      'en': 'Create subscriptions in Play Console.',
    },
    'Go Premium': {
      'tr': 'Premium’a geç',
      'es': 'Hazte Premium',
      'de': 'Premium holen',
      'en': 'Go Premium',
    },
    'Monthly or yearly auto-renewing subscription.': {
      'tr': 'Aylık veya yıllık otomatik yenilenen abonelik.',
      'es': 'Suscripción mensual o anual con renovación automática.',
      'de': 'Monatliches oder jährliches Abo mit automatischer Verlängerung.',
      'en': 'Monthly or yearly auto-renewing subscription.',
    },
    'Unlimited tasks': {
      'tr': 'Sınırsız görev',
      'es': 'Tareas ilimitadas',
      'de': 'Unbegrenzte Aufgaben',
      'en': 'Unlimited tasks',
    },
    'No ads': {
      'tr': 'Reklamsız',
      'es': 'Sin anuncios',
      'de': 'Keine Werbung',
      'en': 'No ads',
    },
    'AI tasks': {
      'tr': 'Yapay zeka görevleri',
      'es': 'Tareas con IA',
      'de': 'KI-Aufgaben',
      'en': 'AI tasks',
    },
    'Restore purchases': {
      'tr': 'Satın alımları geri yükle',
      'es': 'Restaurar compras',
      'de': 'Käufe wiederherstellen',
      'en': 'Restore purchases',
    },
    'Cancel anytime in Google Play > Payments & subscriptions.': {
      'tr':
          'İstediğin zaman Google Play > Ödemeler ve abonelikler kısmından iptal et.',
      'es': 'Cancela cuando quieras en Google Play > Pagos y suscripciones.',
      'de': 'Jederzeit in Google Play > Zahlungen und Abos kündbar.',
      'en': 'Cancel anytime in Google Play > Payments & subscriptions.',
    },
    'By subscribing, you authorize recurring charges based on the plan you choose. Any trial or intro offer is shown before purchase confirmation.': {
      'tr':
          'Abone olarak seçtiğin plana göre yinelenen ücretleri onaylamış olursun. Varsa deneme veya tanıtım teklifi satın alma onayından önce gösterilir.',
      'es':
          'Al suscribirte, autorizas cobros recurrentes según el plan que elijas. Cualquier prueba u oferta se mostrará antes de confirmar la compra.',
      'de':
          'Mit dem Abo autorisierst du wiederkehrende Zahlungen gemäß dem gewählten Plan. Eine Probe- oder Einführungsaktion wird vor dem Kauf angezeigt.',
      'en':
          'By subscribing, you authorize recurring charges based on the plan you choose. Any trial or intro offer is shown before purchase confirmation.',
    },
    'Billed yearly, auto-renews every year.': {
      'tr': 'Yıllık faturalandırılır, her yıl otomatik yenilenir.',
      'es': 'Se cobra anualmente y se renueva cada año.',
      'de': 'Jährliche Abrechnung, verlängert sich jedes Jahr automatisch.',
      'en': 'Billed yearly, auto-renews every year.',
    },
    'Billed monthly, auto-renews every month.': {
      'tr': 'Aylık faturalandırılır, her ay otomatik yenilenir.',
      'es': 'Se cobra mensualmente y se renueva cada mes.',
      'de': 'Monatliche Abrechnung, verlängert sich jeden Monat automatisch.',
      'en': 'Billed monthly, auto-renews every month.',
    },
    'Recurring subscription, auto-renews until canceled.': {
      'tr': 'Yinelenen abonelik, iptal edilene kadar otomatik yenilenir.',
      'es': 'Suscripción recurrente, se renueva hasta que se cancele.',
      'de':
          'Wiederkehrendes Abo, verlängert sich bis zur Kündigung automatisch.',
      'en': 'Recurring subscription, auto-renews until canceled.',
    },
    'Best value': {
      'tr': 'En iyi değer',
      'es': 'Mejor valor',
      'de': 'Bestes Angebot',
      'en': 'Best value',
    },
    'Boost center': {
      'tr': 'Destek merkezi',
      'es': 'Centro de impulso',
      'de': 'Boost-Zentrale',
      'en': 'Boost center',
    },
    'If you want a little extra support today.': {
      'tr': 'Bugün biraz ekstra desteğe ihtiyacın varsa.',
      'es': 'Si hoy quieres un poco de apoyo extra.',
      'de': 'Falls du heute etwas extra Unterstützung brauchst.',
      'en': 'If you want a little extra support today.',
    },
    'Long-term support': {
      'tr': 'Uzun vadeli destek',
      'es': 'Apoyo a largo plazo',
      'de': 'Langfristige Unterstützung',
      'en': 'Long-term support',
    },
    'Today boosts': {
      'tr': 'Bugünkü destekler',
      'es': 'Impulsos de hoy',
      'de': 'Heutige Boosts',
      'en': 'Today boosts',
    },
    'Short unlocks for now': {
      'tr': 'Şimdilik kısa açılımlar',
      'es': 'Desbloqueos cortos por ahora',
      'de': 'Kurzzeitige Freischaltungen',
      'en': 'Short unlocks for now',
    },
    '30 min Premium': {
      'tr': '30 dk Premium',
      'es': '30 min Premium',
      'de': '30 Min Premium',
      'en': '30 min Premium',
    },
    'Temporary premium access.': {
      'tr': 'Geçici premium erişim.',
      'es': 'Acceso premium temporal.',
      'de': 'Vorübergehender Premium-Zugang.',
      'en': 'Temporary premium access.',
    },
    'Active now': {
      'tr': 'Şimdi aktif',
      'es': 'Activo ahora',
      'de': 'Jetzt aktiv',
      'en': 'Active now',
    },
    'Preparing ad...': {
      'tr': 'Reklam hazırlanıyor...',
      'es': 'Preparando anuncio...',
      'de': 'Werbung wird vorbereitet...',
      'en': 'Preparing ad...',
    },
    'Unlock by watching a short ad': {
      'tr': 'Kısa bir reklam izleyerek aç',
      'es': 'Desbloquea viendo un anuncio corto',
      'de': 'Durch kurzes Ansehen einer Werbung freischalten',
      'en': 'Unlock by watching a short ad',
    },
    'No ads for 1 day': {
      'tr': '1 gün reklamsız',
      'es': 'Sin anuncios por 1 día',
      'de': '1 Tag ohne Werbung',
      'en': 'No ads for 1 day',
    },
    'Ad-free until tomorrow.': {
      'tr': 'Yarına kadar reklamsız.',
      'es': 'Sin anuncios hasta mañana.',
      'de': 'Werbefrei bis morgen.',
      'en': 'Ad-free until tomorrow.',
    },
    'Need a little help today?': {
      'tr': 'Bugün biraz desteğe ihtiyacın var mı?',
      'es': '¿Necesitas un poco de ayuda hoy?',
      'de': 'Brauchst du heute etwas Hilfe?',
      'en': 'Need a little help today?',
    },
    'Optional support tools': {
      'tr': 'İsteğe bağlı destek araçları',
      'es': 'Herramientas opcionales de apoyo',
      'de': 'Optionale Unterstützung',
      'en': 'Optional support tools',
    },
    'Get one extra task': {
      'tr': '1 ekstra görev al',
      'es': 'Obtén una tarea extra',
      'de': 'Eine Extra-Aufgabe holen',
      'en': 'Get one extra task',
    },
    'Recover streak': {
      'tr': 'Seriyi kurtar',
      'es': 'Recuperar racha',
      'de': 'Serie retten',
      'en': 'Recover streak',
    },
    'Premium plan': {
      'tr': 'Premium plan',
      'es': 'Plan Premium',
      'de': 'Premium-Plan',
      'en': 'Premium plan',
    },
    'Auto-renewing monthly/yearly subscription.': {
      'tr': 'Aylık/yıllık otomatik yenilenen abonelik.',
      'es': 'Suscripción mensual/anual con renovación automática.',
      'de': 'Monatliches/jährliches Abo mit automatischer Verlängerung.',
      'en': 'Auto-renewing monthly/yearly subscription.',
    },
    'Manage': {
      'tr': 'Yönet',
      'es': 'Gestionar',
      'de': 'Verwalten',
      'en': 'Manage',
    },
    'See plans': {
      'tr': 'Planları gör',
      'es': 'Ver planes',
      'de': 'Pläne ansehen',
      'en': 'See plans',
    },
    "Let's reset your day.": {
      'tr': 'Gününü yeniden dengeleyelim.',
      'es': 'Reiniciemos tu día.',
      'de': 'Lass uns deinen Tag neu ausrichten.',
      'en': "Let's reset your day.",
    },
    "Pick what you need. We'll handle the rest.": {
      'tr': 'Neye ihtiyacın olduğunu seç. Kalanını biz hallederiz.',
      'es': 'Elige lo que necesitas. Nosotros nos encargamos del resto.',
      'de': 'Wähle, was du brauchst. Den Rest übernehmen wir.',
      'en': "Pick what you need. We'll handle the rest.",
    },
    'Close': {'tr': 'Kapat', 'es': 'Cerrar', 'de': 'Schließen', 'en': 'Close'},
    'Feeling stressed': {
      'tr': 'Stresli misin',
      'es': '¿Te sientes estresado?',
      'de': 'Fühlst du dich gestresst?',
      'en': 'Feeling stressed',
    },
    'Slow down. 2 minutes is enough.': {
      'tr': 'Yavaşla. 2 dakika yeter.',
      'es': 'Baja el ritmo. 2 minutos bastan.',
      'de': 'Langsamer. 2 Minuten reichen.',
      'en': 'Slow down. 2 minutes is enough.',
    },
    '2-minute breathing reset': {
      'tr': '2 dakikalık nefes reseti',
      'es': 'Reinicio de respiración de 2 minutos',
      'de': '2-Minuten-Atemreset',
      'en': '2-minute breathing reset',
    },
    'Low energy': {
      'tr': 'Enerji düşük',
      'es': 'Baja energía',
      'de': 'Wenig Energie',
      'en': 'Low energy',
    },
    "Let's wake your brain up.": {
      'tr': 'Zihnini biraz uyandıralım.',
      'es': 'Vamos a despertar tu mente.',
      'de': 'Lass uns dein Gehirn aufwecken.',
      'en': "Let's wake your brain up.",
    },
    '2-minute energy reset': {
      'tr': '2 dakikalık enerji reseti',
      'es': 'Reinicio de energía de 2 minutos',
      'de': '2-Minuten-Energiereset',
      'en': '2-minute energy reset',
    },
    'Need focus': {
      'tr': 'Odağa ihtiyacın var',
      'es': 'Necesitas enfoque',
      'de': 'Brauchst du Fokus',
      'en': 'Need focus',
    },
    'One small win. Ready?': {
      'tr': 'Bir küçük kazanım. Hazır mısın?',
      'es': 'Una pequeña victoria. ¿Listo?',
      'de': 'Ein kleiner Erfolg. Bereit?',
      'en': 'One small win. Ready?',
    },
    '2-minute focus reset': {
      'tr': '2 dakikalık odak reseti',
      'es': 'Reinicio de foco de 2 minutos',
      'de': '2-Minuten-Fokusreset',
      'en': '2-minute focus reset',
    },
    'Maybe later': {
      'tr': 'Belki sonra',
      'es': 'Quizá después',
      'de': 'Vielleicht später',
      'en': 'Maybe later',
    },
    'Start with one spark.': {
      'tr': 'Bir spark ile başla.',
      'es': 'Empieza con un spark.',
      'de': 'Starte mit einem Spark.',
      'en': 'Start with one spark.',
    },
    'Pick a pace that feels sustainable.': {
      'tr': 'Sürdürülebilir gelen bir tempo seç.',
      'es': 'Elige un ritmo que se sienta sostenible.',
      'de': 'Wähle ein Tempo, das nachhaltig wirkt.',
      'en': 'Pick a pace that feels sustainable.',
    },
    'A light week. Keep it easy.': {
      'tr': 'Hafif bir hafta. Rahat tut.',
      'es': 'Una semana ligera. Mantenlo fácil.',
      'de': 'Eine leichte Woche. Halte es locker.',
      'en': 'A light week. Keep it easy.',
    },
    '{count} sparks planned': {
      'tr': '{count} spark planlandı',
      'es': '{count} sparks planificados',
      'de': '{count} Sparks geplant',
      'en': '{count} sparks planned',
    },
    'Perfect balance': {
      'tr': 'Mükemmel denge',
      'es': 'Equilibrio perfecto',
      'de': 'Perfekte Balance',
      'en': 'Perfect balance',
    },
    'Steady momentum': {
      'tr': 'Dengeli momentum',
      'es': 'Impulso constante',
      'de': 'Stetiges Momentum',
      'en': 'Steady momentum',
    },
    'Strong week ahead': {
      'tr': 'Güçlü bir hafta geliyor',
      'es': 'Se viene una semana fuerte',
      'de': 'Eine starke Woche steht bevor',
      'en': 'Strong week ahead',
    },
    'Ambitious week. Pace yourself.': {
      'tr': 'İddialı bir hafta. Temponu koru.',
      'es': 'Semana ambiciosa. Dosifícate.',
      'de': 'Ambitionierte Woche. Pace dich.',
      'en': 'Ambitious week. Pace yourself.',
    },
    'Plan Your Week': {
      'tr': 'Haftanı planla',
      'es': 'Planifica tu semana',
      'de': 'Plane deine Woche',
      'en': 'Plan Your Week',
    },
    'Set your goals for this week': {
      'tr': 'Bu hafta için hedeflerini belirle',
      'es': 'Define tus objetivos para esta semana',
      'de': 'Setze deine Ziele für diese Woche',
      'en': 'Set your goals for this week',
    },
    'Not now': {
      'tr': 'Şimdi değil',
      'es': 'Ahora no',
      'de': 'Jetzt nicht',
      'en': 'Not now',
    },
    'Start this week': {
      'tr': 'Bu haftaya başla',
      'es': 'Empieza esta semana',
      'de': 'Starte diese Woche',
      'en': 'Start this week',
    },
    'Light': {'tr': 'Hafif', 'es': 'Ligero', 'de': 'Leicht', 'en': 'Light'},
    'Stronger': {
      'tr': 'Daha güçlü',
      'es': 'Más fuerte',
      'de': 'Stärker',
      'en': 'Stronger',
    },
    'Enter a task title.': {
      'tr': 'Bir görev başlığı gir.',
      'es': 'Introduce un título de tarea.',
      'de': 'Gib einen Aufgabentitel ein.',
      'en': 'Enter a task title.',
    },
    'Create a task': {
      'tr': 'Bir görev oluştur',
      'es': 'Crear una tarea',
      'de': 'Eine Aufgabe erstellen',
      'en': 'Create a task',
    },
    'Small wins -> Big change.': {
      'tr': 'Küçük kazanımlar -> Büyük değişim.',
      'es': 'Pequeñas victorias -> Gran cambio.',
      'de': 'Kleine Siege -> Große Veränderung.',
      'en': 'Small wins -> Big change.',
    },
    'What do you want to improve today?': {
      'tr': 'Bugün neyi iyileştirmek istiyorsun?',
      'es': '¿Qué quieres mejorar hoy?',
      'de': 'Was möchtest du heute verbessern?',
      'en': 'What do you want to improve today?',
    },
    'How challenging?': {
      'tr': 'Ne kadar zor?',
      'es': '¿Qué tan desafiante?',
      'de': 'Wie anspruchsvoll?',
      'en': 'How challenging?',
    },
    'Chill': {'tr': 'Rahat', 'es': 'Suave', 'de': 'Locker', 'en': 'Chill'},
    'Focus': {'tr': 'Odak', 'es': 'Enfoque', 'de': 'Fokus', 'en': 'Focus'},
    'Beast': {'tr': 'Güçlü', 'es': 'Bestia', 'de': 'Beast', 'en': 'Beast'},
    'Task Packs': {
      'tr': 'Görev paketleri',
      'es': 'Paquetes de tareas',
      'de': 'Aufgabenpakete',
      'en': 'Task Packs',
    },
    'Focus, Sleep, Stress packs in one tap.': {
      'tr': 'Odak, uyku ve stres paketleri tek dokunuşta.',
      'es': 'Paquetes de enfoque, sueño y estrés en un toque.',
      'de': 'Fokus-, Schlaf- und Stresspakete mit einem Tippen.',
      'en': 'Focus, Sleep, Stress packs in one tap.',
    },
    'Focus Pack': {
      'tr': 'Odak paketi',
      'es': 'Paquete de enfoque',
      'de': 'Fokuspaket',
      'en': 'Focus Pack',
    },
    'Sleep Pack': {
      'tr': 'Uyku paketi',
      'es': 'Paquete de sueño',
      'de': 'Schlafpaket',
      'en': 'Sleep Pack',
    },
    'Stress Pack': {
      'tr': 'Stres paketi',
      'es': 'Paquete de estrés',
      'de': 'Stresspaket',
      'en': 'Stress Pack',
    },
    'Creator Packs': {
      'tr': 'Üretici paketleri',
      'es': 'Paquetes de creadores',
      'de': 'Creator-Pakete',
      'en': 'Creator Packs',
    },
    'Discover, rate, and save creator-made packs.': {
      'tr': 'Üretici paketlerini keşfet, puanla ve kaydet.',
      'es': 'Descubre, puntúa y guarda paquetes creados por otros.',
      'de': 'Entdecke, bewerte und speichere Creator-Pakete.',
      'en': 'Discover, rate, and save creator-made packs.',
    },
    'Popular': {
      'tr': 'Popüler',
      'es': 'Popular',
      'de': 'Beliebt',
      'en': 'Popular',
    },
    'New': {'tr': 'Yeni', 'es': 'Nuevo', 'de': 'Neu', 'en': 'New'},
    'For you': {
      'tr': 'Senin için',
      'es': 'Para ti',
      'de': 'Für dich',
      'en': 'For you',
    },
    'Try Premium': {
      'tr': 'Premium’u dene',
      'es': 'Prueba Premium',
      'de': 'Premium testen',
      'en': 'Try Premium',
    },
    'AI mood tasks are Premium only.': {
      'tr': 'Yapay zeka ruh hali görevleri yalnızca Premium’da.',
      'es': 'Las tareas de ánimo con IA son solo para Premium.',
      'de': 'KI-Stimmungsaufgaben sind nur für Premium verfügbar.',
      'en': 'AI mood tasks are Premium only.',
    },
    'Example sparks': {
      'tr': 'Örnek sparks',
      'es': 'Sparks de ejemplo',
      'de': 'Beispiel-Sparks',
      'en': 'Example sparks',
    },
    'How long will it take?': {
      'tr': 'Ne kadar sürecek?',
      'es': '¿Cuánto tardará?',
      'de': 'Wie lange dauert es?',
      'en': 'How long will it take?',
    },
    'Add': {'tr': 'Ekle', 'es': 'Añadir', 'de': 'Hinzufügen', 'en': 'Add'},
    'Your rating': {
      'tr': 'Puanın',
      'es': 'Tu valoración',
      'de': 'Deine Bewertung',
      'en': 'Your rating',
    },
    'saved': {
      'tr': 'kayıt',
      'es': 'guardados',
      'de': 'gespeichert',
      'en': 'saved',
    },
    'NEW': {'tr': 'YENİ', 'es': 'NUEVO', 'de': 'NEU', 'en': 'NEW'},
    'Referral reward unlocked: +1 extra spark slot and 1 day premium boost.': {
      'tr':
          'Davet ödülü açıldı: +1 ekstra spark slotu ve 1 gün premium desteği.',
      'es':
          'Recompensa por invitación desbloqueada: +1 espacio extra de spark y 1 día premium.',
      'de':
          'Empfehlungsbelohnung freigeschaltet: +1 Extra-Spark-Slot und 1 Tag Premium.',
      'en':
          'Referral reward unlocked: +1 extra spark slot and 1 day premium boost.',
    },
    'Tap to open': {
      'tr': 'Açmak için dokun',
      'es': 'Toca para abrir',
      'de': 'Zum Öffnen tippen',
      'en': 'Tap to open',
    },
    'Retry': {
      'tr': 'Tekrar dene',
      'es': 'Reintentar',
      'de': 'Erneut versuchen',
      'en': 'Retry',
    },
    'Copy': {'tr': 'Kopyala', 'es': 'Copiar', 'de': 'Kopieren', 'en': 'Copy'},
    'Invite used: {code}': {
      'tr': 'Kullanılan davet: {code}',
      'es': 'Invitación usada: {code}',
      'de': 'Verwendeter Code: {code}',
      'en': 'Invite used: {code}',
    },
    'Enter invite code': {
      'tr': 'Davet kodunu gir',
      'es': 'Introduce el código de invitación',
      'de': 'Einladungscode eingeben',
      'en': 'Enter invite code',
    },
    'Claim': {'tr': 'Al', 'es': 'Canjear', 'de': 'Einlösen', 'en': 'Claim'},
    'Profile': {
      'tr': 'Profil',
      'es': 'Perfil',
      'de': 'Profil',
      'en': 'Profile',
    },
    'XP to Level {level}': {
      'tr': 'Seviye {level} için XP',
      'es': 'XP para nivel {level}',
      'de': 'XP bis Level {level}',
      'en': 'XP to Level {level}',
    },
    'Complete 1 spark to move your weekly plan forward.': {
      'tr': 'Haftalık planını ilerletmek için 1 spark tamamla.',
      'es': 'Completa 1 spark para avanzar tu plan semanal.',
      'de': 'Schließe 1 Spark ab, um deinen Wochenplan voranzubringen.',
      'en': 'Complete 1 spark to move your weekly plan forward.',
    },
    'Light your first spark today.': {
      'tr': 'Bugün ilk sparkını yak.',
      'es': 'Enciende hoy tu primer spark.',
      'de': 'Entfache heute deinen ersten Spark.',
      'en': 'Light your first spark today.',
    },
    'Do one more spark today to keep momentum.': {
      'tr': 'Momentumu korumak için bugün bir spark daha yap.',
      'es': 'Haz un spark más hoy para mantener el impulso.',
      'de': 'Mache heute noch einen Spark, um das Momentum zu halten.',
      'en': 'Do one more spark today to keep momentum.',
    },
    'Your journey just started.': {
      'tr': 'Yolculuğun yeni başladı.',
      'es': 'Tu camino acaba de empezar.',
      'de': 'Deine Reise hat gerade erst begonnen.',
      'en': 'Your journey just started.',
    },
    'Unlock first badge': {
      'tr': 'İlk rozeti aç',
      'es': 'Desbloquea la primera insignia',
      'de': 'Erstes Abzeichen freischalten',
      'en': 'Unlock first badge',
    },
    'Quick actions': {
      'tr': 'Hızlı aksiyonlar',
      'es': 'Acciones rápidas',
      'de': 'Schnellaktionen',
      'en': 'Quick actions',
    },
    'Add a custom task': {
      'tr': 'Özel görev ekle',
      'es': 'Añadir tarea personalizada',
      'de': 'Eigene Aufgabe hinzufügen',
      'en': 'Add a custom task',
    },
    'Personalize your list': {
      'tr': 'Listenini kişiselleştir',
      'es': 'Personaliza tu lista',
      'de': 'Personalisiere deine Liste',
      'en': 'Personalize your list',
    },
    'Premium active': {
      'tr': 'Premium aktif',
      'es': 'Premium activo',
      'de': 'Premium aktiv',
      'en': 'Premium active',
    },
    'Unlock perks': {
      'tr': 'Avantajları aç',
      'es': 'Desbloquear ventajas',
      'de': 'Vorteile freischalten',
      'en': 'Unlock perks',
    },
    'Boosts & no-ads': {
      'tr': 'Destekler ve reklamsız',
      'es': 'Impulsos y sin anuncios',
      'de': 'Boosts & keine Werbung',
      'en': 'Boosts & no-ads',
    },
    'Daily progress': {
      'tr': 'Günlük ilerleme',
      'es': 'Progreso diario',
      'de': 'Täglicher Fortschritt',
      'en': 'Daily progress',
    },
    'Hard': {'tr': 'Zor', 'es': 'Difícil', 'de': 'Schwer', 'en': 'Hard'},
    'Medium': {'tr': 'Orta', 'es': 'Medio', 'de': 'Mittel', 'en': 'Medium'},
    'Easy': {'tr': 'Kolay', 'es': 'Fácil', 'de': 'Leicht', 'en': 'Easy'},
    'Start your spark': {
      'tr': 'Sparkını başlat',
      'es': 'Inicia tu spark',
      'de': 'Starte deinen Spark',
      'en': 'Start your spark',
    },
    "That's it.": {
      'tr': 'Bu kadar.',
      'es': 'Eso es todo.',
      'de': 'Das ist alles.',
      'en': "That's it.",
    },
    'Ready when you are.': {
      'tr': 'Hazır olduğunda buradayım.',
      'es': 'Listo cuando tú lo estés.',
      'de': 'Bereit, wenn du es bist.',
      'en': 'Ready when you are.',
    },
    'Completed today': {
      'tr': 'Bugün tamamlandı',
      'es': 'Completado hoy',
      'de': 'Heute abgeschlossen',
      'en': 'Completed today',
    },
    'Ready to finish': {
      'tr': 'Bitirmeye hazır',
      'es': 'Listo para terminar',
      'de': 'Bereit zum Abschließen',
      'en': 'Ready to finish',
    },
    'Premium': {
      'tr': 'Premium',
      'es': 'Premium',
      'de': 'Premium',
      'en': 'Premium',
    },
    'Cancel timer': {
      'tr': 'Zamanlayıcıyı iptal et',
      'es': 'Cancelar temporizador',
      'de': 'Timer abbrechen',
      'en': 'Cancel timer',
    },
    'Mark complete': {
      'tr': 'Tamamlandı işaretle',
      'es': 'Marcar como completado',
      'de': 'Als erledigt markieren',
      'en': 'Mark complete',
    },
    'Start': {'tr': 'Başla', 'es': 'Empezar', 'de': 'Start', 'en': 'Start'},
    'minutes': {
      'tr': 'dakika',
      'es': 'minutos',
      'de': 'Minuten',
      'en': 'minutes',
    },
    'min': {'tr': 'dk', 'es': 'min', 'de': 'Min', 'en': 'min'},
    'seconds': {
      'tr': 'saniye',
      'es': 'segundos',
      'de': 'Sekunden',
      'en': 'seconds',
    },
    'Saved to your packs.': {
      'tr': 'Paketlerine kaydedildi.',
      'es': 'Guardado en tus paquetes.',
      'de': 'Zu deinen Paketen gespeichert.',
      'en': 'Saved to your packs.',
    },
    'Removed from saved.': {
      'tr': 'Kayıtlardan kaldırıldı.',
      'es': 'Eliminado de guardados.',
      'de': 'Aus Gespeichert entfernt.',
      'en': 'Removed from saved.',
    },
    'Rating saved.': {
      'tr': 'Puan kaydedildi.',
      'es': 'Valoración guardada.',
      'de': 'Bewertung gespeichert.',
      'en': 'Rating saved.',
    },
    'Rate us': {
      'tr': 'Bizi puanla',
      'es': 'Valóranos',
      'de': 'Bewerte uns',
      'en': 'Rate us',
    },
    'Help Sparkio grow with a quick review.': {
      'tr': 'Kısa bir değerlendirme ile Sparkio\'nun büyümesine destek ol.',
      'es': 'Ayuda a que Sparkio crezca con una reseña rápida.',
      'de': 'Hilf Sparkio mit einer kurzen Bewertung zu wachsen.',
      'en': 'Help Sparkio grow with a quick review.',
    },
    'Unable to open rating right now.': {
      'tr': 'Puanlama şu anda açılamıyor.',
      'es': 'No se puede abrir la valoración ahora mismo.',
      'de': 'Bewertung kann gerade nicht geöffnet werden.',
      'en': 'Unable to open rating right now.',
    },
    'Invites': {
      'tr': 'Davetler',
      'es': 'Invitaciones',
      'de': 'Einladungen',
      'en': 'Invites',
    },
    'Extra sparks': {
      'tr': 'Ekstra sparklar',
      'es': 'Sparks extra',
      'de': 'Extra-Sparks',
      'en': 'Extra sparks',
    },
    'Mastery track active': {
      'tr': 'Ustalık yolu aktif',
      'es': 'Ruta de dominio activa',
      'de': 'Meisterschaftspfad aktiv',
      'en': 'Mastery track active',
    },
    "Today's rhythm": {
      'tr': 'Bugünün ritmi',
      'es': 'Ritmo de hoy',
      'de': 'Heutiger Rhythmus',
      'en': "Today's rhythm",
    },
    'Now': {'tr': 'Şimdi', 'es': 'Ahora', 'de': 'Jetzt', 'en': 'Now'},
    'Done': {'tr': 'Bitti', 'es': 'Hecho', 'de': 'Erledigt', 'en': 'Done'},
    'Later': {'tr': 'Sonra', 'es': 'Después', 'de': 'Später', 'en': 'Later'},
    'Start small.': {
      'tr': 'Küçük başla.',
      'es': 'Empieza pequeño.',
      'de': 'Starte klein.',
      'en': 'Start small.',
    },
    'Optional - no pressure.': {
      'tr': 'Opsiyonel - baskı yok.',
      'es': 'Opcional - sin presión.',
      'de': 'Optional - kein Druck.',
      'en': 'Optional - no pressure.',
    },
    '{count} optional': {
      'tr': '{count} opsiyonel',
      'es': '{count} opcionales',
      'de': '{count} optional',
      'en': '{count} optional',
    },
    'Edit': {'tr': 'Düzenle', 'es': 'Editar', 'de': 'Bearbeiten', 'en': 'Edit'},
    'Choose avatar': {
      'tr': 'Avatar seç',
      'es': 'Elegir avatar',
      'de': 'Avatar wählen',
      'en': 'Choose avatar',
    },
    'Take photo': {
      'tr': 'Foto çek',
      'es': 'Tomar foto',
      'de': 'Foto aufnehmen',
      'en': 'Take photo',
    },
    'Gallery': {
      'tr': 'Galeri',
      'es': 'Galería',
      'de': 'Galerie',
      'en': 'Gallery',
    },
    'Remove avatar': {
      'tr': 'Avatarı kaldır',
      'es': 'Quitar avatar',
      'de': 'Avatar entfernen',
      'en': 'Remove avatar',
    },
    'Done button': {'tr': 'Tamam', 'es': 'Hecho', 'de': 'Fertig', 'en': 'Done'},
    'Cancel': {
      'tr': 'Vazgeç',
      'es': 'Cancelar',
      'de': 'Abbrechen',
      'en': 'Cancel',
    },
    'Save': {'tr': 'Kaydet', 'es': 'Guardar', 'de': 'Speichern', 'en': 'Save'},
    'Enter your first name': {
      'tr': 'Adını gir',
      'es': 'Ingresa tu nombre',
      'de': 'Gib deinen Vornamen ein',
      'en': 'Enter your first name',
    },
    'Please enter your name': {
      'tr': 'Lütfen adını gir',
      'es': 'Ingresa tu nombre',
      'de': 'Bitte gib deinen Namen ein',
      'en': 'Please enter your name',
    },
    'Name is too short': {
      'tr': 'İsim çok kısa',
      'es': 'El nombre es demasiado corto',
      'de': 'Der Name ist zu kurz',
      'en': 'Name is too short',
    },
    'Invite code copied.': {
      'tr': 'Davet kodu kopyalandı.',
      'es': 'Código de invitación copiado.',
      'de': 'Einladungscode kopiert.',
      'en': 'Invite code copied.',
    },
    'Enter an invite code.': {
      'tr': 'Bir davet kodu gir.',
      'es': 'Ingresa un código de invitación.',
      'de': 'Gib einen Einladungscode ein.',
      'en': 'Enter an invite code.',
    },
    'You cannot use your own invite code.': {
      'tr': 'Kendi davet kodunu kullanamazsın.',
      'es': 'No puedes usar tu propio código de invitación.',
      'de': 'Du kannst deinen eigenen Einladungscode nicht verwenden.',
      'en': 'You cannot use your own invite code.',
    },
    'Unable to claim invite code.': {
      'tr': 'Davet kodu kullanılamadı.',
      'es': 'No se pudo canjear el código de invitación.',
      'de': 'Der Einladungscode konnte nicht eingelöst werden.',
      'en': 'Unable to claim invite code.',
    },
    'You already used an invite code.': {
      'tr': 'Bu davet kodunu zaten kullandın.',
      'es': 'Ya usaste un código de invitación.',
      'de': 'Du hast bereits einen Einladungscode verwendet.',
      'en': 'You already used an invite code.',
    },
    'Invite code is invalid.': {
      'tr': 'Davet kodu geçersiz.',
      'es': 'El código de invitación no es válido.',
      'de': 'Der Einladungscode ist ungültig.',
      'en': 'Invite code is invalid.',
    },
    'Enter a valid invite code.': {
      'tr': 'Geçerli bir davet kodu gir.',
      'es': 'Ingresa un código de invitación válido.',
      'de': 'Gib einen gültigen Einladungscode ein.',
      'en': 'Enter a valid invite code.',
    },
    'Unable to claim invite right now.': {
      'tr': 'Davet şu anda kullanılamıyor.',
      'es': 'No se puede canjear la invitación ahora mismo.',
      'de': 'Die Einladung kann gerade nicht eingelöst werden.',
      'en': 'Unable to claim invite right now.',
    },
    'Morning intention': {
      'tr': 'Sabah niyeti',
      'es': 'Intención de la mañana',
      'de': 'Morgenabsicht',
      'en': 'Morning intention',
    },
    'What is one tiny intention for today?': {
      'tr': 'Bugün için tek küçük niyetin ne?',
      'es': '¿Cuál es una pequeña intención para hoy?',
      'de': 'Was ist eine kleine Absicht für heute?',
      'en': 'What is one tiny intention for today?',
    },
    'e.g. Show up for one 2-min spark': {
      'tr': 'ör. 2 dakikalık bir spark için ortaya çık',
      'es': 'p. ej. preséntate para un spark de 2 min',
      'de': 'z. B. für einen 2-Minuten-Spark auftauchen',
      'en': 'e.g. Show up for one 2-min spark',
    },
    'Intention saved for today.': {
      'tr': 'Bugünkü niyet kaydedildi.',
      'es': 'La intención de hoy se guardó.',
      'de': 'Die Absicht für heute wurde gespeichert.',
      'en': 'Intention saved for today.',
    },
    'Evening mini review': {
      'tr': 'Akşam mini değerlendirme',
      'es': 'Mini revisión de la tarde',
      'de': 'Mini-Abendcheck',
      'en': 'Evening mini review',
    },
    'You showed up with {count} sparks today.': {
      'tr': 'Bugün {count} spark ile ortaya çıktın.',
      'es': 'Hoy apareciste con {count} sparks.',
      'de': 'Heute warst du mit {count} Sparks da.',
      'en': 'You showed up with {count} sparks today.',
    },
    'Top focus today: {category}': {
      'tr': 'Bugünün ana odağı: {category}',
      'es': 'Enfoque principal de hoy: {category}',
      'de': 'Hauptfokus heute: {category}',
      'en': 'Top focus today: {category}',
    },
    'Weekly progress: {done}/{total}': {
      'tr': 'Haftalık ilerleme: {done}/{total}',
      'es': 'Progreso semanal: {done}/{total}',
      'de': 'Wochenfortschritt: {done}/{total}',
      'en': 'Weekly progress: {done}/{total}',
    },
    'Focus Badge': {
      'tr': 'Odak Rozeti',
      'es': 'Insignia de Enfoque',
      'de': 'Fokus-Abzeichen',
      'en': 'Focus Badge',
    },
    'Spark Starter Badge': {
      'tr': 'İlk Spark Rozeti',
      'es': 'Insignia Primer Spark',
      'de': 'Erster-Spark-Abzeichen',
      'en': 'Spark Starter Badge',
    },
    'Growth Badge': {
      'tr': 'Gelişim Rozeti',
      'es': 'Insignia de Crecimiento',
      'de': 'Wachstums-Abzeichen',
      'en': 'Growth Badge',
    },
    'Momentum Badge': {
      'tr': 'Momentum Rozeti',
      'es': 'Insignia de Impulso',
      'de': 'Momentum-Abzeichen',
      'en': 'Momentum Badge',
    },
    'No plan': {
      'tr': 'Plan yok',
      'es': 'Sin plan',
      'de': 'Kein Plan',
      'en': 'No plan',
    },
    'Week just started': {
      'tr': 'Hafta yeni başladı',
      'es': 'La semana acaba de empezar',
      'de': 'Die Woche hat gerade begonnen',
      'en': 'Week just started',
    },
    'Back to today': {
      'tr': 'Bugüne dön',
      'es': 'Volver a hoy',
      'de': 'Zurück zu heute',
      'en': 'Back to today',
    },
    'Last 7 days': {
      'tr': 'Son 7 gün',
      'es': 'Últimos 7 días',
      'de': 'Letzte 7 Tage',
      'en': 'Last 7 days',
    },
    'Best streak: {count}': {
      'tr': 'En iyi seri: {count}',
      'es': 'Mejor racha: {count}',
      'de': 'Beste Serie: {count}',
      'en': 'Best streak: {count}',
    },
    'Best streak: {count} {dayLabel}': {
      'tr': 'En iyi seri: {count} {dayLabel}',
      'es': 'Mejor racha: {count} {dayLabel}',
      'de': 'Beste Serie: {count} {dayLabel}',
      'en': 'Best streak: {count} {dayLabel}',
    },
    'Total sparks: {count}': {
      'tr': 'Toplam spark: {count}',
      'es': 'Sparks totales: {count}',
      'de': 'Gesamt-Sparks: {count}',
      'en': 'Total sparks: {count}',
    },
    'Consistency: {count}%': {
      'tr': 'Tutarlılık: %{count}',
      'es': 'Constancia: {count}%',
      'de': 'Konstanz: {count}%',
      'en': 'Consistency: {count}%',
    },
    'You showed up today.': {
      'tr': 'Bugün geldin.',
      'es': 'Hoy apareciste.',
      'de': 'Du warst heute da.',
      'en': 'You showed up today.',
    },
    'You showed up yesterday.': {
      'tr': 'Dün geldin.',
      'es': 'Apareciste ayer.',
      'de': 'Du warst gestern da.',
      'en': 'You showed up yesterday.',
    },
    'Tasks that work best': {
      'tr': 'En iyi çalışan görevler',
      'es': 'Tareas que mejor funcionan',
      'de': 'Aufgaben, die am besten funktionieren',
      'en': 'Tasks that work best',
    },
    'We will suggest your best tasks once you complete more sparks.': {
      'tr': 'Daha fazla spark tamamladığında en iyi görevlerini önereceğiz.',
      'es': 'Te sugeriremos tus mejores tareas cuando completes más sparks.',
      'de':
          'Wir schlagen dir deine besten Aufgaben vor, sobald du mehr Sparks abschließt.',
      'en': 'We will suggest your best tasks once you complete more sparks.',
    },
    'Based on completed sparks only.': {
      'tr': 'Yalnızca tamamlanan sparklara göre.',
      'es': 'Basado solo en sparks completados.',
      'de': 'Basiert nur auf abgeschlossenen Sparks.',
      'en': 'Based on completed sparks only.',
    },
    'Mon': {'tr': 'Pzt', 'es': 'Lun', 'de': 'Mo', 'en': 'Mon'},
    'Tue': {'tr': 'Sal', 'es': 'Mar', 'de': 'Di', 'en': 'Tue'},
    'Wed': {'tr': 'Çar', 'es': 'Mié', 'de': 'Mi', 'en': 'Wed'},
    'Thu': {'tr': 'Per', 'es': 'Jue', 'de': 'Do', 'en': 'Thu'},
    'Fri': {'tr': 'Cum', 'es': 'Vie', 'de': 'Fr', 'en': 'Fri'},
    'Sat': {'tr': 'Cmt', 'es': 'Sáb', 'de': 'Sa', 'en': 'Sat'},
    'Sun': {'tr': 'Paz', 'es': 'Dom', 'de': 'So', 'en': 'Sun'},
    'day': {'tr': 'gün', 'es': 'día', 'de': 'Tag', 'en': 'day'},
    'days': {'tr': 'gün', 'es': 'días', 'de': 'Tage', 'en': 'days'},
    'Low': {'tr': 'Düşük', 'es': 'Bajo', 'de': 'Niedrig', 'en': 'Low'},
    'High': {'tr': 'Yüksek', 'es': 'Alto', 'de': 'Hoch', 'en': 'High'},
    'Other': {'tr': 'Diğer', 'es': 'Otro', 'de': 'Andere', 'en': 'Other'},
    'Move a little, feel better.': {
      'tr': 'Biraz hareket et, daha iyi hisset.',
      'es': 'Muévete un poco, siéntete mejor.',
      'de': 'Beweg dich ein wenig, fühl dich besser.',
      'en': 'Move a little, feel better.',
    },
    'Clear your head with small resets.': {
      'tr': 'Küçük resetlerle zihnini aç.',
      'es': 'Despeja tu mente con pequeños reinicios.',
      'de': 'Mach deinen Kopf mit kleinen Resets frei.',
      'en': 'Clear your head with small resets.',
    },
    'Make room for one small improvement.': {
      'tr': 'Küçük bir gelişim için yer aç.',
      'es': 'Haz espacio para una pequeña mejora.',
      'de': 'Schaffe Raum für eine kleine Verbesserung.',
      'en': 'Make room for one small improvement.',
    },
    'Protect your calm moments this week.': {
      'tr': 'Bu hafta sakin anlarını koru.',
      'es': 'Protege tus momentos de calma esta semana.',
      'de': 'Schütze diese Woche deine ruhigen Momente.',
      'en': 'Protect your calm moments this week.',
    },
    'Support your energy and wellbeing.': {
      'tr': 'Enerjini ve iyi oluşunu destekle.',
      'es': 'Apoya tu energía y bienestar.',
      'de': 'Unterstütze deine Energie und dein Wohlbefinden.',
      'en': 'Support your energy and wellbeing.',
    },
    'slot': {'tr': 'slot', 'es': 'slot', 'de': 'Slot', 'en': 'slot'},
    'slots': {'tr': 'slot', 'es': 'slots', 'de': 'Slots', 'en': 'slots'},
    '{title} ready now': {
      'tr': '{title} şimdi hazır',
      'es': '{title} listo ahora',
      'de': '{title} jetzt bereit',
      'en': '{title} ready now',
    },
    '{title} in {count} {unit}': {
      'tr': '{title} için {count} {unit} kaldı',
      'es': '{title} en {count} {unit}',
      'de': '{title} in {count} {unit}',
      'en': '{title} in {count} {unit}',
    },
    'Camera permission is denied. Check app permissions.': {
      'tr': 'Kamera izni reddedildi. Uygulama izinlerini kontrol et.',
      'es': 'El permiso de cámara fue denegado. Revisa los permisos.',
      'de': 'Kamerazugriff verweigert. Prüfe die App-Berechtigungen.',
      'en': 'Camera permission is denied. Check app permissions.',
    },
    'Camera is not available on this device.': {
      'tr': 'Bu cihazda kamera kullanılamıyor.',
      'es': 'La cámara no está disponible en este dispositivo.',
      'de': 'Auf diesem Gerät ist keine Kamera verfügbar.',
      'en': 'Camera is not available on this device.',
    },
    'Photo library permission is denied.': {
      'tr': 'Fotoğraf arşivi izni reddedildi.',
      'es': 'El permiso de la galería fue denegado.',
      'de': 'Zugriff auf die Fotomediathek verweigert.',
      'en': 'Photo library permission is denied.',
    },
    'Unable to open gallery right now.': {
      'tr': 'Galeri şu anda açılamıyor.',
      'es': 'No se puede abrir la galería ahora mismo.',
      'de': 'Galerie kann gerade nicht geöffnet werden.',
      'en': 'Unable to open gallery right now.',
    },
    'Unable to open camera right now.': {
      'tr': 'Kamera şu anda açılamıyor.',
      'es': 'No se puede abrir la cámara ahora mismo.',
      'de': 'Kamera kann gerade nicht geöffnet werden.',
      'en': 'Unable to open camera right now.',
    },
    'Next builds consistency': {
      'tr': 'Sıradaki adım tutarlılık kurar',
      'es': 'Lo siguiente construye constancia',
      'de': 'Der nächste Schritt baut Konstanz auf',
      'en': 'Next builds consistency',
    },
    '{duration} done': {
      'tr': '{duration} tamamlandı',
      'es': '{duration} completados',
      'de': '{duration} erledigt',
      'en': '{duration} done',
    },
    'minute': {'tr': 'dakika', 'es': 'minuto', 'de': 'Minute', 'en': 'minute'},
    'Good morning': {
      'tr': 'Günaydın',
      'es': 'Buenos días',
      'de': 'Guten Morgen',
      'en': 'Good morning',
    },
    'Good afternoon': {
      'tr': 'Tünaydın',
      'es': 'Buenas tardes',
      'de': 'Guten Tag',
      'en': 'Good afternoon',
    },
    'Good evening': {
      'tr': 'İyi akşamlar',
      'es': 'Buenas noches',
      'de': 'Guten Abend',
      'en': 'Good evening',
    },
    'Store not available.': {
      'tr': 'Mağaza kullanılamıyor.',
      'es': 'La tienda no está disponible.',
      'de': 'Store ist nicht verfügbar.',
      'en': 'Store not available.',
    },
    'Purchase error.': {
      'tr': 'Satın alma hatası.',
      'es': 'Error de compra.',
      'de': 'Kauffehler.',
      'en': 'Purchase error.',
    },
    'Unable to load products.': {
      'tr': 'Ürünler yüklenemedi.',
      'es': 'No se pudieron cargar los productos.',
      'de': 'Produkte konnten nicht geladen werden.',
      'en': 'Unable to load products.',
    },
    'No products found.': {
      'tr': 'Ürün bulunamadı.',
      'es': 'No se encontraron productos.',
      'de': 'Keine Produkte gefunden.',
      'en': 'No products found.',
    },
    'Purchase pending...': {
      'tr': 'Satın alma bekleniyor...',
      'es': 'Compra pendiente...',
      'de': 'Kauf ausstehend...',
      'en': 'Purchase pending...',
    },
    'Purchase failed.': {
      'tr': 'Satın alma başarısız oldu.',
      'es': 'La compra falló.',
      'de': 'Kauf fehlgeschlagen.',
      'en': 'Purchase failed.',
    },
    'Premium active.': {
      'tr': 'Premium aktif.',
      'es': 'Premium activo.',
      'de': 'Premium aktiv.',
      'en': 'Premium active.',
    },
    'Purchase invalid.': {
      'tr': 'Satın alma geçersiz.',
      'es': 'Compra no válida.',
      'de': 'Kauf ungültig.',
      'en': 'Purchase invalid.',
    },
    'Active Timer': {
      'tr': 'Aktif zamanlayıcı',
      'es': 'Temporizador activo',
      'de': 'Aktiver Timer',
      'en': 'Active Timer',
    },
    'Time is up!': {
      'tr': 'Süre doldu!',
      'es': '¡Se acabó el tiempo!',
      'de': 'Die Zeit ist um!',
      'en': 'Time is up!',
    },
    'DONE': {'tr': 'BİTTİ', 'es': 'HECHO', 'de': 'FERTIG', 'en': 'DONE'},
    'LIVE': {'tr': 'CANLI', 'es': 'ACTIVO', 'de': 'LIVE', 'en': 'LIVE'},
    'Ready to mark as completed.': {
      'tr': 'Tamamlandı olarak işaretlemeye hazır.',
      'es': 'Listo para marcar como completado.',
      'de': 'Bereit zum Abschließen.',
      'en': 'Ready to mark as completed.',
    },
    'Keep focus - {count} sec left': {
      'tr': 'Odakta kal - {count} sn kaldı',
      'es': 'Mantén el foco: quedan {count} s',
      'de': 'Bleib fokussiert - noch {count} Sek.',
      'en': 'Keep focus - {count} sec left',
    },
    'Progress': {
      'tr': 'İlerleme',
      'es': 'Progreso',
      'de': 'Fortschritt',
      'en': 'Progress',
    },
    'Complete': {
      'tr': 'Tamamla',
      'es': 'Completar',
      'de': 'Abschließen',
      'en': 'Complete',
    },
    "Today's tiny wins": {
      'tr': 'Bugünün küçük kazanımları',
      'es': 'Pequeñas victorias de hoy',
      'de': 'Kleine Erfolge heute',
      'en': "Today's tiny wins",
    },
    'No sparks yet. Your first one starts the story.': {
      'tr': 'Henüz spark yok. Hikâye ilk spark ile başlar.',
      'es': 'Aún no hay sparks. El primero empieza la historia.',
      'de': 'Noch keine Sparks. Der erste beginnt die Geschichte.',
      'en': 'No sparks yet. Your first one starts the story.',
    },
    'Weekly arc': {
      'tr': 'Haftalık yay',
      'es': 'Arco semanal',
      'de': 'Wochenbogen',
      'en': 'Weekly arc',
    },
    "This week you're training consistency.": {
      'tr': 'Bu hafta tutarlılığı çalıştırıyorsun.',
      'es': 'Esta semana estás entrenando constancia.',
      'de': 'Diese Woche trainierst du Konstanz.',
      'en': "This week you're training consistency.",
    },
    '{done} of {total} sparks done.': {
      'tr': '{total} sparkın {done} kadarı tamamlandı.',
      'es': '{done} de {total} sparks completados.',
      'de': '{done} von {total} Sparks erledigt.',
      'en': '{done} of {total} sparks done.',
    },
    'Set a weekly spark target to start your arc.': {
      'tr': 'Yayını başlatmak için haftalık spark hedefi belirle.',
      'es': 'Define un objetivo semanal de sparks para empezar tu arco.',
      'de': 'Setze ein Wochenziel für Sparks, um deinen Bogen zu starten.',
      'en': 'Set a weekly spark target to start your arc.',
    },
    'Set one tiny intention for today before your first spark.': {
      'tr': 'İlk sparkından önce bugün için tek bir küçük niyet belirle.',
      'es': 'Define una pequeña intención para hoy antes de tu primer spark.',
      'de': 'Setze vor deinem ersten Spark eine kleine Intention für heute.',
      'en': 'Set one tiny intention for today before your first spark.',
    },
    'Set intention': {
      'tr': 'Niyet belirle',
      'es': 'Definir intención',
      'de': 'Intention setzen',
      'en': 'Set intention',
    },
    'Weekly closing': {
      'tr': 'Hafta kapanışı',
      'es': 'Cierre semanal',
      'de': 'Wochenabschluss',
      'en': 'Weekly closing',
    },
    '{count} sparks • Top category {category}': {
      'tr': '{count} spark • En üst kategori {category}',
      'es': '{count} sparks • Categoría principal {category}',
      'de': '{count} Sparks • Top-Kategorie {category}',
      'en': '{count} sparks • Top category {category}',
    },
    'Close week': {
      'tr': 'Haftayı kapat',
      'es': 'Cerrar semana',
      'de': 'Woche abschließen',
      'en': 'Close week',
    },
    'Timer finished': {
      'tr': 'Sayaç bitti',
      'es': 'Temporizador terminado',
      'de': 'Timer beendet',
      'en': 'Timer finished',
    },
    'Mark "{title}" as done.': {
      'tr': '"{title}" görevini tamamlandı olarak işaretle.',
      'es': 'Marca "{title}" como completado.',
      'de': 'Markiere "{title}" als erledigt.',
      'en': 'Mark "{title}" as done.',
    },
    'Mark done': {
      'tr': 'Tamamlandı işaretle',
      'es': 'Marcar como hecho',
      'de': 'Als erledigt markieren',
      'en': 'Mark done',
    },
    'Challenge day is open': {
      'tr': 'Challenge günü açık',
      'es': 'El día del reto está abierto',
      'de': 'Der Challenge-Tag ist offen',
      'en': 'Challenge day is open',
    },
    '{title}: one spark logs today automatically.': {
      'tr': '{title}: bugün bir spark otomatik olarak kaydolur.',
      'es': '{title}: un spark registra hoy automáticamente.',
      'de': '{title}: Ein Spark wird heute automatisch erfasst.',
      'en': '{title}: one spark logs today automatically.',
    },
    'Start spark': {
      'tr': 'Spark başlat',
      'es': 'Iniciar spark',
      'de': 'Spark starten',
      'en': 'Start spark',
    },
    'Protect your streak': {
      'tr': 'Serini koru',
      'es': 'Protege tu racha',
      'de': 'Schütze deine Serie',
      'en': 'Protect your streak',
    },
    'One quick spark keeps your rhythm alive today.': {
      'tr': 'Bugün tek bir hızlı spark ritmini canlı tutar.',
      'es': 'Un spark rápido mantiene tu ritmo vivo hoy.',
      'de': 'Ein schneller Spark hält deinen Rhythmus heute lebendig.',
      'en': 'One quick spark keeps your rhythm alive today.',
    },
    'Keep streak': {
      'tr': 'Seriyi koru',
      'es': 'Mantener racha',
      'de': 'Serie halten',
      'en': 'Keep streak',
    },
    'Start with one tiny spark': {
      'tr': 'Tek bir küçük spark ile başla',
      'es': 'Empieza con un pequeño spark',
      'de': 'Starte mit einem kleinen Spark',
      'en': 'Start with one tiny spark',
    },
    '60 seconds is enough to build momentum.': {
      'tr': 'Momentum kurmak için 60 saniye yeter.',
      'es': '60 segundos bastan para crear impulso.',
      'de': '60 Sekunden reichen aus, um Momentum aufzubauen.',
      'en': '60 seconds is enough to build momentum.',
    },
    'Start now': {
      'tr': 'Şimdi başla',
      'es': 'Empieza ahora',
      'de': 'Jetzt starten',
      'en': 'Start now',
    },
    'Today': {'tr': 'Bugün', 'es': 'Hoy', 'de': 'Heute', 'en': 'Today'},
    'Weekly plan needs {count} more': {
      'tr': 'Haftalık plan için {count} tane daha gerekiyor',
      'es': 'El plan semanal necesita {count} más',
      'de': 'Der Wochenplan braucht noch {count}',
      'en': 'Weekly plan needs {count} more',
    },
    '{dayLabel} is a good time to catch up.': {
      'tr': '{dayLabel} toparlamak için iyi bir zaman.',
      'es': '{dayLabel} es un buen momento para ponerte al día.',
      'de': '{dayLabel} ist ein guter Zeitpunkt, um aufzuholen.',
      'en': '{dayLabel} is a good time to catch up.',
    },
    'Open plan': {
      'tr': 'Planı aç',
      'es': 'Abrir plan',
      'de': 'Plan öffnen',
      'en': 'Open plan',
    },
    'Momentum is active': {
      'tr': 'Momentum aktif',
      'es': 'El impulso está activo',
      'de': 'Momentum ist aktiv',
      'en': 'Momentum is active',
    },
    'One more micro spark makes today stick.': {
      'tr': 'Bir mikro spark daha bugünü sağlamlaştırır.',
      'es': 'Un micro spark más hace que el día se mantenga.',
      'de': 'Ein weiterer Mikro-Spark lässt den Tag besser sitzen.',
      'en': 'One more micro spark makes today stick.',
    },
    'Do one more': {
      'tr': 'Bir tane daha yap',
      'es': 'Haz uno más',
      'de': 'Noch einen machen',
      'en': 'Do one more',
    },
    'Challenges': {
      'tr': 'Challengelar',
      'es': 'Retos',
      'de': 'Challenges',
      'en': 'Challenges',
    },
    'Pick one and start today.': {
      'tr': 'Birini seç ve bugün başla.',
      'es': 'Elige uno y empieza hoy.',
      'de': 'Wähle einen aus und starte heute.',
      'en': 'Pick one and start today.',
    },
    '{title} - {done}/{total} days': {
      'tr': '{title} - {done}/{total} gün',
      'es': '{title} - {done}/{total} días',
      'de': '{title} - {done}/{total} Tage',
      'en': '{title} - {done}/{total} days',
    },
    'Advanced': {
      'tr': 'İleri',
      'es': 'Avanzado',
      'de': 'Fortgeschritten',
      'en': 'Advanced',
    },
    'Starter': {
      'tr': 'Başlangıç',
      'es': 'Inicial',
      'de': 'Starter',
      'en': 'Starter',
    },
    '{count} days': {
      'tr': '{count} gün',
      'es': '{count} días',
      'de': '{count} Tage',
      'en': '{count} days',
    },
    'Goal {count}/day': {
      'tr': 'Hedef {count}/gün',
      'es': 'Meta {count}/día',
      'de': 'Ziel {count}/Tag',
      'en': 'Goal {count}/day',
    },
    'Active': {'tr': 'Aktif', 'es': 'Activo', 'de': 'Aktiv', 'en': 'Active'},
    'No active challenge': {
      'tr': 'Aktif challenge yok',
      'es': 'No hay reto activo',
      'de': 'Keine aktive Challenge',
      'en': 'No active challenge',
    },
    'Start one today and keep your streak moving.': {
      'tr': 'Bugün bir tane başlat ve serini hareket halinde tut.',
      'es': 'Empieza uno hoy y mantén tu racha en movimiento.',
      'de': 'Starte heute eine und halte deine Serie in Bewegung.',
      'en': 'Start one today and keep your streak moving.',
    },
    'Start one today': {
      'tr': 'Bugün bir tane başlat',
      'es': 'Empieza uno hoy',
      'de': 'Heute eine starten',
      'en': 'Start one today',
    },
    '{done}/{total} days completed': {
      'tr': '{done}/{total} gün tamamlandı',
      'es': '{done}/{total} días completados',
      'de': '{done}/{total} Tage abgeschlossen',
      'en': '{done}/{total} days completed',
    },
    'Start today spark': {
      'tr': 'Bugünün sparkını başlat',
      'es': 'Inicia el spark de hoy',
      'de': 'Heutigen Spark starten',
      'en': 'Start today spark',
    },
    'Active challenge removed.': {
      'tr': 'Aktif challenge kaldırıldı.',
      'es': 'Se eliminó el reto activo.',
      'de': 'Aktive Challenge entfernt.',
      'en': 'Active challenge removed.',
    },
    'Remove': {
      'tr': 'Kaldır',
      'es': 'Quitar',
      'de': 'Entfernen',
      'en': 'Remove',
    },
    '{title} is already active.': {
      'tr': '{title} zaten aktif.',
      'es': '{title} ya está activo.',
      'de': '{title} ist bereits aktiv.',
      'en': '{title} is already active.',
    },
    '{title} challenge started.': {
      'tr': '{title} challenge başladı.',
      'es': 'El reto {title} ha comenzado.',
      'de': 'Challenge {title} wurde gestartet.',
      'en': '{title} challenge started.',
    },
    '{title} completed': {
      'tr': '{title} tamamlandı',
      'es': '{title} completado',
      'de': '{title} abgeschlossen',
      'en': '{title} completed',
    },
    'Great consistency. You completed {done}/{total} days.': {
      'tr': 'Harika tutarlılık. {done}/{total} günü tamamladın.',
      'es': 'Gran constancia. Completaste {done}/{total} días.',
      'de': 'Starke Konstanz. Du hast {done}/{total} Tage abgeschlossen.',
      'en': 'Great consistency. You completed {done}/{total} days.',
    },
    'Nice': {'tr': 'Harika', 'es': 'Bien', 'de': 'Stark', 'en': 'Nice'},
    '{title}: {done}/{total} days logged.': {
      'tr': '{title}: {done}/{total} gün kaydedildi.',
      'es': '{title}: {done}/{total} días registrados.',
      'de': '{title}: {done}/{total} Tage erfasst.',
      'en': '{title}: {done}/{total} days logged.',
    },
    'Focus Reset': {
      'tr': 'Odak Sıfırlama',
      'es': 'Reinicio de enfoque',
      'de': 'Fokus-Reset',
      'en': 'Focus Reset',
    },
    'Run one distraction-free spark each day to regain focus.': {
      'tr':
          'Odağını geri kazanmak için her gün dikkat dağıtmayan bir spark yap.',
      'es':
          'Haz un spark sin distracciones cada día para recuperar el enfoque.',
      'de':
          'Führe jeden Tag einen ablenkungsfreien Spark aus, um den Fokus zurückzugewinnen.',
      'en': 'Run one distraction-free spark each day to regain focus.',
    },
    'Sleep Week': {
      'tr': 'Uyku Haftası',
      'es': 'Semana del sueño',
      'de': 'Schlafwoche',
      'en': 'Sleep Week',
    },
    'Close each day with one short sleep-friendly spark.': {
      'tr': 'Her günü uyku dostu kısa bir spark ile kapat.',
      'es': 'Cierra cada día con un spark corto y apto para el sueño.',
      'de': 'Beende jeden Tag mit einem kurzen, schlaffreundlichen Spark.',
      'en': 'Close each day with one short sleep-friendly spark.',
    },
    'Stress Offload': {
      'tr': 'Stresi Boşalt',
      'es': 'Descarga de estrés',
      'de': 'Stress abbauen',
      'en': 'Stress Offload',
    },
    'Use one daily spark to downshift stress and reset calmly.': {
      'tr':
          'Stresi azaltmak ve sakin şekilde resetlemek için günde bir spark kullan.',
      'es': 'Usa un spark diario para bajar el estrés y reiniciarte con calma.',
      'de':
          'Nutze täglich einen Spark, um Stress herunterzufahren und ruhig neu zu starten.',
      'en': 'Use one daily spark to downshift stress and reset calmly.',
    },
    '7-Day Reset': {
      'tr': '7 Günlük Reset',
      'es': 'Reinicio de 7 días',
      'de': '7-Tage-Reset',
      'en': '7-Day Reset',
    },
    'Do at least one spark every day for 7 days.': {
      'tr': '7 gün boyunca her gün en az bir spark yap.',
      'es': 'Haz al menos un spark cada día durante 7 días.',
      'de': 'Mache 7 Tage lang jeden Tag mindestens einen Spark.',
      'en': 'Do at least one spark every day for 7 days.',
    },
    '14-Day Momentum': {
      'tr': '14 Günlük Momentum',
      'es': 'Impulso de 14 días',
      'de': '14-Tage-Momentum',
      'en': '14-Day Momentum',
    },
    'Build consistency with one daily spark for 14 days.': {
      'tr': '14 gün boyunca günde bir spark ile tutarlılık oluştur.',
      'es': 'Construye constancia con un spark diario durante 14 días.',
      'de': 'Baue mit einem täglichen Spark über 14 Tage Konstanz auf.',
      'en': 'Build consistency with one daily spark for 14 days.',
    },
    'Focus Flow': {
      'tr': 'Odak Akışı',
      'es': 'Flujo de enfoque',
      'de': 'Fokusfluss',
      'en': 'Focus Flow',
    },
    'Creator-curated pack for deep work blocks.': {
      'tr': 'Derin çalışma blokları için üretici seçkisi paket.',
      'es': 'Paquete curado por creadores para bloques de trabajo profundo.',
      'de': 'Von Creatorn kuratiertes Paket für Deep-Work-Blöcke.',
      'en': 'Creator-curated pack for deep work blocks.',
    },
    'Set one clear focus outcome': {
      'tr': 'Tek bir net odak sonucu belirle',
      'es': 'Define un resultado de enfoque claro',
      'de': 'Lege ein klares Fokusziel fest',
      'en': 'Set one clear focus outcome',
    },
    'Write your top focus target': {
      'tr': 'En önemli odak hedefini yaz',
      'es': 'Escribe tu objetivo principal de enfoque',
      'de': 'Schreibe dein wichtigstes Fokusziel auf',
      'en': 'Write your top focus target',
    },
    'Run a 5-minute deep focus sprint': {
      'tr': '5 dakikalık derin odak sprinti yap',
      'es': 'Haz un sprint de enfoque profundo de 5 minutos',
      'de': 'Mache einen 5-minütigen Tiefenfokus-Sprint',
      'en': 'Run a 5-minute deep focus sprint',
    },
    'Clear distractions for 2 minutes': {
      'tr': '2 dakika dikkat dağıtıcıları temizle',
      'es': 'Elimina distracciones durante 2 minutos',
      'de': 'Beseitige 2 Minuten lang Ablenkungen',
      'en': 'Clear distractions for 2 minutes',
    },
    'Do a 12-minute deep work sprint': {
      'tr': '12 dakikalık derin çalışma sprinti yap',
      'es': 'Haz un sprint de trabajo profundo de 12 minutos',
      'de': 'Mache einen 12-minütigen Deep-Work-Sprint',
      'en': 'Do a 12-minute deep work sprint',
    },
    'Write one distraction to avoid': {
      'tr': 'Kaçınacağın bir dikkat dağıtıcı yaz',
      'es': 'Escribe una distracción que evitarás',
      'de': 'Schreibe eine Ablenkung auf, die du vermeiden willst',
      'en': 'Write one distraction to avoid',
    },
    'Sleep Reset': {
      'tr': 'Uyku Reset',
      'es': 'Reinicio del sueño',
      'de': 'Schlaf-Reset',
      'en': 'Sleep Reset',
    },
    'Simple evening wind-down steps from a creator routine.': {
      'tr': 'Bir üretici rutininden gelen basit akşam sakinleşme adımları.',
      'es': 'Pasos simples de desconexión nocturna de una rutina de creador.',
      'de': 'Einfache Abend-Runterfahr-Schritte aus einer Creator-Routine.',
      'en': 'Simple evening wind-down steps from a creator routine.',
    },
    'Dim lights and reduce noise for 5 minutes': {
      'tr': 'Işıkları kıs ve 5 dakika gürültüyü azalt',
      'es': 'Atenúa las luces y reduce el ruido durante 5 minutos',
      'de': 'Dimme das Licht und reduziere 5 Minuten lang Geräusche',
      'en': 'Dim lights and reduce noise for 5 minutes',
    },
    'Write tomorrow first task': {
      'tr': 'Yarının ilk görevini yaz',
      'es': 'Escribe la primera tarea de mañana',
      'de': 'Schreibe die erste Aufgabe für morgen auf',
      'en': 'Write tomorrow first task',
    },
    'No phone and breathe for 4 minutes': {
      'tr': 'Telefon yok, 4 dakika nefes al',
      'es': 'Sin teléfono y respira durante 4 minutos',
      'de': 'Kein Handy und 4 Minuten atmen',
      'en': 'No phone and breathe for 4 minutes',
    },
    'No screens for the next 10 minutes': {
      'tr': 'Önümüzdeki 10 dakika ekran yok',
      'es': 'Sin pantallas durante los próximos 10 minutos',
      'de': 'Für die nächsten 10 Minuten keine Bildschirme',
      'en': 'No screens for the next 10 minutes',
    },
    'Do 4-7-8 breathing for 3 minutes': {
      'tr': '3 dakika 4-7-8 nefesi yap',
      'es': 'Haz respiración 4-7-8 durante 3 minutos',
      'de': 'Mache 3 Minuten lang 4-7-8-Atmung',
      'en': 'Do 4-7-8 breathing for 3 minutes',
    },
    'Prepare tomorrow with 2 bullet points': {
      'tr': 'Yarını 2 maddeyle hazırla',
      'es': 'Prepara mañana con 2 puntos',
      'de': 'Bereite morgen mit 2 Stichpunkten vor',
      'en': 'Prepare tomorrow with 2 bullet points',
    },
    'Box breathe for 2 minutes': {
      'tr': '2 dakika kutu nefesi yap',
      'es': 'Haz respiración en caja durante 2 minutos',
      'de': 'Mache 2 Minuten Box-Atmung',
      'en': 'Box breathe for 2 minutes',
    },
    'Release shoulder tension for 90 seconds': {
      'tr': '90 saniye omuz gerginliğini bırak',
      'es': 'Libera la tensión de los hombros durante 90 segundos',
      'de': 'Löse 90 Sekunden lang Schulterspannung',
      'en': 'Release shoulder tension for 90 seconds',
    },
    'Write one thing you can control': {
      'tr': 'Kontrol edebileceğin bir şeyi yaz',
      'es': 'Escribe una cosa que puedas controlar',
      'de': 'Schreibe eine Sache auf, die du kontrollieren kannst',
      'en': 'Write one thing you can control',
    },
    'Quick body + breath routine to downshift stress.': {
      'tr': 'Stresi düşürmek için hızlı beden + nefes rutini.',
      'es': 'Rutina rápida de cuerpo y respiración para bajar el estrés.',
      'de': 'Schnelle Körper- und Atemroutine, um Stress herunterzufahren.',
      'en': 'Quick body + breath routine to downshift stress.',
    },
    'Slow exhale breathing for 2 minutes': {
      'tr': '2 dakika yavaş veriş nefesi yap',
      'es': 'Haz respiración con exhalación lenta durante 2 minutos',
      'de': 'Atme 2 Minuten lang mit langsamer Ausatmung',
      'en': 'Slow exhale breathing for 2 minutes',
    },
    'Neck and shoulder release for 3 minutes': {
      'tr': '3 dakika boyun ve omuz gevşetme yap',
      'es': 'Haz una liberación de cuello y hombros durante 3 minutos',
      'de': 'Mache 3 Minuten Nacken- und Schulterlockerung',
      'en': 'Neck and shoulder release for 3 minutes',
    },
    'Note one pressure you can postpone': {
      'tr': 'Erteleyebileceğin bir baskıyı not et',
      'es': 'Anota una presión que puedas posponer',
      'de': 'Notiere einen Druck, den du verschieben kannst',
      'en': 'Note one pressure you can postpone',
    },
    'Morning Reset': {
      'tr': 'Sabah Reset',
      'es': 'Reinicio matutino',
      'de': 'Morgen-Reset',
      'en': 'Morning Reset',
    },
    'A low-friction start to regain momentum in under 10 minutes.': {
      'tr':
          '10 dakikadan kısa sürede momentumu geri kazanmak için sürtünmesiz başlangıç.',
      'es':
          'Un comienzo de baja fricción para recuperar el impulso en menos de 10 minutos.',
      'de':
          'Ein reibungsarmer Start, um in unter 10 Minuten wieder Momentum zu gewinnen.',
      'en': 'A low-friction start to regain momentum in under 10 minutes.',
    },
    'Open curtains and take 5 deep breaths': {
      'tr': 'Perdeleri aç ve 5 derin nefes al',
      'es': 'Abre las cortinas y toma 5 respiraciones profundas',
      'de': 'Öffne die Vorhänge und nimm 5 tiefe Atemzüge',
      'en': 'Open curtains and take 5 deep breaths',
    },
    'Write one tiny win target for today': {
      'tr': 'Bugün için küçük bir kazanım hedefi yaz',
      'es': 'Escribe un pequeño objetivo de victoria para hoy',
      'de': 'Schreibe ein kleines Erfolgsziel für heute auf',
      'en': 'Write one tiny win target for today',
    },
    'Do a 4-minute start sprint on your top task': {
      'tr': 'En önemli görevinde 4 dakikalık başlangıç sprinti yap',
      'es': 'Haz un sprint inicial de 4 minutos en tu tarea principal',
      'de':
          'Mache einen 4-minütigen Start-Sprint bei deiner wichtigsten Aufgabe',
      'en': 'Do a 4-minute start sprint on your top task',
    },
    'Walk Boost': {
      'tr': 'Yürüyüş Boost',
      'es': 'Impulso de caminata',
      'de': 'Geh-Boost',
      'en': 'Walk Boost',
    },
    'Body-first micro routine to break mental fog quickly.': {
      'tr': 'Zihinsel sisi hızlıca dağıtmak için beden odaklı mikro rutin.',
      'es':
          'Micro rutina centrada en el cuerpo para romper rápidamente la niebla mental.',
      'de':
          'Körperfokussierte Mikroroutine, um mentalen Nebel schnell zu lösen.',
      'en': 'Body-first micro routine to break mental fog quickly.',
    },
    'Walk for 4 minutes without your phone': {
      'tr': 'Telefon olmadan 4 dakika yürü',
      'es': 'Camina 4 minutos sin tu teléfono',
      'de': 'Gehe 4 Minuten ohne dein Handy',
      'en': 'Walk for 4 minutes without your phone',
    },
    'Drink water and relax jaw tension': {
      'tr': 'Su iç ve çene gerginliğini gevşet',
      'es': 'Bebe agua y relaja la tensión de la mandíbula',
      'de': 'Trink Wasser und löse die Kieferspannung',
      'en': 'Drink water and relax jaw tension',
    },
    'Take 90-second long exhales': {
      'tr': '90 saniye uzun verişler yap',
      'es': 'Haz exhalaciones largas durante 90 segundos',
      'de': 'Mache 90 Sekunden lange Ausatmungen',
      'en': 'Take 90-second long exhales',
    },
    'Evening Shutdown': {
      'tr': 'Akşam Kapanışı',
      'es': 'Cierre nocturno',
      'de': 'Abendabschluss',
      'en': 'Evening Shutdown',
    },
    'Close the day with light planning and calm transition.': {
      'tr': 'Günü hafif planlama ve sakin geçişle kapat.',
      'es':
          'Cierra el día con planificación ligera y una transición tranquila.',
      'de': 'Beende den Tag mit leichter Planung und ruhigem Übergang.',
      'en': 'Close the day with light planning and calm transition.',
    },
    'Write tomorrow top priority in one line': {
      'tr': 'Yarının en önemli işini tek satırda yaz',
      'es': 'Escribe la prioridad principal de mañana en una línea',
      'de': 'Schreibe die wichtigste Aufgabe für morgen in einer Zeile auf',
      'en': 'Write tomorrow top priority in one line',
    },
    'Do gentle neck release for 2 minutes': {
      'tr': '2 dakika nazik boyun gevşetme yap',
      'es': 'Haz una suave liberación de cuello durante 2 minutos',
      'de': 'Mache 2 Minuten sanfte Nackenlockerung',
      'en': 'Do gentle neck release for 2 minutes',
    },
    'Sit quietly with slow breathing for 3 minutes': {
      'tr': '3 dakika yavaş nefesle sessizce otur',
      'es': 'Siéntate en silencio con respiración lenta durante 3 minutos',
      'de': 'Sitze 3 Minuten ruhig mit langsamer Atmung',
      'en': 'Sit quietly with slow breathing for 3 minutes',
    },
  };

  String categoryBadgeLabel(String category) {
    switch (_code) {
      case 'tr':
        switch (category) {
          case 'health':
            return 'SAĞLIK';
          case 'growth':
            return 'GELİŞİM';
          case 'body':
            return 'VÜCUT';
          case 'calm':
            return 'SAKİN';
          case 'mind':
          default:
            return 'ZİHİN';
        }
      case 'es':
        switch (category) {
          case 'health':
            return 'SALUD';
          case 'growth':
            return 'CRECER';
          case 'body':
            return 'CUERPO';
          case 'calm':
            return 'CALMA';
          case 'mind':
          default:
            return 'MENTE';
        }
      case 'de':
        switch (category) {
          case 'health':
            return 'GESUND';
          case 'growth':
            return 'WACHSTUM';
          case 'body':
            return 'KÖRPER';
          case 'calm':
            return 'RUHE';
          case 'mind':
          default:
            return 'GEIST';
        }
      default:
        switch (category) {
          case 'health':
            return 'HEALTH';
          case 'growth':
            return 'GROWTH';
          case 'body':
            return 'BODY';
          case 'calm':
            return 'CALM';
          case 'mind':
          default:
            return 'MIND';
        }
    }
  }

  // Onboarding Strings
  String get onboardingGoalTitle {
    switch (_code) {
      case 'tr':
        return 'Sparkio\'ya seni ne getirdi?';
      case 'es':
        return '¿Qué te trae a Sparkio?';
      case 'de':
        return 'Was führt dich zu Sparkio?';
      default:
        return 'What brings you to Sparkio?';
    }
  }

  String get onboardingGoalSubtitle {
    switch (_code) {
      case 'tr':
        return 'Motoru ihtiyaçlarına göre uyarlayacağız.';
      case 'es':
        return 'Adaptaremos el motor a tus necesidades.';
      case 'de':
        return 'Wir passen die Engine deinen Bedürfnissen an.';
      default:
        return 'We will adapt the engine to your needs.';
    }
  }

  String get goalConsistency {
    switch (_code) {
      case 'tr':
        return 'Tutarlılık Kur';
      case 'es':
        return 'Crear constancia';
      case 'de':
        return 'Konstanz aufbauen';
      default:
        return 'Build Consistency';
    }
  }

  String get goalBurnout {
    switch (_code) {
      case 'tr':
        return 'Tükenmişliği Azalt';
      case 'es':
        return 'Reducir agotamiento';
      case 'de':
        return 'Burnout reduzieren';
      default:
        return 'Reduce Burnout';
    }
  }

  String get goalFocus {
    switch (_code) {
      case 'tr':
        return 'Derin Odaklanma';
      case 'es':
        return 'Enfoque profundo';
      case 'de':
        return 'Tiefer Fokus';
      default:
        return 'Deep Focus';
    }
  }

  String get onboardingNameTitle {
    switch (_code) {
      case 'tr':
        return 'Her harika yolculuk bir isimle başlar.';
      case 'es':
        return 'Todo gran viaje comienza con un nombre.';
      case 'de':
        return 'Jede große Reise beginnt mit einem Namen.';
      default:
        return 'Every great journey starts with a name.';
    }
  }

  String get onboardingNameSubtitle {
    switch (_code) {
      case 'tr':
        return 'Sana nasıl hitap etmemizi istersin?';
      case 'es':
        return '¿Cómo deberíamos llamarte?';
      case 'de':
        return 'Wie dürfen wir dich nennen?';
      default:
        return 'What should your companion call you?';
    }
  }

  String get onboardingNameHint {
    switch (_code) {
      case 'tr':
        return 'Senin adın';
      case 'es':
        return 'Tu nombre';
      case 'de':
        return 'Dein Name';
      default:
        return 'Your name';
    }
  }

  String get beginJourney {
    switch (_code) {
      case 'tr':
        return 'Yolculuğuma Başla';
      case 'es':
        return 'Comenzar mi viaje';
      case 'de':
        return 'Meine Reise beginnen';
      default:
        return 'Begin My Journey';
    }
  }

  String get onboardingContinue {
    switch (_code) {
      case 'tr':
        return 'Devam Et';
      case 'es':
        return 'Continuar';
      case 'de':
        return 'Weiter';
      default:
        return 'Continue';
    }
  }

  String get generatingAnalyzing {
    switch (_code) {
      case 'tr':
        return 'Hedeflerin analiz ediliyor...';
      case 'es':
        return 'Analizando tus objetivos...';
      case 'de':
        return 'Deine Ziele analysieren...';
      default:
        return 'Analyzing your goals...';
    }
  }

  String get generatingCalibrating {
    switch (_code) {
      case 'tr':
        return 'Adaptif motor kalibre ediliyor...';
      case 'es':
        return 'Calibrando motor adaptativo...';
      case 'de':
        return 'Adaptive Engine kalibrieren...';
      default:
        return 'Calibrating adaptive engine...';
    }
  }

  String get generatingBuilding {
    switch (_code) {
      case 'tr':
        return 'Kişiselleştirilmiş rutinin inşa ediliyor...';
      case 'es':
        return 'Construyendo tu rutina personalizada...';
      case 'de':
        return 'Deine personalisierte Routine aufbauen...';
      default:
        return 'Building your personalized routine...';
    }
  }

  String get generatingReady {
    switch (_code) {
      case 'tr':
        return 'Hazır.';
      case 'es':
        return 'Listo.';
      case 'de':
        return 'Bereit.';
      default:
        return 'Ready.';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
