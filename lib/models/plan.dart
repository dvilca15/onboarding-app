class Plan {
  final int idPlan;
  final int idEmpresa;
  final String nombre;
  final String? descripcion;
  final bool esPlantilla;
  final DateTime fechaCreacion;
  final String? mensajeBienvenida;

  const Plan({
    required this.idPlan,
    required this.idEmpresa,
    required this.nombre,
    this.descripcion,
    required this.esPlantilla,
    required this.fechaCreacion,
    this.mensajeBienvenida,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        idPlan:            json['id_plan'] as int,
        idEmpresa:         json['id_empresa'] as int,
        nombre:            json['nombre'] as String,
        descripcion:       json['descripcion'] as String?,
        esPlantilla:       json['es_plantilla'] as bool? ?? false,
        fechaCreacion:     DateTime.parse(json['fecha_creacion'] as String),
        mensajeBienvenida: json['mensaje_bienvenida'] as String?,
      );
}


class Task {
  final int idTask;
  final int idStep;
  final String titulo;
  final String tipo;
  final bool obligatorio;
  final int orden;

  const Task({
    required this.idTask,
    required this.idStep,
    required this.titulo,
    required this.tipo,
    required this.obligatorio,
    required this.orden,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        idTask:      json['id_task'] as int,
        idStep:      json['id_step'] as int,
        titulo:      json['titulo'] as String,
        tipo:        json['tipo'] as String,
        obligatorio: json['obligatorio'] as bool,
        orden:       json['orden'] as int,
      );
}


class OnboardingStep {
  final int idStep;
  final int idPlan;
  final String titulo;
  final String? descripcion;
  final int orden;
  final int? duracionDias;
  final List<Task> tasks;

  const OnboardingStep({
    required this.idStep,
    required this.idPlan,
    required this.titulo,
    this.descripcion,
    required this.orden,
    this.duracionDias,
    this.tasks = const [],
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) => OnboardingStep(
        idStep:       json['id_step'] as int,
        idPlan:       json['id_plan'] as int,
        titulo:       json['titulo'] as String,
        descripcion:  json['descripcion'] as String?,
        orden:        json['orden'] as int,
        duracionDias: json['duracion_dias'] as int?,
        tasks: (json['tasks'] as List<dynamic>? ?? [])
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}


class PlanDetalle extends Plan {
  final List<OnboardingStep> steps;

  const PlanDetalle({
    required super.idPlan,
    required super.idEmpresa,
    required super.nombre,
    super.descripcion,
    required super.esPlantilla,
    required super.fechaCreacion,
    super.mensajeBienvenida,
    this.steps = const [],
  });

  factory PlanDetalle.fromJson(Map<String, dynamic> json) => PlanDetalle(
        idPlan:            json['id_plan'] as int,
        idEmpresa:         json['id_empresa'] as int,
        nombre:            json['nombre'] as String,
        descripcion:       json['descripcion'] as String?,
        esPlantilla:       json['es_plantilla'] as bool? ?? false,
        fechaCreacion:     DateTime.parse(json['fecha_creacion'] as String),
        mensajeBienvenida: json['mensaje_bienvenida'] as String?,
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((s) => OnboardingStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}