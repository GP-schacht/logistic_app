import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

enum AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();
bool _loading = false;
bool _obscurePassword = true;
bool _obscureConfirm = true;


//controladores
final _nameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmController = TextEditingController();

String _selectedRole = 'chofer';

@override
void dispose(){
  _nameController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
  _confirmController.dispose();
  super.dispose();
} // valor por defecto

// LOGIN--------------------------------------------------------------
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
     _showError(_mapAuthError(e.message));
    } catch (_) {
      _showError('Error inesperado. Intenta nuevamente.');
    } 
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

//REGISTRO
Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
         emailRedirectTo: 'io.supabase.logiflow://login-callback',
        data: {
          'full_name': _nameController.text.trim(),
          'role': _selectedRole,
        },
      );

      if (mounted) {
        _showSuccess('Cuenta creada.');
        setState(() => _mode = AuthMode.login);
      }
    } on AuthException catch (e) {
      _showError(_mapAuthError(e.message));
    } catch (_) {
      _showError('Error al crear cuenta. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

// ERROR MAPPING------------------------------------------------------
String _mapAuthError(String message) {
  if (message.contains('Invalid Login')) return 'Correo o contraseña incorrectos.';
  if (message.contains('User not found')) return 'No existe una cuenta con ese correo';
  if (message.contains('already registered')) return 'Ya existe una cuenta con ese correo';
  if (message.contains('Password should be')) return 'La contraseña debe tener al menos 6 caracteres';
  return message; // mensaje original si no se mapea
}

void _showError(String message) {
if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}
void _showSuccess(String message) {
if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.green),
  );
}

 // ── UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // Logo
                  const Icon(Icons.local_shipping_rounded, size: 56, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text('LogiFlow',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Gestión de contenedores y flota',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 32),

                  // Tabs
                  SegmentedButton<AuthMode>(
                    segments: const [
                      ButtonSegment(value: AuthMode.login,    label: Text('Ingresar')),
                      ButtonSegment(value: AuthMode.register, label: Text('Registrarse')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (v) {
                      setState(() {
                        _mode = v.first;
                        _formKey.currentState?.reset();
                      });
                    },
                  ),
                  const SizedBox(height: 28),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Solo en registro
                        if (!isLogin) ...[
                          _buildField(
                            controller: _nameController,
                            label: 'Nombre completo',
                            hint: 'Juan Pérez',
                            icon: Icons.person_outline,
                            validator: (v) =>
                              (v == null || v.trim().length < 3) ? 'Ingresa tu nombre completo' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          hint: 'correo@empresa.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          toggleObscure: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            if (!isLogin && v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),

                        // Solo en registro
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _confirmController,
                            label: 'Confirmar contraseña',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscureConfirm,
                            toggleObscure: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                            validator: (v) =>
                              v != _passwordController.text ? 'Las contraseñas no coinciden' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildRoleDropdown(),
                        ],

                        const SizedBox(height: 24),

                        // Botón principal
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : (isLogin ? _login : _register),
                            child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                              : Text(isLogin ? 'Ingresar' : 'Crear cuenta'),
                          ),
                        ),

                        // Recuperar contraseña (solo en login)
                        if (isLogin) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _forgotPassword,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: toggleObscure != null
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: toggleObscure,
            )
          : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      decoration: const InputDecoration(
        labelText: 'Rol',
        prefixIcon: Icon(Icons.badge_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'chofer',   child: Text('Chofer')),
        DropdownMenuItem(value: 'operador', child: Text('Operador')),
      ],
      onChanged: (v) => setState(() => _selectedRole = v!),
      // Admin no aparece aquí — solo otro admin puede asignarlo
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresa tu correo primero.');
      return;
    }
    await supabase.auth.resetPasswordForEmail(email);
    _showSuccess('Revisa tu correo para restablecer tu contraseña.');
  }
}