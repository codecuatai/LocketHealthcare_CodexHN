import 'package:flutter/painting.dart';

/// Một tấm ảnh người dùng vừa chụp hoặc chọn.
///
/// Bản demo dùng ảnh mẫu trong assets; [id] giúp AI giả lập trả kết quả
/// tương ứng. Khi có camera thật, ảnh sẽ trỏ tới file trên máy.
class Photo {
  const Photo(this.id, this.asset);
  final String id;
  final String asset;

  ImageProvider get image => AssetImage(asset);

  @override
  bool operator ==(Object other) => other is Photo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

abstract final class SamplePhotos {
  static const pho = Photo('pho', 'assets/images/samples/pho.jpg');
  static const salad = Photo('salad', 'assets/images/samples/salad.jpg');
  static const eggSalad =
      Photo('eggsalad', 'assets/images/samples/eggsalad.jpg');
  static const chicken = Photo('chicken', 'assets/images/samples/chicken.jpg');
  static const run = Photo('run', 'assets/images/samples/run.jpg');
  static const bottle = Photo('bottle', 'assets/images/samples/bottle.jpg');
  static const desk = Photo('desk', 'assets/images/samples/desk.jpg');

  /// Ảnh khung ngắm camera có thể chĩa vào trong bản demo, kèm nhãn.
  static const camera = <(Photo, String)>[
    (pho, 'Phở bò'),
    (salad, 'Salad ức gà'),
    (eggSalad, 'Salad trứng'),
    (run, 'Chạy bộ'),
    (bottle, 'Chai nước'),
    (desk, 'Bàn làm việc'),
  ];
}
