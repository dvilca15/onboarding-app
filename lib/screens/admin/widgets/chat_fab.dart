import 'package:flutter/material.dart';
import '../../../models/chat_models.dart';
import '../../../services/api_service.dart';

class ChatFab extends StatefulWidget {
  const ChatFab({super.key});

  @override
  State<ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<ChatFab> {
  bool _abierto  = false;
  bool _cargando = false;

  final _controller = TextEditingController();
  final _scroll     = ScrollController();
  final List<_ChatMsg> _mensajes = [];
  final List<Map<String, String>> _historial = [];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Chat logic ────────────────────────────────────────────

  void _initChat() {
    if (_mensajes.isEmpty) {
      _mensajes.add(_ChatMsg(
        rol: 'assistant',
        texto: 'Hola, soy tu asistente para crear planes de onboarding. '
               'Descríbeme el perfil del nuevo empleado y genero un plan personalizado.',
      ));
    }
  }

  void _scrollAbajo(ScrollController sc) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sc.hasClients) {
        sc.animateTo(
          sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar(ScrollController sc) async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _cargando) return;
    _controller.clear();
    setState(() {
      _mensajes.add(_ChatMsg(rol: 'user', texto: texto));
      _cargando = true;
    });
    _scrollAbajo(sc);
    try {
      final respuesta = await ApiService.chatAdminMensaje(
        mensaje: texto,
        historial: List.from(_historial),
      );
      final textoResp = respuesta['texto'] as String? ?? '';
      final planJson  = respuesta['plan'] as Map<String, dynamic>?;
      final plan      = planJson != null ? PlanSugerido.fromJson(planJson) : null;
      _historial.add({'role': 'user', 'content': texto});
      _historial.add({'role': 'assistant', 'content': textoResp});
      setState(() {
        _mensajes.add(_ChatMsg(rol: 'assistant', texto: textoResp, plan: plan));
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensajes.add(_ChatMsg(
            rol: 'assistant', texto: 'Hubo un error. Intenta de nuevo.'));
        _cargando = false;
      });
    }
    _scrollAbajo(sc);
  }

