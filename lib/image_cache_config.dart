part of 'network_image_cache.dart';

class _ImageCacheConfig {
  static LazyBox? imageKeyBox;
  static LazyBox? imageBox;
  static bool isInitialized = false;

  static Future<void> _init() async {
    if (isInitialized) return;

    final clearCacheAfter = const Duration(days: 7);

    await Hive.initFlutter();
    isInitialized = true;

    imageKeyBox = await Hive.openLazyBox('imageKeyBox');
    imageBox = await Hive.openLazyBox('imageBox');
    await _clearOldCache(clearCacheAfter);
  }

  static Future<Uint8List?> _getImage(String url) async {
    final key = _keyFromUrl(url);
    if (imageKeyBox!.keys.contains(url) && imageBox!.containsKey(url)) {
      await _replaceImageKey(oldKey: url, newKey: key);
      await _replaceOldImage(oldKey: url, newKey: key, image: await imageBox!.get(url));
    }

    if (imageKeyBox!.keys.contains(key) && imageBox!.keys.contains(key)) {
      Uint8List? data = await imageBox!.get(key);
      if (data == null || data.isEmpty) return null;
      return data;
    }

    return null;
  }

  static Future<void> _saveImage(String url, Uint8List image) async {
    final key = _keyFromUrl(url);

    await imageKeyBox!.put(key, DateTime.now());
    await imageBox!.put(key, image);
  }

  static Future<void> _clearOldCache(Duration cleatCacheAfter) async {
    DateTime today = DateTime.now();

    for (final key in imageKeyBox!.keys) {
      DateTime? dateCreated = await imageKeyBox!.get(key);

      if (dateCreated == null) continue;

      if (today.difference(dateCreated) > cleatCacheAfter) {
        await imageKeyBox!.delete(key);
        await imageBox!.delete(key);
      }
    }
  }

  static Future<void> _replaceImageKey({required String oldKey, required String newKey}) async {
    await _checkInit();

    DateTime? dateCreated = await imageKeyBox!.get(oldKey);

    if (dateCreated == null) return;

    imageKeyBox!.delete(oldKey);
    imageKeyBox!.put(newKey, dateCreated);
  }

  static Future<void> _replaceOldImage({
    required String oldKey,
    required String newKey,
    required Uint8List image,
  }) async {
    await imageBox!.delete(oldKey);
    await imageBox!.put(newKey, image);
  }

  static Future<void> deleteCachedImage({required String imageUrl, bool showLog = true}) async {
    await _checkInit();

    final key = _keyFromUrl(imageUrl);
    if (imageKeyBox!.keys.contains(key) && imageBox!.keys.contains(key)) {
      await imageKeyBox!.delete(key);
      await imageBox!.delete(key);
      if (showLog) {
        log('Removed image $imageUrl from cache.', name: 'NetworkImageCache');
      }
    }
  }

  static Future<void> _checkInit() async {
    if ((_ImageCacheConfig.imageKeyBox == null || !_ImageCacheConfig.imageKeyBox!.isOpen) ||
        _ImageCacheConfig.imageBox == null ||
        !_ImageCacheConfig.imageBox!.isOpen) {
      await _init();
    }
  }

  static _keyFromUrl(String url) => const Uuid().v5('4r.-z.-h4', url);
}
