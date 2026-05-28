import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Controls/navbar.dart';
import '../Controls/CalorieCont.dart';
import 'Home.dart';
import 'Adding.dart';
import 'Results.dart';
import 'Profile.dart';
import 'Favorites.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final NavController navController = Get.put(NavController());
    Get.put(CalorieController());

    final List<Widget> screens = [
      Home(),
      const Adding(),
      const Results(),
      const Profile(),
      const Favorites(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Kalori Kontrol',style: TextStyle(fontWeight: FontWeight.bold,color: Color.fromARGB(255, 0, 0, 0)),),
        elevation: 0
    
        
      ),
      body: Obx(() => screens[navController.selectedIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: navController.selectedIndex.value,
          onTap: navController.changePage,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Ekle',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'İstatistikler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Favoriler',
            ),
          ],
        ),
      ),
    );
  }
}
