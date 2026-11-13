import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/nutrition_model.dart';
import '../../widgets/custom_pill.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key, required this.hasSharedPho});
  final bool hasSharedPho;

  @override
  Widget build(BuildContext context) {
    final posts = [
      if (hasSharedPho)
        const _FeedPost(
            author: 'Bạn',
            initials: 'B',
            time: 'Vừa xong',
            food: NutritionModel.phoBoTai),
      const _FeedPost(
          author: 'Minh Anh',
          initials: 'MA',
          time: '2 giờ trước',
          food: NutritionModel.chickenSalad),
      const _FeedPost(
          author: 'Gia Huy',
          initials: 'GH',
          time: 'Hôm qua',
          food: NutritionModel.phoBoTai),
    ];
    return SafeArea(
        child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) => index == 0
          ? const Padding(
              padding: EdgeInsets.only(bottom: 22),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Khoảnh Khắc', style: AppStyles.heading),
                      SizedBox(height: 4),
                      Text('Cảm hứng từ những bữa ăn thường ngày.',
                          style: AppStyles.bodySmall),
                    ])),
                CustomPill(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_fire_department,
                          color: AppColors.amber, size: 17),
                      SizedBox(width: 4),
                      Text('12', style: TextStyle(fontWeight: FontWeight.w800)),
                    ])),
              ]))
          : Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _postCard(posts[index - 1])),
    ));
  }

  Widget _postCard(_FeedPost post) => Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyles.radius),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.mint.withOpacity(.16),
                    child: Text(post.initials,
                        style: const TextStyle(
                            color: AppColors.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.author,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(post.time, style: AppStyles.bodySmall),
                ]),
                const Spacer(),
                const Icon(Icons.more_horiz, color: AppColors.muted),
              ])),
          ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(2)),
              child: AspectRatio(
                  aspectRatio: 1.35,
                  child: Image.asset(post.food.assetPath, fit: BoxFit.cover))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: Text(post.food.foodName, style: AppStyles.title)),
                CustomPill(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('${post.food.kcal} kcal',
                        style: const TextStyle(
                            color: AppColors.mint,
                            fontWeight: FontWeight.w700,
                            fontSize: 12))),
              ])),
        ]),
      );
}

class _FeedPost {
  const _FeedPost(
      {required this.author,
      required this.initials,
      required this.time,
      required this.food});
  final String author;
  final String initials;
  final String time;
  final NutritionModel food;
}
