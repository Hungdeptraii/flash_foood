import 'package:flash_food/Core/Routes/routes_name.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/assets_constantes.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'models/food_model.dart';
import 'package:provider/provider.dart';
import '../Auth/provider/auth_provider.dart';
import 'dart:io';

class FoodItem extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const FoodItem({required this.food, this.onEdit, this.onDelete, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.role == 'admin';
    print('FoodItem: ${food.name} images = ${food.images}');
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        RoutesName.aboutMenu,
        arguments: food,
      ),
      child: Container(
        height: getHeight(220),
        width: getWidth(160),
        padding: EdgeInsets.all(getSize(12)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(getSize(16)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 30,
              offset: Offset(0, 8),
              spreadRadius: 0,
            )
          ],
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: getHeight(90),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(getSize(12)),
                    color: Colors.orange.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: (food.images.isNotEmpty && food.images.first != null && food.images.first.trim().isNotEmpty && food.images.first != 'null')
                      ? _buildFoodImage(food.images.first, food.category)
                      : Center(
                          child: Padding(
                            padding: EdgeInsets.all(getSize(8)),
                            child: Image.asset(
                              _getFoodIcon(food.category),
                              width: getSize(48),
                              height: getSize(48),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
                const Gap(10),
                Text(
                  food.name,
                  style: TextStyles.bodyLargeMedium.copyWith(
                    color: Pallete.neutral100,
                    fontSize: getFontSize(FontSizes.large),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(6),
                Row(
                  children: [
                    Icon(Icons.star, color: Pallete.orangePrimary, size: getSize(16)),
                    const Gap(4),
                    Text(
                      food.stars.toString(),
                      style: TextStyles.bodySmallMedium.copyWith(color: Pallete.neutral100),
                    ),
                    const Spacer(),
                    Icon(Icons.location_on_outlined, color: Pallete.orangePrimary, size: getSize(16)),
                    const Gap(2),
                    Text(
                      "190m",
                      style: TextStyles.bodySmallMedium.copyWith(
                        color: Pallete.neutral100,
                        fontSize: getFontSize(FontSizes.small),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Row(
                  children: [
                    Text(
                      '${food.price.toStringAsFixed(0)} VND',
                      style: TextStyles.bodyLargeBold.copyWith(
                        color: Pallete.orangePrimary,
                      ),
                    ),
                    if (food.stars != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(
                        food.stars!.toStringAsFixed(1),
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (onEdit != null || onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit, color: Pallete.orangePrimary, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Sửa món ăn',
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete, color: Pallete.pureError, size: 20),
                        onPressed: onDelete,
                        tooltip: 'Xóa món ăn',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _getFoodIcon(String category) {
  switch (category.toLowerCase()) {
    case 'burger':
      return AssetsConstants.burger;
    case 'pizza':
      return AssetsConstants.pizza;
    case 'drink':
      return AssetsConstants.drink;
    case 'taco':
      return AssetsConstants.taco;
    default:
      return AssetsConstants.ordinaryBurger;
  }
}

Widget _buildFoodImage(String path, String category) {
  Widget imageWidget;
  if (path.startsWith('http')) {
    imageWidget = Image.network(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $path - $error');
        return Image.asset(
          _getFoodIcon(category),
          fit: BoxFit.contain,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  } else if (path.startsWith('assets/')) {
    imageWidget = Image.asset(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        _getFoodIcon(category),
        fit: BoxFit.contain,
      ),
    );
  } else if (path.startsWith('file://') ||
             path.startsWith('/data/') ||
             path.startsWith('/storage/') ||
             path.startsWith('/sdcard/')) {
    imageWidget = Image.file(
      File(path.replaceFirst('file://', '')),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        _getFoodIcon(category),
        fit: BoxFit.contain,
      ),
    );
  } else {
    imageWidget = Image.asset(
      _getFoodIcon(category),
      fit: BoxFit.contain,
    );
  }
  return Padding(
    padding: EdgeInsets.all(getSize(4)),
    child: SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(getSize(12)),
        child: imageWidget,
      ),
    ),
  );
}
