import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/plan.dart';
import '../../models/onboarding.dart';

import 'widgets/ui_helpers.dart';
import 'widgets/chat_fab.dart';
import 'widgets/formulario_builder.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/empleados_tab.dart';
import 'tabs/planes_tab.dart';
import 'tabs/onboardings_tab.dart';
import 'modals/nuevo_empleado_modal.dart';
import 'modals/nuevo_plan_modal.dart';
import 'modals/asignar_plan_modal.dart';
import 'modals/eliminar_plan_modal.dart';

import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import 'tabs/conocimiento_tab.dart';
import '../../theme/app_dialog.dart';
import '../../theme/app_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Breakpoint mobile/web para el admin (igual que el shell)
// ─────────────────────────────────────────────────────────────
const double _kAdminBreakpoint = 600;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  List<Usuario>    _usuarios    = [];
  List<Plan>       _planes      = [];
  List<Onboarding> _onboardings = [];
  bool   _loading   = true;
  String? _loadError;

  static const _navItems = [
    (icon: Icons.dashboard_rounded,     label: 'Dashboard'),
    (icon: Icons.people_rounded,        label: 'Empleados'),
    (icon: Icons.assignment_rounded,    label: 'Planes'),
    (icon: Icons.track_changes_rounded, label: 'Onboardings'),
    (icon: Icons.auto_stories_rounded,   label: 'Conocimiento'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Carga de datos ────────────────────────────────────────

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
        _loading     = false;
      });
    } catch (e) {
      setState(() {
        _loading   = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Modales de empleados ──────────────────────────────────

  void _showNuevoEmpleado() => NuevoEmpleadoModal.show(context, _loadData);

  void _showEditarEmpleado(Usuario usuario) {
    final nombreCtrl = TextEditingController(text: usuario.nombre);
    final emailCtrl  = TextEditingController(text: usuario.email);
    final passCtrl   = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    bool loading     = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AppAlertDialog(
          title: const Text('Editar empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField('Nombre', nombreCtrl, Icons.person_outline,
                  (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              modalField('Email', emailCtrl, Icons.email_outlined, (v) {
                if (v!.isEmpty) return 'Requerido';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              }),
              const SizedBox(height: 12),
              modalField(
                  'Nueva contraseña (vacío = sin cambio)', passCtrl,
                  Icons.lock_outline,
                  (v) => v!.isNotEmpty && v.length < 6 ? 'Mínimo 6' : null,
                  obscure: true),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.editarUsuario(
                    idUser: usuario.idUser,
                    nombre: nombreCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.isEmpty ? null : passCtrl.text,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    showSnack(context, 'Empleado actualizado', success: true);
                  }
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

  void _confirmarEliminarEmpleado(Usuario u) {
    _confirmarEliminar(
      titulo: 'Eliminar empleado',
      mensaje: '¿Eliminar a ${u.nombre}?\n\nSe eliminarán sus onboardings. Irreversible.',
      onConfirm: () async {
        try {
          await ApiService.eliminarUsuario(u.idUser);
          _loadData();
          showSnack(context, 'Empleado eliminado', success: true);
        } catch (e) {
          showSnack(context, e.toString().replaceAll('Exception: ', ''));
        }
      },
    );
  }

  // ── Modales de planes ─────────────────────────────────────

  void _showNuevoPlan() => NuevoPlanModal.show(context, _loadData);

  void _showAsignarPlan() {
    if (_usuarios.isEmpty || _planes.isEmpty) {
      showSnack(context, 'Necesitas al menos un empleado y un plan');
      return;
    }
    AsignarPlanModal.show(context,
        usuarios: _usuarios, planes: _planes, onAsignado: _loadData);
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
        builder: (ctx, set) => AppAlertDialog(
          title: const Text('Editar plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField('Nombre del plan', nombreCtrl,
                  Icons.assignment_outlined,
                  (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              modalField('Descripción (opcional)', descCtrl,
                  Icons.notes_outlined, (_) => null, maxLines: 3),
              const SizedBox(height: 12),
              Row(children: [
                Switch(value: esPlantilla,
                    onChanged: (v) => set(() => esPlantilla = v),
                    activeColor: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Marcar como plantilla',
                    style: TextStyle(fontSize: 14)),
              ]),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.editarPlan(
                    idPlan: plan.idPlan,
                    nombre: nombreCtrl.text.trim(),
                    descripcion: descCtrl.text.trim().isEmpty
                        ? null : descCtrl.text.trim(),
                    esPlantilla: esPlantilla,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    showSnack(context, 'Plan actualizado', success: true);
                  }
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

  // ── Paso 6: confirmar eliminar plan con conteo de activos ─

  void _confirmarEliminarPlan(Plan plan) async {
    try {
      final data = await ApiService.tieneEmpleadosActivos(plan.idPlan);
      final count = data['count'] as int;
      final tieneActivos = data['tiene_activos'] as bool;

      if (!mounted) return;

      if (tieneActivos) {
        // Mostrar advertencia con conteo
        _confirmarEliminarConAdvertencia(plan, count);
      } else {
        // Sin empleados activos — confirmación simple
        EliminarPlanModal.show(context,
            idPlan: plan.idPlan,
            nombrePlan: plan.nombre,
            onEliminado: _loadData);
      }
    } catch (_) {
      // Si falla el check, usar confirmación simple
      EliminarPlanModal.show(context,
          idPlan: plan.idPlan,
          nombrePlan: plan.nombre,
          onEliminado: _loadData);
    }
  }

  void _confirmarEliminarConAdvertencia(Plan plan, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AppAlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 22),
            SizedBox(width: 8),
            Text('Eliminar plan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advertencia en banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded,
                      color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$count empleado${count != 1 ? "s" : ""} con onboarding activo en este plan.',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Eliminar "${plan.nombre}"?\n\nSe eliminarán todos los onboardings activos y el progreso de esos empleados. Esta acción es irreversible.',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.eliminarPlan(plan.idPlan);
                _loadData();
                showSnack(context, 'Plan eliminado', success: true);
              } catch (e) {
                showSnack(context,
                    e.toString().replaceAll('Exception: ', ''));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sí, eliminar de todas formas'),
          ),
        ],
      ),
    );
  }

  // ── Modales de etapas ─────────────────────────────────────

  void _showNuevoStep(int idPlan, String nombrePlan, int cantidadSteps) {
    final tituloCtrl = TextEditingController();
    final descCtrl   = TextEditingController();
    final ordenCtrl  = TextEditingController(text: '${cantidadSteps + 1}');
    final diasCtrl   = TextEditingController();
    final formKey    = GlobalKey<FormState>();
    bool loading     = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AppAlertDialog(
          title: Text('Nueva etapa — $nombrePlan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField('Título', tituloCtrl, Icons.view_agenda_outlined,
                  (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              modalField('Descripción (opcional)', descCtrl,
                  Icons.notes_outlined, (_) => null, maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: modalField('Orden', ordenCtrl,
                    Icons.format_list_numbered, (v) {
                  if (v!.isEmpty) return 'Requerido';
                  final n = int.tryParse(v);
                  if (n == null) return 'Número';
                  if (n < 1) return 'Mínimo 1';
                  if (n <= cantidadSteps)
                    return 'Ya existe orden $n — usa ${cantidadSteps + 1}';
                  return null;
                }, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: modalField('Duración (días)', diasCtrl,
                    Icons.calendar_today_outlined, (v) {
                  if (v!.isNotEmpty && int.tryParse(v) == null) return 'Número';
                  return null;
                }, keyboardType: TextInputType.number)),
              ]),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.crearStep(
                    idPlan: idPlan,
                    titulo: tituloCtrl.text.trim(),
                    descripcion: descCtrl.text.trim().isEmpty
                        ? null : descCtrl.text.trim(),
                    orden: int.parse(ordenCtrl.text),
                    duracionDias: diasCtrl.text.trim().isEmpty
                        ? null : int.parse(diasCtrl.text),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showSnack(context, 'Etapa creada', success: true);
                  }
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

  void _showEditarStep(int idPlan, OnboardingStep step,
      VoidCallback onGuardado) {
    final tituloCtrl = TextEditingController(text: step.titulo);
    final descCtrl   = TextEditingController(text: step.descripcion ?? '');
    final ordenCtrl  = TextEditingController(text: '${step.orden}');
    final diasCtrl   = TextEditingController(
        text: step.duracionDias != null ? '${step.duracionDias}' : '');
    final formKey = GlobalKey<FormState>();
    bool loading  = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AppAlertDialog(
          title: const Text('Editar etapa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              modalField('Título', tituloCtrl, Icons.view_agenda_outlined,
                  (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              modalField('Descripción (opcional)', descCtrl,
                  Icons.notes_outlined, (_) => null, maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: modalField('Orden', ordenCtrl,
                    Icons.format_list_numbered, (v) {
                  if (v!.isEmpty) return 'Requerido';
                  if (int.tryParse(v) == null) return 'Número';
                  return null;
                }, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: modalField('Duración (días)', diasCtrl,
                    Icons.calendar_today_outlined, (v) {
                  if (v!.isNotEmpty && int.tryParse(v) == null) return 'Número';
                  return null;
                }, keyboardType: TextInputType.number)),
              ]),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.editarStep(
                    idPlan: idPlan,
                    idStep: step.idStep,
                    titulo: tituloCtrl.text.trim(),
                    descripcion: descCtrl.text.trim().isEmpty
                        ? null : descCtrl.text.trim(),
                    orden: int.parse(ordenCtrl.text),
                    duracionDias: diasCtrl.text.trim().isEmpty
                        ? null : int.parse(diasCtrl.text),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showSnack(context, 'Etapa actualizada', success: true);
                    onGuardado();
                  }
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

  void _showNuevoTask(int idStep,
      {int? idPlan, int cantidadTasks = 0, VoidCallback? onCreated}) {
    final tituloCtrl     = TextEditingController();
    final ordenCtrl      = TextEditingController(text: '${cantidadTasks + 1}');
    final bienvenidaCtrl = TextEditingController();
    final urlVideoCtrl   = TextEditingController();
    List<PreguntaFormulario> preguntasData = [];
    String tipo          = 'CONFIRMACION';
    bool obligatorio     = true;
    bool requiereEntrega = false;
    bool loading         = false;
    // Para DOCUMENTO: archivo seleccionado antes de crear
    List<int>? archivoBytesSeleccionado;
    String? archivoNombreSeleccionado;
    bool archivoSubido = false;
    final formKey = GlobalKey<FormState>();
    const tipos = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO', 'BIENVENIDA'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AppAlertDialog(
          title: const Text('Nueva tarea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: SizedBox(width: 400, child: Form(key: formKey, child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tipo != 'BIENVENIDA') ...[
                  modalField('Título', tituloCtrl, Icons.task_outlined,
                      (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
              isExpanded: true,
                  value: tipo,
                  decoration: inputDec('Tipo', Icons.category_outlined),
                  items: tipos.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => set(() {
                    tipo = v!;
                    if (tipo != 'DOCUMENTO') {
                      requiereEntrega = false;
                      archivoBytesSeleccionado = null;
                      archivoNombreSeleccionado = null;
                      archivoSubido = false;
                    }
                  }),
                ),

                // ── BIENVENIDA ──────────────────────────────
                if (tipo == 'BIENVENIDA') ...[
                  const SizedBox(height: 12),
                  _infoBanner(
                      'El empleado verá este mensaje al entrar por primera vez.',
                      AppColors.primarySoft, AppColors.primary),
                  const SizedBox(height: 12),
                  modalField('Escribe el mensaje de bienvenida...',
                      bienvenidaCtrl, Icons.waving_hand_outlined,
                      (v) => v!.isEmpty ? 'Requerido' : null, maxLines: 4),

                // ── VIDEO ───────────────────────────────────
                ] else if (tipo == 'VIDEO') ...[
                  const SizedBox(height: 12),
                  modalField('URL del video (YouTube, Drive, etc.)',
                      urlVideoCtrl, Icons.play_circle_outline_rounded,
                      (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),

                // ── FORMULARIO ──────────────────────────────
                ] else if (tipo == 'FORMULARIO') ...[
                  const SizedBox(height: 12),
                  FormularioBuilder(
                    preguntasIniciales: const [],
                    onChanged: (lista) => preguntasData = lista,
                  ),
                  const SizedBox(height: 12),
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),

                // ── DOCUMENTO ───────────────────────────────
                ] else if (tipo == 'DOCUMENTO') ...[
                  const SizedBox(height: 12),

                  // Estado del archivo seleccionado
                  if (archivoSubido)
                    _infoBanner('Archivo cargado correctamente.',
                        AppColors.successSoft, AppColors.success)
                  else if (archivoNombreSeleccionado != null)
                    _infoBanner(
                        'Archivo listo: $archivoNombreSeleccionado',
                        AppColors.infoSoft, AppColors.info)
                  else
                    _infoBanner(
                        'Opcional: sube el archivo ahora o hazlo después desde "Editar tarea".',
                        AppColors.infoSoft, AppColors.info),

                  const SizedBox(height: 8),

                  // Botón seleccionar archivo
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                          withData: true,
                        );
                        if (result == null) return;
                        final file = result.files.single;
                        if (file.bytes == null) return;
                        set(() {
                          archivoBytesSeleccionado = file.bytes;
                          archivoNombreSeleccionado = file.name;
                        });
                      },
                      icon: const Icon(Icons.upload_file_outlined, size: 16),
                      label: Text(
                        archivoNombreSeleccionado != null
                            ? 'Cambiar archivo'
                            : 'Seleccionar PDF / imagen',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle requiere entrega
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.upload_file_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      const Expanded(child: Text(
                        '¿El empleado debe subir el documento firmado?',
                        style: TextStyle(fontSize: 13,
                            color: AppColors.successDark),
                      )),
                      Switch(
                        value: requiereEntrega,
                        onChanged: (v) => set(() => requiereEntrega = v),
                        activeColor: AppColors.success,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),

                // ── OTROS (CONFIRMACION) ────────────────────
                ] else ...[
                  const SizedBox(height: 12),
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),
                ],
              ],
            ))),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                if (tipo == 'FORMULARIO') {
                  if (preguntasData.isEmpty) {
                    showSnack(context,
                        'El formulario debe tener al menos 1 pregunta');
                    return;
                  }
                  final errores = preguntasData
                      .map((p) => p.validar())
                      .where((e) => e != null)
                      .toList();
                  if (errores.isNotEmpty) {
                    showSnack(context, 'Revisa las preguntas del formulario');
                    return;
                  }
                }
                set(() => loading = true);
                try {
                  if (tipo == 'BIENVENIDA') {
                    if (idPlan == null)
                      throw Exception('No se encontró el plan');
                    await ApiService.actualizarBienvenida(
                        idPlan: idPlan,
                        mensaje: bienvenidaCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSnack(context, 'Bienvenida guardada', success: true);
                      _loadData();
                      onCreated?.call();
                    }
                  } else {
                    String? descripcion;
                    String? urlContenido;
                    if (tipo == 'FORMULARIO') {
                      descripcion =
                          PreguntaFormulario.serializarLista(preguntasData);
                    } else if (tipo == 'VIDEO') {
                      urlContenido = urlVideoCtrl.text.trim();
                    }

                    // 1. Crear la tarea
                    final taskData = await ApiService.crearTask(
                      idStep: idStep,
                      titulo: tituloCtrl.text.trim(),
                      tipo: tipo,
                      obligatorio: obligatorio,
                      orden: int.parse(ordenCtrl.text),
                      descripcion: descripcion,
                      urlContenido: urlContenido,
                      requiereEntrega: requiereEntrega,
                    );

                    // 2. Si es DOCUMENTO y hay archivo seleccionado, subirlo
                    if (tipo == 'DOCUMENTO' &&
                        archivoBytesSeleccionado != null &&
                        archivoNombreSeleccionado != null) {
                      final idTaskNuevo = taskData['id_task'] as int;
                      await ApiService.subirArchivoTaskWeb(
                        idStep: idStep,
                        idTask: idTaskNuevo,
                        bytes: archivoBytesSeleccionado!,
                        nombreArchivo: archivoNombreSeleccionado!,
                      );
                      set(() => archivoSubido = true);
                    }

                    if (mounted) {
                      Navigator.pop(ctx);
                      showSnack(context, 'Tarea creada', success: true);
                      onCreated?.call();
                    }
                  }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context,
                      e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading
                  ? btnSpinner()
                  : Text(tipo == 'BIENVENIDA'
                      ? 'Guardar bienvenida' : 'Crear tarea'),
            ),
          ],
        ),
      ),
    );
  }

void _showEditarTask(Task task, int idStep, VoidCallback onGuardado) {
    final tituloCtrl   = TextEditingController(text: task.titulo);
    final ordenCtrl    = TextEditingController(text: '${task.orden}');
    final urlVideoCtrl = TextEditingController(text: task.urlContenido ?? '');
    List<PreguntaFormulario> preguntasEditData = task.descripcion != null
        ? PreguntaFormulario.parsearDescripcion(task.descripcion!)
        : [];
    // urlContenidoActual rastrea la URL real — se actualiza tras subir archivo
    String? urlContenidoActual = task.urlContenido;
    bool archivoSubido   = urlContenidoActual != null && urlContenidoActual.isNotEmpty;
    String tipo          = task.tipo;
    bool obligatorio     = task.obligatorio;
    bool requiereEntrega = task.requiereEntrega;
    final formKey        = GlobalKey<FormState>();
    bool loading         = false;
    const tipos = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AppAlertDialog(
          title: const Text('Editar tarea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: SizedBox(width: 400, child: Form(key: formKey, child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                modalField('Título', tituloCtrl, Icons.task_outlined,
                    (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
              isExpanded: true,
                  value: tipos.contains(tipo) ? tipo : 'CONFIRMACION',
                  decoration: inputDec('Tipo', Icons.category_outlined),
                  items: tipos.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => set(() {
                    tipo = v!;
                    if (tipo != 'DOCUMENTO') requiereEntrega = false;
                  }),
                ),
                const SizedBox(height: 12),

                // ── VIDEO ───────────────────────────────────
                if (tipo == 'VIDEO') ...[
                  modalField('URL del video', urlVideoCtrl,
                      Icons.play_circle_outline_rounded, (_) => null),
                  const SizedBox(height: 12),
                ],

                // ── FORMULARIO ──────────────────────────────
                if (tipo == 'FORMULARIO') ...[
                  FormularioBuilder(
                    preguntasIniciales: preguntasEditData,
                    onChanged: (lista) => preguntasEditData = lista,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── DOCUMENTO ───────────────────────────────
                if (tipo == 'DOCUMENTO') ...[
                  if (archivoSubido)
                    _infoBanner('Archivo cargado correctamente.',
                        AppColors.successSoft, AppColors.success),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                          withData: true,
                        );
                        if (result == null) return;
                        final file = result.files.single;
                        if (file.bytes == null) return;
                        set(() => loading = true);
                        try {
                          final resp = await ApiService.subirArchivoTaskWeb(
                            idStep: idStep,
                            idTask: task.idTask,
                            bytes: file.bytes!,
                            nombreArchivo: file.name,
                          );
                          // ── Actualizar urlContenidoActual con la URL real
                          //    que devuelve el backend
                          set(() {
                            loading = false;
                            archivoSubido = true;
                            urlContenidoActual =
                                resp['url_contenido'] as String? ??
                                '/static/uploads/${file.name}';
                          });
                          if (mounted)
                            showSnack(context, 'Archivo subido',
                                success: true);
                        } catch (e) {
                          set(() => loading = false);
                          if (mounted)
                            showSnack(context,
                                e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      icon: loading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.info))
                          : const Icon(Icons.upload_file_outlined, size: 16),
                      label: Text(
                        archivoSubido
                            ? 'Reemplazar archivo'
                            : 'Subir PDF / imagen',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle requiere entrega
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.upload_file_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      const Expanded(child: Text(
                        '¿El empleado debe subir el documento firmado?',
                        style: TextStyle(fontSize: 13,
                            color: AppColors.successDark),
                      )),
                      Switch(
                        value: requiereEntrega,
                        onChanged: (v) => set(() => requiereEntrega = v),
                        activeColor: AppColors.success,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Orden + Obligatoria
                Row(children: [
                  Expanded(child: modalField('Orden', ordenCtrl,
                      Icons.format_list_numbered, (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (int.tryParse(v) == null) return 'Número';
                    return null;
                  }, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Row(children: [
                    Switch(
                      value: obligatorio,
                      onChanged: (v) => set(() => obligatorio = v),
                      activeColor: AppColors.primary,
                    ),
                    const Text('Obligatoria',
                        style: TextStyle(fontSize: 13)),
                  ]),
                ]),
              ],
            ))),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  String? descripcion;
                  String? urlContenido;

                  if (tipo == 'FORMULARIO' && preguntasEditData.isNotEmpty) {
                    descripcion =
                        PreguntaFormulario.serializarLista(preguntasEditData);
                  }
                  if (tipo == 'VIDEO' &&
                      urlVideoCtrl.text.trim().isNotEmpty) {
                    urlContenido = urlVideoCtrl.text.trim();
                  }
                  // ── DOCUMENTO: usar urlContenidoActual (ya actualizado
                  //    tras subir el archivo, no el objeto task original)
                  if (tipo == 'DOCUMENTO') {
                    urlContenido = urlContenidoActual;
                  }

                  await ApiService.editarTask(
                    idStep: idStep,
                    idTask: task.idTask,
                    titulo: tituloCtrl.text.trim(),
                    tipo: tipo,
                    obligatorio: obligatorio,
                    orden: int.parse(ordenCtrl.text),
                    descripcion: descripcion,
                    urlContenido: urlContenido,
                    requiereEntrega: requiereEntrega,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showSnack(context, 'Tarea actualizada', success: true);
                    onGuardado();
                  }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context,
                      e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading
                  ? btnSpinner()
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modal bienvenida ──────────────────────────────────────

  void _showEditarBienvenida({
    required int idPlan,
    required String? mensajeActual,
    required VoidCallback onGuardado,
  }) {
    final ctrl    = TextEditingController(text: mensajeActual ?? '');
    final formKey = GlobalKey<FormState>();
    bool loading  = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AppAlertDialog(
          title: Text(mensajeActual == null
              ? 'Agregar bienvenida' : 'Editar bienvenida',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoBanner(
                  'El empleado verá este mensaje al entrar por primera vez.',
                  AppColors.primarySoft, AppColors.primary),
              const SizedBox(height: 12),
              modalField('Escribe el mensaje de bienvenida...', ctrl,
                  Icons.waving_hand_outlined,
                  (v) => v!.isEmpty ? 'Requerido' : null, maxLines: 5),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                set(() => loading = true);
                try {
                  await ApiService.actualizarBienvenida(
                      idPlan: idPlan, mensaje: ctrl.text.trim());
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    showSnack(context, 'Bienvenida guardada', success: true);
                    onGuardado();
                  }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context, e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading ? btnSpinner() : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modal detalle del plan ────────────────────────────────
  // (igual que antes — sin cambios)

  void _showPlanDetalle(Plan plan) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.obtenerPlan(plan.idPlan),
        builder: (ctx, snap) {
          if (!snap.hasData) return const AppAlertDialog(
              content: SizedBox(height: 100,
                  child: Center(child: CircularProgressIndicator())));
          final detalle = PlanDetalle.fromJson(snap.data!);
          final stepsVisibles = detalle.steps
              .where((s) => s.titulo != '__BIENVENIDA__')
              .toList()
            ..sort((a, b) => a.orden.compareTo(b.orden));
          final mensajeActual = detalle.mensajeBienvenida;

          return AppAlertDialog(
            title: Text(detalle.nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            content: SizedBox(width: 500,
                child: SingleChildScrollView(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBienvenidaSection(ctx, plan, mensajeActual),
                    ...stepsVisibles.asMap().entries.map((entry) =>
                        _buildStepCard(ctx, plan, entry.value, entry.key + 1)),
                  ],
                ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBienvenidaSection(BuildContext ctx, Plan plan,
      String? mensajeActual) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCECBF6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.waving_hand_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          const Expanded(child: Text('Mensaje de bienvenida',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.primary))),
          if (mensajeActual != null) ...[
            InkWell(
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 100));
                if (!mounted) return;
                _showEditarBienvenida(
                  idPlan: plan.idPlan,
                  mensajeActual: mensajeActual,
                  onGuardado: () => _showPlanDetalle(plan),
                );
              },
              child: const Padding(padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 16,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () async {
                Navigator.pop(ctx);
                await Future.delayed(const Duration(milliseconds: 100));
                if (!mounted) return;
                _confirmarEliminar(
                  titulo: 'Eliminar bienvenida',
                  mensaje: '¿Eliminar el mensaje de bienvenida?',
                  onConfirm: () async {
                    await ApiService.actualizarBienvenida(
                        idPlan: plan.idPlan, mensaje: null);
                    _loadData();
                    showSnack(context, 'Bienvenida eliminada', success: true);
                  },
                );
              },
              child: const Padding(padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 16,
                      color: AppColors.danger)),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        if (mensajeActual != null)
          Text(mensajeActual,
              style: const TextStyle(fontSize: 13,
                  color: AppColors.textBody, height: 1.5))
        else
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              _showEditarBienvenida(
                idPlan: plan.idPlan,
                mensajeActual: null,
                onGuardado: () => _showPlanDetalle(plan),
              );
            },
            icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
            label: const Text('Agregar mensaje de bienvenida',
                style: TextStyle(fontSize: 12, color: AppColors.primary)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
      ]),
    );
  }

  Widget _buildStepCard(BuildContext ctx, Plan plan,
      OnboardingStep s, int numero) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: AppColors.primary,
                borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('$numero',
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(s.titulo,
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14))),
          InkWell(
            onTap: () async {
              Navigator.pop(ctx);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              _showEditarStep(plan.idPlan, s, () => _showPlanDetalle(plan));
            },
            child: const Padding(padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, size: 15,
                    color: AppColors.primary)),
          ),
          InkWell(
            onTap: () async {
              Navigator.pop(ctx);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              _confirmarEliminar(
                titulo: 'Eliminar etapa',
                mensaje: '¿Eliminar "${s.titulo}"?\nSe eliminarán todas sus tareas.',
                onConfirm: () async {
                  try {
                    await ApiService.eliminarStep(
                        idPlan: plan.idPlan, idStep: s.idStep);
                    _loadData();
                    showSnack(context, 'Etapa eliminada', success: true);
                  } catch (e) {
                    showSnack(context,
                        e.toString().replaceAll('Exception: ', ''));
                  }
                },
              );
            },
            child: const Padding(padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 15,
                    color: AppColors.danger)),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) _showNuevoTask(s.idStep,
                  idPlan: plan.idPlan,
                  cantidadTasks: s.tasks.length,
                  onCreated: () => _showPlanDetalle(plan));
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Tarea', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary),
          ),
        ]),
        if (s.tasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...s.tasks.map((t) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Row(children: [
              const Icon(Icons.radio_button_unchecked,
                  size: 14, color: AppColors.textSubtle),
              const SizedBox(width: 6),
              Expanded(child: Text(t.titulo,
                  style: const TextStyle(fontSize: 13))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(t.tipo,
                    style: const TextStyle(fontSize: 10,
                        color: Color(0xFF0369A1))),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return;
                  _showEditarTask(t, s.idStep, () => _showPlanDetalle(plan));
                },
                child: const Padding(padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 13,
                        color: AppColors.primary)),
              ),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return;
                  _confirmarEliminar(
                    titulo: 'Eliminar tarea',
                    mensaje: '¿Eliminar "${t.titulo}"?',
                    onConfirm: () async {
                      try {
                        await ApiService.eliminarTask(
                            idStep: s.idStep, idTask: t.idTask);
                        _loadData();
                        showSnack(context, 'Tarea eliminada', success: true);
                      } catch (e) {
                        showSnack(context,
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    },
                  );
                },
                child: const Padding(padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 13,
                        color: AppColors.danger)),
              ),
            ]),
          )),
        ] else
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text('Sin tareas aún',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ),
      ]),
    );
  }

  // ── Helper genérico de confirmación ──────────────────────

  Future<void> _confirmarEliminar({
    required String titulo,
    required String mensaje,
    required VoidCallback onConfirm,
  }) async {
    final ok = await confirmarAccion(context, titulo: titulo, mensaje: mensaje);
    if (ok) onConfirm();
  }

  // ── Helpers de UI ─────────────────────────────────────────

  Widget _infoBanner(String texto, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.info_outline, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(texto,
            style: TextStyle(fontSize: 11, color: color))),
      ]),
    );
  }

  Widget _ordenObligatorioRow(
      TextEditingController ordenCtrl,
      bool obligatorio,
      int cantidadTasks,
      StateSetter set,
      void Function(bool) onObligatorioChanged) {
    return Row(children: [
      Expanded(child: modalField('Orden', ordenCtrl,
          Icons.format_list_numbered, (v) {
        if (v!.isEmpty) return 'Requerido';
        final n = int.tryParse(v);
        if (n == null) return 'Número';
        if (n < 1) return 'Mínimo 1';
        if (n <= cantidadTasks)
          return 'Ya existe orden $n — usa ${cantidadTasks + 1}';
        return null;
      }, keyboardType: TextInputType.number)),
      const SizedBox(width: 12),
      Row(children: [
        Switch(
          value: obligatorio,
          onChanged: (v) => set(() => onObligatorioChanged(v)),
          activeColor: AppColors.primary,
        ),
        const Text('Obligatoria', style: TextStyle(fontSize: 13)),
      ]),
    ]);
  }

  // ── Build principal ───────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // ── Paso 6: LayoutBuilder para responsive ─────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kAdminBreakpoint;
        return isWide
            ? _buildWideLayout(auth)
            : _buildMobileLayout(auth);
      },
    );
  }

  // ── Web/Tablet: sidebar fijo ──────────────────────────────

  Widget _buildWideLayout(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        Row(children: [
          _buildSidebar(auth),
          Expanded(child: Column(children: [
            _buildTopBar(showMenuIcon: false),
            Expanded(child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent()),
          ])),
        ]),
        Positioned(bottom: 24, right: 24, child: ChatFab(onPlanCreado: _loadData)),
      ]),
    );
  }

  // ── Paso 6: Mobile — Drawer con hamburguesa ───────────────

  Widget _buildMobileLayout(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: Drawer(
        child: _buildSidebar(auth, isDrawer: true),
      ),
      body: Stack(children: [
        Column(children: [
          _buildTopBar(showMenuIcon: true),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent()),
        ]),
        Positioned(bottom: 24, right: 24, child: ChatFab(onPlanCreado: _loadData)),
      ]),
    );
  }

  // ── Sidebar (compartido entre wide y drawer) ──────────────

  Widget _buildSidebar(AuthProvider auth, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? double.infinity : 244,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Onboarding',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('MENÚ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textSubtle)),
          ),
          ..._navItems.asMap().entries.map((e) {
            final selected = _selectedIndex == e.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: selected ? AppColors.sidebarActive : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  hoverColor: AppColors.bg,
                  onTap: () {
                    setState(() => _selectedIndex = e.key);
                    if (isDrawer) Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Icon(e.value.icon,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 19),
                      const SizedBox(width: 12),
                      Text(e.value.label,
                          style: TextStyle(
                              color: selected
                                  ? AppColors.primaryHover
                                  : AppColors.textBody,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Row(children: [
              InitialAvatar(auth.userName, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.userName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const Text('Administrador',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout_rounded,
                    size: 19, color: AppColors.textMuted),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (mounted) context.go('/login');
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────

  Widget _buildTopBar({required bool showMenuIcon}) {
    const titles = [
      'Dashboard', 'Empleados', 'Planes de onboarding', 'Onboardings activos',
      'Base de conocimiento'
    ];
    const subtitles = [
      'Resumen general de tu empresa',
      'Gestiona a las personas de tu equipo',
      'Diseña las rutas de incorporación',
      'Seguimiento de cada empleado',
      'Documentos que usa el asistente de IA',
    ];
    final actions = <VoidCallback?>[
      null, _showNuevoEmpleado, _showNuevoPlan, _showAsignarPlan, null
    ];
    const labels = [
      null, 'Nuevo empleado', 'Nuevo plan', 'Asignar plan', null
    ];
    const labelsShort = [
      null, 'Nuevo', 'Nuevo', 'Asignar', null
    ];

    final isWide = MediaQuery.of(context).size.width >= 600;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        if (showMenuIcon)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.text),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menú',
            ),
          ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWide ? titles[_selectedIndex] : _shortTitle(_selectedIndex),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.text),
              ),
              if (isWide)
                Text(subtitles[_selectedIndex],
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
        IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textMuted, size: 20),
            onPressed: _loadData,
            tooltip: 'Actualizar'),
        if (actions[_selectedIndex] != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: actions[_selectedIndex],
            icon: Icon(Icons.add, size: isWide ? 18 : 16),
            label: Text(isWide
                ? labels[_selectedIndex]!
                : labelsShort[_selectedIndex]!),
          ),
        ],
      ]),
    );
  }

  String _shortTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Empleados';
      case 2: return 'Planes';
      case 3: return 'Onboardings';
      case 4: return 'Conocimiento';
      default: return 'Dashboard';
    }
  }


  Widget _buildContent() {
    if (_loadError != null) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded,
            color: AppColors.danger, size: 48),
        const SizedBox(height: 16),
        const Text('Error al cargar datos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_loadError!,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: primaryBtnStyle()),
      ]));
    }
    return switch (_selectedIndex) {
      0 => DashboardTab(
          usuarios: _usuarios,
          planes: _planes,
          onboardings: _onboardings),
      1 => EmpleadosTab(
          usuarios: _usuarios,
          onEditar: _showEditarEmpleado,
          onEliminar: _confirmarEliminarEmpleado),
      2 => PlanesTab(
          planes: _planes,
          onVerDetalle: _showPlanDetalle,
          onEditar: _showEditarPlan,
          onEliminar: _confirmarEliminarPlan,
          onAgregarEtapa: _showNuevoStep),
      3 => OnboardingsTab(onboardings: _onboardings, onRefresh: _loadData),
      4 => const ConocimientoTab(),
      _ => DashboardTab(
          usuarios: _usuarios,
          planes: _planes,
          onboardings: _onboardings),
    };
  }
}

