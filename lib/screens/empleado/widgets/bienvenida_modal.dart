import 'package:flutter/material.dart';

class BienvenidaModal extends StatefulWidget {
  final String nombreEmpleado;
  final String nombrePlan;
  final String mensaje;
  final VoidCallback onLeido;

  const BienvenidaModal({
    super.key,
    required this.nombreEmpleado,
    required this.nombrePlan,
    required this.mensaje,
    required this.onLeido,
  });

  static Future<void> show({
    required BuildContext context,
    required String nombreEmpleado,
    required String nombrePlan,
    required String mensaje,
    required VoidCallback onLeido,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => BienvenidaModal(
        nombreEmpleado: nombreEmpleado,
        nombrePlan: nombrePlan,
        mensaje: mensaje,
        onLeido: onLeido,
      ),
    );
  }

  @override
  State<BienvenidaModal> createState() => _BienvenidaModalState();
}

class _BienvenidaModalState extends State<BienvenidaModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _escala;
  late Animation<double> _opacidad;
  bool _marcando = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _escala = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _opacidad = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: ScaleTransition(
        scale: _escala,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header decorativo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF7C3AED)],
                    ),
                  ),
                  child: Column(children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.waving_hand_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Bienvenido, ${widget.nombreEmpleado}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.nombrePlan,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),

                // Mensaje
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    widget.mensaje,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Indicador de progreso
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 0.5),
                    ),
                    child: Row(children: const [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Al confirmar, esto contará en tu progreso de onboarding',
                          style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                        ),
                      ),
                    ]),
                  ),
                ),

                // Botón
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _marcando ? null : _marcarLeido,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _marcando
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Entendido, ¡comencemos!',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}