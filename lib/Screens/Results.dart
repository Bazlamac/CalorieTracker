import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controls/CalorieCont.dart';

class Results extends StatefulWidget {
  const Results({super.key});

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  final CalorieController calorieController = Get.find();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İstatistikler',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Haftalık Özet Kartı
            FutureBuilder<Map<String, dynamic>>(
              future: calorieController.getWeeklyStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? {};
                final average = data['average'] ?? 0;
                final count = data['count'] ?? 0;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_view_week,
                      color: Colors.purple,
                      size: 36,
                    ),
                    title: const Text(
                      'Bu Haftanın Ortalaması',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      count > 0 ? '$count günün ortalaması' : 'Veri yok',
                    ),
                    trailing: Text(
                      '$average kcal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Aylık Özet Kartı
            FutureBuilder<Map<String, dynamic>>(
              future: calorieController.getMonthlyStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? {};
                final average = data['average'] ?? 0;
                final count = data['count'] ?? 0;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_month,
                      color: Colors.teal,
                      size: 36,
                    ),
                    title: const Text(
                      'Bu Ayın Ortalaması',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      count > 0 ? '$count günün ortalaması' : 'Veri yok',
                    ),
                    trailing: Text(
                      '$average kcal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Haftalık Detaylar
            const Text(
              'Haftalık Detay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: calorieController.getWeeklyData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final weekData = snapshot.data ?? [];

                return Expanded(
                  child: ListView.builder(
                    itemCount: weekData.length,
                    itemBuilder: (context, index) {
                      final day = weekData[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${day['dayName']} - ${day['date'].day}/${day['date'].month}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '+ ${day['gained']} ',
                                style: const TextStyle(color: Colors.orange),
                              ),
                              Text(
                                '- ${day['burned']}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${day['net']} kcal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: day['net'] > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
