import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosstro/core/services/solver_key_service.dart';

/// The key service. Tests override it with a fake store and core.
final solverKeyServiceProvider = Provider<SolverKeyService>(
  (ref) => const SolverKeyService(),
);

/// Whether startup found a stored key it could not read or load
/// ([StoredKeyUnreadable]). Welcome says so; nothing was deleted.
final storedKeyUnreadableProvider = Provider<bool>((ref) => false);

/// The loaded solver key, or null when logged out. Startup restores it
/// before the first frame (`main.dart`) and overrides the initial value; the
/// router sends a null to Welcome.
final solverKeyProvider = NotifierProvider<SolverKeyNotifier, SolverKeyInfo?>(
  SolverKeyNotifier.new,
);

class SolverKeyNotifier extends Notifier<SolverKeyInfo?> {
  SolverKeyNotifier([this._initial]);

  final SolverKeyInfo? _initial;

  @override
  SolverKeyInfo? build() => _initial;

  SolverKeyService get _service => ref.read(solverKeyServiceProvider);

  /// Makes [secret] the solver key (the safe replace) and signs in.
  Future<void> logIn(String secret) async {
    state = await _service.logIn(secret);
  }

  /// Removes the key from the core and the phone, and signs out.
  Future<void> logOut() async {
    await _service.logOut();
    state = null;
  }
}
