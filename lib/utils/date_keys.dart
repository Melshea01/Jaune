/// Source unique de vérité pour les clés de date de l'app.
///
/// Avant cet utilitaire, quatre implémentations coexistaient
/// (CharacterService._dateKey, StorageService._dateToKey, des
/// `toIso8601String().substring(0, 10)` inline dans le calendrier,
/// et _isSameDay dans main) — un changement de format aurait
/// silencieusement corrompu les données.
library;

/// Clé canonique 'yyyy-MM-dd' en heure locale.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Vrai si [a] et [b] tombent le même jour calendaire local.
bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
