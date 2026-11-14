import 'package:flutter/material.dart';
import '../../../models/chat_models.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';
import '../../../widgets/chat_ui.dart';

class ChatFab extends StatefulWidget {
  /// Se llama cuando se crea un plan, para refrescar las listas del dashboard.
  final VoidCallback? onPlanCreado;
  const ChatFab({super.key, this.onPlanCreado});

  @override
  State<ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<ChatFab> {
  bool _abierto = false;
  bool _maximizado = false; // diálogo grande abierto: oculta el panel compacto
  bool _cargando = false;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final List<_ChatMsg> _mensajes = [];
  final List<Map<String, String>> _historial = [];

  /// etiqueta del chip → mensaje que se envía
  static const _sugerencias = {
    'Vendedor': 'Necesito un plan de onboarding de 2 semanas para un vendedor.',
    'Analista junior':
        'Necesito un plan de onboarding para un analista junior.',
    'Atención al cliente':
        'Necesito un plan de onboarding para un agente de atención al cliente.',
    '¿Qué dicen mis documentos?':
        'Resume brevemente qué documentos tiene mi empresa y qué temas cubren.',
  };

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Chat logic ────────────────────────────────────────────

  void _initChat() {
    if (_mensajes.isEmpty) {
      _mensajes.add(const _ChatMsg(
        rol: 'assistant',
        texto: 'Hola, soy tu asistente para crear planes de onboarding. '
            'Descríbeme el perfil del nuevo empleado y genero un plan '
            'personalizado. También uso los documentos que subiste en '
            'Conocimiento para que el plan sea real, y puedes preguntarme '
            'por su contenido.',
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

  Future<void> _enviar(ScrollController sc, {StateSetter? setDialog}) async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _cargando) return;
    _controller.clear();
    setState(() {
      _mensajes.add(_ChatMsg(rol: 'user', texto: texto));
      _cargando = true;
    });
    setDialog?.call(() {});
    _scrollAbajo(sc);
    try {
      final respuesta = await ApiService.chatAdminMensaje(
        mensaje: texto,
        historial: List.from(_historial),
      );
      final textoResp = respuesta['texto'] as String? ?? '';
      final planJson = respuesta['plan'] as Map<String, dynamic>?;
      final plan = planJson != null ? PlanSugerido.fromJson(planJson) : null;
      final fuentes = (respuesta['fuentes'] as List<dynamic>? ?? [])
          .map((f) => FuenteChat.fromJson(f as Map<String, dynamic>))
          .toList();
      _historial.add({'role': 'user', 'content': texto});
      _historial.add({'role': 'assistant', 'content': textoResp});
      if (!mounted) return;
      setState(() {
        _mensajes.add(_ChatMsg(
            rol: 'assistant', texto: textoResp, plan: plan, fuentes: fuentes));
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajes.add(const _ChatMsg(
            rol: 'assistant', texto: 'Hubo un error. Intenta de nuevo.'));
        _cargando = false;
      });
    }
    setDialog?.call(() {});
    _scrollAbajo(sc);
  }

  /// error == null si todo salió bien; adjuntos = documentos adjuntados solos.
  Future<({String? error, int adjuntos})> _crearPlan(PlanSugerido plan) async {
    try {
      final resp = await ApiService.chatAdminCrearPlan(sugerencia: plan.toJson())
          .timeout(const Duration(seconds: 30));
      widget.onPlanCreado?.call();
      return (
        error: null,
        adjuntos: (resp['documentos_adjuntados'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('chatAdminCrearPlan falló: $e');
      final msg = e.toString().replaceAll('Exception: ', '');
      return (
        error: msg.contains('TimeoutException')
            ? 'El servidor tardó demasiado. Revisa la pestaña Planes: '
                'puede que el plan sí se haya creado.'
            : msg,
        adjuntos: 0,
      );
    }
  }

  void _ajustar() {
    _controller.text = 'Ajusta el plan: ';
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    _focus.requestFocus();
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
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
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
        title: 'Asistente de planes',
        subtitle: 'Describe el perfil del empleado',
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatBubble(
                  texto: msg.texto,
                  esUsuario: msg.rol == 'user',
                  fuentes: msg.fuentes
                      .map((f) => (
                            numero: f.numero,
                            documento: f.documento,
                            extracto: f.extracto
                          ))
                      .toList(),
                ),
                if (msg.plan != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 34),
                    child: _PlanCard(
                      plan: msg.plan!,
                      onCrear: () => _crearPlan(msg.plan!),
                      onAjustar: _ajustar,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      if (_mensajes.length == 1 && !_cargando)
        ChatSuggestions(
          items: _sugerencias.keys.toList(),
          onTap: (label) {
            _controller.text = _sugerencias[label]!;
            _enviar(sc, setDialog: setDialog);
          },
        ),
      ChatInput(
        controller: _controller,
        focusNode: _focus,
        cargando: _cargando,
        hint: 'Describe el perfil del empleado…',
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
            width: ancho < 420 ? ancho - 32 : 390,
            height: 520,
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

// ── Modelo y tarjeta del plan sugerido ────────────────────────

class _ChatMsg {
  final String rol;
  final String texto;
  final PlanSugerido? plan;
  final List<FuenteChat> fuentes;
  const _ChatMsg({
    required this.rol,
    required this.texto,
    this.plan,
    this.fuentes = const [],
  });
}

class _PlanCard extends StatefulWidget {
  final PlanSugerido plan;
  final Future<({String? error, int adjuntos})> Function() onCrear;
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
  bool _creado = false;
  bool _creando = false;
  int _adjuntos = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryBorder),
        boxShadow: kShadowSm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera del plan
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.route_rounded,
                size: 18, color: AppColors.primaryHover),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.titulo,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.duracionDias} días · ${plan.etapas.length} etapas',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryHover),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _expandido = !_expandido),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryHover,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_expandido ? 'Ocultar' : 'Ver detalle',
                    style: const TextStyle(fontSize: 12)),
                Icon(
                    _expandido
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18),
              ]),
            ),
          ]),
        ),

