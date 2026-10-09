import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';

/// Thin wrapper around Supabase so feature code never touches the SDK
/// directly (easy to mock in tests, easy to swap backend later).
class SupabaseClientProvider {
  static final provider = Provider<SupabaseClient>((ref) {
    return Supabase.instance.client;
  });
}

/// Initializes Supabase. Safe to call once in main(); if credentials are not
/// provided via --dart-define the app still runs (auth screens will show a
/// configuration error instead of crashing).
Future<void> initSupabase() async {
  if (!AppConfig.hasSupabase) return;
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!AppConfig.hasSupabase) {
    // Emit a signed-out state so the router can decide what to show.
    return Stream.value(AuthState(UserSession(null), null));
  }
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final state = ref.watch(authStateProvider).valueOrNull;
  return state?.session?.user.id;
});
