import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/models/profile.dart';
import '../core/models/social.dart';
import '../data/app_services.dart';
import '../data/demo/demo_people.dart';
import 'health_controller.dart';
import 'journal_controller.dart';
import 'social_controllers.dart';

/// Người dùng đang đăng nhập, dưới dạng một [Person] để vẽ avatar.
class Me {
  const Me(this.profile);
  final Profile profile;
  Person get person =>
      Person(id: profile.id, name: profile.displayName, color: meColor);
}

/// Dữ liệu của một phiên đăng nhập. Đặt phía trên Navigator để mọi màn và
/// sheet đều đọc được; tạo mới (và huỷ dữ liệu cũ) khi đổi Tài khoản.
class SessionScope extends StatefulWidget {
  const SessionScope({
    super.key,
    required this.profile,
    required this.createServices,
    required this.child,
  });

  final Profile profile;
  final AppServices Function() createServices;
  final Widget child;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  late final AppServices _services = widget.createServices();

  @override
  void dispose() {
    _services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider.value(value: _services),
          Provider.value(value: Me(widget.profile)),
          ChangeNotifierProvider(
              create: (_) => HealthController(_services.health)),
          ChangeNotifierProvider(
              create: (_) => JournalController(_services.journal)),
          ChangeNotifierProvider(
              create: (_) => MomentsController(_services.moments)),
          ChangeNotifierProvider(create: (_) => ChatController(_services.chat)),
          ChangeNotifierProvider(
              create: (_) => FriendsController(_services.friends)),
        ],
        child: widget.child,
      );
}
