import 'package:bluefish/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsStore {
  static const String _themePreferenceKey = 'settings.theme_preference';
  static const String _seedColorKey = 'settings.seed_color';
  static const String _contentFontScaleKey = 'settings.content_font_scale';
  static const String _titleFontScaleKey = 'settings.title_font_scale';
  static const String _metaFontScaleKey = 'settings.meta_font_scale';
  static const String _imageShrinkTriggerMaxEdgeDpKey =
      'settings.image_shrink_trigger_max_edge_dp';
  static const String _imageShrinkTargetMaxEdgeDpKey =
      'settings.image_shrink_target_max_edge_dp';
  static const String _replyLocateTotalProbeBudgetKey =
      'settings.reply_locate_total_probe_budget';
  static const String _replyLocateCacheMaxEntriesKey =
      'settings.reply_locate_cache_max_entries';
  static const String _apiVersionOverrideKey = 'settings.api_version_override';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<AppSettings> load() async {
    final prefs = await _preferences;

    return AppSettings(
      themePreference: AppThemePreference.fromStorage(
        prefs.getString(_themePreferenceKey),
      ),
      seedColorValue:
          prefs.getInt(_seedColorKey) ?? AppSettings.defaults.seedColorValue,
      contentFontScale:
          prefs.getDouble(_contentFontScaleKey) ??
          AppSettings.defaults.contentFontScale,
      titleFontScale:
          prefs.getDouble(_titleFontScaleKey) ??
          AppSettings.defaults.titleFontScale,
      metaFontScale:
          prefs.getDouble(_metaFontScaleKey) ??
          AppSettings.defaults.metaFontScale,
      imageShrinkTriggerMaxEdgeDp:
          prefs.getDouble(_imageShrinkTriggerMaxEdgeDpKey) ??
          AppSettings.defaults.imageShrinkTriggerMaxEdgeDp,
      imageShrinkTargetMaxEdgeDp:
          prefs.getDouble(_imageShrinkTargetMaxEdgeDpKey) ??
          AppSettings.defaults.imageShrinkTargetMaxEdgeDp,
      replyLocateTotalProbeBudget:
          prefs.getInt(_replyLocateTotalProbeBudgetKey) ??
          AppSettings.defaults.replyLocateTotalProbeBudget,
      replyLocateCacheMaxEntries:
          prefs.getInt(_replyLocateCacheMaxEntriesKey) ??
          AppSettings.defaults.replyLocateCacheMaxEntries,
      apiVersionOverride: prefs.getString(_apiVersionOverrideKey),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await _preferences;

    await prefs.setString(
      _themePreferenceKey,
      settings.themePreference.storageValue,
    );
    await prefs.setInt(_seedColorKey, settings.seedColorValue);
    await prefs.setDouble(_contentFontScaleKey, settings.contentFontScale);
    await prefs.setDouble(_titleFontScaleKey, settings.titleFontScale);
    await prefs.setDouble(_metaFontScaleKey, settings.metaFontScale);
    await prefs.setDouble(
      _imageShrinkTriggerMaxEdgeDpKey,
      settings.imageShrinkTriggerMaxEdgeDp,
    );
    await prefs.setDouble(
      _imageShrinkTargetMaxEdgeDpKey,
      settings.imageShrinkTargetMaxEdgeDp,
    );
    await prefs.setInt(
      _replyLocateTotalProbeBudgetKey,
      settings.replyLocateTotalProbeBudget,
    );
    await prefs.setInt(
      _replyLocateCacheMaxEntriesKey,
      settings.replyLocateCacheMaxEntries,
    );
    if (settings.apiVersionOverride == null) {
      await prefs.remove(_apiVersionOverrideKey);
    } else {
      await prefs.setString(
        _apiVersionOverrideKey,
        settings.apiVersionOverride!,
      );
    }
  }

  Future<void> reset() async {
    final prefs = await _preferences;

    await prefs.remove(_themePreferenceKey);
    await prefs.remove(_seedColorKey);
    await prefs.remove(_contentFontScaleKey);
    await prefs.remove(_titleFontScaleKey);
    await prefs.remove(_metaFontScaleKey);
    await prefs.remove(_imageShrinkTriggerMaxEdgeDpKey);
    await prefs.remove(_imageShrinkTargetMaxEdgeDpKey);
    await prefs.remove(_replyLocateTotalProbeBudgetKey);
    await prefs.remove(_replyLocateCacheMaxEntriesKey);
    await prefs.remove(_apiVersionOverrideKey);
  }
}
