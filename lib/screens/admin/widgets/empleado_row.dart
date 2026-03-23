import 'package:flutter/material.dart';
import '../../../models/usuario.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Nombre
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text(
                    usuario.inicial,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    usuario.nombre,
                    style: const TextStyle(fontSize: 14),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: esAdmin
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: esAdmin
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Acciones
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B7280)),
                tooltip: 'Editar',
                onPressed: onEditar,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
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