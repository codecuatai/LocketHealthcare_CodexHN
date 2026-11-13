import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nạp font thật của app để test bố cục sát với máy thật
/// (font mặc định của flutter_test vẽ mỗi ký tự thành một ô vuông rất rộng).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load(
      'Chivo', ['Chivo-Bold.ttf', 'Chivo-ExtraBold.ttf', 'Chivo-Black.ttf']);
  await load('SpaceGrotesk', [
    'SpaceGrotesk-Regular.ttf',
    'SpaceGrotesk-Medium.ttf',
    'SpaceGrotesk-SemiBold.ttf',
    'SpaceGrotesk-Bold.ttf',
  ]);
  await testMain();
}
