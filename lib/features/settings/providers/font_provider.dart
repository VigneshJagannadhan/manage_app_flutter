import 'package:huddle/core/resources/app_fonts.dart';
import 'package:huddle/core/services/font_preference_service.dart';
import 'package:huddle/features/shared/providers/base_provider.dart';

class FontProvider extends BaseProvider {
  FontProvider({required this.fontPreferenceService});

  final FontPreferenceService fontPreferenceService;

  AppFontOption _font = AppFontOption.defaultOption;
  AppFontOption get font => _font;

  @override
  void onInit() {
    fontPreferenceService.readFont().then((font) {
      _font = font;
      notifyListeners();
    });
  }

  @override
  void onDispose() {}

  Future<void> setFont(AppFontOption font) async {
    _font = font;
    notifyListeners();
    await fontPreferenceService.saveFont(font);
  }
}
