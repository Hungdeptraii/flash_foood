import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Base/models/food_model.dart';
import '../Base/provider/food_provider.dart';
import '../Models/category_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../Core/assets_constantes.dart';

class FoodManagerPage extends StatefulWidget {
  const FoodManagerPage({Key? key}) : super(key: key);

  @override
  State<FoodManagerPage> createState() => _FoodManagerPageState();
}

class _FoodManagerPageState extends State<FoodManagerPage> with SingleTickerProviderStateMixin {
  int selectedCategory = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    Future.microtask(() => Provider.of<FoodProvider>(context, listen: false).fetchFoods());
    _tabController.addListener(() {
      setState(() {
        selectedCategory = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFoodForm({FoodModel? food}) {
    final nameController = TextEditingController(text: food?.name ?? '');
    final descController = TextEditingController(text: food?.description ?? '');
    final priceController = TextEditingController(text: food?.price.toString() ?? '');
    List<String> selectedImages = List<String>.from(food?.images ?? []);
    final category = categories[selectedCategory];
    String defaultImage = category.link;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    food == null ? 'Thêm món ăn' : 'Sửa món ăn',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: selectedImages.isNotEmpty
                        ? (selectedImages[0].startsWith('http')
                            ? Image.network(
                                selectedImages[0], 
                                fit: BoxFit.cover, 
                                width: 96, 
                                height: 96,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: ${selectedImages[0]} - $error');
                                  return Image.asset(_getFoodIcon(category.designation), width: 64, height: 64, fit: BoxFit.contain);
                                },
                              )
                            : Image.file(
                                File(selectedImages[0]), 
                                fit: BoxFit.cover, 
                                width: 96, 
                                height: 96,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading file image: ${selectedImages[0]} - $error');
                                  return Image.asset(_getFoodIcon(category.designation), width: 64, height: 64, fit: BoxFit.contain);
                                },
                              ))
                        : Image.asset(_getFoodIcon(category.designation), width: 64, height: 64, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text('Chọn tệp ảnh', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      backgroundColor: Colors.orange.withOpacity(0.12),
                      foregroundColor: Colors.orange,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: false, type: FileType.image);
                      if (result != null && result.paths.isNotEmpty) {
                        setState(() {
                          selectedImages = result.paths.whereType<String>().toList();
                        });
                      }
                    },
                  ),
                ),
                if (selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 2),
                    child: Center(
                      child: Text(
                        selectedImages[0].split('/').last,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên món ăn',
                    prefixIcon: const Icon(Icons.fastfood_rounded, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: const Icon(Icons.description_outlined, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VND)',
                    prefixIcon: const Icon(Icons.payments, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    suffixText: 'VND',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final priceText = priceController.text.trim();
                        if (name.isEmpty || priceText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập đầy đủ tên món ăn và giá!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final imagesToSave = selectedImages.isNotEmpty ? selectedImages : [defaultImage];
                        final foodModel = FoodModel(
                          id: food?.id,
                          name: name,
                          description: descController.text.trim(),
                          price: double.tryParse(priceText) ?? 0,
                          images: imagesToSave,
                          category: category.designation,
                        );
                        final provider = Provider.of<FoodProvider>(context, listen: false);
                        bool success = false;
                        String errorMsg = '';
                        try {
                          if (food == null) {
                            await provider.addFood(foodModel);
                          } else {
                            await provider.updateFood(foodModel);
                          }
                          await provider.fetchFoods();
                          success = true;
                        } catch (e) {
                          errorMsg = e.toString();
                        }
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Thêm món ăn thành công!' : 'Thêm món ăn thất bại: $errorMsg'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                      child: Text(food == null ? 'Thêm' : 'Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteFood(BuildContext context, int? id) async {
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa món ăn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Provider.of<FoodProvider>(context, listen: false).deleteFood(id);
    }
  }

  String _getFoodIcon(String category) {
    switch (category.toLowerCase()) {
      case 'burger':
        return AssetsConstants.burger;
      case 'pizza':
        return AssetsConstants.pizza;
      case 'drink':
      case 'đồ uống':
        return AssetsConstants.drink;
      case 'taco':
        return AssetsConstants.taco;
      default:
        return AssetsConstants.ordinaryBurger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final foods = foodProvider.foods;
    final isLoading = foodProvider.isLoading;
    final error = foodProvider.error;
    // Lọc món ăn theo category
    String selectedCat = categories[selectedCategory].designation;
    List<FoodModel> filteredFoods = foods.where((food) {
      return food.category == selectedCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý món ăn')),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: categories.map((cat) => Tab(text: cat.designation)).toList(),
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: filteredFoods.isEmpty
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm món ăn'),
                                onPressed: () => _showFoodForm(),
                              )
                            : null,
                      )
                    : filteredFoods.isEmpty
                        ? Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm món ăn'),
                              onPressed: () => _showFoodForm(),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredFoods.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final food = filteredFoods[index];
                              return ListTile(
                                leading: Image.asset(
                                  _getFoodIcon(food.category),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                                title: Text(food.name),
                                subtitle: Text('Giá:  ${food.price.toStringAsFixed(0)} VND'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () => _showFoodForm(food: food),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteFood(context, food.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: (!isLoading && error == null && filteredFoods.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () => _showFoodForm(),
              child: const Icon(Icons.add),
              backgroundColor: Colors.orange,
              tooltip: 'Thêm món ăn',
            )
          : null,
    );
  }
} 