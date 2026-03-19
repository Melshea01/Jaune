import 'package:flutter/foundation.dart';

class ValidationService {
  /// Valide qu'une date est dans un format valide (yyyy-MM-dd)
  static bool isValidDateKey(String dateKey) {
    if (dateKey.length != 10) return false;
    try {
      final date = DateTime.parse(dateKey);
      return dateKey == date.toIso8601String().substring(0, 10);
    } catch (_) {
      return false;
    }
  }

  /// Valide qu'un nombre de consommations est raisonnable
  static bool isValidConsumptionCount(int count) {
    return count >= 0 && count <= 50; // limite raisonnable
  }

  /// Valide qu'un pourcentage de santé est dans la bonne plage
  static bool isValidHealthPercent(double percent) {
    return percent >= 0.0 && percent <= 1.0 && !percent.isNaN;
  }

  /// Valide qu'un niveau de personnage est valide
  static bool isValidLevel(int level) {
    return level >= 1 && level <= 100; // limite raisonnable
  }

  /// Valide qu'un montant d'XP est valide
  static bool isValidXp(int xp) {
    return xp >= 0 && xp < 100; // XP doit être < 100 (sinon level up)
  }

  /// Nettoie une map de consommations quotidiennes en supprimant les entrées invalides
  static Map<String, int> cleanDailyMap(Map<String, int> dailyMap) {
    final Map<String, int> cleaned = {};

    dailyMap.forEach((dateKey, consos) {
      if (isValidDateKey(dateKey) && isValidConsumptionCount(consos)) {
        cleaned[dateKey] = consos;
      } else {
        debugPrint('Removing invalid entry: $dateKey -> $consos');
      }
    });

    return cleaned;
  }

  /// Valide qu'une date n'est pas dans le futur
  static bool isNotFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return !checkDate.isAfter(today);
  }

  /// Valide qu'une date n'est pas trop ancienne (ex: plus de 2 ans)
  static bool isNotTooOld(DateTime date, {int maxAgeInDays = 730}) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    return difference <= maxAgeInDays;
  }

  /// Validation complète d'une entrée de consommation
  static ValidationResult validateConsumptionEntry(String dateKey, int consos) {
    final List<String> errors = [];

    if (!isValidDateKey(dateKey)) {
      errors.add('Format de date invalide: $dateKey');
    } else {
      final date = DateTime.parse(dateKey);
      if (!isNotFutureDate(date)) {
        errors.add('La date ne peut pas être dans le futur');
      }
      if (!isNotTooOld(date)) {
        errors.add('La date est trop ancienne (> 2 ans)');
      }
    }

    if (!isValidConsumptionCount(consos)) {
      errors.add('Nombre de consommations invalide: $consos');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Calcule des statistiques de santé des données
  static DataHealthStats calculateDataHealth(Map<String, int> dailyMap) {
    int totalEntries = dailyMap.length;
    int validEntries = 0;
    int futureEntries = 0;
    int oldEntries = 0;
    int invalidConsosEntries = 0;

    dailyMap.forEach((dateKey, consos) {
      bool isValidEntry = true;

      if (!isValidDateKey(dateKey)) {
        isValidEntry = false;
      } else {
        final date = DateTime.parse(dateKey);
        if (!isNotFutureDate(date)) {
          futureEntries++;
          isValidEntry = false;
        }
        if (!isNotTooOld(date)) {
          oldEntries++;
          isValidEntry = false;
        }
      }

      if (!isValidConsumptionCount(consos)) {
        invalidConsosEntries++;
        isValidEntry = false;
      }

      if (isValidEntry) {
        validEntries++;
      }
    });

    return DataHealthStats(
      totalEntries: totalEntries,
      validEntries: validEntries,
      futureEntries: futureEntries,
      oldEntries: oldEntries,
      invalidConsosEntries: invalidConsosEntries,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

class DataHealthStats {
  final int totalEntries;
  final int validEntries;
  final int futureEntries;
  final int oldEntries;
  final int invalidConsosEntries;

  DataHealthStats({
    required this.totalEntries,
    required this.validEntries,
    required this.futureEntries,
    required this.oldEntries,
    required this.invalidConsosEntries,
  });

  double get validityPercent =>
      totalEntries > 0 ? validEntries / totalEntries : 1.0;

  bool get isHealthy => validityPercent > 0.95;

  List<String> get issues {
    final List<String> issues = [];
    if (futureEntries > 0) {
      issues.add('$futureEntries entrées dans le futur');
    }
    if (oldEntries > 0) {
      issues.add('$oldEntries entrées trop anciennes');
    }
    if (invalidConsosEntries > 0) {
      issues.add('$invalidConsosEntries valeurs de consommation invalides');
    }
    return issues;
  }
}
