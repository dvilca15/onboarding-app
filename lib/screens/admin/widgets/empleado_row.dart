import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';

class EmpleadoRow extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const EmpleadoRow({
    super.key,
    required this.usuario,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Nombre
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InitialAvatar(usuario.nombre),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usuario.nombre,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Email
          Expanded(
            flex: 4,
            child: Text(
              usuario.email,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Roles
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: usuario.roles.map((r) {
                final esAdmin = r == 'ADMIN_EMPRESA';
                return StatusBadge(
                  esAdmin ? 'Administrador' : 'Empleado',
                  tone: esAdmin ? BadgeTone.primary : BadgeTone.neutral,
                  dot: false,
                );
              }).toList(),
            ),
          ),

          // Acciones
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                tooltip: 'Editar',
                onPressed: onEditar,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                tooltip: 'Eliminar',
                onPressed: onEliminar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}