        // Detalle de etapas
        if (_expandido)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.mensajeBienvenida != null &&
                    plan.mensajeBienvenida!.trim().isNotEmpty)
                  _BienvenidaPreview(texto: plan.mensajeBienvenida!),
                ...plan.etapas.asMap().entries.map((e) {
                final etapa = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(etapa.nombre,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text)),
                          ),
                          Text('${etapa.duracionDias} días',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSubtle)),
                        ]),
                        ...etapa.tareas.map((t) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 30, top: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                        t.titulo +
                                            (t.requiereEntrega
                                                ? ' (con entrega)'
                                                : '') +
                                            (t.obligatorio ? '' : ' (opcional)'),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.4,
                                            color: AppColors.textMuted)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (t.documento != null) ...[
                                    Tooltip(
                                      message:
                                          'Se adjuntará «${t.documento}» automáticamente',
                                      child: const Icon(Icons.attach_file_rounded,
                                          size: 15,
                                          color: AppColors.primaryHover),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  TipoTareaChip(t.tipo),
                                ],
                              ),
                            )),
                      ]),
                );
              }),
              ],
            ),
          ),

        // Resumen por tipo de tarea
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: _ResumenTipos(plan: plan),
        ),

        // Acciones
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onAjustar,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38)),
                child: const Text('Ajustar', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_creado || _creando)
                    ? null
                    : () async {
                        setState(() {
                          _creando = true;
                          _error = null;
                        });
                        String? error;
                        var adjuntos = 0;
                        try {
                          final r = await widget.onCrear();
                          error = r.error;
                          adjuntos = r.adjuntos;
                        } catch (e) {
                          error = e.toString();
                        }
                        if (!mounted) return;
                        setState(() {
                          _creando = false;
                          _creado = error == null;
                          _adjuntos = adjuntos;
                          _error = error;
                        });
                      },
                icon: Icon(
                    _creado ? Icons.check_rounded : Icons.add_rounded,
                    size: 16),
                label: Text(
                    _creado ? 'Creado' : (_creando ? 'Creando…' : 'Crear plan'),
                    style: const TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38)),
              ),
            ),
          ]),
        ),
        if (_creado)
          _EstadoPlan(
              icono: Icons.check_circle_rounded,
              color: AppColors.successDark,
              texto: _adjuntos > 0
                  ? 'Plan creado. Se adjuntaron $_adjuntos '
                      '${_adjuntos == 1 ? 'documento' : 'documentos'} automáticamente.'
                  : 'Plan creado. Ya está en la pestaña Planes.'),
        if (_error != null)
          _EstadoPlan(
              icono: Icons.error_outline_rounded,
              color: AppColors.danger,
              texto: _error!),
      ]),
    );
  }
}

