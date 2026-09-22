import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/section_header.dart';
import 'package:bobadex/ui/components/theme_preview_card.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsThemePage extends StatefulWidget {
  const SettingsThemePage({super.key});

  @override
  State<SettingsThemePage> createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends State<SettingsThemePage> {
  late final String originalTheme;

  @override
  void initState() {
    super.initState();
    originalTheme = context.read<UserState>().current.themeSlug;
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && originalTheme != userState.current.themeSlug) {
          userState.saveTheme();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Theme')),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SectionHeader(title: 'Light')),
            _themeGrid(BobaThemes.light, userState),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: BobaSpace.x4),
                child: SectionHeader(title: 'Dark'),
              ),
            ),
            _themeGrid(BobaThemes.dark, userState),
            const SliverPadding(padding: EdgeInsets.only(bottom: BobaSpace.x8)),
          ],
        ),
      ),
    );
  }

  Widget _themeGrid(List<BobaThemeDefinition> themes, UserState userState) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x3),
      sliver: SliverGrid.builder(
        itemCount: themes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: BobaSpace.x2,
          mainAxisSpacing: BobaSpace.x2,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final theme = themes[index];
          return ThemePreviewCard(
            definition: theme,
            selected: userState.current.themeSlug == theme.slug,
            onTap: () => userState.setTheme(theme.slug),
          );
        },
      ),
    );
  }
}
