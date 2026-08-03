import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

abstract class BaseProvider extends ChangeNotifier {
  void onInit();
  void onDispose();

  bool _disposed = false;
  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    onDispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    // An awaited async chain (e.g. one provider's init waiting on another's) can resume
    // and land here while Flutter is mid-build for something unrelated - marking an
    // already-mounted, non-ancestor scope dirty at that point throws. Deferring to the
    // next frame in that case is the standard fix; the common case (not mid-build) is untouched.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => super.notifyListeners());
    } else {
      super.notifyListeners();
    }
  }
}
