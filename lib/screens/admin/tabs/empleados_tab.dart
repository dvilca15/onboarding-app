import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../widgets/ui_helpers.dart';

class EmpleadosTab extends StatefulWidget {
  final List<Usuario> usuarios;
  final void Function(Usuario) onEditar;
  final void Function(Usuario) onEliminar;

  const EmpleadosTab({
    super.key,
    required this.usuarios,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<EmpleadosTab> createState() => _EmpleadosTabState();
}

class _EmpleadosTabState extends State<EmpleadosTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtrados = _search.isEmpty
        ? widget.usuarios
        : widget.usuarios.where((u) {
            final q = _search.toLowerCase();
            return u.nombre.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8,
              offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: inputDec(
                  'Buscar por nombre o email...', Icons.search_rounded)
                  .copyWith(
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF9CA3AF), size: 18),
                        onPressed: () => setState(() => _search = ''))
                    : null,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(flex: 3, child: Text('Nombre',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: Color(0xFF6B7280)))),
              Expanded(flex: 4, child: Text('Email',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: Color(0xFF6B7280)))),
              Expanded(flex: 2, child: Text('Roles',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: Color(0xFF6B7280)))),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _search.isEmpty ? 'No hay empleados' : 'Sin resultados',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ),
          ...filtrados.map((u) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(children: [
              Expanded(flex: 3, child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text(u.inicial,
                      style: const TextStyle(color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(u.nombre,
                    style: const TextStyle(fontSize: 14))),
              ])),
              Expanded(flex: 4, child: Text(u.email,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF6B7280)))),
              Expanded(flex: 2, child: Wrap(
                spacing: 4,
                children: u.roles.map((r) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: r == 'ADMIN_EMPRESA'
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(r,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: r == 'ADMIN_EMPRESA'
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF0369A1))),
                )).toList(),
              )),
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18,
                      color: Color(0xFF6B7280)),
                  tooltip: 'Editar',
                  onPressed: () => widget.onEditar(u),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18,
                      color: Color(0xFFDC2626)),
                  tooltip: 'Eliminar',
                  onPressed: () => widget.onEliminar(u),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}