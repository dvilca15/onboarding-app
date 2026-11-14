import 'package:flutter/material.dart';
import '../../../models/chat_models.dart';
import '../../../services/api_service.dart';
import '../../../widgets/chat_ui.dart';

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
  bool _abierto = false;
  bool _maximizado = false; // diálogo grande abierto: oculta el panel compacto
  bool _cargando = false;

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _mensajes = [];
  final List<Map<String, String>> _historial = [];

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
      final resp = await ApiService.chatEmpleadoMensaje(
        mensaje: texto,
        historial: List.from(_historial),
        idOnboarding: widget.idOnboarding,
      );
      final respuesta = resp['texto'] as String? ?? '';
      final fuentes = (resp['fuentes'] as List<dynamic>? ?? [])
          .map((f) => FuenteChat.fromJson(f as Map<String, dynamic>))
          .toList();
      _historial.add({'role': 'user', 'content': texto});
      _historial.add({'role': 'assistant', 'content': respuesta});
      if (!mounted) return;
      setState(() {
        _mensajes.add(_Msg(rol: 'assistant', texto: respuesta, fuentes: fuentes));
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajes.add(const _Msg(
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
    setState(() => _maximizado = true);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
            child: Container(
              decoration: chatPanelDecoration(),
              child: _contenido(
                sc: scrollExpandido,
                isExpandido: true,
                onExpandir: () => Navigator.pop(ctx),
                setDialog: setDialog,
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      scrollExpandido.dispose();
      if (mounted) setState(() => _maximizado = false);
    });
  }

  // ── Contenido (compartido por panel y diálogo) ────────────

  Widget _contenido({
    required ScrollController sc,
    required bool isExpandido,
    required VoidCallback onExpandir,
    VoidCallback? onCerrar,
    StateSetter? setDialog,
  }) {
    return Column(children: [
      ChatHeader(
        title: 'Asistente de onboarding',
        subtitle: widget.nombrePlan,
        isExpandido: isExpandido,
        onExpandir: onExpandir,
        onCerrar: onCerrar,
      ),
      Expanded(
        child: ListView.builder(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          itemCount: _mensajes.length + (_cargando ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _mensajes.length) return const ChatTyping();
            final msg = _mensajes[i];
            return ChatBubble(
              texto: msg.texto,
              esUsuario: msg.rol == 'user',
              fuentes: msg.fuentes
                  .map((f) => (
                        numero: f.numero,
                        documento: f.documento,
                        extracto: f.extracto
                      ))
                  .toList(),
            );
          },
        ),
      ),
      if (_mensajes.length == 1 && !_cargando)
        ChatSuggestions(
          items: _sugerencias,
          onTap: (s) {
            _controller.text = s;
            _enviar(sc, setDialog: setDialog);
          },
        ),
      ChatInput(
        controller: _controller,
        cargando: _cargando,
        hint: 'Pregunta sobre tus tareas o progreso…',
        showHint: isExpandido,
        onSend: () => _enviar(sc, setDialog: setDialog),
      ),
    ]);
  }

  // ── Build principal ───────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_abierto && !_maximizado)
          Container(
            width: ancho < 400 ? ancho - 32 : 380,
            height: 500,
            decoration: chatPanelDecoration(),
            child: _contenido(
              sc: _scroll,
              isExpandido: false,
              onExpandir: _abrirExpandido,
              onCerrar: () => setState(() => _abierto = false),
            ),
          ),
        const SizedBox(height: 12),
        ChatFabButton(
          abierto: _abierto,
          onTap: () => setState(() {
            _abierto = !_abierto;
            if (_abierto) _initChat();
          }),
        ),
      ],
    );
  }
}

class _Msg {
  final String rol;
  final String texto;
  final List<FuenteChat> fuentes;
  const _Msg({required this.rol, required this.texto, this.fuentes = const []});
}
