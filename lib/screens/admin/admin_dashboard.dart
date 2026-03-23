import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/plan.dart';
import '../../models/onboarding.dart';

import 'widgets/stat_card.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/donut_chart.dart';
import 'widgets/ui_helpers.dart';
import 'modals/nuevo_empleado_modal.dart';
import 'modals/nuevo_plan_modal.dart';
import 'modals/asignar_plan_modal.dart';
import 'modals/eliminar_plan_modal.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  List<Usuario> _usuarios = [];
  List<Plan> _planes = [];
  List<Onboarding> _onboardings = [];
  bool _loading = true;
  String? _loadError;
  String _searchEmpleado = '';

  static const _navItems = [
    (icon: Icons.dashboard_rounded,      label: 'Dashboard'),
    (icon: Icons.people_rounded,         label: 'Empleados'),
    (icon: Icons.assignment_rounded,     label: 'Planes'),
    (icon: Icons.track_changes_rounded,  label: 'Onboardings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data ──────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final results = await Future.wait([
        ApiService.listarUsuarios(),
        ApiService.listarPlanes(),
        ApiService.listarOnboardings(),
      ]);
      setState(() {
        _usuarios    = (results[0] as List).map((e) => Usuario.fromJson(e)).toList();
        _planes      = (results[1] as List).map((e) => Plan.fromJson(e)).toList();
        _onboardings = (results[2] as List).map((e) => Onboarding.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _loadError = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  // ── Modales ───────────────────────────────────────────────

  void _showNuevoEmpleado() => NuevoEmpleadoModal.show(context, _loadData);

  void _showNuevoPlan() => NuevoPlanModal.show(context, _loadData);

  void _showAsignarPlan() {
    if (_usuarios.isEmpty || _planes.isEmpty) {
      showSnack(context, 'Necesitas al menos un empleado y un plan');
      return;
    }
    AsignarPlanModal.show(context,
        usuarios: _usuarios, planes: _planes, onAsignado: _loadData);
  }

  void _showNuevoStep(int idPlan, String nombrePlan) {
    final tituloCtrl = TextEditingController();
    final descCtrl   = TextEditingController();
    final ordenCtrl  = TextEditingController(text: '1');
    final diasCtrl   = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    bool loading     = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text('Nueva etapa — $nombrePlan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            modalField('Título', tituloCtrl, Icons.view_agenda_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            modalField('Descripción (opcional)', descCtrl, Icons.notes_outlined, (_) => null, maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: modalField('Orden', ordenCtrl, Icons.format_list_numbered, (v) {
                if (v!.isEmpty) return 'Requerido';
                if (int.tryParse(v) == null) return 'Número';
                return null;
              }, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: modalField('Duración (días)', diasCtrl, Icons.calendar_today_outlined, (v) {
                if (v!.isNotEmpty && int.tryParse(v) == null) return 'Número';
                return null;
              }, keyboardType: TextInputType.number)),
            ]),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.crearStep(idPlan: idPlan, titulo: tituloCtrl.text.trim(),
                    descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    orden: int.parse(ordenCtrl.text),
                    duracionDias: diasCtrl.text.trim().isEmpty ? null : int.parse(diasCtrl.text),
                  );
                  if (mounted) { Navigator.pop(ctx); showSnack(context, 'Etapa creada', success: true); }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context, e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading ? btnSpinner() : const Text('Crear etapa'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNuevoTask(int idStep, {VoidCallback? onCreated}) {
    final tituloCtrl = TextEditingController();
    final ordenCtrl  = TextEditingController(text: '1');
    String tipo      = 'CONFIRMACION';
    bool obligatorio = true;
    bool loading     = false;
    final formKey    = GlobalKey<FormState>();
    const tipos      = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Nueva tarea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            modalField('Título', tituloCtrl, Icons.task_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipo,
              decoration: inputDec('Tipo', Icons.category_outlined),
              items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => set(() => tipo = v!),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: modalField('Orden', ordenCtrl, Icons.format_list_numbered, (v) {
                if (v!.isEmpty) return 'Requerido';
                if (int.tryParse(v) == null) return 'Número';
                return null;
              }, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Row(children: [
                Switch(value: obligatorio, onChanged: (v) => set(() => obligatorio = v),
                    activeColor: const Color(0xFF1565C0)),
                const Text('Obligatoria', style: TextStyle(fontSize: 13)),
              ]),
            ]),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.crearTask(idStep: idStep, titulo: tituloCtrl.text.trim(),
                      tipo: tipo, obligatorio: obligatorio, orden: int.parse(ordenCtrl.text));
                  if (mounted) { Navigator.pop(ctx); showSnack(context, 'Tarea creada', success: true); onCreated?.call(); }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context, e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading ? btnSpinner() : const Text('Crear tarea'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditarEmpleado(Usuario usuario) {
    final nombreCtrl = TextEditingController(text: usuario.nombre);
    final emailCtrl  = TextEditingController(text: usuario.email);
    final passCtrl   = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    bool loading     = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Editar empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            modalField('Nombre', nombreCtrl, Icons.person_outline,
                (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            modalField('Email', emailCtrl, Icons.email_outlined, (v) {
              if (v!.isEmpty) return 'Requerido';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            }),
            const SizedBox(height: 12),
            modalField('Nueva contraseña (vacío = sin cambio)', passCtrl, Icons.lock_outline,
                (v) => v!.isNotEmpty && v.length < 6 ? 'Mínimo 6' : null, obscure: true),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.editarUsuario(idUser: usuario.idUser,
                      nombre: nombreCtrl.text.trim(), email: emailCtrl.text.trim(),
                      password: passCtrl.text.isEmpty ? null : passCtrl.text);
                  if (mounted) { Navigator.pop(ctx); _loadData(); showSnack(context, 'Empleado actualizado', success: true); }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context, e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading ? btnSpinner() : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar({required String titulo, required String mensaje, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
        content: Text(mensaje, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, elevation: 0),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarEmpleado(Usuario u) => _confirmarEliminar(
    titulo: 'Eliminar empleado',
    mensaje: '¿Eliminar a ${u.nombre}?\n\nSe eliminarán sus onboardings y progreso. Irreversible.',
    onConfirm: () async {
      try { await ApiService.eliminarUsuario(u.idUser); _loadData(); showSnack(context, 'Empleado eliminado', success: true); }
      catch (e) { showSnack(context, e.toString().replaceAll('Exception: ', '')); }
    },
  );

  void _confirmarEliminarPlan(Plan plan) {
    EliminarPlanModal.show(
      context,
      idPlan: plan.idPlan,
      nombrePlan: plan.nombre,
      onEliminado: _loadData,
    );
  }

  void _showEditarPlan(Plan plan) {
    final nombreCtrl = TextEditingController(text: plan.nombre);
    final descCtrl   = TextEditingController(text: plan.descripcion ?? '');
    bool esPlantilla = plan.esPlantilla;
    final formKey    = GlobalKey<FormState>();
    bool loading     = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Editar plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            modalField('Nombre del plan', nombreCtrl, Icons.assignment_outlined,
                (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            modalField('Descripción (opcional)', descCtrl, Icons.notes_outlined, (_) => null, maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Switch(value: esPlantilla, onChanged: (v) => set(() => esPlantilla = v), activeColor: const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              const Text('Marcar como plantilla', style: TextStyle(fontSize: 14)),
            ]),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.editarPlan(idPlan: plan.idPlan,
                      nombre: nombreCtrl.text.trim(),
                      descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      esPlantilla: esPlantilla);
                  if (mounted) { Navigator.pop(ctx); _loadData(); showSnack(context, 'Plan actualizado', success: true); }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context, e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading ? btnSpinner() : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDetalle(Plan plan) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.obtenerPlan(plan.idPlan),
        builder: (ctx, snap) {
          if (!snap.hasData) return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
          final detalle = PlanDetalle.fromJson(snap.data!);
          return AlertDialog(
            title: Text(detalle.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: detalle.steps.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 24, height: 24,
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('${s.orden}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (mounted) _showNuevoTask(s.idStep, onCreated: () => _showPlanDetalle(plan));
                      },
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Tarea', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
                    ),
                  ]),
                  if (s.tasks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...s.tasks.map((t) => Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: Row(children: [
                        const Icon(Icons.radio_button_unchecked, size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(t.titulo, style: const TextStyle(fontSize: 13))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),
                            child: Text(t.tipo, style: const TextStyle(fontSize: 10, color: Color(0xFF0369A1)))),
                      ]),
                    )),
                  ] else Padding(padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text('Sin tareas aún', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
                ]),
              )).toList(),
            ))),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(children: [
        _buildSidebar(auth),
        Expanded(child: Column(children: [
          _buildTopBar(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildContent()),
        ])),
      ]),
    );
  }

  Widget _buildSidebar(AuthProvider auth) {
    return Container(
      width: 220,
      color: const Color(0xFF1565C0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Onboarding',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 6),
            Text(auth.userName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), overflow: TextOverflow.ellipsis),
          ]),
        ),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
        ..._navItems.asMap().entries.map((e) {
          final selected = _selectedIndex == e.key;
          return InkWell(
            onTap: () => setState(() => _selectedIndex = e.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(e.value.icon, color: selected ? Colors.white : Colors.white.withOpacity(0.6), size: 20),
                const SizedBox(width: 10),
                Text(e.value.label, style: TextStyle(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                    fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              ]),
            ),
          );
        }),
        const Spacer(),
        InkWell(
          onTap: () async { await context.read<AuthProvider>().logout(); if (mounted) context.go('/login'); },
          child: Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.6), size: 20),
              const SizedBox(width: 10),
              Text('Cerrar sesión', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildTopBar() {
    const titles  = ['Dashboard', 'Empleados', 'Planes de Onboarding', 'Onboardings Activos'];
    final actions = <VoidCallback?>[null, _showNuevoEmpleado, _showNuevoPlan, _showAsignarPlan];
    const labels  = [null, 'Nuevo empleado', 'Nuevo plan', 'Asignar plan'];

    return Container(
      height: 60, padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(children: [
        Text(titles[_selectedIndex],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const Spacer(),
        IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)), onPressed: _loadData, tooltip: 'Actualizar'),
        if (actions[_selectedIndex] != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
              onPressed: actions[_selectedIndex],
              icon: const Icon(Icons.add, size: 18),
              label: Text(labels[_selectedIndex]!),
              style: primaryBtnStyle()),
        ],
      ]),
    );
  }

  Widget _buildContent() {
    if (_loadError != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFDC2626), size: 48),
        const SizedBox(height: 16),
        const Text('Error al cargar datos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_loadError!, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'), style: primaryBtnStyle()),
      ]));
    }
    return switch (_selectedIndex) {
      0 => _buildDashboard(),
      1 => _buildEmpleados(),
      2 => _buildPlanes(),
      3 => _buildOnboardings(),
      _ => _buildDashboard(),
    };
  }

  // ── Tabs ──────────────────────────────────────────────────

  Widget _buildDashboard() {
    final completados = _onboardings.where((o) => o.completado).length;
    final enProgreso  = _onboardings.where((o) => o.enProgreso).length;
    final pendientes  = _onboardings.where((o) => o.estado == 'PENDIENTE').length;
    final total       = _onboardings.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.8,
          children: [
            StatCard(title: 'Empleados',   value: '${_usuarios.length}',  icon: Icons.people_rounded,        color: const Color(0xFF1565C0)),
            StatCard(title: 'Planes',      value: '${_planes.length}',    icon: Icons.assignment_rounded,    color: const Color(0xFF7C3AED)),
            StatCard(title: 'En Progreso', value: '$enProgreso',          icon: Icons.track_changes_rounded, color: const Color(0xFFF59E0B)),
            StatCard(title: 'Completados', value: '$completados',         icon: Icons.check_circle_rounded,  color: const Color(0xFF10B981)),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Estado de onboardings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              Row(children: [
                DonutChart(completados: completados, enProgreso: enProgreso, pendientes: pendientes),
                const SizedBox(width: 32),
                Expanded(child: Column(children: [
                  LegendItem(label: 'Completados', value: completados, total: total, color: const Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  LegendItem(label: 'En progreso', value: enProgreso,  total: total, color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  LegendItem(label: 'Pendientes',  value: pendientes,  total: total, color: const Color(0xFF9CA3AF)),
                ])),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        const Text('Onboardings recientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._onboardings.take(5).map((o) => OnboardingCard(onboarding: o)),
      ]),
    );
  }

  Widget _buildEmpleados() {
    final filtrados = _searchEmpleado.isEmpty ? _usuarios
        : _usuarios.where((u) {
            final q = _searchEmpleado.toLowerCase();
            return u.nombre.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchEmpleado = v),
              decoration: inputDec('Buscar por nombre o email...', Icons.search_rounded).copyWith(
                suffixIcon: _searchEmpleado.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, color: Color(0xFF9CA3AF), size: 18),
                        onPressed: () => setState(() => _searchEmpleado = ''))
                    : null,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(flex: 3, child: Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF6B7280)))),
              Expanded(flex: 4, child: Text('Email',  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF6B7280)))),
              Expanded(flex: 2, child: Text('Roles',  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF6B7280)))),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (filtrados.isEmpty)
            Padding(padding: const EdgeInsets.all(32),
                child: Text(_searchEmpleado.isEmpty ? 'No hay empleados' : 'Sin resultados',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14))),
          ...filtrados.map((u) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(children: [
              Expanded(flex: 3, child: Row(children: [
                CircleAvatar(radius: 16,
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                    child: Text(u.inicial, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 13))),
                const SizedBox(width: 8),
                Expanded(child: Text(u.nombre, style: const TextStyle(fontSize: 14))),
              ])),
              Expanded(flex: 4, child: Text(u.email, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
              Expanded(flex: 2, child: Wrap(spacing: 4,
                children: u.roles.map((r) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: r == 'ADMIN_EMPRESA' ? const Color(0xFFEDE9FE) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: r == 'ADMIN_EMPRESA' ? const Color(0xFF7C3AED) : const Color(0xFF0369A1))),
                )).toList(),
              )),
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B7280)),
                    tooltip: 'Editar', onPressed: () => _showEditarEmpleado(u)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                    tooltip: 'Eliminar', onPressed: () => _confirmarEliminarEmpleado(u)),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildPlanes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: _planes.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF7C3AED), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if (p.descripcion != null)
                Text(p.descripcion!, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ])),
            if (p.esPlantilla)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Plantilla', style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _planBtn('Agregar etapa', Icons.add,                const Color(0xFF7C3AED), () => _showNuevoStep(p.idPlan, p.nombre)),
            _planBtn('Ver detalle',   Icons.visibility_outlined, const Color(0xFF6B7280), () => _showPlanDetalle(p)),
            _planBtn('Editar',        Icons.edit_outlined,       const Color(0xFF1565C0), () => _showEditarPlan(p)),
            _planBtn('Eliminar',      Icons.delete_outline,      const Color(0xFFDC2626), () => _confirmarEliminarPlan(p)),
          ]),
        ]),
      )).toList()),
    );
  }

  Widget _planBtn(String label, IconData icon, Color color, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color, side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );

  Widget _buildOnboardings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: _onboardings.map((o) => OnboardingCard(onboarding: o)).toList()),
    );
  }
}