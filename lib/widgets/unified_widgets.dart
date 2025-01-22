// lib/widgets/unified_widgets.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';


// Widget MusicCard optimisé
class MusicCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MusicCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: AppTheme.cardGradient,
      child: ListTile(
        leading: OptimizedNetworkImage(
          imageUrl: imageUrl,
          width: 48,
          height: 48,
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// Widget OptimizedNetworkImage avec gestion de cache et d'erreurs
class OptimizedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool isSpotifyContent;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.borderRadius,
    this.isSpotifyContent = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final containerDecoration = BoxDecoration(
      color: backgroundColor ?? AppTheme.spotifyDarkGrey,
      borderRadius: borderRadius,
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: containerDecoration,
        child: _buildPlaceholder(),
      );
    }

    // Optimisation du cache selon la densité de pixels
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (width * devicePixelRatio).round();
    final cacheHeight = (height * devicePixelRatio).round();

    final imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (_, __, ___) => errorWidget ?? _buildPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildLoadingIndicator(loadingProgress);
      },
    );

    if (borderRadius != null) {
      return Container(
        decoration: containerDecoration,
        child: ClipRRect(
          borderRadius: borderRadius!,
          child: imageWidget,
        ),
      );
    }

    return Container(
      decoration: containerDecoration,
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        isSpotifyContent ? Icons.music_note : Icons.image,
        size: width * 0.4,
        color: Colors.white24,
      ),
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Center(
      child: SizedBox(
        width: width * 0.4,
        height: width * 0.4,
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          color: AppTheme.spotifyGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// Widget d'en-tête réutilisable
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  const ScreenHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.spotifyBlack,
            AppTheme.spotifyDarkGrey.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              color: Colors.white,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// Widget de chargement réutilisable
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              color: AppTheme.spotifyGreen,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}




// Widget d'état d'erreur réutilisable
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const ErrorDisplay({
    Key? key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Réessayer'),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: Text('Retour'),
          ),
        ],
      ),
    );
  }
}