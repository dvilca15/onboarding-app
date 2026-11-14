import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Modal de bienvenida al iniciar un plan.
/// Patrón de los "welcome tours" de Notion, Slack o Deel: tarjeta centrada,
/// saludo grande, mensaje legible, resumen de lo que viene y un único botón.
class BienvenidaModal extends StatefulWidget {
  final String nombreEmpleado;
  final String nombrePlan;
  final String mensaje;
  final VoidCallback onLeido;
  final int? totalEtapas;
  final int? totalTareas;
  final int? totalDias;

  const BienvenidaModal({
    super.key,
    required this.nombreEmpleado,
    required this.nombrePlan,
    required this.mensaje,
    required this.onLeido,
    this.totalEtapas,
    this.totalTareas,
    this.totalDias,
  });

  static Future<void> show({
    required BuildContext context,
    required String nombreEmpleado,
    required String nombrePlan,
    required String mensaje,
    required VoidCallback onLeido,
    int? totalEtapas,
    int? totalTareas,
    int? totalDias,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BienvenidaModal(
        nombreEmpleado: nombreEmpleado,
        nombrePlan: nombrePlan,
        mensaje: mensaje,
        onLeido: onLeido,
        totalEtapas: totalEtapas,
        totalTareas: totalTareas,
        totalDias: totalDias,
      ),
    );
  }

  @override
  State<BienvenidaModal> createState() => _BienvenidaModalState();
}

class _BienvenidaModalState extends State<BienvenidaModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final Animation<double> _escala =
      Tween(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  late final Animation<double> _opacidad =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  bool _marcando = false;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _marcarLeido() async {
    setState(() => _marcando = true);
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop();
    widget.onLeido();
  }

  String get _primerNombre {
    final n = widget.nombreEmpleado.trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final stats = <_Stat>[
      if (widget.totalEtapas != null && widget.totalEtapas! > 0)
        _Stat(Icons.layers_rounded, '${widget.totalEtapas}',
            widget.totalEtapas == 1 ? 'Etapa' : 'Etapas'),
      if (widget.totalTareas != null && widget.totalTareas! > 0)
        _Stat(Icons.checklist_rounded, '${widget.totalTareas}',
            widget.totalTareas == 1 ? 'Tarea' : 'Tareas'),
      if (widget.totalDias != null && widget.totalDias! > 0)
        _Stat(Icons.schedule_rounded, '${widget.totalDias}',
            widget.totalDias == 1 ? 'Día' : 'Días'),
    ];

    return FadeTransition(
      opacity: _opacidad,
      child: ScaleTransition(
        scale: _escala,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: kShadowMd,
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Hero(
                      saludo: _primerNombre.isEmpty
                          ? '¡Bienvenido!'
                          : '¡Hola, $_primerNombre!',
                      plan: widget.nombrePlan,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mensaje de bienvenida (cita)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    widget.mensaje,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.65,
                                      color: AppColors.textBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Qué viene
                          if (stats.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text('TU PLAN EN RESUMEN',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.9,
                                    color: AppColors.textSubtle)),
                            const SizedBox(height: 10),
                            Row(children: [
                              for (var i = 0; i < stats.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(child: _StatTile(stats[i])),
                              ],
                            ]),
                          ],

                          // Aviso de etapas secuenciales
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lock_open_rounded,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Avanzas etapa por etapa: al completar '
                                    'una, se desbloquea la siguiente.',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _marcando ? null : _marcarLeido,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _marcando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Comenzar mi onboarding',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 0, 28, 22),
                      child: Text(
                        'Esto marcará tu bienvenida como leída.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSubtle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cabecera con degradado suave y círculos decorativos ───────

class _Hero extends StatelessWidget {
  final String saludo;
  final String plan;
  const _Hero({required this.saludo, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primarySoft, AppColors.surface],
            ),
          ),
        ),
      ),
      Positioned(
        top: -60,
        right: -40,
        child: _circulo(190, 0.07),
      ),
      Positioned(
        top: 30,
        left: -70,
        child: _circulo(150, 0.06),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
        child: SizedBox(
          width: double.infinity,
          child: Column(children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primaryHover],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.waving_hand_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const Text('BIENVENIDA AL EQUIPO',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: AppColors.primaryHover)),
            const SizedBox(height: 8),
            Text(saludo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    color: AppColors.text)),
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.route_rounded,
                    size: 14, color: AppColors.primaryHover),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(plan,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryHover)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _circulo(double d, double alpha) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: alpha),
        ),
      );
}

// ── Mini estadísticas del plan ────────────────────────────────

class _Stat {
  final IconData icono;
  final String valor;
  final String etiqueta;
  const _Stat(this.icono, this.valor, this.etiqueta);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  const _StatTile(this.stat);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(stat.icono, size: 18, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(stat.valor,
            style: const TextStyle(
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.text)),
        const SizedBox(height: 3),
        Text(stat.etiqueta,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}
