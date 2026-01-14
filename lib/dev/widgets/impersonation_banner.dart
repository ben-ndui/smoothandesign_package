import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_event.dart';
import '../../core/blocs/auth/auth_state.dart';

/// Bannière affichée quand un MasterDev impersone un utilisateur.
///
/// Affichez ce widget en haut de vos scaffolds:
/// ```dart
/// Column(
///   children: [
///     const ImpersonationBanner(),
///     Expanded(child: ...),
///   ],
/// )
/// ```
class ImpersonationBanner extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final String? customText;

  const ImpersonationBanner({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          prev is AuthImpersonatingState != curr is AuthImpersonatingState ||
          (prev is AuthImpersonatingState &&
              curr is AuthImpersonatingState &&
              prev.impersonatedUser.uid != curr.impersonatedUser.uid),
      builder: (context, state) {
        if (state is! AuthImpersonatingState) {
          return const SizedBox.shrink();
        }

        final user = state.impersonatedUser;
        final bgColor = backgroundColor ?? Colors.orange;
        final txtColor = textColor ?? Colors.white;

        return Material(
          color: bgColor,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: txtColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customText ?? 'Mode impersonation: ${user.fullName}',
                      style: TextStyle(
                        color: txtColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const StopImpersonationEvent());
                    },
                    icon: Icon(Icons.close, color: txtColor, size: 18),
                    label: Text(
                      'Quitter',
                      style: TextStyle(color: txtColor),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
