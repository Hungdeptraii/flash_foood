import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/assets_constantes.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Auth/screens/default_button.dart';
import 'package:flash_food/Presentation/Base/base.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flash_food/Presentation/Base/models/food_model.dart';
import 'package:provider/provider.dart';
import 'package:flash_food/Presentation/Base/provider/cart_provider.dart';
import 'dart:io';

class AboutMenuView extends StatefulWidget {
  final FoodModel? food;
  const AboutMenuView({Key? key, this.food}) : super(key: key);

  @override
  State<AboutMenuView> createState() => _AboutMenuViewState();
}

class _AboutMenuViewState extends State<AboutMenuView> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    MathUtils.init(context);
    final FoodModel food = widget.food ?? ModalRoute.of(context)!.settings.arguments as FoodModel;
    return Scaffold(
      appBar: buildAppBar(buildContext: context, screenTitle: "Về món ăn này"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: getWidth(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(8),
            Container(
              width: double.infinity,
              height: getHeight(295),
              padding: EdgeInsets.all(getSize(16)),
              decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: buildImage(
                      food.images.isNotEmpty ? food.images[0] : null,
                      getHeight(263),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: getHeight(30),
                      height: getHeight(30),
                      padding: EdgeInsets.all(getSize(5)),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Pallete.pureError,
                        size: getSize(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Text(
              food.name,
              style: TextStyles.headingH5SemiBold.copyWith(
                color: Pallete.neutral100,
                fontSize: getFontSize(FontSizes.h5),
              ),
            ),
            const Gap(8),
            Text(
              "${food.price.toStringAsFixed(0)} VND",
              style: TextStyles.headingH6Bold.copyWith(
                color: Pallete.orangePrimary,
                fontSize: getFontSize(FontSizes.h6),
              ),
            ),
            const Gap(16),
            Container(
              height: getHeight(39),
              width: double.infinity,
              padding: EdgeInsets.all(getSize(8)),
              decoration: BoxDecoration(
                color: const Color(0xFFFE8C00).withOpacity(0.04),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money_sharp, size: getSize(14), color: Pallete.orangePrimary),
                      const Gap(8),
                      Text(
                        "Giao hàng miễn phí",
                        style: TextStyles.bodyMediumRegular.copyWith(
                          color: Pallete.neutral60,
                          fontSize: getFontSize(FontSizes.medium),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: getSize(14), color: Pallete.orangePrimary),
                      const Gap(8),
                      Text(
                        "20 - 30 phút",
                        style: TextStyles.bodyMediumRegular.copyWith(
                          color: Pallete.neutral60,
                          fontSize: getFontSize(FontSizes.medium),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, size: getSize(14), color: Pallete.orangePrimary),
                      const Gap(8),
                      Text(
                        food.stars?.toStringAsFixed(1) ?? "4.5",
                        style: TextStyles.bodyMediumRegular.copyWith(
                          color: Pallete.neutral60,
                          fontSize: getFontSize(FontSizes.medium),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),
            Container(
              width: double.infinity,
              height: 2,
              color: const Color(0xFFEDEDED),
            ),
            const Gap(16),
            Text(
              "Mô tả",
              style: TextStyles.headingH5SemiBold.copyWith(
                color: Pallete.neutral100,
                fontSize: getFontSize(FontSizes.h5),
              ),
            ),
            const Gap(8),
            Text(
              food.description,
              style: TextStyles.bodyMediumRegular.copyWith(
                color: const Color(0xFF878787),
                fontSize: getFontSize(FontSizes.medium),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.symmetric(horizontal: getWidth(24)).copyWith(top: getHeight(16), bottom: getHeight(32)),
        height: getHeight(100),
        width: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                  child: Container(
                    height: getSize(36),
                    width: getSize(36),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                    ),
                    child: Icon(Icons.remove, size: getSize(20), color: Pallete.neutral100),
                  ),
                ),
                const Gap(16),
                Text(
                  quantity.toString(),
                  style: TextStyles.headingH5Bold.copyWith(
                    color: Pallete.neutral100,
                    fontSize: getFontSize(FontSizes.h5),
                  ),
                ),
                const Gap(16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  child: Container(
                    height: getSize(36),
                    width: getSize(36),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                    ),
                    child: Icon(Icons.add, size: getSize(20), color: Pallete.neutral100),
                  ),
                ),
              ],
            ),
            const Gap(26),
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: cartProvider.isLoading
                        ? null
                        : () async {
                            try {
                              await cartProvider.addToCart(food, quantity: quantity);
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 56),
                                        SizedBox(height: 12),
                                        Text('Đã thêm vào giỏ hàng!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        SizedBox(height: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            child: Text('Đóng', style: TextStyle(fontSize: 16)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi thêm vào giỏ hàng: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: cartProvider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Thêm vào giỏ hàng'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImage(String? imagePath, double height) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.black12,
        height: height,
        child: Center(child: Text('No image', style: TextStyle(color: Colors.white))),
      );
    }
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath, 
        height: height, 
        width: double.infinity, 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $imagePath - $error');
          return Container(
            color: Colors.black12,
            height: height,
            child: Center(child: Text('Error loading image', style: TextStyle(color: Colors.white))),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black12,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
    if (imagePath.startsWith('/')) {
      return Image.file(
        File(imagePath), 
        height: height, 
        width: double.infinity, 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading file image: $imagePath - $error');
          return Container(
            color: Colors.black12,
            height: height,
            child: Center(child: Text('Error loading image', style: TextStyle(color: Colors.white))),
          );
        },
      );
    }
    return Container(
      color: Colors.black12,
      height: height,
      child: Center(child: Text('No image', style: TextStyle(color: Colors.white))),
    );
  }
}

