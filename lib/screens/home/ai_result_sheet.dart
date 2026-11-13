import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/nutrition_model.dart';
import '../../core/models/profile.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/macro_bar.dart';

class AiResultSheet extends StatelessWidget {
  const AiResultSheet({super.key, required this.onShare});
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().profile!;
    const food = NutritionModel.phoBoTai;
    return SafeArea(
        child: FractionallySizedBox(
            heightFactor: .86,
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KẾT QUẢ NHẬN DIỆN',
                                style: TextStyle(
                                    color: AppColors.mint,
                                    letterSpacing: 2,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                    height: 155,
                                    width: double.infinity,
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      Image.asset(food.assetPath,
                                          fit: BoxFit.cover),
                                      Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                              padding: const EdgeInsets.all(15),
                                              color:
                                                  Colors.black.withOpacity(.6),
                                              child: Text(
                                                  'Đã nhận diện: ${food.foodName}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700)))),
                                    ]))),
                            const SizedBox(height: 22),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${food.kcal}',
                                      style: AppStyles.display),
                                  const Padding(
                                      padding:
                                          EdgeInsets.only(left: 7, bottom: 9),
                                      child: Text('KCAL',
                                          style: TextStyle(
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5))),
                                ]),
                            const Text('Giá trị dinh dưỡng ước tính',
                                style: AppStyles.bodySmall),
                            const SizedBox(height: 19),
                            MacroBar(
                                label: 'Protein',
                                grams: food.proteinGrams,
                                color: AppColors.mint,
                                progress: .65),
                            const SizedBox(height: 16),
                            MacroBar(
                                label: 'Carbs',
                                grams: food.carbsGrams,
                                color: AppColors.amber,
                                progress: .82),
                            const SizedBox(height: 16),
                            MacroBar(
                                label: 'Fat',
                                grams: food.fatGrams,
                                color: AppColors.rose,
                                progress: .38),
                            const SizedBox(height: 22),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    color: AppColors.amber.withOpacity(.11),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            AppColors.amber.withOpacity(.28))),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                          Icons.health_and_safety_outlined,
                                          color: AppColors.amber,
                                          size: 21),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(
                                              user.conditions.contains(
                                                      MedicalCondition
                                                          .hypertension)
                                                  ? 'Huyết áp cao: Hạn chế húp cạn nước dùng (chứa nhiều Natri).'
                                                  : 'Gợi ý: Thêm rau và một phần đạm để cân bằng bữa ăn.',
                                              style: const TextStyle(
                                                  color: AppColors.white,
                                                  height: 1.4,
                                                  fontSize: 13))),
                                    ])),
                            const SizedBox(height: 16),
                          ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                  child: ElevatedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Lưu & Chia sẻ lên Feed'))),
            ])));
  }
}
