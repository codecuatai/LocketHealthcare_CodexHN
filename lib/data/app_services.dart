import '../core/models/health_info.dart';
import 'coach/coach_repository.dart';
import 'health/health_repository.dart';
import 'journal/journal_repository.dart';
import 'social/chat_repository.dart';
import 'social/friends_repository.dart';
import 'social/moments_repository.dart';
import 'vision/vision_repository.dart';

/// Các nguồn dữ liệu của một phiên đăng nhập. Bản demo chạy hoàn toàn trong
/// bộ nhớ; khi có backend chỉ cần thay từng repository.
class AppServices {
  AppServices({
    required this.vision,
    required this.journal,
    required this.moments,
    required this.chat,
    required this.friends,
    required this.health,
    required this.coach,
  });

  factory AppServices.demo({
    Duration visionDelay = const Duration(milliseconds: 1400),
    bool simulateFriends = true,
    HealthInfo? health,
  }) =>
      AppServices(
        vision: DemoVisionRepository(delay: visionDelay),
        journal: DemoJournalRepository(),
        moments: DemoMomentsRepository(simulateFriends: simulateFriends),
        chat: DemoChatRepository(simulateReplies: simulateFriends),
        friends: DemoFriendsRepository(),
        health: InMemoryHealthRepository(health),
        coach: DemoCoachRepository(),
      );

  final VisionRepository vision;
  final JournalRepository journal;
  final MomentsRepository moments;
  final ChatRepository chat;
  final FriendsRepository friends;
  final HealthRepository health;
  final CoachRepository coach;

  void dispose() {
    moments.dispose();
    chat.dispose();
  }
}
