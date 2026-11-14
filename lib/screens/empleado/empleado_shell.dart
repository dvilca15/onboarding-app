import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/onboarding.dart';
import '../../services/api_service.dart';

import 'tabs/mi_plan_tab.dart';
import 'tabs/inicio_tab.dart';
import 'tabs/perfil_tab.dart';
import 'widgets/chat_fab_empleado.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Breakpoint a partir del cual se muestra NavigationRail (web/tablet)
// ─────────────────────────────────────────────────────────────
const double _kRailBreakpoint = 600;

class EmpleadoShell extends StatefulWidget {
  const EmpleadoShell({super.key});

  @override
  State<EmpleadoShell> createState() => _EmpleadoShellState();
}

class _EmpleadoShellState extends State<EmpleadoShell> {
  int _tabIndex = 1; // Inicia en "Mi Plan" (tab central)

  // Estado compartido entre tabs — se carga una vez y se pasa hacia abajo
  List<Onboarding> _onboardings = [];
  OnboardingDetalle? _detalle;
  int? _onboardingSeleccionado;
  bool _loadingShell = true;

  @override
  void initState() {
    super.initState();
    _loadOnboardings();
  }

  // ── Carga inicial de onboardings del usuario ──────────────

  Future<void> _loadOnboardings() async {
    setState(() => _loadingShell = true);
    try {
      final raw = await ApiService.listarOnboardings();
      final idUsuario = context.read<AuthProvider>().userId;
      final lista = raw
          .map((e) => Onboarding.fromJson(e))
          .where((o) => o.idUser == idUsuario)
          .toList();
      setState(() {
        _onboardings = lista;
        _loadingShell = false;
      });
    } catch (_) {
      setState(() => _loadingShell = false);
    }
  }

  // Callback que MiPlanTab llama cuando carga/cambia el detalle activo.
  // Permite que InicioTab y PerfilTab accedan al mismo objeto sin
  // duplicar llamadas a la API.
  void _onDetalleChanged(OnboardingDetalle? detalle, int? idOnboarding) {
    setState(() {
      _detalle = detalle;
      _onboardingSeleccionado = idOnboarding;
    });
  }

  // ── Definición de tabs ────────────────────────────────────

  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _TabItem(
      label: 'Mi plan',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    _TabItem(
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _kRailBreakpoint;
        return isWide ? _buildWideLayout() : _buildMobileLayout();
      },
    );
  }

  // Web / Tablet: menú lateral (mismo lenguaje visual que el admin)
  Widget _buildWideLayout() {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          Container(
            width: 244,
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('Onboarding',
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                    ]),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text('MENÚ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.textSubtle)),
                  ),
                  ..._tabs.asMap().entries.map((e) {
                    final selected = _tabIndex == e.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      child: Material(
                        color: selected
                            ? AppColors.sidebarActive
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          hoverColor: AppColors.bg,
                          onTap: () => setState(() => _tabIndex = e.key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Icon(
                                  selected
                                      ? e.value.activeIcon
                                      : e.value.icon,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 19),
                              const SizedBox(width: 12),
                              Text(e.value.label,
                                  style: TextStyle(
                                      color: selected
                                          ? AppColors.primaryHover
                                          : AppColors.textBody,
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                    child: Row(children: [
                      InitialAvatar(auth.userName, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.userName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text)),
                            const Text('Empleado',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar sesión',
                        icon: const Icon(Icons.logout_rounded,
                            size: 19, color: AppColors.textMuted),
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (mounted) context.go('/login');
                        },
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _buildTabBody(),
                _buildFab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile: barra de navegación inferior
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          _buildTabBody(),
          _buildFab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primarySoft,
          elevation: 0,
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith((states) =>
              TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? AppColors.primaryHover
                    : AppColors.textMuted,
              )),
          destinations: _tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon, color: AppColors.textMuted),
                    selectedIcon:
                        Icon(t.activeIcon, color: AppColors.primary),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  // IndexedStack mantiene el estado de cada tab en memoria;
  // evita recargas al cambiar de pestaña.
  Widget _buildTabBody() {
    if (_loadingShell) {
      return const Center(child: CircularProgressIndicator());
    }
    return IndexedStack(
      index: _tabIndex,
      children: [
        InicioTab(
          detalle: _detalle,
          onboardings: _onboardings,
        ),
        MiPlanTab(
          onboardings: _onboardings,
          onDetalleChanged: _onDetalleChanged,
        ),
        PerfilTab(
          onboardings: _onboardings,
        ),
      ],
    );
  }

  // FAB del chat IA — flota sobre todos los tabs.
  // Solo se muestra cuando hay un onboarding activo cargado.
  Widget _buildFab() {
    if (_onboardingSeleccionado == null || _detalle == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 24,
      right: 24,
      child: ChatFabEmpleado(
        idOnboarding: _onboardingSeleccionado!,
        nombrePlan: _detalle!.nombrePlan,
        nombreEmpleado: context.read<AuthProvider>().userName,
      ),
    );
  }
}

// ── Modelo simple para la definición de cada tab ─────────────

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