class _EstadoPlan extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;
  const _EstadoPlan(
      {required this.icono, required this.color, required this.texto});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(texto,
                  style: TextStyle(fontSize: 12, height: 1.4, color: color))),
        ]),
      );
}


/// "2 documentos · 1 video · 1 formulario ..." + aviso de qué adjuntar luego.
class _ResumenTipos extends StatelessWidget {
  final PlanSugerido plan;
  const _ResumenTipos({required this.plan});

  @override
  Widget build(BuildContext context) {
    final todas = plan.etapas.expand((e) => e.tareas).toList();
    final cuenta = <String, int>{};
    for (final t in todas) {
      cuenta[t.tipo] = (cuenta[t.tipo] ?? 0) + 1;
    }
    final docsConArchivo = todas
        .where((t) => t.tipo == 'DOCUMENTO' && t.documento != null)
        .map((t) => t.documento!)
        .toSet();
    final docsSinArchivo = todas
        .where((t) => t.tipo == 'DOCUMENTO' && t.documento == null)
        .length;
    final videos = cuenta['VIDEO'] ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        if (plan.mensajeBienvenida != null &&
            plan.mensajeBienvenida!.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.waving_hand_rounded,
                  size: 13, color: AppColors.primaryHover),
              SizedBox(width: 5),
              Text('Con bienvenida',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryHover)),
            ]),
          ),
        for (final tipo in kTiposTarea)
          if ((cuenta[tipo] ?? 0) > 0)
            _ConteoTipo(tipo: tipo, cantidad: cuenta[tipo]!),
      ]),
      if (docsConArchivo.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.attach_file_rounded,
                size: 14, color: AppColors.primaryHover),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Se adjuntará automáticamente: '
              '${docsConArchivo.map((d) => '«$d»').join(', ')}.',
              style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryHover),
            ),
          ),
        ]),
      ],
      if (docsSinArchivo + videos > 0) ...[
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded,
                size: 14, color: AppColors.textSubtle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              docsConArchivo.isNotEmpty
                  ? 'Los demás documentos y los enlaces de los videos se '
                      'adjuntan después, desde la pestaña Planes.'
                  : 'Después de crear el plan, adjunta los archivos de los '
                      'documentos y el enlace de los videos desde la pestaña Planes.',
              style: const TextStyle(
                  fontSize: 11.5, height: 1.4, color: AppColors.textMuted),
            ),
          ),
        ]),
      ],
    ]);
  }
}

class _ConteoTipo extends StatelessWidget {
  final String tipo;
  final int cantidad;
  const _ConteoTipo({required this.tipo, required this.cantidad});

  String _etiqueta(int n) {
    const singular = {
      'DOCUMENTO': 'documento',
      'VIDEO': 'video',
      'FORMULARIO': 'formulario',
      'CONFIRMACION': 'confirmación',
    };
    const plural = {
      'DOCUMENTO': 'documentos',
      'VIDEO': 'videos',
      'FORMULARIO': 'formularios',
      'CONFIRMACION': 'confirmaciones',
    };
    return '$n ${(n == 1 ? singular : plural)[tipo] ?? tipo}';
  }

  @override
  Widget build(BuildContext context) {
    final t = TipoTareaInfo.de(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(t.icono, size: 13, color: t.color),
        const SizedBox(width: 5),
        Text(_etiqueta(cantidad),
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: t.color)),
      ]),
    );
  }
}


/// Vista previa del mensaje de bienvenida que se creará con el plan.
class _BienvenidaPreview extends StatelessWidget {
  final String texto;
  const _BienvenidaPreview({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.waving_hand_rounded,
              size: 14, color: AppColors.primaryHover),
          SizedBox(width: 6),
          Text('Mensaje de bienvenida',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryHover)),
        ]),
        const SizedBox(height: 6),
        Text(texto,
            style: const TextStyle(
                fontSize: 12.5, height: 1.5, color: AppColors.textBody)),
      ]),
    );
  }
}
