import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Imagen HTTPS para el feed social (p. ej. Supabase Storage); cache en disco + URLs normalizadas.
class VetgoSocialNetworkImage extends StatelessWidget {
  const VetgoSocialNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  /// Devuelve una URL válida para [Image.network] / CDN o `null`.
  static String? normalizeUrl(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = normalizeUrl(url);
    if (resolved == null) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: scheme.outline, size: width != null ? width! * 0.45 : 40),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      httpHeaders: const {
        'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      },
      fadeInDuration: const Duration(milliseconds: 140),
      fadeOutDuration: const Duration(milliseconds: 140),
      placeholder: (context, _) => ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: scheme.outline, size: width != null ? width! * 0.45 : 40),
      ),
    );
  }
}
