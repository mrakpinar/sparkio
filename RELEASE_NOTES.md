# Sparkio Release Notes

## 1.0.17+36 (2026-11-12)

- Uygulama logosu, platform ikonları ve açılış görselleri yenilendi.
- Plus Jakarta Sans yazı tipi, sade kartlar, artırılmış kontrast ve mercan ödül vurguları eklendi.
- Ruh hali / hızlı destek ekranının kart düzeni, ikonları ve boşlukları iyileştirildi.
- Eski günlük görevlerin eksik atama kimlikleri kalıcı olarak doldurularak tamamlanabilmeleri sağlandı.

## 1.0.16+35 (2026-11-10)

- Google Play Faturalandırma Kütüphanesi `7.1.1` sürümünden `8.0.0` sürümüne yükseltildi (`in_app_purchase` `3.3.1`, Android paketi `0.5.0`).
- Play Console'a yüklemek için Android sürüm kodu 35'e yükseltildi.

## 1.0.8+26 (2026-02-28)

- Android hotfix: uygulama yeniden açıldığında bitmiş aktif görev kartının bazen hatalı şekilde `Begin now` göstermesi düzeltildi.
- Restore edilen task timer state'i artık ana kartta doğru öncelikle gösteriliyor.
- Timer bitmişse kart artık doğru şekilde `Mark complete` aksiyonunu sunuyor.

## 1.0.4+22 (2026-02-18)

- Home deneyimi ve görev kartları premium hissiyat için kapsamlı görsel/motion iyileştirmeleriyle güncellendi.
- "How are you feeling?" sheet’i yeniden tasarlandı:
  - Yeni başlık dili, daha güçlü backdrop/atmosfer, suggested kart mantığı ve kart hiyerarşisi iyileştirildi.
  - Kart etkileşimleri, metin yapısı, chip/ikon dengesi ve mikro motion detayları revize edildi.
- Task tamamlanma akışı güncellendi:
  - Snackbar kaldırıldı.
  - Completed/all-done kart ve modal dili, hiyerarşisi ve görsel tonu sadeleştirildi.
- XP ve seviye sistemi geliştirildi; seviye atlamada kullanıcıya bilgilendirme ekranı eklendi.
- Stats, weekly plan, premium sheet, drawer ve badge ekranlarında:
  - Daha sakin hiyerarşi,
  - Daha az teknik dil,
  - Daha tutarlı yüzey/spacing/motion yaklaşımı uygulandı.
- Share görseli story formatına taşındı:
  - Minimal 4 öğeli kurgu (küçük marka, hero day/streak, proof, duygu cümlesi),
  - Atmosferik arka plan, mikro grain ve editorial tipografi düzeni eklendi.
- Debug modunda (`--dart-define=SHOW_DEBUG_TOOLS=true`) ana ekrana hızlı test amaçlı task ekleme butonu desteği eklendi.
