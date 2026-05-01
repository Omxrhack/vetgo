import 'package:flutter/material.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/async_endpoint_button.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Flujo progresivo (varios pasos) para solicitar una visita; demo hasta conectar citas API.
class ScheduleVisitFlowScreen extends StatefulWidget {
  const ScheduleVisitFlowScreen({super.key, required this.pets});

  final List<ClientPetVm> pets;

  @override
  State<ScheduleVisitFlowScreen> createState() => _ScheduleVisitFlowScreenState();
}

class _ScheduleVisitFlowScreenState extends State<ScheduleVisitFlowScreen> {
  final PageController _page = PageController();
  int _step = 0;

  ClientPetVm? _pet;
  DateTime? _suggestedDate;

  @override
  void initState() {
    super.initState();
    if (widget.pets.isNotEmpty) {
      _pet = widget.pets.first;
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _page.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Paso ${_step + 1} de 3'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: active ? scheme.primary : scheme.outline.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepIntro(context),
                _stepPet(context),
                _stepConfirm(context),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _back,
                      child: const Text('Atr\u00E1s'),
                    ),
                  const Spacer(),
                  if (_step < 2)
                    FilledButton(
                      onPressed: _step == 1 && (_pet == null && widget.pets.isNotEmpty)
                          ? null
                          : _step == 1 && widget.pets.isEmpty
                              ? null
                              : _next,
                      child: Text(_step == 0 ? 'Continuar' : 'Siguiente'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIntro(BuildContext context) {
    final muted = ClientPastelColors.mutedOn(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: ClientSoftCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agendar visita a domicilio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'En los siguientes pasos elegir\u00E1s la mascota y una fecha sugerida. '
              'La confirmaci\u00F3n final llegar\u00E1 cuando conectemos la API de citas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepPet(BuildContext context) {
    if (widget.pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay mascotas registradas. Vuelve cuando sincronicemos tus datos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          '\u00BFQu\u00E9 mascota necesita la visita?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...widget.pets.map(
          (ClientPetVm p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _pet = p),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _pet?.id == p.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                            Text(
                              '${p.speciesLabel} \u00B7 ${p.breedLabel}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ClientPastelColors.mutedOn(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepConfirm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    _suggestedDate ??= DateTime.now().add(const Duration(days: 3));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: ClientSoftCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirmaci\u00F3n',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Mascota: ${_pet?.name ?? '\u2014'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha sugerida: ${_suggestedDate!.toIso8601String().split('T').first}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            AsyncEndpointButton(
              label: 'Enviar solicitud',
              icon: Icons.check_rounded,
              loadingLabel: 'Enviando\u2026',
              style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
              onPressed: () async {
                await Future<void>.delayed(const Duration(milliseconds: 1200));
                if (!context.mounted) return;
                VetgoNotice.show(context, message: AppStrings.scheduleSolicitudDemo);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
