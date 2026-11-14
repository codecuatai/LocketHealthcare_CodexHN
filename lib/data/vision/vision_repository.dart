import '../../core/models/activity.dart';
import '../../core/models/analysis.dart';
import '../../core/models/health_info.dart';
import '../../core/models/photo.dart';

/// AI đọc ảnh: lọc ảnh ngoài luồng, nhận ra món ăn hoặc hoạt động.
abstract interface class VisionRepository {
  Future<PhotoVerdict> classify(Photo photo);

  /// Phân tích món ăn trong [photo]. [health] null nghĩa là người dùng chưa
  /// khai Thông tin sức khỏe: chỉ chấm theo dinh dưỡng chung.
  Future<FoodAnalysis> analyzeFood(Photo photo, {HealthInfo? health});
}

/// AI giả lập: trả kết quả cố định theo ảnh mẫu.
class DemoVisionRepository implements VisionRepository {
  DemoVisionRepository({this.delay = const Duration(milliseconds: 1400)});

  final Duration delay;

  @override
  Future<PhotoVerdict> classify(Photo photo) async {
    await Future<void>.delayed(delay);
    return switch (photo.id) {
      'pho' => const FoodPhoto('Phở bò tái'),
      'salad' => const FoodPhoto('Salad ức gà'),
      'eggsalad' => const FoodPhoto('Salad trứng quinoa'),
      'chicken' => const FoodPhoto('Gỏi gà nướng'),
      'run' => const ActivityPhoto(ActivityType.running),
      'bottle' => const UncertainPhoto(
          'AI thấy chai nước điện giải và dụng cụ tập nhưng chưa chắc đây là '
          'lúc tập hay chỉ là đồ uống.'),
      _ => const RejectedPhoto(),
    };
  }

  @override
  Future<FoodAnalysis> analyzeFood(Photo photo, {HealthInfo? health}) async {
    await Future<void>.delayed(delay ~/ 3);
    final bp = health?.has(MedicalCondition.hypertension) ?? false;
    const general = 'Dinh dưỡng chung';
    const bpTag = 'Huyết áp cao';
    return switch (photo.id) {
      'pho' => FoodAnalysis(
          dishName: 'Phở bò tái',
          mealLabel: 'Bữa tối',
          servingLabel: '1 tô vừa',
          kcal: 480,
          proteinG: 28,
          carbsG: 62,
          fatG: 12,
          verdict: bp ? FitVerdict.adjust : FitVerdict.good,
          reasons: [
            bp
                ? const FitReason(bpTag,
                    'Nước dùng phở khá mặn, khoảng 1.500 mg natri một tô. Cả ngày cậu nên giữ dưới 2.000 mg.')
                : const FitReason(
                    general, 'Bữa tối cân đối giữa đạm và tinh bột.'),
          ],
          tips: [
            if (bp) 'Ăn hết bánh phở và thịt, chừa lại nửa nước dùng.',
            if (bp)
              'Không chấm thêm nước mắm hay tương đen.'
            else
              'Nước dùng khá mặn, không cần húp hết.',
            'Thêm giá và rau thơm để no lâu hơn.',
          ],
        ),
      'salad' => FoodAnalysis(
          dishName: 'Salad ức gà',
          mealLabel: 'Bữa tối',
          servingLabel: '1 tô',
          kcal: 410,
          proteinG: 38,
          carbsG: 14,
          fatG: 22,
          verdict: FitVerdict.good,
          reasons: [
            bp
                ? const FitReason(bpTag,
                    'Ít muối, nhiều rau. Bơ và cà chua có kali, tốt cho huyết áp.')
                : const FitReason(general, 'Nhiều đạm, ít tinh bột, no lâu.'),
          ],
          tips: const ['Dùng dầu ô liu và chanh thay cho sốt mayonnaise.'],
        ),
      'eggsalad' => FoodAnalysis(
          dishName: 'Salad trứng quinoa',
          mealLabel: 'Bữa tối',
          servingLabel: '1 tô',
          kcal: 420,
          proteinG: 22,
          carbsG: 38,
          fatG: 18,
          verdict: FitVerdict.good,
          reasons: [
            bp
                ? const FitReason(
                    bpTag, 'Ít muối, nhiều rau, đạm từ trứng và quinoa.')
                : const FitReason(
                    general, 'Cân đối đạm, tinh bột tốt và chất béo.'),
          ],
          tips: const ['Ăn chậm để no lâu hơn.'],
        ),
      'chicken' => FoodAnalysis(
          dishName: 'Gỏi gà nướng',
          mealLabel: 'Bữa tối',
          servingLabel: '1 đĩa',
          kcal: 520,
          proteinG: 34,
          carbsG: 46,
          fatG: 20,
          verdict: bp ? FitVerdict.adjust : FitVerdict.good,
          reasons: [
            bp
                ? const FitReason(bpTag,
                    'Nước mắm trộn gỏi khá mặn, khoảng 900 mg natri một đĩa.')
                : const FitReason(general, 'Nhiều đạm và rau, hợp bữa tối.'),
          ],
          tips: const ['Xin nước trộn để riêng, chấm vừa đủ.'],
        ),
      'bottle' => FoodAnalysis(
          dishName: 'Nước điện giải',
          mealLabel: 'Đồ uống',
          servingLabel: '1 chai 500 ml',
          kcal: 90,
          proteinG: 0,
          carbsG: 22,
          fatG: 0,
          verdict: bp ? FitVerdict.adjust : FitVerdict.good,
          reasons: [
            bp
                ? const FitReason(bpTag,
                    'Nước điện giải có thêm natri, khoảng 400 mg một chai.')
                : const FitReason(general, 'Bù nước và khoáng sau khi tập.'),
          ],
          tips: const [
            'Chỉ cần khi tập lâu và ra nhiều mồ hôi.',
            'Ngày thường uống nước lọc là đủ.',
          ],
        ),
      _ => const FoodAnalysis(
          dishName: '',
          mealLabel: 'Bữa ăn',
          servingLabel: 'AI chưa chắc, cậu sửa tên và khẩu phần',
          kcal: 300,
          proteinG: 15,
          carbsG: 35,
          fatG: 10,
          verdict: FitVerdict.adjust,
          reasons: [
            FitReason('AI chưa chắc',
                'Ảnh chưa rõ món nên các con số chỉ là tạm tính. Sửa tên món để AI tính lại.'),
          ],
          tips: ['Chụp gần hơn, đủ sáng để AI nhận ra món.'],
          confident: false,
        ),
    };
  }
}
