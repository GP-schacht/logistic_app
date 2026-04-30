import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/drivers_providers.dart';
import '../../../core/config/supabase_config.dart';

class DriverFormScreen extends ConsumerStatefulWidget {
  const DriverFormScreen({super.key, this.driverId});
  final String? driverId;

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _formKey         = GlobalKey<FormState>();
  bool _loading          = false;
  bool _loadingTrucks    = false;
  bool get _isEditing    => widget.driverId != null;

  final _nameCtrl        = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _licenseCtrl     = TextEditingController();
  final _emergencyCtrl   = TextEditingController();

  DateTime? _licenseExpiry;
  String?   _profileId;
  String?   _defaultTruckId;
  String?   _truckWarning;

  List<Map<String, dynamic>> _trucks = [];

  @override
  void initState() {
    super.initState();
    _loadTrucks();
    if (_isEditing) _loadDriver();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  // ── Carga camiones disponibles ───────────────────────────
  Future<void> _loadTrucks() async {
    setState(() => _loadingTrucks = true);
    try {
      final rows = await supabase
          .from('trucks')
          .select('id, plate, brand, model, status')
          .order('plate');
      setState(() => _trucks = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      _showError('Error cargando camiones: $e');
    } finally {
      if (mounted) setState(() => _loadingTrucks = false);
    }
  }

  // ── Carga datos del conductor al editar ──────────────────
  Future<void> _loadDriver() async {
    try {
      final driver = await ref.read(driverByIdProvider(widget.driverId!).future);
      if (driver == null || !mounted) return;
      setState(() {
        _profileId           = driver.profileId;
        _nameCtrl.text       = driver.fullName;
        _phoneCtrl.text      = driver.phone ?? '';
        _licenseCtrl.text    = driver.licenseNumber;
        _emergencyCtrl.text  = driver.emergencyContact ?? '';
        _licenseExpiry       = driver.licenseExpiry;
        _defaultTruckId      = driver.defaultTruckId;
      });
      _checkTruckWarning(_defaultTruckId);
    } catch (e) {
      _showError('Error cargando conductor: $e');
    }
  }

  // ── Selector de fecha de vencimiento ─────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ??
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _licenseExpiry = picked);
  }

  // ── Advertencia si el camión base no está disponible ─────
  void _checkTruckWarning(String? truckId) {
    if (truckId == null) {
      setState(() => _truckWarning = null);
      return;
    }
    final truck = _trucks.firstWhere(
      (t) => t['id'] == truckId,
      orElse: () => {},
    );
    if (truck.isEmpty) return;
    final status = truck['status'] as String?;
    setState(() {
      _truckWarning = (status != null && status != 'disponible')
          ? 'Este camión está en $status — se deberá asignar otro al crear el viaje'
          : null;
    });
  }

  // ── Guardar ──────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null) {
      _showError('Selecciona la fecha de vencimiento de la licencia');
      return;
    }
    setState(() => _loading = true);

    try {
      final repo = ref.read(driversRepoProvider);

      if (_isEditing) {
        await repo.update(
          driverId:        widget.driverId!,
          profileId:       _profileId!,
          fullName:        _nameCtrl.text.trim(),
          phone:           _phoneCtrl.text.trim().isEmpty
                               ? null : _phoneCtrl.text.trim(),
          licenseNumber:   _licenseCtrl.text.trim().toUpperCase(),
          licenseExpiry:   _licenseExpiry!,
          emergencyContact: _emergencyCtrl.text.trim().isEmpty
                               ? null : _emergencyCtrl.text.trim(),
          defaultTruckId:  _defaultTruckId,
        );
      } else {
        await repo.create(
          fullName:        _nameCtrl.text.trim(),
          phone:           _phoneCtrl.text.trim().isEmpty
                               ? null : _phoneCtrl.text.trim(),
          licenseNumber:   _licenseCtrl.text.trim().toUpperCase(),
          licenseExpiry:   _licenseExpiry!,
          emergencyContact: _emergencyCtrl.text.trim().isEmpty
                               ? null : _emergencyCtrl.text.trim(),
          defaultTruckId:  _defaultTruckId,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  String get _expiryFormatted => _licenseExpiry == null
      ? 'Seleccionar fecha'
      : '${_licenseExpiry!.day.toString().padLeft(2, '0')}/'
        '${_licenseExpiry!.month.toString().padLeft(2, '0')}/'
        '${_licenseExpiry!.year}';

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar conductor' : 'Nuevo conductor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Nombre
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Ingresa el nombre completo' : null,
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: '+507 6000-0000',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

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

            // Fecha de vencimiento
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vencimiento de licencia *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _expiryFormatted,
                  style: TextStyle(
                    color: _licenseExpiry == null
                        ? Colors.grey.shade600 : null,
                  ),
                ),
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

            // Camión base
            _loadingTrucks
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _defaultTruckId,
                    decoration: const InputDecoration(
                      labelText: 'Camión base asignado',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'Se puede cambiar por viaje si es necesario',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin camión base'),
                      ),
                      ..._trucks.map((t) {
                        final label =
                            '${t['plate']} · ${t['brand'] ?? ''} '
                            '${t['model'] ?? ''}'.trim();
                        final enMantenimiento =
                            t['status'] == 'mantenimiento';
                        return DropdownMenuItem(
                          value: t['id'] as String,
                          child: Row(children: [
                            Expanded(child: Text(label)),
                            if (enMantenimiento)
                              const Icon(Icons.build_outlined,
                                  size: 14, color: Colors.orange),
                          ]),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setState(() => _defaultTruckId = v);
                      _checkTruckWarning(v);
                    },
                  ),

            // Advertencia camión en mantenimiento
            if (_truckWarning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _truckWarning!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 28),

            // Botón guardar
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing
                        ? 'Guardar cambios' : 'Crear conductor'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}