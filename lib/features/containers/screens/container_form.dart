import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/container.dart';
import '../providers/containers_provider.dart';

class ContainerFormScreen extends ConsumerStatefulWidget {
  const ContainerFormScreen({super.key, this.containerId});
  final String? containerId;

  @override
  ConsumerState<ContainerFormScreen> createState() =>
      _ContainerFormScreenState();
}

class _ContainerFormScreenState
    extends ConsumerState<ContainerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;
  bool get _isEditing => widget.containerId != null;

  final _numberCtrl   = TextEditingController();
  final _blCtrl       = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _weightCtrl   = TextEditingController();
  final _notesCtrl    = TextEditingController();

  ContainerType?   _type;
  ContainerStatus  _status = ContainerStatus.en_patio;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadContainer();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _blCtrl.dispose();
    _locationCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContainer() async {
    final containerModel =
        await ref.read(containerByIdProvider(widget.containerId!).future);
    if (containerModel == null || !mounted) return;
    setState(() {
      _numberCtrl.text   = containerModel.containerNumber;
      _blCtrl.text       = containerModel.blNumber ?? '';
      _locationCtrl.text = containerModel.currentLocation ?? '';
      _weightCtrl.text   = containerModel.weightKg?.toString() ?? '';
      _notesCtrl.text    = containerModel.notes ?? '';
      _type              = containerModel.type;
      _status            = containerModel.status;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final containerModel = ContainerModel(
      id:              widget.containerId ?? '',
      containerNumber: _numberCtrl.text.trim().toUpperCase(),
      type:            _type,
      weightKg:        double.tryParse(_weightCtrl.text),
      status:          _status,
      currentLocation: _locationCtrl.text.trim().isEmpty
                           ? null : _locationCtrl.text.trim(),
      blNumber:        _blCtrl.text.trim().isEmpty
                           ? null : _blCtrl.text.trim().toUpperCase(),
      notes:           _notesCtrl.text.trim().isEmpty
                           ? null : _notesCtrl.text.trim(),
      createdAt:       DateTime.now(),
    );

    try {
      final repo = ref.read(containersRepoProvider);
      if (_isEditing) {
        await repo.update(widget.containerId!, containerModel);
      } else {
        await repo.create(containerModel);
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar contenedor' : 'Nuevo contenedor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Número de contenedor
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de contenedor *',
                hintText: 'MSCU1234567',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El número es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Número BL
            TextFormField(
              controller: _blCtrl,
              decoration: const InputDecoration(
                labelText: 'Número BL',
                hintText: 'MSCUBL123456',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Tipo + Peso en fila
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<ContainerType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: ContainerType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()
                        .replaceAll('_', ' ')),
                  )).toList(),
                  onChanged: (v) => setState(() => _type = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Ubicación actual
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Ubicación actual',
                hintText: 'Puerto Balboa — Patio 3',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Estado
            DropdownButtonFormField<ContainerStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
              items: ContainerStatus.values.map((s) {
                final label = switch (s) {
                  ContainerStatus.en_patio    => 'En patio',
                  ContainerStatus.en_puerto   => 'En puerto',
                  ContainerStatus.en_transito => 'En tránsito',
                  ContainerStatus.entregado   => 'Entregado',
                };
                return DropdownMenuItem(value: s, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _status = v!),
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
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing
                        ? 'Guardar cambios' : 'Crear contenedor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}