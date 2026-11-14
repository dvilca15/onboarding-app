import 'package:flutter/material.dart';
import '../../../models/chat_models.dart';
import '../../../theme/app_theme.dart';

class BurbujaMensaje extends StatelessWidget {
  final ChatMensaje mensaje;
  const BurbujaMensaje({super.key, required this.mensaje});

  static const _morado = AppColors.primaryHover;
  static const _moradoClaro = AppColors.primarySoft;

  bool get _esBot => mensaje.rol == 'assistant';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _esBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: _esBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _esBot ? Colors.white : _morado,
              border: _esBot ? Border.all(color: AppColors.border, width: 0.5) : null,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: _esBot ? const Radius.circular(4) : null,
                bottomRight: _esBot ? null : const Radius.circular(4),
              ),
            ),
            child: Text(
              mensaje.texto,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: _esBot ? AppColors.text : _moradoClaro,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(_horaActual(), style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
        ],
      ),
    );
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}