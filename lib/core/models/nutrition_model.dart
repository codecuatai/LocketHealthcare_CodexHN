class NutritionModel {
  const NutritionModel(
      {required this.foodName,
      required this.kcal,
      required this.proteinGrams,
      required this.carbsGrams,
      required this.fatGrams,
      required this.assetPath});
  final String foodName;
  final int kcal;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final String assetPath;
  static const phoBoTai = NutritionModel(
      foodName: 'Phở Bò Tái',
      kcal: 520,
      proteinGrams: 32,
      carbsGrams: 65,
      fatGrams: 14,
      assetPath: 'assets/images/pho_bo_tai.png');
  static const chickenSalad = NutritionModel(
      foodName: 'Salad Ức Gà',
      kcal: 380,
      proteinGrams: 38,
      carbsGrams: 20,
      fatGrams: 16,
      assetPath: 'assets/images/chicken_salad.png');
}
