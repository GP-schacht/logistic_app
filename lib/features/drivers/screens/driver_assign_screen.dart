import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/drivers_providers.dart';
import '../../../core/config/supabase_config.dart';

class DriverAssignScreen extends ConsumerStatefulWidget {
  const DriverAssignScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<DriverAssignScreen> createState() =>
      _DriverAssignScreenState();
}

class _DriverAssignScreenState extends ConsumerState<DriverAssignScreen> {
  final _formKey       = GlobalKey<FormState>();
  bool _loading        = false;
  bool _loadingTrucks  = false;

  final _licenseCtrl   = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  DateTime? _licenseExpiry;
  String?   _selectedTruckId;
  String?   _truckWarning;
  List<Map<String, dynamic>> _trucks = [];

  @override
  void initState() {
    super.initState();
    _loadTrucks();
  }

  @override
  void dispose() {
    _licenseCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTrucks() async {
    setState(() => _loadingTrucks = true);
    try {
      final rows = await supabase
          .from('trucks')
          .select('id, plate, brand, model, status')
          .order('plate') as List<dynamic>?;

      final validRows = (rows ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .where((t) => t['id'] != null && t['plate'] != null)
          .map((t) => Map<String, dynamic>.from(t))
          .toList();

      debugPrint('Camiones cargados: ${validRows.length}');
      debugPrint('Primer camión: ${validRows.isNotEmpty ? validRows.first : 'Ninguno'}');

      setState(() => _trucks = validRows.isNotEmpty ? validRows : [
        {'id': '1', 'plate': 'ABC-123', 'brand': 'Volvo', 'model': 'FH16', 'status': 'disponible'},
        {'id': '2', 'plate': 'DEF-456', 'brand': 'Scania', 'model': 'R450', 'status': 'disponible'},
        {'id': '3', 'plate': 'GHI-789', 'brand': 'Mercedes', 'model': 'Actros', 'status': 'mantenimiento'},
      ]);
    } catch (e) {
      debugPrint('Error cargando camiones: $e');
      // En caso de error, usar datos de ejemplo
      debugPrint('Usando datos de ejemplo por error de conexión');
      final exampleTrucks = [
        {'id': '1', 'plate': 'ABC-123', 'brand': 'Volvo', 'model': 'FH16', 'status': 'disponible'},
        {'id': '2', 'plate': 'DEF-456', 'brand': 'Scania', 'model': 'R450', 'status': 'disponible'},
      ];
      setState(() => _trucks = exampleTrucks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando camiones: $e\nUsando datos de ejemplo'), backgroundColor: Colors.orange.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTrucks = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _licenseExpiry = picked);
  }

  void _checkTruckWarning(String? truckId) {
    if (truckId == null) {
      setState(() => _truckWarning = null);
      return;
    }
    final truck = _trucks.firstWhere(
      (t) => t['id'] == truckId,
      orElse: () => {},
    );
    final status = truck['status'] as String?;
    setState(() {
      _truckWarning = (status != null && status != 'disponible')
          ? 'Este camión está en $status — podrá cambiarse al crear el viaje'
          : null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de vencimiento')),
      );
      return;
    }
    final profileId = widget.profile['id']?.toString();
    if (profileId == null || profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de perfil no encontrado')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      await ref.read(driversRepoProvider).create(
        profileId:        profileId,
        licenseNumber:    _licenseCtrl.text.trim().toUpperCase(),
        licenseExpiry:    _licenseExpiry!,
        emergencyContact: _emergencyCtrl.text.trim().isEmpty
                              ? null : _emergencyCtrl.text.trim(),
        defaultTruckId:   _selectedTruckId,
      );

      ref.invalidate(driversProvider);
      ref.invalidate(unassignedProfilesProvider);

      if (mounted) {
        context.go('/drivers');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.profile['full_name']} asignado a la flota'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile['full_name']?.toString().trim();
    final displayName = name == null || name.isEmpty ? 'Chofer' : name;
    final phone = widget.profile['phone']?.toString();
    final expiryFormatted = _licenseExpiry == null
        ? 'Seleccionar fecha'
        : '${_licenseExpiry!.day.toString().padLeft(2, '0')}/'
          '${_licenseExpiry!.month.toString().padLeft(2, '0')}/'
          '${_licenseExpiry!.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar conductor')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Info del chofer (solo lectura)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                          child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                      style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                subtitle: Text(phone ?? 'Sin teléfono'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pendiente',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Número de licencia
            TextFormField(
              controller: _licenseCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de licencia *',
                prefixIcon: Icon(Icons.credit_card_outlined),
                border: OutlineInputBorder(),
                hintText: 'LIC-PA-00000',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El número de licencia es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Vencimiento licencia
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vencimiento de licencia *',
                  prefixIcon:
                      Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(expiryFormatted,
                    style: TextStyle(
                      color: _licenseExpiry == null
                          ? Colors.grey.shade600 : null,
                    )),
              ),
            ),
            const SizedBox(height: 16),

            // Contacto de emergencia
            TextFormField(
              controller: _emergencyCtrl,
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia',
                prefixIcon: Icon(Icons.emergency_outlined),
                border: OutlineInputBorder(),
                hintText: 'Nombre + teléfono',
              ),
            ),
            const SizedBox(height: 16),

            // Camión base (opcional)
            _loadingTrucks
                ? const LinearProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String?>(
                          initialValue: _selectedTruckId,
                          decoration: const InputDecoration(
                            labelText: 'Camión base (opcional)',
                            prefixIcon:
                                Icon(Icons.local_shipping_outlined),
                            border: OutlineInputBorder(),
                            helperText:
                                'Se puede asignar o cambiar después',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sin camión base por ahora'),
                            ),
                            ..._trucks.map((t) {
                              final plate = t['plate']?.toString() ?? '';
                              final brand = t['brand']?.toString() ?? '';
                              final model = t['model']?.toString() ?? '';
                              final label =
                                  '$plate · $brand $model'.trim();
                              final enMantenimiento =
                                  t['status']?.toString() == 'mantenimiento';
                              return DropdownMenuItem<String?>(
                                value: t['id']?.toString(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (enMantenimiento) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.build_outlined,
                                          size: 14,
                                          color: Colors.orange),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedTruckId = v);
                            _checkTruckWarning(v);
                          },
                        ),
                      ),

            // Advertencia camión
            if (_truckWarning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_truckWarning!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange)),
                  ),
                ]),
              ),
            ],

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
                    : const Text('Confirmar asignación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}