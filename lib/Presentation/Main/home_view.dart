import 'package:flash_food/Core/Routes/routes_name.dart';
import 'package:flash_food/Core/app_colors.dart';
import 'package:flash_food/Core/assets_constantes.dart';
import 'package:flash_food/Core/font_size.dart';
import 'package:flash_food/Core/response_conf.dart';
import 'package:flash_food/Core/text_styles.dart';
import 'package:flash_food/Presentation/Base/food_item.dart';
import 'package:flash_food/Presentation/Models/category_model.dart';
import 'package:flash_food/Presentation/Notifications/widgets/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flash_food/Presentation/Auth/provider/auth_provider.dart';
import 'package:flash_food/Presentation/Base/provider/food_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<FoodProvider>(context, listen: false).fetchFoods());
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final foods = foodProvider.foods;
    final isLoading = foodProvider.isLoading;
    final error = foodProvider.error;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: getHeight(250),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: getWidth(24),
            ).copyWith(
              top: MediaQuery.of(context).viewPadding.top,
            ),
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(AssetsConstants.homeTopBackgroundImage),
                    fit: BoxFit.fill)),
            child: Padding(
              padding:
              EdgeInsets.only(top: getHeight(20), bottom: getHeight(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Địa điểm của bạn",
                                style: TextStyles.bodyMediumRegular
                                    .copyWith(color: Colors.white, fontSize: getFontSize(FontSizes.medium)),
                              ),
                              const Gap(8),
                              const Icon(
                                Icons.keyboard_arrow_down_outlined,
                                color: Colors.white,
                                size: 16,
                              )
                            ],
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: getSize(24),
                              ),
                              const Gap(8),
                              Text(
                                "Hà Nội",
                                style: TextStyles.bodyMediumSemiBold
                                    .copyWith(color: Colors.white, fontSize: getFontSize(FontSizes.medium)),
                              )
                            ],
                          )
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, RoutesName.search),
                            child: Container(
                              height: getSize(40),
                              width: getSize(40),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: Colors.white, width: 1)),
                              child: Icon(
                                Icons.search,
                                color: Colors.white,
                                size: getSize(24),
                              ),
                            ),
                          ),
                          const Gap(16),
                          NotificationBadge(
                            onTap: () => Navigator.pushNamed(
                                context, RoutesName.notification),
                            child: Container(
                              height: getSize(40),
                              width: getSize(40),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1)),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: getSize(24),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  const Gap(26),
                  Text(
                    "Cung cấp những \nmón ăn tốt nhất",
                    style: TextStyles.headingH4SemiBold
                        .copyWith(color: Pallete.neutral10, fontSize: getFontSize(FontSizes.h4)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: getWidth(24)),
                child: Column(
                  children: [
                    const Gap(26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tìm kiếm theo danh mục",
                          style: TextStyles.bodyLargeSemiBold
                              .copyWith(color: Pallete.neutral100, fontSize: getFontSize(FontSizes.large)),
                        ),
                      ],
                    ),
                    const Gap(18),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: categories
                            .asMap()
                            .map((key, category) => MapEntry(
                            key,
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = key;
                                });
                              },
                              child: Container(
                                width: getSize(65),
                                height: getSize(65),
                                padding: const EdgeInsets.all(8),
                                decoration: ShapeDecoration(
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x0A111111),
                                      blurRadius: 24,
                                      offset: Offset(0, 4),
                                      spreadRadius: 0,
                                    )
                                  ],
                                  color: key == selectedIndex
                                      ? Pallete.orangePrimary
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(category.link),
                                    const Gap(4),
                                    Text(
                                      category.designation,
                                      style: TextStyles.bodyMediumMedium.copyWith(
                                          color: key == selectedIndex
                                              ? Colors.white
                                              : Pallete.neutral60),
                                    )
                                  ],
                                ),
                              ),
                            )))
                            .values
                            .toList()),
                    const Gap(24),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (error != null)
                      Center(child: Text('Lỗi: ' + error)),
                    if (!isLoading && error == null)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 153 / 204,
                        children: foods
                            .where((food) => food.category == categories[selectedIndex].designation)
                            .map((food) => FoodItem(
                          food: food,
                        ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
