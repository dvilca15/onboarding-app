import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/onboarding.dart';
import '../../services/api_service.dart';

import 'tabs/mi_plan_tab.dart';
import 'tabs/inicio_tab.dart';
import 'tabs/perfil_tab.dart';
import 'widgets/chat_fab_empleado.dart';

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

  // Web / Tablet: NavigationRail lateral
  Widget _buildWideLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme:
                const IconThemeData(color: Color(0xFF1565C0)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedIconTheme:
                const IconThemeData(color: Color(0xFF9CA3AF)),
            unselectedLabelTextStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
            destinations: _tabs
                .map((t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
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

  // Mobile: BottomNavigationBar
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          _buildTabBody(),
          _buildFab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
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
