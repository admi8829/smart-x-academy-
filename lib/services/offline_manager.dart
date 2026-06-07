import 'package:shared_preferences/shared_preferences.dart';

class OfflineManager {
  static final Set<String> _downloadedUnitIds = {};
  static bool _isLoaded = false;
  static final List<VoidCallback> _listeners = [];

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('downloaded_unit_ids');
      if (list != null) {
        _downloadedUnitIds.clear();
        _downloadedUnitIds.addAll(list);
      }
      _isLoaded = true;
    } catch (e) {
      // In case of any error, we keep operating in-memory
      _isLoaded = true;
    }
  }

  static Future<Set<String>> getDownloadedUnitIds() async {
    await init();
    return _downloadedUnitIds;
  }

  static bool isDownloadedSync(String id) {
    return _downloadedUnitIds.contains(id);
  }

  static Future<bool> isDownloaded(String id) async {
    await init();
    return _downloadedUnitIds.contains(id);
  }

  static Future<void> addDownload(String id) async {
    await init();
    _downloadedUnitIds.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_unit_ids', _downloadedUnitIds.toList());
    } catch (_) {}
    _notifyListeners();
  }

  static Future<void> removeDownload(String id) async {
    await init();
    _downloadedUnitIds.remove(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_unit_ids', _downloadedUnitIds.toList());
    } catch (_) {}
    _notifyListeners();
  }

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {}
    }
  }
}

typedef VoidCallback = void Function();
