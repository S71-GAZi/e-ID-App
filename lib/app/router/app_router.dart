import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../../features/auth/data/supabase_providers.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/cards/presentation/my_cards_screen.dart';
import '../../features/received/received_card_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/share/qr_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';

/// Route names.
class Routes {
  static const auth = '/auth';
  static const home = '/';
  static const share = '/share';
  static const scan = '/scan';
  static const received = '/received'; // /received/:shortCode
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    key: _rootKey,
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final signedIn = ref_read_currentUserId() != null;
      final loggingIn = state.matchedLocation == Routes.auth;
      if (!signedIn && !loggingIn) return Routes.auth;
      if (signedIn && loggingIn) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.auth, builder: (_, __) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            HomeShell(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(
              path: Routes.home,
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: MyCardsScreen())),
          GoRoute(
              path: '/wallet',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: WalletScreen())),
        ],
      ),
      GoRoute(path: Routes.scan, builder: (_, __) => const ScannerScreen()),
      GoRoute(
        path: '${Routes.received}/:shortCode',
        builder: (_, state) => ReceivedCardScreen(
            shortCode: state.pathParameters['shortCode']!),
      ),
      GoRoute(
        path: '${Routes.share}/:cardId',
        builder: (context, state) => ShareCardGate(cardId: state.pathParameters['cardId']!),
      ),
    ],
  );
}

/// Gate screen: resolves the card by id from the user's cached list.
class ShareCardGate extends ConsumerWidget {
  const ShareCardGate({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final cards = ref.watch(userCardsStreamProvider(userId)).valueOrNull ?? [];
    final card = cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppStrings.of(context).genericError)),
      );
    }
    return QrScreen(card: card);
  }
}

/// Bottom-navigation shell with three tabs: My cards / Wallet / +actions.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  int get _index => switch (currentPath) {
        '/wallet' => 1,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.credit_card_rounded),
            label: strings.tabMyCards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: strings.tabWallet,
          ),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              if (currentPath != '/') context.go(Routes.home);
            case 1:
              if (currentPath != '/wallet') context.go('/wallet');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'scan',
        onPressed: () => context.push(Routes.scan),
        tooltip: strings.scanQr,
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ---- router glue ----

/// The root ProviderContainer, set in main(). Router needs read access to
/// auth state outside of widget context.
late final ProviderContainer rootContainer;

String? ref_read_currentUserId() {
  try {
    return rootContainer.read(currentUserIdProvider);
  } catch (_) {
    return null;
  }
}
