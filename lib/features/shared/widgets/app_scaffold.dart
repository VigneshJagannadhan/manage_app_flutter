import 'package:flutter/material.dart';

/// Wraps both [body] and [bottomNavigationBar] in [SafeArea] - do not replace
/// this with a manual `MediaQuery.viewPadding` calculation. `SafeArea` alone
/// already resolves to the right per-platform bottom inset: near-zero on iOS
/// gesture nav and Android gesture nav, the home-indicator inset on iOS, and
/// the larger inset Android reports when 3-button navigation is active - so
/// content and the floating nav bar clear the system UI on every device
/// without any platform-specific branching here.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.scrollable = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final navigationBar = bottomNavigationBar;
    return Scaffold(
      appBar: appBar,
      body: Listener(
        onPointerDown: (_) => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: scrollable ? _ScrollableBody(child: body) : body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: navigationBar == null
          ? null
          : SafeArea(child: navigationBar),
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
    );
  }
}

class _ScrollableBody extends StatelessWidget {
  const _ScrollableBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}
