import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../network/api_exception.dart';

/// User-facing message for any error thrown by a repository.
String errorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    return switch (error.kind) {
      ApiErrorKind.network => l10n.errorNetwork,
      ApiErrorKind.forbidden => l10n.errorForbidden,
      ApiErrorKind.notFound => l10n.errorNotFound,
      ApiErrorKind.conflict => l10n.errorStale,
      ApiErrorKind.tooManyRequests => l10n.errorTooManyAttempts,
      // Server problem details are Turkish by contract.
      ApiErrorKind.validation when error.fieldErrors.isNotEmpty =>
        error.fieldErrors.values.expand((m) => m).join('\n'),
      _ => error.detail ?? error.title ?? l10n.errorGeneric,
    };
  }
  return l10n.errorGeneric;
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: AppLocalizations.of(context).loading,
          child: const CircularProgressIndicator(),
        ),
      );
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MessageView(
      icon: Icons.cloud_off_outlined,
      title: errorMessage(l10n, error),
      action: FilledButton.icon(
        key: const Key('retryButton'),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(l10n.retry),
      ),
    );
  }
}

/// LEDCare OS wordmark: an LED-matrix glyph + name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 28});

  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    const accent = Color(0xFF2F6BFF);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: size * 0.08,
            crossAxisSpacing: size * 0.08,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: List.generate(
              9,
              (i) => DecoratedBox(
                decoration: BoxDecoration(
                  color: i == 4 || i == 0 || i == 8
                      ? accent
                      : color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(size * 0.06),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: size * 0.4),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'LEDCare',
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
            const TextSpan(
              text: ' OS',
              style: TextStyle(fontWeight: FontWeight.w500, color: accent),
            ),
          ]),
          style: TextStyle(fontSize: size * 0.8, letterSpacing: -0.3),
        ),
      ],
    );
  }
}
