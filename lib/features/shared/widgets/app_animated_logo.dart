import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';

/// Animated wordmark reveal in three sequential stages:
///
/// 1. The leading letter scales from [initialScale] down to 1.0 (with a
///    brief overshoot), sitting dead-center on screen, and holds there for
///    [centerHoldDuration].
/// 2. The letter then slides left over [slideDuration], from screen-center
///    into its final position in the completed wordmark.
/// 3. Once the letter has landed, the rest of [logoText] reveals
///    left-to-right over [revealDuration] via a growing [ClipRect] window,
///    completing the word.
class AppAnimatedLogo extends StatefulWidget {
  const AppAnimatedLogo({
    super.key,
    this.logoText = _defaultLogoText,
    this.scaleInDuration = _defaultScaleInDuration,
    this.centerHoldDuration = _defaultCenterHoldDuration,
    this.slideDuration = _defaultSlideDuration,
    this.revealDuration = _defaultRevealDuration,
    this.initialScale = _defaultInitialScale,
    this.fontSize,
    this.fontWeight = _defaultFontWeight,
    this.textColor,
    this.backgroundColor,
    this.curve = _defaultCurve,
    this.onAnimationComplete,
  }) : assert(logoText.length > 1, 'logoText must have at least 2 characters');

  /// Full wordmark, e.g. "Manage App". The first character is treated as
  /// the "logo letter" that scales in and slides; the rest reveals after.
  final String logoText;

  /// How long the leading letter takes to scale in from [initialScale].
  final Duration scaleInDuration;

  /// How long the leading letter holds, centered on screen, before sliding.
  final Duration centerHoldDuration;

  /// How long the leading letter takes to slide from screen-center to its
  /// final position in the completed wordmark.
  final Duration slideDuration;

  /// How long the remaining letters take to reveal once the leading letter
  /// has landed.
  final Duration revealDuration;

  /// Starting scale of the leading letter, relative to its final size.
  final double initialScale;

  /// Falls back to the theme's headlineLarge font size, then [_defaultFontSize].
  final double? fontSize;

  final FontWeight fontWeight;

  /// Falls back to the theme's primary color, then the ambient color scheme.
  final Color? textColor;

  /// Left transparent so the widget can be dropped onto any background.
  final Color? backgroundColor;

  /// Eases the scale-in, the slide, and the reveal.
  final Curve curve;

  final VoidCallback? onAnimationComplete;

  static const String _defaultLogoText = 'Manage App';
  static const Duration _defaultScaleInDuration = Duration(milliseconds: 500);
  static const Duration _defaultCenterHoldDuration = Duration(milliseconds: 2000);
  static const Duration _defaultSlideDuration = Duration(milliseconds: 500);
  static const Duration _defaultRevealDuration = Duration(milliseconds: 500);
  static const double _defaultInitialScale = 3.5;
  static const double _defaultFontSize = 40;
  static const FontWeight _defaultFontWeight = FontWeight.bold;
  static const Curve _defaultCurve = Curves.easeOut;

  @override
  State<AppAnimatedLogo> createState() => _AppAnimatedLogoState();
}

class _AppAnimatedLogoState extends State<AppAnimatedLogo> with SingleTickerProviderStateMixin {
  // Subtle overshoot on the letter scale: shrink -> dip -> peak -> settle.
  static const double _scaleOvershootDip = 0.96;
  static const double _scaleOvershootPeak = 1.03;
  static const double _scaleSettled = 1.0;
  static const double _shrinkWeight = 70;
  static const double _dipWeight = 15;
  static const double _peakWeight = 15;

  // Extra parallax offset applied to the revealed text, as a fraction of
  // its own width, purely for polish - the ClipRect width is what actually
  // gates visibility.
  static const double _revealSlideMagnitude = 0.12;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _revealAnimation;
  late final Animation<Offset> _revealSlideAnimation;

  Animation<double>? _letterOffsetAnimation;
  TextStyle? _logoStyle;
  double _letterWidth = 0;

  double get _scaleEndFraction => widget.scaleInDuration.inMicroseconds / _totalMicroseconds;

  double get _slideStartFraction => (widget.scaleInDuration + widget.centerHoldDuration).inMicroseconds / _totalMicroseconds;

  double get _slideEndFraction =>
      (widget.scaleInDuration + widget.centerHoldDuration + widget.slideDuration).inMicroseconds / _totalMicroseconds;

