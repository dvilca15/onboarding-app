import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class ChatFabEmpleado extends StatefulWidget {
  final int idOnboarding;
  final String nombrePlan;
  final String nombreEmpleado;

  const ChatFabEmpleado({
    super.key,
    required this.idOnboarding,
    required this.nombrePlan,
    required this.nombreEmpleado,
  });

  @override
  State<ChatFabEmpleado> createState() => _ChatFabEmpleadoState();
}

class _ChatFabEmpleadoState extends State<ChatFabEmpleado> {
  bool _abierto  = false;
  bool _cargando = false;

  final _controller = TextEditingController();
  final _scroll     = ScrollController();
  final List<_Msg> _mensajes = [];
  final List<Map<String, String>> _historial = [];

  static const _azul      = Color(0xFF1565C0);
  static const _azulClaro = Color(0xFFE3F2FD);

  static const _sugerencias = [
    '¿Qué tareas me faltan?',
    '¿Cuál es mi progreso?',
    '¿Qué debo hacer primero?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _initChat() {
    if (_mensajes.isEmpty) {
      _mensajes.add(_Msg(
        rol: 'assistant',
        texto: '¡Hola ${widget.nombreEmpleado}! Soy tu asistente de onboarding. '
               'Puedo ayudarte con dudas sobre tus tareas o tu progreso. '
               '¿En qué te puedo ayudar?',
      ));
    }
  }

  void _scrollAbajo(ScrollController sc) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sc.hasClients) {
        sc.animateTo(sc.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _enviar(ScrollController sc, {StateSetter? setDialog}) async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _cargando) return;
    _controller.clear();
    setState(() {
      _mensajes.add(_Msg(rol: 'user', texto: texto));
      _cargando = true;
    });
    setDialog?.call(() {});
    _scrollAbajo(sc);
    try {
      final respuesta = await ApiService.chatEmpleadoMensaje(
        mensaje: texto,
        historial: List.from(_historial),
        idOnboarding: widget.idOnboarding,
      );
      _historial.add({'role': 'user', 'content': texto});
      _historial.add({'role': 'assistant', 'content': respuesta});
      setState(() {
        _mensajes.add(_Msg(rol: 'assistant', texto: respuesta));
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensajes.add(_Msg(
            rol: 'assistant',
            texto: 'Ocurrió un error. Por favor intenta de nuevo.'));
        _cargando = false;
      });
    }
    setDialog?.call(() {});
    _scrollAbajo(sc);
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
              _buildHeader(
                  isExpandido: true,
                  onExpandir: () => Navigator.pop(ctx),
                  onCerrar: null),
              Expanded(child: _buildMensajes(sc: scrollExpandido)),
              if (_mensajes.length == 1 && !_cargando)
                _buildSugerencias(sc: scrollExpandido, setDialog: setDialog),
              _buildInput(
                  sc: scrollExpandido, setDialog: setDialog),
            ]),
          ),
        ),
      ),
    ).then((_) => scrollExpandido.dispose());
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildHeader({
    required bool isExpandido,
    required VoidCallback onExpandir,
    VoidCallback? onCerrar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _azul,
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
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Asistente de onboarding',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white)),
          Text(widget.nombrePlan,
              style: TextStyle(fontSize: 11,
                  color: Colors.white.withOpacity(0.75)),
              overflow: TextOverflow.ellipsis),
        ])),
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

  Widget _buildMensajes({required ScrollController sc}) {
    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _mensajes.length + (_cargando ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _mensajes.length) return const _TypingIndicator();
        final msg = _mensajes[i];
        final esUsuario = msg.rol == 'user';
        return Align(
          alignment: esUsuario
              ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6),
            decoration: BoxDecoration(
              color: esUsuario ? _azul : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(esUsuario ? 12 : 4),
                bottomRight: Radius.circular(esUsuario ? 4 : 12),
              ),
              border: esUsuario
                  ? null
                  : Border.all(color: const Color(0xFFE5E7EB),
                  width: 0.5),
            ),
            child: Text(msg.texto,
                style: TextStyle(
                  fontSize: 13,
                  color: esUsuario
                      ? Colors.white : const Color(0xFF374151),
                  height: 1.5,
                )),
          ),
        );
      },
    );
  }

  Widget _buildSugerencias({
    required ScrollController sc,
    StateSetter? setDialog,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Wrap(
        spacing: 6, runSpacing: 6,
        children: _sugerencias.map((s) => GestureDetector(
          onTap: () {
            _controller.text = s;
            _enviar(sc, setDialog: setDialog);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _azulClaro,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Text(s,
                style: const TextStyle(fontSize: 11,
                    color: _azul, fontWeight: FontWeight.w500)),
          ),
        )).toList(),
      ),
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
        border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
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
              hintText: 'Pregunta sobre tus tareas o progreso...',
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
          onTap: () => _enviar(sc, setDialog: setDialog),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _cargando
                  ? const Color(0xFF90CAF9) : _azul,
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
            width: 320, height: 400,
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
              Expanded(child: _buildMensajes(sc: _scroll)),
              if (_mensajes.length == 1 && !_cargando)
                _buildSugerencias(sc: _scroll),
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
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _abierto
                  ? const Color(0xFF0D47A1) : _azul,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _abierto ? Icons.close_rounded : Icons.chat_outlined,
              color: Colors.white, size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String rol;
  final String texto;
  const _Msg({required this.rol, required this.texto});
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
  void dispose() { _anim.dispose(); super.dispose(); }

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
              final opacity =
                  ((_anim.value * 3 - i) % 1).clamp(0.2, 1.0);
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