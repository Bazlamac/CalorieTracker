import 'package:isar/isar.dart';

// Bu satır hata verecek, endişelenme. Birazdan terminalden bir komutla bu dosyayı üreteceğiz.
part 'DailyRecords.g.dart'; 

@collection
class DailyRecord {
  // Her kaydın benzersiz bir ID'si olmak zorundadır.
  Id id = Isar.autoIncrement;

  // Aynı güne birden fazla kayıt açmamak için tarihi benzersiz (unique) yapıyoruz
  @Index(unique: true, replace: true) 
  late DateTime date;

  int caloriesGained = 0;
  int caloriesBurned = 0;
}