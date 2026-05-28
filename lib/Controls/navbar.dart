import 'package:get/get.dart';

class NavController extends GetxController {
  // Varsayılan olarak 0. indeks (Home) seçili
  var selectedIndex = 0.obs;

  // Menüye tıklandığında indeksi değiştirecek fonksiyon
  void changePage(int index) {
    selectedIndex.value = index;
  }
}