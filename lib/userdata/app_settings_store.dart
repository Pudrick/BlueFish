import 'package:bluefish/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsStore {
  static const String _themePreferenceKey = 'settings.theme_preference';
  static const String _seedColorKey = 'settings.seed_color';
  static const String _contentFontScaleKey = 'settings.content_font_scale';
  static const String _titleFontScaleKey = 'settings.title_font_scale';
  static const String _metaFontScaleKey = 'settings.meta_font_scale';
  static const String _imageShrinkTriggerWidthFactorKey =
      'settings.image_shrink_trigger_width_factor';
  static const String _imageShrinkTargetWidthFactorKey =
      'settings.image_shrink_target_width_factor';
  static const String _legacyImageShrinkTriggerMaxEdgeDpKey =
      'settings.image_shrink_trigger_max_edge_dp';
  static const String _legacyImageShrinkTargetMaxEdgeDpKey =
      'settings.image_shrink_target_max_edge_dp';
  static const String _replyLocateTotalProbeBudgetKey =
      'settings.reply_locate_total_probe_budget';
  static const String _replyLocateCacheMaxEntriesKey =
      'settings.reply_locate_cache_max_entries';
  static const String _replyLocateCoarseProbeStrideKey =
      'settings.reply_locate_coarse_probe_stride';
  static const String _generateJumpLogsKey = 'settings.generate_jump_logs';
  static const String _defaultCollapseLightedRepliesKey =
      'settings.default_collapse_lighted_replies';
  static const String _imageSaveDirectoryPathKey =
      'settings.image_save_directory_path';
  static const String _videoSaveDirectoryPathKey =
      'settings.video_save_directory_path';
  static const String _apiVersionOverrideKey = 'settings.api_version_override';
  static const double _legacyImageShrinkReferenceWidthDp = 500;

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
      imageShrinkTriggerWidthFactor:
          prefs.getDouble(_imageShrinkTriggerWidthFactorKey) ??
          _loadLegacyImageShrinkTriggerWidthFactor(prefs) ??
          AppSettings.defaults.imageShrinkTriggerWidthFactor,
      imageShrinkTargetWidthFactor:
          prefs.getDouble(_imageShrinkTargetWidthFactorKey) ??
          _loadLegacyImageShrinkTargetWidthFactor(prefs) ??
          AppSettings.defaults.imageShrinkTargetWidthFactor,
      replyLocateTotalProbeBudget:
          prefs.getInt(_replyLocateTotalProbeBudgetKey) ??
          AppSettings.defaults.replyLocateTotalProbeBudget,
      replyLocateCacheMaxEntries:
          prefs.getInt(_replyLocateCacheMaxEntriesKey) ??
          AppSettings.defaults.replyLocateCacheMaxEntries,
      replyLocateCoarseProbeStride:
          prefs.getInt(_replyLocateCoarseProbeStrideKey) ??
          AppSettings.defaults.replyLocateCoarseProbeStride,
      generateJumpLogs:
          prefs.getBool(_generateJumpLogsKey) ??
          AppSettings.defaults.generateJumpLogs,
      defaultCollapseLightedReplies:
          prefs.getBool(_defaultCollapseLightedRepliesKey) ??
          AppSettings.defaults.defaultCollapseLightedReplies,
      imageSaveDirectoryPath: prefs.getString(_imageSaveDirectoryPathKey),
      videoSaveDirectoryPath: prefs.getString(_videoSaveDirectoryPathKey),
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
      _imageShrinkTriggerWidthFactorKey,
      settings.imageShrinkTriggerWidthFactor,
    );
    await prefs.setDouble(
      _imageShrinkTargetWidthFactorKey,
      settings.imageShrinkTargetWidthFactor,
    );
    await prefs.remove(_legacyImageShrinkTriggerMaxEdgeDpKey);
    await prefs.remove(_legacyImageShrinkTargetMaxEdgeDpKey);
    await prefs.setInt(
      _replyLocateTotalProbeBudgetKey,
      settings.replyLocateTotalProbeBudget,
    );
    await prefs.setInt(
      _replyLocateCacheMaxEntriesKey,
      settings.replyLocateCacheMaxEntries,
    );
    await prefs.setInt(
      _replyLocateCoarseProbeStrideKey,
      settings.replyLocateCoarseProbeStride,
    );
    await prefs.setBool(_generateJumpLogsKey, settings.generateJumpLogs);
    await prefs.setBool(
      _defaultCollapseLightedRepliesKey,
      settings.defaultCollapseLightedReplies,
    );
    if (settings.imageSaveDirectoryPath == null) {
      await prefs.remove(_imageSaveDirectoryPathKey);
    } else {
      await prefs.setString(
        _imageSaveDirectoryPathKey,
        settings.imageSaveDirectoryPath!,
      );
    }
    if (settings.videoSaveDirectoryPath == null) {
      await prefs.remove(_videoSaveDirectoryPathKey);
    } else {
      await prefs.setString(
        _videoSaveDirectoryPathKey,
        settings.videoSaveDirectoryPath!,
      );
    }
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
    await prefs.remove(_imageShrinkTriggerWidthFactorKey);
    await prefs.remove(_imageShrinkTargetWidthFactorKey);
    await prefs.remove(_legacyImageShrinkTriggerMaxEdgeDpKey);
    await prefs.remove(_legacyImageShrinkTargetMaxEdgeDpKey);
    await prefs.remove(_replyLocateTotalProbeBudgetKey);
    await prefs.remove(_replyLocateCacheMaxEntriesKey);
    await prefs.remove(_replyLocateCoarseProbeStrideKey);
    await prefs.remove(_generateJumpLogsKey);
    await prefs.remove(_defaultCollapseLightedRepliesKey);
    await prefs.remove(_imageSaveDirectoryPathKey);
    await prefs.remove(_videoSaveDirectoryPathKey);
    await prefs.remove(_apiVersionOverrideKey);
  }

  double? _loadLegacyImageShrinkTriggerWidthFactor(SharedPreferences prefs) {
    final legacyValue = prefs.getDouble(_legacyImageShrinkTriggerMaxEdgeDpKey);
    if (legacyValue == null) {
      return null;
    }

    return AppSettings.normalizeImageShrinkTriggerWidthFactor(
      legacyValue / _legacyImageShrinkReferenceWidthDp,
    );
  }

  double? _loadLegacyImageShrinkTargetWidthFactor(SharedPreferences prefs) {
    final legacyValue = prefs.getDouble(_legacyImageShrinkTargetMaxEdgeDpKey);
    if (legacyValue == null) {
      return null;
    }

    return AppSettings.normalizeImageShrinkTargetWidthFactor(
      legacyValue / _legacyImageShrinkReferenceWidthDp,
    );
  }
}