  int get _totalMicroseconds =>
      (widget.scaleInDuration + widget.centerHoldDuration + widget.slideDuration + widget.revealDuration).inMicroseconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.scaleInDuration + widget.centerHoldDuration + widget.slideDuration + widget.revealDuration,
    )..addStatusListener(_handleStatusChanged);

    _scaleAnimation = _buildScaleAnimation();

    final revealCurve = CurvedAnimation(parent: _controller, curve: Interval(_slideEndFraction, 1.0, curve: widget.curve));
    _revealAnimation = revealCurve;
    _revealSlideAnimation = Tween<Offset>(
      begin: const Offset(-_revealSlideMagnitude, 0),
      end: Offset.zero,
    ).animate(revealCurve);
  }

  Animation<double> _buildScaleAnimation() {
    final scaleCurve = CurvedAnimation(parent: _controller, curve: Interval(0, _scaleEndFraction, curve: widget.curve));
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: widget.initialScale, end: _scaleOvershootDip), weight: _shrinkWeight),
      TweenSequenceItem(tween: Tween(begin: _scaleOvershootDip, end: _scaleOvershootPeak), weight: _dipWeight),
      TweenSequenceItem(tween: Tween(begin: _scaleOvershootPeak, end: _scaleSettled), weight: _peakWeight),
    ]).animate(scaleCurve);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onAnimationComplete?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveLayout();
  }

  @override
  void didUpdateWidget(covariant AppAnimatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoText != widget.logoText ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.fontWeight != widget.fontWeight ||
        oldWidget.textColor != widget.textColor) {
      _resolveLayout();
    }
  }

  // The leading letter starts centered on screen and slides left into its
  // resting spot in the completed wordmark. Both positions are absolute
  // pixel offsets, so they're measured once here rather than approximated.
  void _resolveLayout() {
    final theme = context.appTheme;
    final style = TextStyle(
      fontSize: widget.fontSize ?? theme.headlineLarge?.fontSize ?? AppAnimatedLogo._defaultFontSize,
      fontWeight: widget.fontWeight,
      color: widget.textColor ?? theme.primaryColor ?? Theme.of(context).colorScheme.primary,
      height: 1.0,
    );

    final textScaler = MediaQuery.textScalerOf(context);
    final letterWidth = _measureWidth(widget.logoText.substring(0, 1), style, textScaler);
    final wordWidth = _measureWidth(widget.logoText, style, textScaler);
    final centeredOffset = (wordWidth - letterWidth) / 2;

    setState(() {
      _logoStyle = style;
      _letterWidth = letterWidth;
      _letterOffsetAnimation = Tween<double>(
        begin: centeredOffset,
        end: 0,
      ).animate(CurvedAnimation(parent: _controller, curve: Interval(_slideStartFraction, _slideEndFraction, curve: widget.curve)));
    });

    if (!_controller.isAnimating && _controller.status == AnimationStatus.dismissed) _controller.forward();
  }

  double _measureWidth(String text, TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: textScaler)
      ..layout();
    return painter.size.width;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoStyle = _logoStyle;
    final letterOffsetAnimation = _letterOffsetAnimation;
    if (logoStyle == null || letterOffsetAnimation == null) return const SizedBox.shrink();

    final logo = Center(
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Invisible full-word placeholder: gives the Stack (and therefore
          // the Center above) a stable size matching the finished wordmark,
          // so nothing shifts as the letter slides or the text reveals.
          Opacity(opacity: 0, child: Text(widget.logoText, style: logoStyle, softWrap: false)),
          AnimatedBuilder(
            animation: letterOffsetAnimation,
            builder: (context, child) => Positioned(left: letterOffsetAnimation.value, child: child!),
            child: ScaleTransition(scale: _scaleAnimation, child: Text(widget.logoText.substring(0, 1), style: logoStyle, softWrap: false)),
          ),
          Positioned(
            left: _letterWidth,
            child: _RevealingText(revealAnimation: _revealAnimation, slideAnimation: _revealSlideAnimation, style: logoStyle, text: widget.logoText.substring(1)),
          ),
        ],
      ),
    );

    if (widget.backgroundColor == null) return logo;
    return ColoredBox(color: widget.backgroundColor!, child: logo);
  }
}

/// The trailing letters of the wordmark, revealed left-to-right by growing
/// a [ClipRect] window rather than by fading or wiping - this is what makes
/// each character appear as though it was physically hidden behind the
/// leading letter until the window passes over it.
class _RevealingText extends StatelessWidget {
  const _RevealingText({required this.revealAnimation, required this.slideAnimation, required this.style, required this.text});

  final Animation<double> revealAnimation;
  final Animation<Offset> slideAnimation;
  final TextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: revealAnimation,
      builder: (context, child) {
        return ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: revealAnimation.value.clamp(0.0, 1.0), child: child));
      },
      child: SlideTransition(position: slideAnimation, child: Text(text, style: style, softWrap: false)),
    );
  }
}
