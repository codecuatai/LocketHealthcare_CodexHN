import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../core/models/activity.dart';
import '../core/models/entry.dart';
import '../data/journal/journal_repository.dart';
import 'safe_notifier.dart';

/// Nhật ký hôm nay và chuỗi ngày.
class JournalController extends ChangeNotifier with SafeNotifier {
  JournalController(this._repo, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    refresh();
  }

  final JournalRepository _repo;
  final DateTime Function() _clock;

  DateTime get today => dateOnly(_clock());

  List<Entry> _entries = const [];
  List<Entry> get todayEntries => _entries;

  int _streak = 0;
  int get streak => _streak;

  /// Tăng mỗi khi Nhật ký đổi, để màn khác biết cần tải lại.
  int _version = 0;
  int get version => _version;

  /// Id Bản ghi vừa thêm, để Nhật ký làm nổi nó một lúc.
  String? _freshId;
  String? get freshId => _freshId;

  Future<void> refresh() async {
    final day = today;
    _entries = await _repo.entriesOn(day);
    _streak = await _repo.streak(day);
    _version++;
    notifyListeners();
  }

  Future<void> add(Entry entry) async {
    await _repo.add(entry);
    _freshId = entry.id;
    await refresh();
  }

  Future<Map<Metric, double>?> lastValues(ActivityType type) =>
      _repo.lastValues(type);

  Future<List<DayTotals>> lastDays(int count, {double? bodyKg}) =>
      _repo.lastDays(count, today, bodyKg: bodyKg);
}
