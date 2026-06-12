import 'package:flutter/widgets.dart';

class AppNavigationGuardController {
  Future<bool> Function()? _guard;

  void registerGuard(Future<bool> Function() guard) {
    _guard = guard;
  }

  void unregisterGuard(Future<bool> Function() guard) {
    if (_guard == guard) {
      _guard = null;
    }
  }

  Future<bool> canNavigateAway() async {
    if (_guard != null) {
      return await _guard!();
    }
    return true;
  }
}

class AppNavigationGuardScope extends InheritedWidget {
  final AppNavigationGuardController controller;

  const AppNavigationGuardScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static AppNavigationGuardController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppNavigationGuardScope>();
    assert(
      scope != null,
      'Nenhum AppNavigationGuardScope encontrado no contexto',
    );
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AppNavigationGuardScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
