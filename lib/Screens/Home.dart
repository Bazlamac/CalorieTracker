import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../Controls/CalorieCont.dart';
import '../Models/DailyEntry.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CalorieController calorieController = Get.find();

  bool showGainedDetails = false;
  bool showBurnedDetails = false;

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _showEditEntrySheet(DailyEntry entry) async {
    final amountController = TextEditingController(text: entry.amount.toString());
    final noteController = TextEditingController(text: entry.note);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.isBurned ? 'Yakılan Kaydı Düzenle' : 'Alınan Kaydı Düzenle',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Kalori',
                  suffixText: 'kcal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Not',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountController.text);
                    final note = noteController.text.trim();

                    if (amount == null || amount <= 0 || note.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen geçerli değerler girin'),
                        ),
                      );
                      return;
                    }

                    await calorieController.updateEntry(
                      entry: entry,
                      amount: amount,
                      note: note,
                    );

                    Navigator.of(context).pop();
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        );
      },
    );

    amountController.dispose();
    noteController.dispose();
  }

  Future<void> _confirmDelete(DailyEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu kaydı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      await calorieController.deleteEntry(entry);
    }
  }

  Widget _buildEntryList({
    required List<DailyEntry> entries,
    required bool isBurned,
  }) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 12),
        child: Text(
          'Bugün kayıt yok',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isBurned ? Icons.directions_run : Icons.fastfood,
              color: isBurned ? Colors.blue : Colors.orange,
            ),
            title: Text(entry.note),
            subtitle: Text('Saat: ${_formatTime(entry.createdAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.amount} kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBurned ? Colors.blue : Colors.orange,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditEntrySheet(entry);
                    } else if (value == 'delete') {
                      _confirmDelete(entry);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Düzenle'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bugünün Özeti',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(() => InkWell(
                  onTap: () {
                    setState(() => showGainedDetails = !showGainedDetails);
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.fastfood,
                        color: Colors.orange,
                        size: 40,
                      ),
                      title: const Text(
                        'Alınan Kalori',
                        style: TextStyle(fontSize: 18),
                      ),
                      trailing: Text(
                        '${calorieController.caloriesGained} kcal',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                )),
            if (showGainedDetails)
              Obx(() => _buildEntryList(
                    entries: calorieController.todayGainedEntries,
                    isBurned: false,
                  )),
            const SizedBox(height: 16),
            Obx(() {
              final bmrValue = calorieController.bmr.value ?? 0;
              final burned = calorieController.effectiveBurned;
              return InkWell(
                onTap: () {
                  setState(() => showBurnedDetails = !showBurnedDetails);
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(
                      Icons.directions_run,
                      color: Colors.blue,
                      size: 40,
                    ),
                    title: const Text(
                      'Yakılan Kalori',
                      style: TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      bmrValue > 0 ? 'BMR: $bmrValue kcal' : 'BMR bilgisi yok',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    trailing: Text(
                      '$burned kcal',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (showBurnedDetails)
              Obx(() {
                final bmrValue = calorieController.bmr.value ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bmrValue > 0)
                      Card(
                        color: Colors.blue.shade50,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.local_fire_department,
                            color: Colors.blue,
                          ),
                          title: const Text('Bazal Metabolizma'),
                          trailing: Text('$bmrValue kcal'),
                        ),
                      ),
                    _buildEntryList(
                      entries: calorieController.todayBurnedEntries,
                      isBurned: true,
                    ),
                  ],
                );
              }),
            const SizedBox(height: 16),
            Obx(() {
              bool isWarning = calorieController.netCalories > 2000;
              return Card(
                color: isWarning ? Colors.red.shade100 : Colors.green.shade100,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: const Text(
                    'Net Kalori Durumu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    '${calorieController.netCalories} kcal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isWarning ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
