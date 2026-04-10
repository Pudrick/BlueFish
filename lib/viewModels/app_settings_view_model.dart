import 'dart:async';

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/userdata/app_settings_store.dart';
import 'package:flutter/foundation.dart';

class AppSettingsViewModel extends ChangeNotifier {
  final AppSettingsStore _store;
  final ReplyPageLocatorCacheService _replyPageLocatorCacheService;

  AppSettings _settings;
  Future<void>? _initialization;
  bool _isInitialized = false;

  AppSettingsViewModel({
    AppSettingsStore? store,
    AppSettings? initialSettings,
    ReplyPageLocatorCacheService? replyPageLocatorCacheService,
  }) : _store = store ?? AppSettingsStore(),
       _replyPageLocatorCacheService =
           replyPageLocatorCacheService ?? ReplyPageLocatorCacheService(),
       _settings = initialSettings ?? AppSettings.defaults {
    unawaited(
      _replyPageLocatorCacheService.configureMaxEntries(
        _settings.replyLocateCacheMaxEntries,
      ),
    );
    ApiConfig.setApiVersionOverride(_settings.apiVersionOverride);
  }

  static Future<AppSettingsViewModel> create({
    AppSettingsStore? store,
    ReplyPageLocatorCacheService? replyPageLocatorCacheService,
  }) async {
    final viewModel = AppSettingsViewModel(
      store: store,
      replyPageLocatorCacheService: replyPageLocatorCacheService,
    );
    await viewModel.initialize();
    return viewModel;
  }

  Future<void> initialize() {
    return _initialization ??= _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await _store.load();
    await _replyPageLocatorCacheService.configureMaxEntries(
      _settings.replyLocateCacheMaxEntries,
    );
    ApiConfig.setApiVersionOverride(_settings.apiVersionOverride);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateThemePreference(AppThemePreference themePreference) {
    return _applyAndPersist(
      _settings.copyWith(themePreference: themePreference),
    );
  }

  Future<void> updateSeedColor(int seedColorValue) {
    return _applyAndPersist(_settings.copyWith(seedColorValue: seedColorValue));
  }

  Future<void> updateContentFontScale(double contentFontScale) {
    return _applyAndPersist(
      _settings.copyWith(contentFontScale: contentFontScale),
    );
  }

  Future<void> updateTitleFontScale(double titleFontScale) {
    return _applyAndPersist(_settings.copyWith(titleFontScale: titleFontScale));
  }

  Future<void> updateMetaFontScale(double metaFontScale) {
    return _applyAndPersist(_settings.copyWith(metaFontScale: metaFontScale));
  }

  Future<void> updateImageShrinkTriggerMaxEdgeDp(
    double imageShrinkTriggerMaxEdgeDp,
  ) {
    return _applyAndPersist(
      _settings.copyWith(
        imageShrinkTriggerMaxEdgeDp: imageShrinkTriggerMaxEdgeDp,
      ),
    );
  }

  Future<void> updateImageShrinkTargetMaxEdgeDp(
    double imageShrinkTargetMaxEdgeDp,
  ) {
    return _applyAndPersist(
      _settings.copyWith(
        imageShrinkTargetMaxEdgeDp: imageShrinkTargetMaxEdgeDp,
      ),
    );
  }

  Future<void> updateReplyLocateTotalProbeBudget(
    int replyLocateTotalProbeBudget,
  ) {
    return _applyAndPersist(
      _settings.copyWith(
        replyLocateTotalProbeBudget: replyLocateTotalProbeBudget,
      ),
    );
  }

  Future<void> updateReplyLocateCacheMaxEntries(
    int replyLocateCacheMaxEntries,
  ) {
    return _applyAndPersist(
      _settings.copyWith(
        replyLocateCacheMaxEntries: replyLocateCacheMaxEntries,
      ),
    );
  }

  Future<void> updateImageSaveDirectoryPath(String? imageSaveDirectoryPath) {
    return _applyAndPersist(
      _settings.copyWith(imageSaveDirectoryPath: imageSaveDirectoryPath),
    );
  }

  Future<void> updateVideoSaveDirectoryPath(String? videoSaveDirectoryPath) {
    return _applyAndPersist(
      _settings.copyWith(videoSaveDirectoryPath: videoSaveDirectoryPath),
    );
  }

  Future<void> updateApiVersionOverride(String? apiVersionOverride) {
    return _applyAndPersist(
      _settings.copyWith(apiVersionOverride: apiVersionOverride),
    );
  }

  Future<int> clearReplyLocateCacheBefore(DateTime cutoff) {
    return _replyPageLocatorCacheService.clearBefore(cutoff);
  }

  Future<void> clearAllReplyLocateCache() {
    return _replyPageLocatorCacheService.clearAll();
  }

  Future<void> reset() async {
    _settings = AppSettings.defaults;
    await _replyPageLocatorCacheService.configureMaxEntries(
      _settings.replyLocateCacheMaxEntries,
    );
    ApiConfig.setApiVersionOverride(_settings.apiVersionOverride);
    notifyListeners();
    await _store.reset();
  }

  Future<void> _applyAndPersist(AppSettings nextSettings) async {
    if (nextSettings == _settings) {
      return;
    }

    _settings = nextSettings;
    await _replyPageLocatorCacheService.configureMaxEntries(
      _settings.replyLocateCacheMaxEntries,
    );
    ApiConfig.setApiVersionOverride(_settings.apiVersionOverride);
    notifyListeners();
    await _store.save(_settings);
  }

  AppSettings get settings => _settings;

  bool get isInitialized => _isInitialized;
}
