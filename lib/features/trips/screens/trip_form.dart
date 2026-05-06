import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key});

  @override
  ConsumerState<TripFormScreen> createState() =>
      _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey       = GlobalKey<FormState>();
  bool  _loading       = false;

  final _originCtrl      = TextEditingController();
  final _destCtrl        = TextEditingController();
  final _notesCtrl       = TextEditingController();

  String?   _selectedDriverId;
  String?   _selectedTruckId;
  String?   _selectedContainerId;
  DateTime? _scheduledAt;

  // Al elegir conductor, pre-llenar su camión base
  void _onDriverSelected(
      String driverId, List<Map<String, dynamic>> drivers) {
    final driver = drivers.firstWhere(
      (d) => d['id'] == driverId,
      orElse: () => {},
    );
    setState(() {
      _selectedDriverId = driverId;
      _selectedTruckId  =
          driver['default_truck_id'] as String?;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDriverId == null ||
        _selectedTruckId == null ||
        _selectedContainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Selecciona conductor, camión y contenedor'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final trip = Trip(
        id:           '',
        truckId:      _selectedTruckId!,
        driverId:     _selectedDriverId!,
        containerId:  _selectedContainerId!,
        origin:       _originCtrl.text.trim(),
        destination:  _destCtrl.text.trim(),
        status:       TripStatus.programado,
        scheduledAt:  _scheduledAt,
        notes:        _notesCtrl.text.trim().isEmpty
                          ? null : _notesCtrl.text.trim(),
        createdAt:    DateTime.now(),
      );
      await ref.read(tripsRepoProvider).create(trip);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync    = ref.watch(availableDriversProvider);
    final containersAsync = ref.watch(availableContainersProvider);

    final scheduledLabel = _scheduledAt == null
        ? 'Seleccionar fecha y hora'
        : '${_scheduledAt!.day.toString().padLeft(2,'0')}/'
          '${_scheduledAt!.month.toString().padLeft(2,'0')}/'
          '${_scheduledAt!.year}  '
          '${_scheduledAt!.hour.toString().padLeft(2,'0')}:'
          '${_scheduledAt!.minute.toString().padLeft(2,'0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo viaje')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Origen
            TextFormField(
              controller: _originCtrl,
              decoration: const InputDecoration(
                labelText: 'Origen *',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(),
                hintText: 'Puerto Balboa',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa el origen' : null,
            ),
            const SizedBox(height: 16),

            // Destino
            TextFormField(
              controller: _destCtrl,
              decoration: const InputDecoration(
                labelText: 'Destino *',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
                hintText: 'Ciudad de Panamá',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa el destino' : null,
            ),
            const SizedBox(height: 16),

            // Conductor
            driversAsync.when(
              loading: () => const LinearProgressIndicator(),
              error:   (e, _) => Text('Error: $e'),
              data: (drivers) => DropdownButtonFormField<String>(
                value: _selectedDriverId,
                decoration: const InputDecoration(
                  labelText: 'Conductor *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: drivers.map((d) {
                  final name = d['drivers']?['profiles']
                          ?['full_name'] as String?
                      ?? d['profiles']?['full_name'] as String?
                      ?? 'Sin nombre';
                  return DropdownMenuItem(
                    value: d['id'] as String,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) _onDriverSelected(v, drivers);
                },
                validator: (v) =>
                    v == null ? 'Selecciona un conductor' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Camión — pre-llenado del camión base
            driversAsync.when(
              loading: () => const LinearProgressIndicator(),
              error:   (e, _) => Text('Error: $e'),
              data: (drivers) {
                // Todos los camiones disponibles
                final allTrucks = drivers
                    .where((d) => d['default_truck_id'] != null)
                    .map((d) => {
                          'id':    d['default_truck_id'],
                          'plate': d['trucks']?['plate'] ?? '—',
                        })
                    .toList();

                return DropdownButtonFormField<String>(
                  value: _selectedTruckId,
                  decoration: InputDecoration(
                    labelText: 'Camión *',
                    prefixIcon: const Icon(
                        Icons.local_shipping_outlined),
                    border: const OutlineInputBorder(),
                    helperText: _selectedDriverId != null
                        ? 'Pre-llenado con el camión base '
                          'del conductor'
                        : null,
                  ),
                  items: allTrucks.map((t) => DropdownMenuItem(
                    value: t['id'] as String,
                    child: Text(t['plate'] as String),
                  )).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedTruckId = v),
                  validator: (v) =>
                      v == null ? 'Selecciona un camión' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Contenedor
            containersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error:   (e, _) => Text('Error: $e'),
              data: (containers) =>
                  DropdownButtonFormField<String>(
                value: _selectedContainerId,
                decoration: const InputDecoration(
                  labelText: 'Contenedor *',
                  prefixIcon:
                      Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                items: containers.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text(
                    '${c['container_number']} · '
                    '${c['type'] ?? ''}',
                  ),
                )).toList(),
                onChanged: (v) =>
                    setState(() => _selectedContainerId = v),
                validator: (v) =>
                    v == null ? 'Selecciona un contenedor' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Fecha y hora programada
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha programada',
                  prefixIcon:
                      Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(scheduledLabel,
                    style: TextStyle(
                      color: _scheduledAt == null
                          ? Colors.grey.shade600 : null,
                    )),
              ),
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text('Crear viaje'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}