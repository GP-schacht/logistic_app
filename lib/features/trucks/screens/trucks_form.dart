import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trucks.dart';
import '../providers/trucks_provider.dart';

class TruckFormScreen extends ConsumerStatefulWidget {
  const TruckFormScreen({super.key, this.truckId});
  final String? truckId; // null = crear, string = editar

  @override
  ConsumerState<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends ConsumerState<TruckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool get _isEditing => widget.truckId != null;

  // Controladores
  late final _plateCtrl    = TextEditingController();
  late final _brandCtrl    = TextEditingController();
  late final _modelCtrl    = TextEditingController();
  late final _yearCtrl     = TextEditingController();
  late final _capacityCtrl = TextEditingController();
  TruckStatus _status = TruckStatus.disponible;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadTruck();
  }

  Future<void> _loadTruck() async {
    final truck = await ref.read(truckByIdProvider(widget.truckId!).future);
    if (truck == null || !mounted) return;
    _plateCtrl.text    = truck.plate;
    _brandCtrl.text    = truck.brand    ?? '';
    _modelCtrl.text    = truck.model    ?? '';
    _yearCtrl.text     = truck.year?.toString() ?? '';
    _capacityCtrl.text = truck.capacityTons?.toString() ?? '';
    setState(() => _status = truck.status);
  }

  @override
  void dispose() {
    _plateCtrl.dispose(); _brandCtrl.dispose();
    _modelCtrl.dispose(); _yearCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final truck = Truck(
      id:           widget.truckId ?? '',
      plate:        _plateCtrl.text.trim().toUpperCase(),
      brand:        _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      model:        _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      year:         int.tryParse(_yearCtrl.text),
      capacityTons: double.tryParse(_capacityCtrl.text),
      status:       _status,
      createdAt:    DateTime.now(),
    );

    try {
      final repo = ref.read(trucksRepoProvider);
      if (_isEditing) {
        await repo.update(widget.truckId!, truck);
      } else {
        await repo.create(truck);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar camión' : 'Nuevo camión'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _plateCtrl,
              decoration: const InputDecoration(
                labelText: 'Placa *',
                hintText: 'ABC-1234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'La placa es obligatoria' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Marca', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modelo', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _yearCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Año', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final y = int.tryParse(v);
                    if (y == null || y < 1990 || y > 2030)
                      return 'Año no válido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _capacityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad (ton)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<TruckStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado', border: OutlineInputBorder()),
              items: TruckStatus.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name[0].toUpperCase() + s.name.substring(1)
                    .replaceAll('_', ' ')),
              )).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Guardar cambios' : 'Crear camión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}