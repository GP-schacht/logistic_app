import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../../../shared/widgets/bottom_navegation.dart';
import '../../../core/providers/auth_provider.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _statuses = [
    null,                    // Todos
    TripStatus.programado,
    TripStatus.en_curso,
    TripStatus.completado,
    TripStatus.cancelado,
  ];

  static const _labels = [
    'Todos', 'Programados', 'En curso', 'Completados', 'Cancelados'
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripsProvider);
    final role       = ref.watch(userRoleProvider);

    return MainScaffold(
      title: 'Viajes',
      floatingActionButton: role.canEdit
          ? FloatingActionButton(
              heroTag: 'new_trip',
              onPressed: () async {
                await context.push('/trips/new');
                ref.invalidate(tripsProvider);
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      child: Column(
        children: [
          // Tabs de filtro
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _labels.map((l) => Tab(text: l)).toList(),
          ),
          Expanded(
            child: tripsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (trips) => TabBarView(
                controller: _tabs,
                children: _statuses.map((status) {
                  final filtered = status == null
                      ? trips
                      : trips
                          .where((t) => t.status == status)
                          .toList();
                  return _TripsList(
                    trips: filtered,
                    onRefresh: () async =>
                        ref.invalidate(tripsProvider),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  const _TripsList({required this.trips, required this.onRefresh});
  final List<Trip> trips;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.route_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('Sin viajes en esta categoría',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _TripCard(trip: trips[i]),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/trips/${trip.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — ruta + badge
              Row(children: [
                Expanded(
                  child: Text(
                    '${trip.origin}  →  ${trip.destination}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _StatusBadge(status: trip.status),
              ]),
              const SizedBox(height: 10),
              // Info chips
              Wrap(spacing: 12, runSpacing: 6, children: [
                if (trip.truckPlate != null)
                  _Chip(Icons.local_shipping_outlined,
                      trip.truckPlate!),
                if (trip.driverName != null)
                  _Chip(Icons.person_outline, trip.driverName!),
                if (trip.containerNumber != null)
                  _Chip(Icons.inventory_2_outlined,
                      trip.containerNumber!),
              ]),
              // Fecha programada
              if (trip.scheduledAt != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.schedule,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(_formatDate(trip.scheduledAt!),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TripStatus.programado  => ('Programado',  Colors.purple),
      TripStatus.en_curso    => ('En curso',    Colors.blue),
      TripStatus.completado  => ('Completado',  Colors.green),
      TripStatus.cancelado   => ('Cancelado',   Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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