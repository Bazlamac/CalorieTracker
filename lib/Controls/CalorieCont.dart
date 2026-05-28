import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../Models/DailyEntry.dart';
import '../Models/DailyRecords.dart';
import '../Models/FavoriteEntry.dart';
import '../Models/UserProfile.dart';

class CalorieController extends GetxController {
  late Isar isar; // Veritabanı bağlantımız

  var caloriesGained = 0.obs;
  var caloriesBurned = 0.obs;

  final RxnInt bmr = RxnInt();
  final Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  final RxList<DailyEntry> todayGainedEntries = <DailyEntry>[].obs;
  final RxList<DailyEntry> todayBurnedEntries = <DailyEntry>[].obs;
  final RxList<FavoriteEntry> favorites = <FavoriteEntry>[].obs;

  int get effectiveBurned => caloriesBurned.value + (bmr.value ?? 0);
  int get netCalories => caloriesGained.value - effectiveBurned;

  // Uygulama açıldığında çalışacak ilk fonksiyon
  @override
  void onInit() {
    super.onInit();
    _initDatabase();
  }

  // Veritabanını başlatma ve bugünün verilerini çekme
  Future<void> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        DailyRecordSchema,
        UserProfileSchema,
        DailyEntrySchema,
        FavoriteEntrySchema,
      ],
      directory: dir.path,
    );
    await _loadTodayData();
    await _loadUserProfile();
    await _loadTodayEntries();
    await _loadFavorites();
  }

  // Sadece bugünün tarihini (saat/dakika olmadan) almak için yardımcı fonksiyon
  DateTime _getTodayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Bugünün verisini veritabanından okuma
  Future<void> _loadTodayData() async {
    final today = _getTodayMidnight();

    // Veritabanında bugünün tarihiyle eşleşen kaydı bul
    final record = await isar.dailyRecords
        .where()
        .dateEqualTo(today)
        .findFirst();

    if (record != null) {
      caloriesGained.value = record.caloriesGained;
      caloriesBurned.value = record.caloriesBurned;
    } else {
      caloriesGained.value = 0;
      caloriesBurned.value = 0;
    }
  }

  Future<void> _loadTodayEntries() async {
    final today = _getTodayMidnight();
    final entries = await isar.dailyEntrys
        .where()
        .dateEqualTo(today)
        .findAll();

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    todayGainedEntries.assignAll(entries.where((e) => !e.isBurned));
    todayBurnedEntries.assignAll(entries.where((e) => e.isBurned));
  }

  Future<void> _loadFavorites() async {
    final items = await isar.favoriteEntrys.where().findAll();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    favorites.assignAll(items);
  }

  Future<void> _loadUserProfile() async {
    final profile = await isar.userProfiles.get(1);
    if (profile != null) {
      userProfile.value = profile;
      bmr.value = _calculateBmr(profile);
    }
  }

  // Veritabanına kaydetme / Güncelleme işlemi
  Future<void> _saveToDatabase() async {
    final today = _getTodayMidnight();

    final newRecord = DailyRecord()
      ..date = today
      ..caloriesGained = caloriesGained.value
      ..caloriesBurned = caloriesBurned.value;

    // writeTxn (Transaction), veritabanına veri yazarken mecburidir
    await isar.writeTxn(() async {
      await isar.dailyRecords.put(
        newRecord,
      ); // Varsa günceller, yoksa yeni ekler
    });
  }

  // Ekleme metodları (Hem ekranda günceller hem de veritabanına yazar)
  void addCalories(int amount) {
    caloriesGained.value += amount;
    _saveToDatabase();
  }

  void burnCalories(int amount) {
    caloriesBurned.value += amount;
    _saveToDatabase();
  }

  Future<void> addEntry({
    required int amount,
    required String note,
    required bool isBurned,
  }) async {
    final today = _getTodayMidnight();
    final entry = DailyEntry()
      ..date = today
      ..createdAt = DateTime.now()
      ..amount = amount
      ..note = note
      ..isBurned = isBurned;

    await isar.writeTxn(() async {
      final record =
          await isar.dailyRecords.where().dateEqualTo(today).findFirst();
      final daily = record ?? (DailyRecord()..date = today);

      if (isBurned) {
        daily.caloriesBurned += amount;
      } else {
        daily.caloriesGained += amount;
      }

      await isar.dailyRecords.put(daily);
      await isar.dailyEntrys.put(entry);
    });

    if (isBurned) {
      caloriesBurned.value += amount;
    } else {
      caloriesGained.value += amount;
    }

    await _loadTodayEntries();
  }

  Future<void> updateEntry({
    required DailyEntry entry,
    required int amount,
    required String note,
  }) async {
    final delta = amount - entry.amount;
    final entryDate = entry.date;

    await isar.writeTxn(() async {
      final record =
          await isar.dailyRecords.where().dateEqualTo(entryDate).findFirst();
      final daily = record ?? (DailyRecord()..date = entryDate);

      if (entry.isBurned) {
        daily.caloriesBurned =
            math.max(0, daily.caloriesBurned + delta);
      } else {
        daily.caloriesGained =
            math.max(0, daily.caloriesGained + delta);
      }

      entry.amount = amount;
      entry.note = note;
      await isar.dailyEntrys.put(entry);
      await isar.dailyRecords.put(daily);
    });

    if (entryDate == _getTodayMidnight()) {
      if (entry.isBurned) {
        caloriesBurned.value =
            math.max(0, caloriesBurned.value + delta);
      } else {
        caloriesGained.value =
            math.max(0, caloriesGained.value + delta);
      }
      await _loadTodayEntries();
    }
  }

  Future<void> deleteEntry(DailyEntry entry) async {
    final entryDate = entry.date;

    await isar.writeTxn(() async {
      final record =
          await isar.dailyRecords.where().dateEqualTo(entryDate).findFirst();
      if (record != null) {
        if (entry.isBurned) {
          record.caloriesBurned =
              math.max(0, record.caloriesBurned - entry.amount);
        } else {
          record.caloriesGained =
              math.max(0, record.caloriesGained - entry.amount);
        }
        await isar.dailyRecords.put(record);
      }
      await isar.dailyEntrys.delete(entry.id);
    });

    if (entryDate == _getTodayMidnight()) {
      if (entry.isBurned) {
        caloriesBurned.value =
            math.max(0, caloriesBurned.value - entry.amount);
      } else {
        caloriesGained.value =
            math.max(0, caloriesGained.value - entry.amount);
      }
      await _loadTodayEntries();
    }
  }

  Future<void> addFavorite({
    required String title,
    required int amount,
    required bool isBurned,
  }) async {
    final favorite = FavoriteEntry()
      ..title = title
      ..amount = amount
      ..isBurned = isBurned
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.favoriteEntrys.put(favorite);
    });

    await _loadFavorites();
  }

  Future<void> updateFavorite({
    required FavoriteEntry favorite,
    required String title,
    required int amount,
    required bool isBurned,
  }) async {
    favorite
      ..title = title
      ..amount = amount
      ..isBurned = isBurned
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.favoriteEntrys.put(favorite);
    });

    await _loadFavorites();
  }

  Future<void> deleteFavorite(FavoriteEntry favorite) async {
    await isar.writeTxn(() async {
      await isar.favoriteEntrys.delete(favorite.id);
    });

    await _loadFavorites();
  }

  Future<void> saveUserProfile({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) async {
    final profile = UserProfile()
      ..id = 1
      ..weight = weight
      ..height = height
      ..age = age
      ..gender = gender
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.userProfiles.put(profile);
    });

    userProfile.value = profile;
    bmr.value = _calculateBmr(profile);
  }

  int? _calculateBmr(UserProfile profile) {
    if (profile.weight <= 0 || profile.height <= 0 || profile.age <= 0) {
      return null;
    }

    final weight = profile.weight;
    final height = profile.height;
    final age = profile.age;

    if (profile.gender == 'female') {
      return (447.593 +
              (9.247 * weight) +
              (3.098 * height) -
              (4.330 * age))
          .round();
    }

    return (88.362 +
            (13.397 * weight) +
            (4.799 * height) -
            (5.677 * age))
        .round();
  }

  // Haftalık istatistikler (son 7 günün ortalaması)
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final today = _getTodayMidnight();
    final weekAgo = today.subtract(const Duration(days: 7));
    final bmrValue = bmr.value ?? 0;

    final records = await isar.dailyRecords
        .where()
        .dateBetween(weekAgo, today, includeUpper: true)
        .findAll();

    if (records.isEmpty) {
      return {'average': 0, 'count': 0, 'records': []};
    }

    int totalNetCalories = 0;
    int totalBurned = 0;
    for (final record in records) {
      totalNetCalories +=
          (record.caloriesGained - (record.caloriesBurned + bmrValue));
      totalBurned += (record.caloriesBurned + bmrValue);
    }

    return {
      'average': (totalNetCalories ~/ records.length).abs(),
      'count': records.length,
      'records': records,
      'totalGained': records.fold<int>(0, (sum, r) => sum + r.caloriesGained),
      'totalBurned': totalBurned,
    };
  }

  // Aylık istatistikler (son 30 günün ortalaması)
  Future<Map<String, dynamic>> getMonthlyStats() async {
    final today = _getTodayMidnight();
    final monthAgo = today.subtract(const Duration(days: 30));
    final bmrValue = bmr.value ?? 0;

    final records = await isar.dailyRecords
        .where()
        .dateBetween(monthAgo, today, includeUpper: true)
        .findAll();

    if (records.isEmpty) {
      return {'average': 0, 'count': 0, 'records': []};
    }

    int totalNetCalories = 0;
    int totalBurned = 0;
    for (final record in records) {
      totalNetCalories +=
          (record.caloriesGained - (record.caloriesBurned + bmrValue));
      totalBurned += (record.caloriesBurned + bmrValue);
    }

    return {
      'average': (totalNetCalories ~/ records.length).abs(),
      'count': records.length,
      'records': records,
      'totalGained': records.fold<int>(0, (sum, r) => sum + r.caloriesGained),
      'totalBurned': totalBurned,
    };
  }

  // Haftalık (günlük) veriler (grafik için)
  Future<List<Map<String, dynamic>>> getWeeklyData() async {
    final today = _getTodayMidnight();
    final weekAgo = today.subtract(
      const Duration(days: 6),
    ); // Bugün dahil 7 gün
    final bmrValue = bmr.value ?? 0;

    final records = await isar.dailyRecords
        .where()
        .dateBetween(weekAgo, today, includeUpper: true)
        .findAll();

    final weekData = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final record = records.firstWhere(
        (r) => r.date == date,
        orElse: () => DailyRecord()
          ..date = date
          ..caloriesGained = 0
          ..caloriesBurned = 0,
      );

      final burned = record.caloriesBurned + bmrValue;
      weekData.add({
        'date': date,
        'gained': record.caloriesGained,
        'burned': burned,
        'net': record.caloriesGained - burned,
        'dayName': [
          'Pzt',
          'Salı',
          'Çarş',
          'Perş',
          'Cuma',
          'Ctsi',
          'Pazar',
        ][date.weekday - 1],
      });
    }

    return weekData;
  }
}
