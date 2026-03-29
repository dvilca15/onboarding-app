import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import '../../services/api_service.dart';
import 'widgets/burbuja_mensaje.dart';
import 'widgets/tarjeta_plan.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _controller = TextEditingController();
  final _scroll     = ScrollController();
  final List<ChatMensaje> _mensajes = [];
  // Historial en formato que espera el backend
  final List<Map<String, String>> _historial = [];
  bool _cargando = false;

  static const _morado      = Color(0xFF534AB7);
  static const _moradoClaro = Color(0xFFEEEDFE);

  @override
  void initState() {
    super.initState();
    _mensajes.add(ChatMensaje(
      rol: 'assistant',
      texto: 'Hola, soy tu asistente para crear planes de onboarding. '
             'Descríbeme el perfil del nuevo empleado y genero un plan personalizado.',
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _cargando) return;

    _controller.clear();
    setState(() {
      _mensajes.add(ChatMensaje(rol: 'user', texto: texto));
      _cargando = true;
    });
    _scrollAbajo();

    try {
      // Llamar al backend — el backend llama a Groq
      final respuesta = await ApiService.chatAdminMensaje(
        mensaje: texto,
        historial: List.from(_historial),
      );

      final textoRespuesta = respuesta['texto'] as String? ?? '';
      final planJson = respuesta['plan'] as Map<String, dynamic>?;
      final plan = planJson != null ? PlanSugerido.fromJson(planJson) : null;

      // Actualizar historial para mantener contexto en el siguiente mensaje
      _historial.add({'role': 'user', 'content': texto});
      _historial.add({
        'role': 'assistant',
        'content': jsonEncode(respuesta),
      });

      setState(() {
        _mensajes.add(ChatMensaje(rol: 'assistant', texto: textoRespuesta, plan: plan));
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensajes.add(ChatMensaje(
          rol: 'assistant',
          texto: 'Hubo un error al generar el plan. Intenta de nuevo.',
        ));
        _cargando = false;
      });
    }
    _scrollAbajo();
  }

  Future<void> _crearPlan(PlanSugerido plan) async {
    try {
      await ApiService.chatAdminCrearPlan(sugerencia: plan.toJson());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan "${plan.titulo}" creado correctamente'),
          backgroundColor: _morado,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear el plan: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _ajustarPlan() {
    _controller.text = 'Ajusta el plan: ';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _moradoClaro,
              child: const Text('IA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _morado)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Asistente de planes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                Text('Describe el perfil del empleado',
                    style: TextStyle(fontSize: 11, color: Color(0xFF888780))),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _moradoClaro, borderRadius: BorderRadius.circular(20)),
            child: const Text('Admin',
                style: TextStyle(
                    fontSize: 11, color: _morado, fontWeight: FontWeight.w500)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE0DFD8)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _mensajes.length + (_cargando ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _mensajes.length) return const _TypingIndicator();
                final msg = _mensajes[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BurbujaMensaje(mensaje: msg),
                    if (msg.plan != null) ...[
                      const SizedBox(height: 8),
                      TarjetaPlan(
                        plan: msg.plan!,
                        onCrear: () => _crearPlan(msg.plan!),
                        onAjustar: _ajustarPlan,
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0DFD8), width: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Describe el perfil del empleado...',
                      hintStyle:
                          const TextStyle(color: Color(0xFF888780), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF5F4EE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _enviar,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _cargando ? const Color(0xFFAFA9EC) : _morado,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)
              .copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: const Color(0xFFE0DFD8), width: 0.5),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity = ((_anim.value * 3 - i) % 1).clamp(0.2, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
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