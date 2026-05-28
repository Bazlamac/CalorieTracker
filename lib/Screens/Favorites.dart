import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../Controls/CalorieCont.dart';
import '../Models/FavoriteEntry.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final CalorieController calorieController = Get.find();

  Future<void> _showFavoriteSheet({FavoriteEntry? favorite}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _FavoriteSheet(
          favorite: favorite,
          calorieController: calorieController,
        );
      },
    );
  }

  Future<void> _confirmDelete(FavoriteEntry favorite) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favoriyi Sil'),
        content: const Text('Bu favoriyi silmek istediğinize emin misiniz?'),
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
      await calorieController.deleteFavorite(favorite);
    }
  }

  Future<void> _useFavorite(FavoriteEntry favorite) async {
    await calorieController.addEntry(
      amount: favorite.amount,
      note: favorite.title,
      isBurned: favorite.isBurned,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Favori bugüne eklendi')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Favoriler',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFavoriteSheet(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final items = calorieController.favorites;
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz favori eklenmedi',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final favorite = items[index];
                    final color = favorite.isBurned
                        ? Colors.blue
                        : Colors.orange;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          favorite.isBurned
                              ? Icons.directions_run
                              : Icons.fastfood,
                          color: color,
                        ),
                        title: Text(favorite.title),
                        subtitle: Text(
                          '${favorite.amount} kcal • ${favorite.isBurned ? 'Yakılan' : 'Alınan'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'use') {
                              _useFavorite(favorite);
                            } else if (value == 'edit') {
                              _showFavoriteSheet(favorite: favorite);
                            } else if (value == 'delete') {
                              _confirmDelete(favorite);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'use',
                              child: Text('Bugüne ekle'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Düzenle'),
                            ),
                            PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteSheet extends StatefulWidget {
  const _FavoriteSheet({
    required this.calorieController,
    this.favorite,
  });

  final CalorieController calorieController;
  final FavoriteEntry? favorite;

  @override
  State<_FavoriteSheet> createState() => _FavoriteSheetState();
}

class _FavoriteSheetState extends State<_FavoriteSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.favorite?.title ?? '');
    _amountController = TextEditingController(
      text: widget.favorite != null ? widget.favorite!.amount.toString() : '',
    );
    _selectedType = widget.favorite?.isBurned == true ? 'burned' : 'gained';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.favorite == null ? 'Yeni Favori' : 'Favoriyi Düzenle',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn: 1 tabak pilav',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
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
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'gained',
                  label: Text('Alınan'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: 'burned',
                  label: Text('Yakılan'),
                  icon: Icon(Icons.directions_run),
                ),
              ],
              selected: {_selectedType},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedType = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  final amount = int.tryParse(_amountController.text);

                  if (title.isEmpty || amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen geçerli bilgiler girin'),
                      ),
                    );
                    return;
                  }

                  if (widget.favorite == null) {
                    await widget.calorieController.addFavorite(
                      title: title,
                      amount: amount,
                      isBurned: _selectedType == 'burned',
                    );
                  } else {
                    await widget.calorieController.updateFavorite(
                      favorite: widget.favorite!,
                      title: title,
                      amount: amount,
                      isBurned: _selectedType == 'burned',
                    );
                  }

                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
