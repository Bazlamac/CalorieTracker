import 'package:isar/isar.dart';

part 'FavoriteEntry.g.dart';

@collection
class FavoriteEntry {
  Id id = Isar.autoIncrement;

  late String title;
  late int amount;
  late bool isBurned;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
