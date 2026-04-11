import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_chat_screen.dart';
import 'screens/empleado/empleado_shell.dart';
import 'screens/empleado/cambiar_password_screen.dart'; // ← paso 2

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const OnboardingApp(),
    ),
  );
}

class OnboardingApp extends StatelessWidget {
  const OnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sistema de Onboarding',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: _router(context.read<AuthProvider>()),
    );
  }
}

GoRouter _router(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuthenticated = await auth.checkAuth();
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isCambiarPassword = location == '/empleado/cambiar-password';

      // No autenticado → al login
      if (!isAuthenticated && !isLoginRoute) return '/login';

      // Autenticado en login → redirigir según rol
      if (isAuthenticated && isLoginRoute) {
        if (auth.isAdmin) return '/admin/dashboard';
        // ── Paso 2: empleado sin contraseña cambiada va a la pantalla obligatoria
        return auth.passwordChanged
            ? '/empleado/dashboard'
            : '/empleado/cambiar-password';
      }

      // Empleado autenticado que ya cambió su contraseña intenta
      // volver a la pantalla de cambio → redirigir al dashboard
      if (isAuthenticated && isCambiarPassword && auth.passwordChanged) {
        return '/empleado/dashboard';
      }

      // Empleado autenticado sin contraseña cambiada intenta ir
      // a cualquier ruta protegida → forzar cambio de contraseña
      if (isAuthenticated &&
          !auth.isAdmin &&
          !auth.passwordChanged &&
          !isCambiarPassword &&
          !isLoginRoute) {
        return '/empleado/cambiar-password';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/empleado/dashboard',
        builder: (context, state) => const EmpleadoShell(),
      ),
      // ── Paso 2: ruta de cambio de contraseña obligatorio ──
      GoRoute(
        path: '/empleado/cambiar-password',
        builder: (context, state) => const CambiarPasswordScreen(),
      ),
      GoRoute(
        path: '/admin/chat',
        builder: (context, state) => const AdminChatScreen(),
      ),
    ],
  );
}