  Future<void> _crearPlan(PlanSugerido plan) async {
    try {
      await ApiService.chatAdminCrearPlan(sugerencia: plan.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan "${plan.titulo}" creado correctamente'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Dialog expandido ──────────────────────────────────────

  void _abrirExpandido() {
    final scrollExpandido = ScrollController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(40),
          child: SizedBox(
            width: 720,
            height: 580,
            child: Column(children: [
              // Header
              _buildHeader(
                isExpandido: true,
                onExpandir: () => Navigator.pop(ctx),
                onCerrar: null,
              ),
              // Mensajes
              Expanded(
                child: _buildListaMensajes(
                  sc: scrollExpandido,
                  onCrearPlan: _crearPlan,
                  onAjustar: (texto) {
                    _controller.text = texto;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: texto.length),
                    );
                  },
                ),
              ),
              // Input
              _buildInput(sc: scrollExpandido, setDialog: setDialog),
            ]),
          ),
        ),
      ),
    ).then((_) => scrollExpandido.dispose());
  }

  // ── Widgets reutilizables ─────────────────────────────────

  Widget _buildHeader({
    required bool isExpandido,
    required VoidCallback onExpandir,
    VoidCallback? onCerrar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF7C3AED),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: const Text('IA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Asistente de planes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.white)),
            Text('Describe el perfil del empleado',
                style: TextStyle(fontSize: 11, color: Color(0xFFD8B4FE))),
          ]),
        ),
        InkWell(
          onTap: onExpandir,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isExpandido
                  ? Icons.close_fullscreen_rounded
                  : Icons.open_in_full_rounded,
              color: Colors.white, size: 18,
            ),
          ),
        ),
        if (onCerrar != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onCerrar,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildListaMensajes({
    required ScrollController sc,
    required Future<void> Function(PlanSugerido) onCrearPlan,
    required void Function(String) onAjustar,
  }) {
    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _mensajes.length + (_cargando ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _mensajes.length) return const _TypingIndicator();
        final msg = _mensajes[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Burbuja(mensaje: msg),
            if (msg.plan != null) ...[
              const SizedBox(height: 6),
              _PlanCard(
                plan: msg.plan!,
                onCrear: () => onCrearPlan(msg.plan!),
                onAjustar: () => onAjustar('Ajusta el plan: '),
              ),
            ],
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _buildInput({
    required ScrollController sc,
    StateSetter? setDialog,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: 3, minLines: 1,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describe el perfil del empleado...',
              hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF5F4EE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            if (setDialog != null) {
              // Forzar rebuild del dialog también
              await _enviar(sc);
              setDialog(() {});
            } else {
              await _enviar(sc);
            }
          },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _cargando
                  ? const Color(0xFFAFA9EC)
                  : const Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }

  // ── Build principal ───────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Panel compacto
        if (_abierto)
          Container(
            width: 340, height: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(children: [
              _buildHeader(
                isExpandido: false,
                onExpandir: _abrirExpandido,
                onCerrar: () => setState(() => _abierto = false),
              ),
              Expanded(
                child: _buildListaMensajes(
                  sc: _scroll,
                  onCrearPlan: _crearPlan,
                  onAjustar: (texto) {
                    _controller.text = texto;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: texto.length),
                    );
                  },
                ),
              ),
              _buildInput(sc: _scroll),
            ]),
          ),
        const SizedBox(height: 12),
        // FAB
        GestureDetector(
          onTap: () {
            setState(() {
              _abierto = !_abierto;
              if (_abierto) _initChat();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _abierto
                  ? const Color(0xFF534AB7)
                  : const Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _abierto ? Icons.close_rounded : Icons.auto_awesome_rounded,
              color: Colors.white, size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Modelos y widgets internos ────────────────────────────────

class _ChatMsg {
  final String rol;
  final String texto;
  final PlanSugerido? plan;
  const _ChatMsg({required this.rol, required this.texto, this.plan});
}

class _Burbuja extends StatelessWidget {
  final _ChatMsg mensaje;
  const _Burbuja({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.rol == 'user';
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: esUsuario ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(esUsuario ? 12 : 4),
            bottomRight: Radius.circular(esUsuario ? 4 : 12),
          ),
          border: esUsuario
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Text(mensaje.texto,
            style: TextStyle(
              fontSize: 13,
              color: esUsuario ? Colors.white : const Color(0xFF374151),
              height: 1.5,
            )),
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final PlanSugerido plan;
  final VoidCallback onCrear;
  final VoidCallback onAjustar;
  const _PlanCard({
    required this.plan,
    required this.onCrear,
    required this.onAjustar,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Título y resumen
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.plan.titulo,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: Color(0xFF5B21B6))),
              const SizedBox(height: 2),
              Text(
                '${widget.plan.duracionDias} días · '
                '${widget.plan.etapas.length} etapas',
                style: const TextStyle(fontSize: 11,
                    color: Color(0xFF7C3AED)),
              ),
            ],
          )),
          // Botón ver/ocultar detalle
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_expandido ? 'Ocultar' : 'Ver detalle',
                    style: const TextStyle(fontSize: 11,
                        color: Color(0xFF7C3AED))),
                const SizedBox(width: 2),
                Icon(
                  _expandido
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16, color: const Color(0xFF7C3AED),
                ),
              ]),
            ),
          ),
        ]),

        // Detalle de etapas
        if (_expandido) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFDDD6FE)),
          const SizedBox(height: 10),
          ...widget.plan.etapas.asMap().entries.map((e) {
            final i     = e.key;
            final etapa = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Número + nombre etapa
                Row(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(child: Text('${i + 1}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(etapa.nombre,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151)))),
                  Text('${etapa.duracionDias} días',
                      style: const TextStyle(fontSize: 10,
                          color: Color(0xFF9CA3AF))),
                ]),
                // Tareas
                if (etapa.tareas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...etapa.tareas.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 26, bottom: 3),
                    child: Row(children: [
                        const Icon(Icons.radio_button_unchecked,
                            size: 10, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(t,
                        style: const TextStyle(fontSize: 11,
                            color: Color(0xFF6B7280)),
                        )),
                    ]),
                    )),
                ],
              ]),
            );
          }),
        ],

        const SizedBox(height: 10),
        // Botones
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onAjustar,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ajustar', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onCrear,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Crear plan', style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)
              .copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity = ((_anim.value * 3 - i) % 1).clamp(0.2, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF888780).withOpacity(opacity),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}