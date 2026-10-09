import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/add_shop_search_page.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/theme_preview_card.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});
  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _page);
  }

  void _go(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: BobaMotion.normal,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final userState = context.read<UserState>();
    userState.saveTheme();
    try {
      await userState.setOnboarded();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        notify('Error saving onboarding. Try again', SnackType.error);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BobaSpace.x4),
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              _WelcomeStep(onNext: () => _go(1)),
              _ThemeStep(
                userState: userState,
                onBack: () => _go(0),
                onNext: () {
                  userState.saveTheme();
                  _go(2);
                },
              ),
              _FirstBrandStep(onBack: () => _go(1), onSkip: _finish),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Image.asset('lib/assets/badges/first_sip.png', width: 120),
        const SizedBox(height: BobaSpace.x6),
        Text(
          'Welcome to Bobadex',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: BobaSpace.x3),
        Text(
          'Every brand you try becomes an entry in your collection. Rate drinks, earn badges, and see what your friends are collecting.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        BobaButton(label: 'Next', expanded: true, onPressed: onNext),
      ],
    );
  }
}

class _ThemeStep extends StatelessWidget {
  const _ThemeStep({
    required this.userState,
    required this.onBack,
    required this.onNext,
  });

  final UserState userState;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pick a theme', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: BobaSpace.x3),
        Expanded(
          child: GridView.builder(
            itemCount: BobaThemes.all.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: BobaSpace.x2,
              crossAxisSpacing: BobaSpace.x2,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final theme = BobaThemes.all[index];
              return ThemePreviewCard(
                definition: theme,
                selected: userState.current.themeSlug == theme.slug,
                onTap: () => userState.setTheme(theme.slug),
              );
            },
          ),
        ),
        const SizedBox(height: BobaSpace.x3),
        Row(
          children: [
            BobaButton(
              variant: BobaButtonVariant.secondary,
              label: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(width: BobaSpace.x3),
            Expanded(
              child: BobaButton(label: 'Next', onPressed: onNext),
            ),
          ],
        ),
      ],
    );
  }
}

class _FirstBrandStep extends StatelessWidget {
  const _FirstBrandStep({required this.onBack, required this.onSkip});

  final VoidCallback onBack;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add your first brand',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: BobaSpace.x2),
        Text(
          'Search and add a shop, or skip and do it from Dex later.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: BobaSpace.x3),
        const Expanded(child: AddShopSearchPage(embedded: true)),
        const SizedBox(height: BobaSpace.x3),
        Row(
          children: [
            BobaButton(
              variant: BobaButtonVariant.secondary,
              label: 'Back',
              onPressed: onBack,
            ),
            const Spacer(),
            BobaButton(
              variant: BobaButtonVariant.tertiary,
              label: 'Skip for now',
              onPressed: () => onSkip(),
            ),
          ],
        ),
      ],
    );
  }
}
