import 'package:huddle/core/services/local_notification_service.dart';
import 'package:huddle/core/services/notification_schedule_service.dart';
import 'package:huddle/features/auth/providers/auth_provider.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

/// Coordinates fetching the notification schedule and handing it to
/// [LocalNotificationService] - owns no data of its own. [refresh] is always
/// caller-driven (app launch, app resume, and after a preference change) rather than
/// triggered internally, so those entry points stay explicit and visible.
class NotificationScheduleProvider extends BaseProvider {
  NotificationScheduleProvider({required this.notificationScheduleService, required this.localNotificationService, required this.authProvider});

  final NotificationScheduleService notificationScheduleService;
  final LocalNotificationService localNotificationService;
  final AuthProvider authProvider;

  @override
  void onInit() {}

  @override
  void onDispose() {}

  Future<void> refresh() async {
    if (!authProvider.isAuthenticated) return;
    final items = await notificationScheduleService.fetchSchedule();
    await localNotificationService.scheduleAll(items);
  }
}
