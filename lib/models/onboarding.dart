import 'dart:math';

class Onboarding {
  final int idEmployeeOnboarding;
  final int idPlan;
  final int idUser;
  final String estado;
  final double progreso;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime fechaCreacion;
  final String nombreEmpleado;
  final String nombrePlan;

  const Onboarding({
    required this.idEmployeeOnboarding,
    required this.idPlan,
    required this.idUser,
    required this.estado,
    required this.progreso,
    this.fechaInicio,
    this.fechaFin,
    required this.fechaCreacion,
    this.nombreEmpleado = '',
    this.nombrePlan = '',
  });

  factory Onboarding.fromJson(Map<String, dynamic> json) => Onboarding(
        idEmployeeOnboarding: json['id_employee_onboarding'] as int,
        idPlan: json['id_plan'] as int,
        idUser: json['id_user'] as int,
        estado: json['estado'] as String,
        progreso: double.tryParse(json['progreso'].toString()) ?? 0.0,
        fechaInicio: json['fecha_inicio'] != null
            ? DateTime.tryParse(json['fecha_inicio'] as String)
            : null,
        fechaFin: json['fecha_fin'] != null
            ? DateTime.tryParse(json['fecha_fin'] as String)
            : null,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
        nombreEmpleado: json['nombre_empleado'] as String? ?? '',
        nombrePlan: json['nombre_plan'] as String? ?? '',
      );

  bool get completado => estado == 'COMPLETADO';
  bool get enProgreso => estado == 'EN_PROGRESO';

  String get displayEmpleado =>
      nombreEmpleado.isNotEmpty ? nombreEmpleado : 'Empleado #$idUser';

  String get displayPlan =>
      nombrePlan.isNotEmpty ? nombrePlan : 'Plan #$idPlan';
}


class TaskProgressDetalle {
  final int idTaskProgress;
  final int idTask;
  final int idStep;
  final String estado;
  final DateTime? fechaCompletada;
  final String titulo;
  final String tipo;
  final bool obligatorio;
  final int orden;

  const TaskProgressDetalle({
    required this.idTaskProgress,
    required this.idTask,
    required this.idStep,
    required this.estado,
    this.fechaCompletada,
    required this.titulo,
    required this.tipo,
    required this.obligatorio,
    required this.orden,
  });

  factory TaskProgressDetalle.fromJson(Map<String, dynamic> json) =>
      TaskProgressDetalle(
        idTaskProgress: json['id_task_progress'] as int,
        idTask: json['id_task'] as int,
        idStep: json['id_step'] as int,
        estado: json['estado'] as String,
        fechaCompletada: json['fecha_completada'] != null
            ? DateTime.tryParse(json['fecha_completada'] as String)
            : null,
        titulo: json['titulo'] as String,
        tipo: json['tipo'] as String,
        obligatorio: json['obligatorio'] as bool,
        orden: json['orden'] as int,
      );

  bool get completada => estado == 'COMPLETADO';
}


class StepConProgreso {
  final int idStep;
  final String titulo;
  final String? descripcion;
  final int orden;
  final int? duracionDias;
  final List<TaskProgressDetalle> tasks;
  final int totalTasks;
  final int completadas;

  const StepConProgreso({
    required this.idStep,
    required this.titulo,
    this.descripcion,
    required this.orden,
    this.duracionDias,
    this.tasks = const [],
    this.totalTasks = 0,
    this.completadas = 0,
  });

  factory StepConProgreso.fromJson(Map<String, dynamic> json) =>
      StepConProgreso(
        idStep: json['id_step'] as int,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String?,
        orden: json['orden'] as int,
        duracionDias: json['duracion_dias'] as int?,
        tasks: (json['tasks'] as List<dynamic>? ?? [])
            .map((t) =>
                TaskProgressDetalle.fromJson(t as Map<String, dynamic>))
            .toList(),
        totalTasks: json['total_tasks'] as int? ?? 0,
        completadas: json['completadas'] as int? ?? 0,
      );

  bool get todoCompleto => totalTasks > 0 && completadas == totalTasks;
  bool get enProgreso => completadas > 0 && completadas < totalTasks;
  int get porcentaje =>
      totalTasks > 0 ? (completadas / totalTasks * 100).round() : 0;
}


class OnboardingDetalle extends Onboarding {
  final List<StepConProgreso> stepsConProgreso;

  const OnboardingDetalle({
    required super.idEmployeeOnboarding,
    required super.idPlan,
    required super.idUser,
    required super.estado,
    required super.progreso,
    super.fechaInicio,
    super.fechaFin,
    required super.fechaCreacion,
    super.nombreEmpleado,
    super.nombrePlan,
    this.stepsConProgreso = const [],
  });

  factory OnboardingDetalle.fromJson(Map<String, dynamic> json) =>
      OnboardingDetalle(
        idEmployeeOnboarding: json['id_employee_onboarding'] as int,
        idPlan: json['id_plan'] as int,
        idUser: json['id_user'] as int,
        estado: json['estado'] as String,
        progreso: double.tryParse(json['progreso'].toString()) ?? 0.0,
        fechaInicio: json['fecha_inicio'] != null
            ? DateTime.tryParse(json['fecha_inicio'] as String)
            : null,
        fechaFin: json['fecha_fin'] != null
            ? DateTime.tryParse(json['fecha_fin'] as String)
            : null,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
        nombreEmpleado: json['nombre_empleado'] as String? ?? '',
        nombrePlan: json['nombre_plan'] as String? ?? '',
        stepsConProgreso:
            (json['steps_con_progreso'] as List<dynamic>? ?? [])
                .map((s) =>
                    StepConProgreso.fromJson(s as Map<String, dynamic>))
                .toList(),
      );
}