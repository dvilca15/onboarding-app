import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/empleado_row.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';

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

  static const _headStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0.3,
      color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final filtrados = _search.isEmpty
        ? widget.usuarios
        : widget.usuarios.where((u) {
            final q = _search.toLowerCase();
            return u.nombre.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: inputDec(
                          'Buscar por nombre o email', Icons.search_rounded)
                      .copyWith(
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textSubtle, size: 18),
                            onPressed: () => setState(() => _search = ''))
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${filtrados.length} ${filtrados.length == 1 ? 'persona' : 'personas'}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ]),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: filtrados.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: _search.isEmpty
                        ? 'Aún no hay empleados'
                        : 'Sin resultados',
                    message: _search.isEmpty
                        ? 'Crea el primer empleado con el botón "Nuevo empleado".'
                        : 'Prueba con otro nombre o correo.',
                  )
                : Column(children: [
                    if (isWide)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceAlt,
                          border: Border(
                              bottom: BorderSide(color: AppColors.border)),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.lg),
                            topRight: Radius.circular(AppRadius.lg),
                          ),
                        ),
                        child: const Row(children: [
                          Expanded(
                              flex: 3,
                              child: Text('NOMBRE', style: _headStyle)),
                          Expanded(
                              flex: 4,
                              child: Text('EMAIL', style: _headStyle)),
                          Expanded(
                              flex: 2,
                              child: Text('ROL', style: _headStyle)),
                          SizedBox(width: 96),
                        ]),
                      ),
                    ...filtrados.map((u) => isWide
                        ? EmpleadoRow(
                            usuario: u,
                            onEditar: () => widget.onEditar(u),
                            onEliminar: () => widget.onEliminar(u),
                          )
                        : _mobileItem(u)),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _mobileItem(Usuario u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        InitialAvatar(u.nombre, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.nombre,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 2),
              Text(u.email,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: u.roles.map((r) {
                  final admin = r == 'ADMIN_EMPRESA';
                  return StatusBadge(admin ? 'Administrador' : 'Empleado',
                      tone: admin ? BadgeTone.primary : BadgeTone.neutral,
                      dot: false);
                }).toList(),
              ),
            ],
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textMuted),
            onPressed: () => widget.onEditar(u),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.danger),
            onPressed: () => widget.onEliminar(u),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ]),
      ]),
    );
  }
}
