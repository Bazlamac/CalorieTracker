import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../Controls/CalorieCont.dart';
import '../Models/UserProfile.dart';
 
class Profile extends StatefulWidget {
  const Profile({super.key});
 
  @override
  State<Profile> createState() => _ProfileState();
}
 
class _ProfileState extends State<Profile> {
  final CalorieController calorieController = Get.find();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
 
  String selectedGender = 'male';
  bool _initializedFromProfile = false;
  bool _isDirty = false;
 
  @override
  void initState() {
    super.initState();
 
    weightController.addListener(_handleFieldChange);
    heightController.addListener(_handleFieldChange);
    ageController.addListener(_handleFieldChange);
 
    // Veri async geldiğinde yakala
    ever(calorieController.userProfile, (UserProfile? profile) {
      if (mounted) _maybePrefill(profile);
    });
 
    // Veri zaten geldiyse hemen doldur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybePrefill(calorieController.userProfile.value);
    });
  }
 
  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    ageController.dispose();
    super.dispose();
  }
 
  void _handleFieldChange() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }
 
  void _maybePrefill(UserProfile? profile) {
    if (_initializedFromProfile || profile == null || !mounted) return;
 
    weightController.removeListener(_handleFieldChange);
    heightController.removeListener(_handleFieldChange);
    ageController.removeListener(_handleFieldChange);
 
    setState(() {
      selectedGender = profile.gender;
      weightController.text =
          profile.weight > 0 ? profile.weight.toString() : '';
      heightController.text =
          profile.height > 0 ? profile.height.toString() : '';
      ageController.text = profile.age > 0 ? profile.age.toString() : '';
      _initializedFromProfile = true;
      _isDirty = false;
    });
 
    weightController.addListener(_handleFieldChange);
    heightController.addListener(_handleFieldChange);
    ageController.addListener(_handleFieldChange);
  }
 
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
 
    final weight = double.tryParse(weightController.text);
    final height = double.tryParse(heightController.text);
    final age = int.tryParse(ageController.text);
 
    if (weight == null || height == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doğru girin')),
      );
      return;
    }
 
    if (weight <= 0 || height <= 0 || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilo, boy ve yaş pozitif olmalı')),
      );
      return;
    }
 
    await calorieController.saveUserProfile(
      weight: weight,
      height: height,
      age: age,
      gender: selectedGender,
    );
 
    if (mounted) {
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil bilgileri kaydedildi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final isFemale = selectedGender == 'female';
    final themeColor = isFemale ? Colors.pink : Colors.blue;
    final themeSoft = isFemale ? Colors.pink.shade50 : Colors.blue.shade50;
 
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: themeColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişisel Bilgiler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'BMR hesabı için bilgilerinizi kaydedin.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
 
            // Cinsiyet seçimi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cinsiyet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'male',
                          label: Text('Erkek'),
                          icon: Icon(Icons.male),
                        ),
                        ButtonSegment(
                          value: 'female',
                          label: Text('Kadın'),
                          icon: Icon(Icons.female),
                        ),
                      ],
                      selected: {selectedGender},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setState(() {
                          selectedGender = selection.first;
                          _isDirty = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
 
            // Kilo, Boy, Yaş
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kilo ve Boy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Kilo',
                              prefixIcon: const Icon(Icons.scale),
                              suffixText: 'kg',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Boy',
                              prefixIcon: const Icon(Icons.straighten),
                              suffixText: 'cm',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'Yaş',
                        prefixIcon: const Icon(Icons.cake),
                        suffixText: 'yıl',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
 
            // BMR göstergesi
            Obx(() {
              final bmrValue = calorieController.bmr.value;
              if (bmrValue == null) return const SizedBox.shrink();
              return Card(
                color: themeSoft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bazal Metabolizma',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$bmrValue kcal/gün',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                      if (!_isDirty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
 
            // Kaydet butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Kaydet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}