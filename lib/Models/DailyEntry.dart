import 'package:isar/isar.dart';

part 'DailyEntry.g.dart';

@collection
class DailyEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late DateTime createdAt;

  late int amount;

  late String note;

  late bool isBurned;
}
