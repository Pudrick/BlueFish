import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/userdata/app_settings_store.dart';
import 'package:flutter/foundation.dart';

class AppSettingsViewModel extends ChangeNotifier {
  final AppSettingsStore _store;

  AppSettings _settings;
  Future<void>? _initialization;
  bool _isInitialized = false;

  AppSettingsViewModel({AppSettingsStore? store, AppSettings? initialSettings})
    : _store = store ?? AppSettingsStore(),
      _settings = initialSettings ?? AppSettings.defaults;

  AppSettings get settings => _settings;

  bool get isInitialized => _isInitialized;

  static Future<AppSettingsViewModel> create({AppSettingsStore? store}) async {
    final viewModel = AppSettingsViewModel(store: store);
    await viewModel.initialize();
    return viewModel;
  }

  Future<void> initialize() {
    return _initialization ??= _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await _store.load();
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

  Future<void> reset() async {
    _settings = AppSettings.defaults;
    notifyListeners();
    await _store.reset();
  }

  Future<void> _applyAndPersist(AppSettings nextSettings) async {
    if (nextSettings == _settings) {
      return;
    }

    _settings = nextSettings;
    notifyListeners();
    await _store.save(_settings);
  }
}
