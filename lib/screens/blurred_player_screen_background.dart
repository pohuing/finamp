import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_image/octo_image.dart';

import '../services/current_album_image_provider.dart';

/// Same as [_PlayerScreenAlbumImage], but with a BlurHash instead. We also
/// filter the BlurHash so that it works as a background image.
class BlurredPlayerScreenBackground extends ConsumerWidget {
  /// should never be less than 1.0
  final double opacityFactor;
  final ImageProvider? customImageProvider;
  final String? blurHash;

  const BlurredPlayerScreenBackground({
    super.key,
    this.customImageProvider,
    this.opacityFactor = 1.0,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var imageProvider =
        customImageProvider ?? ref.watch(currentAlbumImageProvider);

    var overlayColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
            .withOpacity(ui.clampDouble(0.675 * opacityFactor, 0.0, 1.0))
        : Colors.white
            .withOpacity(ui.clampDouble(0.75 * opacityFactor, 0.0, 1.0));

    Widget placeholderBuilder(_) => blurHash != null
        ? SizedBox.expand(
            child: Image(
                fit: BoxFit.cover,
                color: overlayColor,
                colorBlendMode: BlendMode.srcOver,
                image: BlurHashImage(
                  blurHash!,
                )),
          )
        : const SizedBox.shrink();

    return Positioned.fill(
        child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            switchOutCurve: const Threshold(0.0),
            child: imageProvider == null
                ? placeholderBuilder(null)
                : OctoImage(
                    // Don't transition between images with identical files/urls
                    key: ValueKey(imageProvider.toString()),
                    image: imageProvider,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(seconds: 0),
                    fadeOutDuration: const Duration(seconds: 0),
                    color: overlayColor,
                    colorBlendMode: BlendMode.srcOver,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (x, _, __) => placeholderBuilder(x),
                    placeholderBuilder: placeholderBuilder,
                    imageBuilder: (context, child) => placeholderBuilder(
                        context) /*CachePaint(
                        imageKey: imageProvider.toString(),
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 85,
                            sigmaY: 85,
                            tileMode: TileMode.mirror,
                          ),
                          child: SizedBox.expand(child: child),
                        ))*/
                    )));
  }
}

class CachePaint extends SingleChildRenderObjectWidget {
  const CachePaint({super.key, super.child, required this.imageKey});

  final String imageKey;

  @override
  void updateRenderObject(BuildContext context, RenderCachePaint renderObject) {
    renderObject.screenSize = MediaQuery.sizeOf(context);
  }

  @override
  RenderCachePaint createRenderObject(BuildContext context) {
    return RenderCachePaint(imageKey, MediaQuery.sizeOf(context));
  }
}

class RenderCachePaint extends RenderProxyBox {
  RenderCachePaint(this._imageKey, this._screenSize);

  final String _imageKey;

  String get _cacheKey => _imageKey + _screenSize.toString();

  Size _screenSize;

  set screenSize(Size value) {
    if (value != _screenSize) {
      _disposeCache();
    }
    _screenSize = value;
  }

  static final Map<String, (List<RenderCachePaint>, ui.Image?)> _cache = {};

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    if (_cache[_cacheKey] != null) {
      if (!_cache[_cacheKey]!.$1.contains(this)) {
        // Add use to list of widgets using image
        _cache[_cacheKey]!.$1.add(this);
      }
      if (_cache[_cacheKey]!.$2 != null) {
        // Use cached child
        context.canvas.drawImage(_cache[_cacheKey]!.$2!, offset, Paint());
      } else {
        // Image is currently building, so paint child and move on.
        super.paint(context, offset);
      }
    } else {
      // Create cache entry
      _cache[_cacheKey] = ([this], null);
      // Paint our child
      super.paint(context, offset);
      // Save image of child to cache
      final OffsetLayer offsetLayer = layer! as OffsetLayer;
      Future.sync(() async {
        _cache[_cacheKey] = (
          _cache[_cacheKey]!.$1,
          await offsetLayer.toImage(offset & _screenSize)
        );
        // Schedule repaint next frame because the image is lighter than the full
        // child during compositing, which is more frequent than paints.
        for (var element in _cache[_cacheKey]!.$1) {
          element.markNeedsPaint();
        }
      });
    }
  }

  void _disposeCache() {
    _cache[_cacheKey]?.$1.remove(this);
    if (_cache[_cacheKey]?.$1.isEmpty ?? false) {
      // If we are last user of image, dispose
      _cache[_cacheKey]?.$2?.dispose();
      _cache.remove(_cacheKey);
    }
  }

  @override
  void dispose() {
    _disposeCache();
    super.dispose();
  }
}
