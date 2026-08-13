import 'package:manage_app/core/resources/app_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen font style across app restarts.
class FontPreferenceService {
  static const _fontKey = 'settings_app_font';

  Future<AppFontOption> readFont() async {
    final prefs = await SharedPreferences.getInstance();
    return AppFontOption.fromName(prefs.getString(_fontKey));
  }

  Future<void> saveFont(AppFontOption font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font.name);
  }
}

final fontPreferenceService = FontPreferenceService();
