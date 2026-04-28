import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/drivers_providers.dart';

class DriverFormScreen extends ConsumerStatefulWidget {
  const DriverFormScreen({super.key, this.driverId});
  final String? driverId;

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _formKey    = GlobalKey<FormState>();
  bool _loading     = false;
  bool get _isEditing => widget.driverId != null;

  final _nameCtrl      = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _licenseCtrl   = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  DateTime? _licenseExpiry;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadDriver();
  }

  Future<void> _loadDriver() async {
    final driver = await ref.read(driverByIdProvider(widget.driverId!).future);
    if (driver == null || !mounted) return;
    setState(() {
      _profileId = driver.profileId;
      _nameCtrl.text      = driver.fullName;
      _phoneCtrl.text     = driver.phone ?? '';
      _licenseCtrl.text   = driver.licenseNumber;
      _emergencyCtrl.text = driver.emergencyContact ?? '';
      _licenseExpiry      = driver.licenseExpiry;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _licenseCtrl.dispose(); _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _licenseExpiry = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de vencimiento')),
      );
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
          phone:           _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          licenseNumber:   _licenseCtrl.text.trim().toUpperCase(),
          licenseExpiry:   _licenseExpiry!,
          emergencyContact: _emergencyCtrl.text.trim().isEmpty ? null : _emergencyCtrl.text.trim(),
        );
      } else {
        await repo.create(
          fullName:        _nameCtrl.text.trim(),
          phone:           _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          licenseNumber:   _licenseCtrl.text.trim().toUpperCase(),
          licenseExpiry:   _licenseExpiry!,
          emergencyContact: _emergencyCtrl.text.trim().isEmpty ? null : _emergencyCtrl.text.trim(),
        );
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
    final expiryFormatted = _licenseExpiry == null
        ? 'Seleccionar fecha'
        : '${_licenseExpiry!.day.toString().padLeft(2,'0')}/'
          '${_licenseExpiry!.month.toString().padLeft(2,'0')}/'
          '${_licenseExpiry!.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar conductor' : 'Nuevo conductor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            // Date picker de vencimiento
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vencimiento de licencia *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
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
            TextFormField(
              controller: _emergencyCtrl,
              decoration: const InputDecoration(
                labelText: 'Contacto de emergencia',
                prefixIcon: Icon(Icons.emergency_outlined),
                border: OutlineInputBorder(),
                hintText: 'Nombre + teléfono',
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Guardar cambios' : 'Crear conductor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}