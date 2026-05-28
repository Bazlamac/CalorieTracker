import 'package:isar/isar.dart';

part 'UserProfile.g.dart';

@collection
class UserProfile {
  Id id = 1;

  double weight = 0;
  double height = 0;
  int age = 0;
  String gender = 'male';

  DateTime updatedAt = DateTime.now();
}
