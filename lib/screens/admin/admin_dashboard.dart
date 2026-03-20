import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  List<dynamic> _usuarios = [];
  List<dynamic> _planes = [];
  List<dynamic> _onboardings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.listarUsuarios(),
        ApiService.listarPlanes(),
        ApiService.listarOnboardings(),
      ]);
      setState(() {
        _usuarios = results[0];
        _planes = results[1];
        _onboardings = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ── Modales ───────────────────────────────────────────────

  void _showNuevoEmpleado() {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: const Text('Nuevo empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalField('Nombre completo', nombreCtrl,
                      Icons.person_outline, (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  _modalField('Correo electrónico', emailCtrl,
                      Icons.email_outlined, (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _modalField('Contraseña', passCtrl,
                      Icons.lock_outline, (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  }, obscure: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateModal(() => loading = true);
                      try {
                        final auth = context.read<AuthProvider>();
                        await ApiService.register(
                          nombre: nombreCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text,
                          empresaId: auth.empresaId,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                          _showSnack('Empleado creado correctamente', success: true);
                        }
                      } catch (e) {
                        setStateModal(() => loading = false);
                        _showSnack(e.toString().replaceAll('Exception: ', ''));
                      }
                    },
              style: _btnStyle(),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Crear empleado'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNuevoPlan() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool esPlantilla = false;
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: const Text('Nuevo plan de onboarding',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalField('Nombre del plan', nombreCtrl,
                      Icons.assignment_outlined,
                      (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: _inputDec(
                        'Descripción del plan (opcional)',
                        Icons.notes_outlined),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: esPlantilla,
                        onChanged: (v) =>
                            setStateModal(() => esPlantilla = v),
                        activeColor: const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 8),
                      const Text('Marcar como plantilla',
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateModal(() => loading = true);
                      try {
                        await ApiService.crearPlan(
                          nombre: nombreCtrl.text.trim(),
                          descripcion: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          esPlantilla: esPlantilla,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                          _showSnack('Plan creado correctamente',
                              success: true);
                        }
                      } catch (e) {
                        setStateModal(() => loading = false);
                        _showSnack(
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    },
              style: _btnStyle(),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Crear plan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNuevoStep(int idPlan, String nombrePlan) {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ordenCtrl = TextEditingController(text: '1');
    final diasCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: Text('Nueva etapa — $nombrePlan',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalField('Título de la etapa', tituloCtrl,
                      Icons.view_agenda_outlined,
                      (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: _inputDec(
                        'Descripción (opcional)', Icons.notes_outlined),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _modalField('Orden', ordenCtrl,
                            Icons.format_list_numbered, (v) {
                          if (v!.isEmpty) return 'Requerido';
                          if (int.tryParse(v) == null) return 'Número';
                          return null;
                        }, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _modalField('Duración (días)', diasCtrl,
                            Icons.calendar_today_outlined, (v) {
                          if (v!.isNotEmpty && int.tryParse(v) == null) {
                            return 'Número';
                          }
                          return null;
                        }, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateModal(() => loading = true);
                      try {
                        await ApiService.crearStep(
                          idPlan: idPlan,
                          titulo: tituloCtrl.text.trim(),
                          descripcion: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          orden: int.parse(ordenCtrl.text),
                          duracionDias: diasCtrl.text.trim().isEmpty
                              ? null
                              : int.parse(diasCtrl.text),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _showSnack('Etapa creada correctamente',
                              success: true);
                        }
                      } catch (e) {
                        setStateModal(() => loading = false);
                        _showSnack(
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    },
              style: _btnStyle(),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Crear etapa'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNuevoTask(int idStep) {
    final tituloCtrl = TextEditingController();
    final ordenCtrl = TextEditingController(text: '1');
    String tipoSeleccionado = 'CONFIRMACION';
    bool obligatorio = true;
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    final tipos = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: const Text('Nueva tarea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modalField('Título de la tarea', tituloCtrl,
                      Icons.task_outlined,
                      (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipoSeleccionado,
                    decoration: _inputDec('Tipo de tarea', Icons.category_outlined),
                    items: tipos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setStateModal(() => tipoSeleccionado = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _modalField('Orden', ordenCtrl,
                            Icons.format_list_numbered, (v) {
                          if (v!.isEmpty) return 'Requerido';
                          if (int.tryParse(v) == null) return 'Número';
                          return null;
                        }, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Switch(
                            value: obligatorio,
                            onChanged: (v) =>
                                setStateModal(() => obligatorio = v),
                            activeColor: const Color(0xFF1565C0),
                          ),
                          const Text('Obligatoria',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateModal(() => loading = true);
                      try {
                        await ApiService.crearTask(
                          idStep: idStep,
                          titulo: tituloCtrl.text.trim(),
                          tipo: tipoSeleccionado,
                          obligatorio: obligatorio,
                          orden: int.parse(ordenCtrl.text),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _showSnack('Tarea creada correctamente',
                              success: true);
                        }
                      } catch (e) {
                        setStateModal(() => loading = false);
                        _showSnack(
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    },
              style: _btnStyle(),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Crear tarea'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAsignarPlan() {
    if (_usuarios.isEmpty || _planes.isEmpty) {
      _showSnack('Necesitas al menos un empleado y un plan');
      return;
    }

    int? usuarioSeleccionado;
    int? planSeleccionado;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: const Text('Asignar plan a empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Empleado',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151))),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: usuarioSeleccionado,
                  decoration: _inputDec('Selecciona un empleado', Icons.person_outline),
                  items: _usuarios
                      .map((u) => DropdownMenuItem<int>(
                            value: u['id_user'] as int,
                            child: Text('${u['nombre']} — ${u['email']}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setStateModal(() => usuarioSeleccionado = v),
                ),
                const SizedBox(height: 16),
                const Text('Plan de onboarding',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151))),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: planSeleccionado,
                  decoration: _inputDec(
                      'Selecciona un plan', Icons.assignment_outlined),
                  items: _planes
                      .map((p) => DropdownMenuItem<int>(
                            value: p['id_plan'] as int,
                            child: Text(p['nombre'] as String,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setStateModal(() => planSeleccionado = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (usuarioSeleccionado == null ||
                          planSeleccionado == null) {
                        _showSnack('Selecciona empleado y plan');
                        return;
                      }
                      setStateModal(() => loading = true);
                      try {
                        await ApiService.asignarPlan(
                          idUser: usuarioSeleccionado!,
                          idPlan: planSeleccionado!,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                          _showSnack('Plan asignado correctamente',
                              success: true);
                        }
                      } catch (e) {
                        setStateModal(() => loading = false);
                        _showSnack(
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    },
              style: _btnStyle(),
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Asignar plan'),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
    ));
  }

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _modalField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    String? Function(String?) validator, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: _inputDec(label, icon),
      validator: validator,
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          _buildSidebar(auth),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(auth),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AuthProvider auth) {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.people_rounded, 'label': 'Empleados'},
      {'icon': Icons.assignment_rounded, 'label': 'Planes'},
      {'icon': Icons.track_changes_rounded, 'label': 'Onboardings'},
    ];

    return Container(
      width: 220,
      color: const Color(0xFF1565C0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Onboarding',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(auth.userName,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isSelected = _selectedIndex == i;
            return InkWell(
              onTap: () => setState(() => _selectedIndex = i),
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        size: 20),
                    const SizedBox(width: 10),
                    Text(item['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          InkWell(
            onTap: () async {
              await auth.logout();
              if (mounted) context.go('/login');
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      color: Colors.white.withOpacity(0.6), size: 20),
                  const SizedBox(width: 10),
                  Text('Cerrar sesión',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
    final titles = [
      'Dashboard',
      'Empleados',
      'Planes de Onboarding',
      'Onboardings Activos'
    ];
    final actions = [
      null,
      () => _showNuevoEmpleado(),
      () => _showNuevoPlan(),
      () => _showAsignarPlan(),
    ];
    final actionLabels = [
      null,
      'Nuevo empleado',
      'Nuevo plan',
      'Asignar plan',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(titles[_selectedIndex],
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF6B7280)),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          if (actions[_selectedIndex] != null) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: actions[_selectedIndex],
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabels[_selectedIndex]!),
              style: _btnStyle(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardHome();
      case 1: return _buildEmpleados();
      case 2: return _buildPlanes();
      case 3: return _buildOnboardings();
      default: return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    final completados =
        _onboardings.where((o) => o['estado'] == 'COMPLETADO').length;
    final enProgreso =
        _onboardings.where((o) => o['estado'] == 'EN_PROGRESO').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _statCard('Empleados', _usuarios.length.toString(),
                  Icons.people_rounded, const Color(0xFF1565C0)),
              _statCard('Planes', _planes.length.toString(),
                  Icons.assignment_rounded, const Color(0xFF7C3AED)),
              _statCard('En Progreso', enProgreso.toString(),
                  Icons.track_changes_rounded, const Color(0xFFF59E0B)),
              _statCard('Completados', completados.toString(),
                  Icons.check_circle_rounded, const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Onboardings recientes',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._onboardings.take(5).map((o) => _onboardingCard(o)),
        ],
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpleados() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text('Nombre',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF6B7280)))),
                  Expanded(
                      flex: 4,
                      child: Text('Email',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF6B7280)))),
                  Expanded(
                      flex: 2,
                      child: Text('Roles',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF6B7280)))),
                ],
              ),
            ),
            ..._usuarios.map((u) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1565C0)
                                    .withOpacity(0.1),
                                child: Text(
                                  (u['nombre'] as String)
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(u['nombre'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 14))),
                            ],
                          )),
                      Expanded(
                          flex: 4,
                          child: Text(u['email'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280)))),
                      Expanded(
                          flex: 2,
                          child: Wrap(
                            spacing: 4,
                            children: (u['roles'] as List<dynamic>? ?? [])
                                .map((r) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: r == 'ADMIN_EMPRESA'
                                            ? const Color(0xFFEDE9FE)
                                            : const Color(0xFFE0F2FE),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(r.toString(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: r == 'ADMIN_EMPRESA'
                                                ? const Color(0xFF7C3AED)
                                                : const Color(0xFF0369A1),
                                            fontWeight: FontWeight.w500,
                                          )),
                                    ))
                                .toList(),
                          )),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: _planes.map((p) {
          final idPlan = p['id_plan'] as int;
          final nombre = p['nombre'] as String;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_rounded,
                          color: Color(0xFF7C3AED), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          if (p['descripcion'] != null)
                            Text(p['descripcion'],
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    if (p['es_plantilla'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Plantilla',
                            style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botones de acción del plan
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showNuevoStep(idPlan, nombre),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar etapa',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(
                            color: Color(0xFF7C3AED)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showPlanDetalle(idPlan, nombre),
                      icon: const Icon(Icons.visibility_outlined,
                          size: 16),
                      label: const Text('Ver detalle',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(
                            color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPlanDetalle(int idPlan, String nombrePlan) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.obtenerPlan(idPlan),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final plan = snapshot.data!;
          final steps =
              plan['steps'] as List<dynamic>? ?? [];
          return AlertDialog(
            title: Text(nombrePlan,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: steps.map((s) {
                    final tasks =
                        s['tasks'] as List<dynamic>? ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    s['orden'].toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(s['titulo'],
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 14)),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showNuevoTask(
                                      s['id_step'] as int);
                                },
                                icon: const Icon(Icons.add,
                                    size: 14),
                                label: const Text('Tarea',
                                    style: TextStyle(
                                        fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFF7C3AED),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                ),
                              ),
                            ],
                          ),
                          if (tasks.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...tasks.map((t) => Padding(
                                  padding: const EdgeInsets.only(
                                      left: 32, bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.radio_button_unchecked,
                                        size: 14,
                                        color: const Color(
                                            0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          t['titulo'],
                                          style: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  4),
                                        ),
                                        child: Text(
                                          t['tipo'],
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(
                                                  0xFF0369A1)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 32, top: 4),
                              child: Text(
                                'Sin tareas aún',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400]),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOnboardings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children:
            _onboardings.map((o) => _onboardingCard(o)).toList(),
      ),
    );
  }

  Widget _onboardingCard(Map<String, dynamic> o) {
    final progreso =
        double.tryParse(o['progreso'].toString()) ?? 0.0;
    final estado = o['estado'] as String;
    final color = estado == 'COMPLETADO'
        ? const Color(0xFF10B981)
        : estado == 'EN_PROGRESO'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Onboarding #${o['id_employee_onboarding']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                    'Plan ID: ${o['id_plan']} · Usuario ID: ${o['id_user']}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progreso / 100,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                    '${progreso.toStringAsFixed(0)}% completado',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(estado,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}