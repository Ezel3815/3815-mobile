import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/offline/offline_store.dart';

class AppImage extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isCircle;
  final double? radius;
  final Widget? errorWidget;
  final Color? imageColor;

  const AppImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.isCircle = false,
    this.radius,
    this.errorWidget,
    this.imageColor,
  });

  /// Cloudinary uploads (post-migration) already store a full URL.
  /// Legacy local-disk uploads store just a filename and need the
  /// backend's base image URL prepended.
  String get _resolvedUrl {
    if (image.startsWith("http://") || image.startsWith("https://")) {
      return image;
    }
    return Api.imageUrl + image;
  }

  @override
  Widget build(BuildContext context) {
    // downloaded for offline use: show the saved copy, no network at all
    final local = OfflineStore.localPath(_resolvedUrl);
    if (local != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(radius ?? 0),
          image: DecorationImage(
            image: FileImage(File(local)),
            colorFilter: imageColor != null ? ColorFilter.mode(imageColor!, BlendMode.srcIn) : null,
            fit: fit,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: _resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      errorListener: (e) {},
      imageBuilder: (context, imageProvider) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(radius ?? 0),
            image: DecorationImage(
              image: imageProvider,
              colorFilter: imageColor != null
                  ? ColorFilter.mode(imageColor!, BlendMode.srcIn)
                  : null,
              fit: fit,
            ),
          ),
        );
      },
      errorWidget: (context, url, error) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              ),
              child: const Center(
                child: Icon(Icons.info_outline),
              ),
            );
      },
      progressIndicatorBuilder: (context, url, progress) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.withOpacity(.3),
          highlightColor: Colors.white,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              image: DecorationImage(
                image: NetworkImage(url),
                fit: fit,
              ),
            ),
          ),
        );
      },
    );
  }
}
