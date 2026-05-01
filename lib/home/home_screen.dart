import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/auth/auth_session.dart';
import '../core/auth/auth_storage.dart';
import '../core/config/app_config.dart';
import '../core/network/vetgo_api_client.dart';
import 'vet_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLoggedOut});

  /// Tras cerrar sesión vuelve al flujo de login ([AuthFlow]).
  final VoidCallback? onLoggedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<HealthCheckResult> _healthFuture;
  AuthSession? _session;
  bool _sessionReady = false;

  @override
  void initState() {
    super.initState();
    _healthFuture = VetgoApiClient().checkHealth();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final s = await AuthStorage.loadSession();
    if (!mounted) return;
    setState(() {
      _session = s;
      _sessionReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_sessionReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _session?.profile?['role']?.toString();
    if (role == 'vet') {
      final vetName = _session?.profile?['full_name']?.toString() ?? '';
      return VetShell(
        profileFirstName: vetName,
        onLoggedOut: () async {
          await AuthStorage.clear();
          widget.onLoggedOut?.call();
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vetgo listo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 450.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),
              Text(
                'Backend',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                AppConfig.apiBaseUrl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.onLoggedOut != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await AuthStorage.clear();
                      widget.onLoggedOut?.call();
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FutureBuilder<HealthCheckResult>(
                future: _healthFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Comprobando /health…',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    );
                  }

                  final result = snapshot.data;
                  if (result == null) {
                    return Text(
                      'Sin resultado',
                      style: theme.textTheme.bodyLarge,
                    );
                  }

                  final icon = result.ok ? Icons.check_circle : Icons.error_outline;
                  final color = result.ok ? Colors.green.shade700 : theme.colorScheme.error;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: color, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                result.ok ? 'API conectada' : 'Sin conexión',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
