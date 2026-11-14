import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Modal que se muestra al completar el 100% del plan.
class FelicitacionModal {
  static Future<void> show({
    required BuildContext context,
    required String nombreEmpleado,
    required String nombrePlan,
    int? totalEtapas,
    int? totalTareas,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _FelicitacionDialog(
        nombreEmpleado: nombreEmpleado,
        nombrePlan: nombrePlan,
        totalEtapas: totalEtapas,
        totalTareas: totalTareas,
      ),
    );
  }
}

class _FelicitacionDialog extends StatefulWidget {
  final String nombreEmpleado;
  final String nombrePlan;
  final int? totalEtapas;
  final int? totalTareas;

  const _FelicitacionDialog({
    required this.nombreEmpleado,
    required this.nombrePlan,
    this.totalEtapas,
    this.totalTareas,
  });

  @override
  State<_FelicitacionDialog> createState() => _FelicitacionDialogState();
}

class _FelicitacionDialogState extends State<_FelicitacionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _scaleAnim = Tween(begin: 0.9, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _primerNombre {
    final n = widget.nombreEmpleado.trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final chips = <(IconData, String)>[
      if (widget.totalEtapas != null && widget.totalEtapas! > 0)
        (
          Icons.layers_rounded,
          '${widget.totalEtapas} ${widget.totalEtapas == 1 ? 'etapa' : 'etapas'}'
        ),
      if (widget.totalTareas != null && widget.totalTareas! > 0)
        (
          Icons.checklist_rounded,
          '${widget.totalTareas} ${widget.totalTareas == 1 ? 'tarea' : 'tareas'}'
        ),
      (Icons.verified_rounded, '100% completado'),
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: kShadowMd,
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Cabecera
                  Stack(children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.successSoft, AppColors.surface],
                          ),
                        ),
                      ),
                    ),
                    Positioned(top: -50, right: -30, child: _circulo(170, 0.08)),
                    Positioned(top: 40, left: -60, child: _circulo(130, 0.06)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 34, 28, 22),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4ADE80),
                                  AppColors.successDark
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success
                                      .withValues(alpha: 0.35),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.emoji_events_rounded,
                                color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 20),
                          const Text('ONBOARDING COMPLETADO',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.3,
                                  color: AppColors.successDark)),
                          const SizedBox(height: 8),
                          Text(
                              _primerNombre.isEmpty
                                  ? '¡Lo lograste!'
                                  : '¡Lo lograste, $_primerNombre!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 28,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: AppColors.text)),
                        ]),
                      ),
                    ),
                  ]),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                    child: Column(children: [
                      const Text(
                          'Completaste todas las etapas de tu plan. '
                          'Gracias por tu dedicación: ya estás listo para '
                          'seguir creciendo con tu equipo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: AppColors.textBody)),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          const Icon(Icons.route_rounded,
                              size: 16, color: AppColors.successDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(widget.nombrePlan,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: chips
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.successSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(c.$1,
                                            size: 14,
                                            color: AppColors.successDark),
                                        const SizedBox(width: 5),
                                        Text(c.$2,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.successDark)),
                                      ]),
                                ))
                            .toList(),
                      ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continuar',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circulo(double d, double alpha) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: alpha),
        ),
      );
}
