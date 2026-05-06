import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../../../core/providers/auth_provider.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripByIdProvider(tripId));
    final role      = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del viaje'),
        actions: [
          if (role.canEdit)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'cancel') await _cancel(context, ref);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: Icon(Icons.cancel_outlined,
                        color: Colors.red),
                    title: Text('Cancelar viaje',
                        style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: tripAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trip) => trip == null
            ? const Center(child: Text('Viaje no encontrado'))
            : _TripDetailBody(
                trip: trip,
                canEdit: role.canEdit,
                onStatusUpdate: () =>
                    ref.invalidate(tripByIdProvider(tripId)),
              ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Confirmas la cancelación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar viaje'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(tripsRepoProvider).cancel(tripId);
      ref.invalidate(tripByIdProvider(tripId));
      ref.invalidate(tripsProvider);
    }
  }
}

class _TripDetailBody extends ConsumerWidget {
  const _TripDetailBody({
    required this.trip,
    required this.canEdit,
    required this.onStatusUpdate,
  });
  final Trip trip;
  final bool canEdit;
  final VoidCallback onStatusUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RouteCard(trip: trip),
        const SizedBox(height: 12),
        _TimelineCard(trip: trip),
        const SizedBox(height: 12),
        _AssetsCard(trip: trip),
        const SizedBox(height: 12),
        if (trip.notes != null) _NotesCard(notes: trip.notes!),
        if (trip.notes != null) const SizedBox(height: 12),
        // Botón de avance de estado
        if (trip.nextStatus != null)
          _StatusButton(
            trip: trip,
            onPressed: () async {
              await ref
                  .read(tripsRepoProvider)
                  .updateStatus(trip.id, trip.nextStatus!);
              ref.invalidate(tripsProvider);
              onStatusUpdate();
            },
          ),
      ],
    );
  }
}

// ── Tarjeta de ruta ──────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: trip.status),
              if (trip.scheduledAt != null)
                Text(_formatDate(trip.scheduledAt!),
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Column(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2, height: 32,
                color: Colors.grey.shade300,
              ),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.origin,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  Text(trip.destination,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Timeline de estados ──────────────────────────────────

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        label: 'Programado',
        time: trip.scheduledAt,
        done: true,
      ),
      _TimelineStep(
        label: 'En curso',
        time: trip.startedAt,
        done: trip.startedAt != null,
      ),
      _TimelineStep(
        label: 'Completado',
        time: trip.completedAt,
        done: trip.completedAt != null,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final i    = entry.key;
              final step = entry.value;
              final isLast = i == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador
                  Column(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: step.done
                            ? Colors.blue
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.done
                              ? Colors.blue
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: step.done
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2, height: 32,
                        color: step.done
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.grey.shade200,
                      ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(step.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: step.done
                                    ? null
                                    : Colors.grey.shade400,
                              )),
                          if (step.time != null)
                            Text(_formatDateTime(step.time!),
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey.shade500)),
                          if (!isLast)
                            const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.time,
    required this.done,
  });
  final String    label;
  final DateTime? time;
  final bool      done;
}

// ── Assets asignados ─────────────────────────────────────

class _AssetsCard extends StatelessWidget {
  const _AssetsCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          _AssetRow(
            icon: Icons.local_shipping_outlined,
            label: 'Camión',
            value: trip.truckPlate ?? '—',
          ),
          _Divider(),
          _AssetRow(
            icon: Icons.person_outline,
            label: 'Conductor',
            value: trip.driverName ?? '—',
          ),
          _Divider(),
          _AssetRow(
            icon: Icons.inventory_2_outlined,
            label: 'Contenedor',
            value: trip.containerNumber ?? '—',
          ),
        ]),
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
      height: 1,
      indent: 46,
      color: Colors.grey.withOpacity(0.15));
}

// ── Notas ────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notas',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                        fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(notes,
                style: TextStyle(
                    color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ── Botón de avance de estado ────────────────────────────

class _StatusButton extends StatefulWidget {
  const _StatusButton({
    required this.trip,
    required this.onPressed,
  });
  final Trip trip;
  final Future<void> Function() onPressed;

  @override
  State<_StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<_StatusButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.trip.nextStatus == TripStatus.en_curso
        ? Colors.blue
        : Colors.green;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onPressed();
                if (mounted) setState(() => _loading = false);
              },
        icon: _loading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(widget.trip.nextStatus == TripStatus.en_curso
                ? Icons.play_arrow_rounded
                : Icons.task_alt),
        label: Text(widget.trip.nextStatusLabel),
      ),
    );
  }
}

// ── Badge reutilizado ────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TripStatus.programado => ('Programado', Colors.purple),
      TripStatus.en_curso   => ('En curso',   Colors.blue),
      TripStatus.completado => ('Completado', Colors.green),
      TripStatus.cancelado  => ('Cancelado',  Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}