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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  List<Usuario>   _usuarios    = [];
  List<Plan>      _planes      = [];
  List<Onboarding> _onboardings = [];
  bool   _loading   = true;
  String? _loadError;

  static const _navItems = [
    (icon: Icons.dashboard_rounded,     label: 'Dashboard'),
    (icon: Icons.people_rounded,        label: 'Empleados'),
    (icon: Icons.assignment_rounded,    label: 'Planes'),
    (icon: Icons.track_changes_rounded, label: 'Onboardings'),
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
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
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
        builder: (ctx, set) => AlertDialog(
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
              modalField('Nueva contraseña (vacío = sin cambio)', passCtrl,
                  Icons.lock_outline,
                  (v) => v!.isNotEmpty && v.length < 6 ? 'Mínimo 6' : null,
                  obscure: true),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFF6B7280)))),
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
        builder: (ctx, set) => AlertDialog(
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
                    activeColor: const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('Marcar como plantilla',
                    style: TextStyle(fontSize: 14)),
              ]),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFF6B7280)))),
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

  void _confirmarEliminarPlan(Plan plan) {
    EliminarPlanModal.show(context,
        idPlan: plan.idPlan,
        nombrePlan: plan.nombre,
        onEliminado: _loadData);
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
        builder: (ctx, set) => AlertDialog(
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
                    style: TextStyle(color: Color(0xFF6B7280)))),
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
        builder: (ctx, set) => AlertDialog(
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
                    style: TextStyle(color: Color(0xFF6B7280)))),
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

  // ── Modales de tareas ─────────────────────────────────────

  void _showNuevoTask(int idStep,
      {int? idPlan, int cantidadTasks = 0, VoidCallback? onCreated}) {
    final tituloCtrl     = TextEditingController();
    final ordenCtrl      = TextEditingController(text: '${cantidadTasks + 1}');
    final bienvenidaCtrl = TextEditingController();
    final urlVideoCtrl   = TextEditingController();
    List<PreguntaFormulario> preguntasData = [];
    String tipo      = 'CONFIRMACION';
    bool obligatorio = true;
    bool loading     = false;
    final formKey    = GlobalKey<FormState>();
    const tipos = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO', 'BIENVENIDA'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
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
                  value: tipo,
                  decoration: inputDec('Tipo', Icons.category_outlined),
                  items: tipos.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => set(() => tipo = v!),
                ),
                if (tipo == 'BIENVENIDA') ...[
                  const SizedBox(height: 12),
                  _infoBanner('El empleado verá este mensaje al entrar por primera vez.',
                      const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
                  const SizedBox(height: 12),
                  modalField('Escribe el mensaje de bienvenida...',
                      bienvenidaCtrl, Icons.waving_hand_outlined,
                      (v) => v!.isEmpty ? 'Requerido' : null, maxLines: 4),
                ] else if (tipo == 'VIDEO') ...[
                  const SizedBox(height: 12),
                  modalField('URL del video (YouTube, Drive, etc.)',
                      urlVideoCtrl, Icons.play_circle_outline_rounded,
                      (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),
                ] else if (tipo == 'FORMULARIO') ...[
                  const SizedBox(height: 12),
                  FormularioBuilder(
                    preguntasIniciales: const [],
                    onChanged: (lista) => preguntasData = lista,
                  ),
                  const SizedBox(height: 12),
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),
                ] else ...[
                  const SizedBox(height: 12),
                  if (tipo == 'DOCUMENTO') ...[
                    _infoBanner(
                        'Crea la tarea y luego sube el archivo desde "Editar tarea".',
                        const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                  ],
                  _ordenObligatorioRow(ordenCtrl, obligatorio,
                      cantidadTasks, set, (v) => obligatorio = v),
                ],
              ],
            ))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
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
                    await ApiService.crearTask(
                      idStep: idStep,
                      titulo: tituloCtrl.text.trim(),
                      tipo: tipo,
                      obligatorio: obligatorio,
                      orden: int.parse(ordenCtrl.text),
                      descripcion: descripcion,
                      urlContenido: urlContenido,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSnack(context, 'Tarea creada', success: true);
                      onCreated?.call();
                    }
                  }
                } catch (e) {
                  set(() => loading = false);
                  showSnack(context, e.toString().replaceAll('Exception: ', ''));
                }
              },
              style: primaryBtnStyle(),
              child: loading
                  ? btnSpinner()
                  : Text(tipo == 'BIENVENIDA' ? 'Guardar bienvenida' : 'Crear tarea'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditarTask(Task task, int idStep, VoidCallback onGuardado) {
    final tituloCtrl    = TextEditingController(text: task.titulo);
    final ordenCtrl     = TextEditingController(text: '${task.orden}');
    final urlVideoCtrl  = TextEditingController(text: task.urlContenido ?? '');
    List<PreguntaFormulario> preguntasEditData = task.descripcion != null
        ? PreguntaFormulario.parsearDescripcion(task.descripcion!)
        : [];
    bool archivoSubido  = task.urlContenido != null;
    String tipo         = task.tipo;
    bool obligatorio    = task.obligatorio;
    final formKey       = GlobalKey<FormState>();
    bool loading        = false;
    const tipos         = ['CONFIRMACION', 'DOCUMENTO', 'VIDEO', 'FORMULARIO'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
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
                  value: tipos.contains(tipo) ? tipo : 'CONFIRMACION',
                  decoration: inputDec('Tipo', Icons.category_outlined),
                  items: tipos.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => set(() => tipo = v!),
                ),
                const SizedBox(height: 12),
                if (tipo == 'VIDEO') ...[
                  modalField('URL del video', urlVideoCtrl,
                      Icons.play_circle_outline_rounded, (_) => null),
                  const SizedBox(height: 12),
                ],
                if (tipo == 'FORMULARIO') ...[
                  FormularioBuilder(
                    preguntasIniciales: preguntasEditData,
                    onChanged: (lista) => preguntasEditData = lista,
                  ),
                  const SizedBox(height: 12),
                ],
                if (tipo == 'DOCUMENTO') ...[
                  if (archivoSubido)
                    _infoBanner('Archivo cargado correctamente.',
                        const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
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
                          await ApiService.subirArchivoTaskWeb(
                            idStep: idStep,
                            idTask: task.idTask,
                            bytes: file.bytes!,
                            nombreArchivo: file.name,
                          );
                          set(() { loading = false; archivoSubido = true; });
                          if (mounted)
                            showSnack(context, 'Archivo subido', success: true);
                        } catch (e) {
                          set(() => loading = false);
                          if (mounted)
                            showSnack(context,
                                e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      icon: loading
                          ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF3B82F6)))
                          : const Icon(Icons.upload_file_outlined, size: 16),
                      label: Text(archivoSubido
                          ? 'Reemplazar archivo' : 'Subir PDF / imagen',
                          style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(child: modalField('Orden', ordenCtrl,
                      Icons.format_list_numbered, (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (int.tryParse(v) == null) return 'Número';
                    return null;
                  }, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Row(children: [
                    Switch(value: obligatorio,
                        onChanged: (v) => set(() => obligatorio = v),
                        activeColor: const Color(0xFF1565C0)),
                    const Text('Obligatoria',
                        style: TextStyle(fontSize: 13)),
                  ]),
                ]),
              ],
            ))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFF6B7280)))),
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
                  if (tipo == 'VIDEO' && urlVideoCtrl.text.trim().isNotEmpty) {
                    urlContenido = urlVideoCtrl.text.trim();
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
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    showSnack(context, 'Tarea actualizada', success: true);
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
        builder: (ctx, set) => AlertDialog(
          title: Text(mensajeActual == null
              ? 'Agregar bienvenida' : 'Editar bienvenida',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(width: 400, child: Form(key: formKey, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoBanner(
                  'El empleado verá este mensaje al entrar por primera vez.',
                  const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
              const SizedBox(height: 12),
              modalField('Escribe el mensaje de bienvenida...', ctrl,
                  Icons.waving_hand_outlined,
                  (v) => v!.isEmpty ? 'Requerido' : null, maxLines: 5),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Color(0xFF6B7280)))),
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

  void _showPlanDetalle(Plan plan) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.obtenerPlan(plan.idPlan),
        builder: (ctx, snap) {
          if (!snap.hasData) return const AlertDialog(
              content: SizedBox(height: 100,
                  child: Center(child: CircularProgressIndicator())));
          final detalle = PlanDetalle.fromJson(snap.data!);
          final stepsVisibles = detalle.steps
              .where((s) => s.titulo != '__BIENVENIDA__')
              .toList()
            ..sort((a, b) => a.orden.compareTo(b.orden));
          final mensajeActual = detalle.mensajeBienvenida;

          return AlertDialog(
            title: Text(detalle.nombre,
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w600)),
            content: SizedBox(width: 500,
                child: SingleChildScrollView(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBienvenidaSection(
                        ctx, plan, mensajeActual),
                    ...stepsVisibles.asMap().entries.map((entry) =>
                        _buildStepCard(ctx, plan, entry.value,
                            entry.key + 1)),
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
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCECBF6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.waving_hand_rounded, size: 16,
              color: Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          const Expanded(child: Text('Mensaje de bienvenida',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED)))),
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
                      color: Color(0xFF7C3AED))),
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
                      color: Color(0xFFDC2626))),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        if (mensajeActual != null)
          Text(mensajeActual,
              style: const TextStyle(fontSize: 13,
                  color: Color(0xFF374151), height: 1.5))
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
            icon: const Icon(Icons.add, size: 14, color: Color(0xFF7C3AED)),
            label: const Text('Agregar mensaje de bienvenida',
                style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: const Color(0xFF7C3AED),
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
                    color: Color(0xFF1565C0))),
          ),
          InkWell(
            onTap: () async {
              Navigator.pop(ctx);
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              _confirmarEliminar(
                titulo: 'Eliminar etapa',
                mensaje:
                '¿Eliminar "${s.titulo}"?\nSe eliminarán todas sus tareas.',
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
                    color: Color(0xFFDC2626))),
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
                foregroundColor: const Color(0xFF7C3AED)),
          ),
        ]),
        if (s.tasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...s.tasks.map((t) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Row(children: [
              const Icon(Icons.radio_button_unchecked, size: 14,
                  color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Expanded(child: Text(t.titulo,
                  style: const TextStyle(fontSize: 13))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
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
                  _showEditarTask(
                      t, s.idStep, () => _showPlanDetalle(plan));
                },
                child: const Padding(padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 13,
                        color: Color(0xFF1565C0))),
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
                        color: Color(0xFFDC2626))),
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

  void _confirmarEliminar({
    required String titulo,
    required String mensaje,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626))),
        content: Text(mensaje,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151),
                height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white, elevation: 0),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
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
          activeColor: const Color(0xFF1565C0),
        ),
        const Text('Obligatoria', style: TextStyle(fontSize: 13)),
      ]),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(children: [
        Row(children: [
          _buildSidebar(auth),
          Expanded(child: Column(children: [
            _buildTopBar(),
            Expanded(child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent()),
          ])),
        ]),
        const Positioned(
          bottom: 24, right: 24,
          child: ChatFab(),
        ),
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
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Onboarding',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 6),
            Text(auth.userName,
                style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontSize: 12),
                overflow: TextOverflow.ellipsis),
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
                  color: selected
                      ? Colors.white.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(e.value.icon,
                    color: selected ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    size: 20),
                const SizedBox(width: 10),
                Text(e.value.label, style: TextStyle(
                    color: selected ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w600 : FontWeight.normal)),
              ]),
            ),
          );
        }),
        const Spacer(),
        InkWell(
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (mounted) context.go('/login');
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(Icons.logout_rounded,
                  color: Colors.white.withOpacity(0.6), size: 20),
              const SizedBox(width: 10),
              Text('Cerrar sesión',
                  style: TextStyle(color: Colors.white.withOpacity(0.6),
                      fontSize: 14)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildTopBar() {
    const titles = [
      'Dashboard', 'Empleados', 'Planes de Onboarding', 'Onboardings Activos'
    ];
    final actions = <VoidCallback?>[
      null, _showNuevoEmpleado, _showNuevoPlan, _showAsignarPlan
    ];
    const labels = [null, 'Nuevo empleado', 'Nuevo plan', 'Asignar plan'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(children: [
        Text(titles[_selectedIndex],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: _loadData,
            tooltip: 'Actualizar'),
        if (actions[_selectedIndex] != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: actions[_selectedIndex],
            icon: const Icon(Icons.add, size: 18),
            label: Text(labels[_selectedIndex]!),
            style: primaryBtnStyle(),
          ),
        ],
      ]),
    );
  }

  Widget _buildContent() {
    if (_loadError != null) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded,
            color: Color(0xFFDC2626), size: 48),
        const SizedBox(height: 16),
        const Text('Error al cargar datos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_loadError!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
      3 => OnboardingsTab(onboardings: _onboardings),
      _ => DashboardTab(
          usuarios: _usuarios,
          planes: _planes,
          onboardings: _onboardings),
    };
  }
}