import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Componentes visuales compartidos por los chats (admin y empleado).

// ── Cabecera ──────────────────────────────────────────────────

class ChatHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isExpandido;
  final VoidCallback onExpandir;
  final VoidCallback? onCerrar;

  const ChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isExpandido,
    required this.onExpandir,
    this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(children: [
        const ChatAvatar(size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        IconButton(
          tooltip: isExpandido ? 'Minimizar' : 'Maximizar',
          onPressed: onExpandir,
          icon: Icon(
            isExpandido
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ),
        if (onCerrar != null)
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar,
            icon: const Icon(Icons.close_rounded,
                size: 20, color: AppColors.textMuted),
          ),
      ]),
    );
  }
}

/// Avatar del asistente: cuadrado redondeado con degradado y destello.
class ChatAvatar extends StatelessWidget {
  final double size;
  const ChatAvatar({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryHover],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: size * 0.52),
    );
  }
}

// ── Burbujas ──────────────────────────────────────────────────

class ChatBubble extends StatelessWidget {
  final String texto;
  final bool esUsuario;
  /// Fuentes citadas (RAG): (número, documento, extracto)
  final List<({int numero, String documento, String extracto})> fuentes;

  const ChatBubble({
    super.key,
    required this.texto,
    required this.esUsuario,
    this.fuentes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esUsuario ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(esUsuario ? 16 : 4),
          bottomRight: Radius.circular(esUsuario ? 4 : 16),
        ),
        border: esUsuario ? null : Border.all(color: AppColors.border),
        boxShadow: esUsuario ? null : kShadowSm,
      ),
      child: esUsuario
          ? Text(texto,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.5, color: Colors.white))
          : SelectableText(texto,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.5, color: AppColors.textBody)),
    );

    final fila = Row(
      mainAxisAlignment:
          esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!esUsuario) ...[
          const ChatAvatar(size: 26),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: bubble,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fila,
          if (!esUsuario && fuentes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Fuentes:',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSubtle)),
                  for (final f in fuentes)
                    Tooltip(
                      message: f.extracto,
                      waitDuration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.description_outlined,
                              size: 12, color: AppColors.primaryHover),
                          const SizedBox(width: 4),
                          Text('[${f.numero}] ${f.documento}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryHover)),
                        ]),
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

/// "El asistente está escribiendo…"
class ChatTyping extends StatefulWidget {
  const ChatTyping({super.key});

  @override
  State<ChatTyping> createState() => _ChatTypingState();
}

class _ChatTypingState extends State<ChatTyping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const ChatAvatar(size: 26),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = ((_anim.value * 3 - i) % 3) / 3;
                final alpha = (0.25 + 0.75 * (1 - (t * 2 - 1).abs()))
                    .clamp(0.25, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: alpha),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Sugerencias ───────────────────────────────────────────────

class ChatSuggestions extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTap;

  const ChatSuggestions({super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((s) => ActionChip(
                  label: Text(s),
                  onPressed: () => onTap(s),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.primaryBorder),
                  shape: const StadiumBorder(),
                  labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryHover),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    );
  }
}

// ── Campo de entrada (Enter envía, Shift+Enter = nueva línea) ─

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final bool cargando;
  final String hint;
  final bool showHint;

  const ChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSend,
    required this.cargando,
    required this.hint,
    this.showHint = false,
  });

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final esEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent &&
        esEnter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      // No enviar mientras se compone texto con un IME (acentos, CJK...).
      if (controller.value.composing.isValid &&
          !controller.value.composing.isCollapsed) {
        return KeyEventResult.ignored;
      }
      onSend();
      return KeyEventResult.handled; // evita insertar el salto de línea
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      fontSize: 14, color: AppColors.textSubtle),
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final puede = value.text.trim().isNotEmpty && !cargando;
              return Tooltip(
                message: 'Enviar',
                child: Material(
                  color: puede ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: puede ? onSend : null,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: cargando
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textMuted),
                            )
                          : Icon(Icons.arrow_upward_rounded,
                              size: 20,
                              color: puede
                                  ? Colors.white
                                  : AppColors.textSubtle),
                    ),
                  ),
                ),
              );
            },
          ),
        ]),
        if (showHint)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter para enviar · Shift + Enter para nueva línea',
                style: TextStyle(fontSize: 11, color: AppColors.textSubtle),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Contenedor del panel flotante ─────────────────────────────

BoxDecoration chatPanelDecoration() => BoxDecoration(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: AppColors.border),
      boxShadow: kShadowMd,
    );

/// Botón flotante que abre/cierra el chat.
class ChatFabButton extends StatelessWidget {
  final bool abierto;
  final VoidCallback onTap;

  const ChatFabButton({super.key, required this.abierto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: abierto ? 'Cerrar asistente' : 'Abrir asistente',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: abierto
                  ? const [AppColors.primaryHover, AppColors.primaryHover]
                  : const [AppColors.primaryLight, AppColors.primaryHover],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: kShadowMd,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              abierto ? Icons.close_rounded : Icons.auto_awesome_rounded,
              key: ValueKey(abierto),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
