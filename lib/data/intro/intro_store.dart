import 'package:shared_preferences/shared_preferences.dart';

/// Ghi nhớ người dùng đã xem màn Giới thiệu hay chưa (chỉ hiện lần đầu).
abstract interface class IntroStore {
  bool get seen;
  Future<void> markSeen();
}

class SharedPreferencesIntroStore implements IntroStore {
  SharedPreferencesIntroStore._(this._prefs);

  static const _key = 'intro_seen_v1';
  final SharedPreferencesWithCache _prefs;

  static Future<SharedPreferencesIntroStore> load() async =>
      SharedPreferencesIntroStore._(await SharedPreferencesWithCache.create(
          cacheOptions:
              const SharedPreferencesWithCacheOptions(allowList: {_key})));

  @override
  bool get seen => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markSeen() => _prefs.setBool(_key, true);
}

class InMemoryIntroStore implements IntroStore {
  InMemoryIntroStore({this.seen = false});

  @override
  bool seen;

  @override
  Future<void> markSeen() async => seen = true;
}
