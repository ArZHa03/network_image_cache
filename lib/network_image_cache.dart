import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

part 'image_cache_config.dart';

class NetworkImageCache extends StatefulWidget {
  final String _url;
  final Duration _fadeInDuration;
  final double? _width;
  final double? _height;

  const NetworkImageCache(
      {required String url,
      double? width,
      double? height,
      Duration fadeInDuration = const Duration(milliseconds: 500),
      super.key})
      : _height = height,
        _width = width,
        _fadeInDuration = fadeInDuration,
        _url = url;

  @override
  State<NetworkImageCache> createState() => _NetworkImageCacheState();
}

class _NetworkImageCacheState extends State<NetworkImageCache> with TickerProviderStateMixin {
  Uint8List? imageData;
  String? error;

  late Animation<double> animation;
  late AnimationController animationController;

  int downloadedBytes = 0;
  int? totalBytes;
  ValueNotifier<double> progressPercentage = ValueNotifier(0);
  bool isDownloading = false;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: widget._fadeInDuration);
    animation =
        Tween<double>(begin: widget._fadeInDuration == Duration.zero ? 1 : 0, end: 1).animate(animationController);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadAsync(widget._url);
      animationController.addStatusListener((status) => _animationListener(status));
    });

    super.initState();
  }

  void _animationListener(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && widget._fadeInDuration != Duration.zero) setState(() => {});
  }

  @override
  void dispose() {
    animationController.removeListener(() => {});
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) _logErrors(error);

    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          if (animationController.status != AnimationStatus.completed) const SizedBox(),
          if (imageData != null)
            FadeTransition(
              opacity: animation,
              child: Image.memory(
                imageData!,
                width: widget._width,
                height: widget._height,
                key: widget.key,
                fit: BoxFit.contain,
                errorBuilder: (a, c, v) {
                  if (animationController.status != AnimationStatus.completed) {
                    animationController.forward();
                    _logErrors(c);
                    _ImageCacheConfig.deleteCachedImage(imageUrl: widget._url);
                  }
                  return const SizedBox();
                },
                filterQuality: ui.FilterQuality.none,
                frameBuilder: (context, a, b, c) {
                  if (animationController.status != AnimationStatus.completed) animationController.forward();
                  return a;
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadAsync(String url) async {
    await _ImageCacheConfig._checkInit();
    Uint8List? image = await _ImageCacheConfig._getImage(url);

    if (!mounted) return;

    if (image != null) {
      setState(() {
        imageData = image;
        error = null;
      });
      animationController.forward();
      return;
    }

    StreamController chunkEvents = StreamController();

    try {
      final Uri resolved = Uri.base.resolve(url);
      Dio dio = Dio();

      if (!mounted) return;

      isDownloading = true;

      Response response = await dio.get(url, options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: (int received, int total) {
        if (received < 0 || total < 0) return;

        chunkEvents.add(ImageChunkEvent(cumulativeBytesLoaded: received, expectedTotalBytes: total));
      });

      final Uint8List bytes = response.data;

      if (response.statusCode != 200) {
        String error = NetworkImageLoadException(statusCode: response.statusCode ?? 0, uri: resolved).toString();
        if (mounted) {
          setState(() {
            imageData = null;
            error = error;
          });
        }
        return;
      }

      isDownloading = false;

      if (bytes.isEmpty && mounted) {
        setState(() {
          imageData = null;
          error = 'NetworkImage is an empty file: $resolved';
        });
        return;
      }
      if (mounted) {
        setState(() {
          imageData = bytes;
          error = null;
        });
        animationController.forward();
      }

      await _ImageCacheConfig._saveImage(url, bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          imageData = null;
          error = e.toString();
        });
      }
    } finally {
      if (!chunkEvents.isClosed) await chunkEvents.close();
    }
  }

  void _logErrors(dynamic object) => log('$object - Image url : ${widget._url}', name: 'NetworkImageCache');
}
