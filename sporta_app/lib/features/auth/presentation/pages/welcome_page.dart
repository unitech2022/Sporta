import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../widgets/glass_panel.dart';
import '../widgets/language_toggle_button.dart';

/// First auth screen: brand intro with register / login entry points.
class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.pagePadding),
            child: Column(
              children: [
                SizedBox(height: AppSizes.lg),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: LanguageToggleButton(),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SportaLogo(width: 176, white: true),
                      SizedBox(height: AppSizes.xxxl),
                      Text(
                        context.tr('appTagline'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: AppSizes.md),
                      Text(
                        context.tr('brandTagline'),
                        style: TextStyle(
                          fontFamily: AppTextStyles.brandFontFamily,
                          fontSize: 22,
                          color: AppColors.brandGold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 48),
                      _RegisterButton(onTap: onRegister),
                      SizedBox(height: AppSizes.lg),
                      GlassPanel(
                        child: Text(
                          context.tr('registerRolesHint'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  context.tr('haveAccount'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                _LoginButton(onTap: onLogin),
                const SizedBox(height: AppSizes.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt,
                    color: AppColors.primary, size: AppSizes.iconLg),
              ),
              SizedBox(width: AppSizes.md),
              Text(
                context.tr('createNewAccount'),
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      borderWidth: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.login, color: Colors.white, size: AppSizes.iconMd),
          SizedBox(width: AppSizes.md),
          Text(
            context.tr('login'),
            style: AppTextStyles.heading3.copyWith(color: Colors.white),
          ),
          const SizedBox(width: AppSizes.md),
          const Icon(Icons.arrow_back, color: Colors.white,
              size: AppSizes.iconMd),
        ],
      ),
    );
  }
}
