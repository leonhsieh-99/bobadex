import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:bobadex/state/user_state.dart';
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


  void _next() {
    setState(() => _page++);
    _pageController.animateToPage(
      _page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    setState(() => _page--);
    _pageController.animateToPage(
      _page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserState>();
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: [
            // Step 1: About
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Welcome to Bobadex!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  Text(
                    'Bobadex is a passion project I started to make it fun and easy to log all my milk tea adventures. '
                    'This app was developed by just myself, so if you find bugs or run into missing features, '
                    'please be patient and let me know through the contact page so I can make Bobadex better for everyone.\n\n'
                    'Thanks for giving it a try. Let’s start tracking your boba journey together!\n\n'
                    '- Leon Hsieh',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(onPressed: _next, child: Text("Next")),
                ],
              ),
            ),
            // Step 2: Theme/Settings
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Pick your theme color", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 260,
                    child: GridView.count(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        ...Constants.themeMap.entries.map((entry) {
                          final slug = entry.key;
                          final color = entry.value;
                          return GestureDetector(
                            onTap: () => setState(() => userState.setTheme(slug)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: userState.user.themeSlug == slug
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: userState.user.themeSlug == slug
                                ? Icon(Icons.check, color: Colors.black)
                                : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // ---- Layout select ----
                  Text("Pick your page layout", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 2-column
                      GestureDetector(
                        onTap: () => setState(() => userState.setGridLayout(2)),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 12),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: userState.user.gridColumns == 2
                                  ? Colors.deepPurple
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [if (userState.user.gridColumns == 2)
                              BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 4)]
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.view_column, size: 36),
                              Text("Cozy", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text("2 per row", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      // 3-column
                      GestureDetector(
                        onTap: () => setState(() => userState.setGridLayout(3)),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 12),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: userState.user.gridColumns == 3
                                  ? Colors.deepPurple
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [if (userState.user.gridColumns == 3)
                              BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 4)]
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.grid_view, size: 36),
                              Text("Compact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text("3 per row", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // ------- Card Layout ---------
                  Text("Pick your card layout", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 2-column
                      GestureDetector(
                        onTap: () => setState(() => userState.setUseIcon()),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width/3,
                            minWidth: MediaQuery.of(context).size.width/3
                          ),
                          margin: EdgeInsets.symmetric(horizontal: 12),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: !userState.user.useIcons
                                  ? Colors.deepPurple
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [if (!userState.user.useIcons)
                              BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 4)]
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.view_column, size: 36),
                              Text("Use photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text("User uploaded photos as background", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      // 3-column
                      GestureDetector(
                        onTap: () => setState(() => userState.setUseIcon()),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width/3,
                            minWidth: MediaQuery.of(context).size.width/3
                          ),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: userState.user.useIcons
                                  ? Colors.deepPurple
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [if (userState.user.useIcons)
                              BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 4)]
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.grid_view, size: 36),
                              Text("Use icons", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text("Uses built-in icons as foreground", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300), textAlign: TextAlign.center,),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                  // ---- Buttons ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          userState.saveLayout();
                          userState.saveTheme();
                        _back();
                        },
                        child: Text("Back")
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          userState.saveLayout();
                          userState.saveTheme();
                          try {
                            await userState.setOnboarded();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => HomePage(showAddShopSnackBar: true, user: userState.user),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              context.read<NotificationQueue>().queue('Error saving onboarding. Try again', SnackType.error);
                            }
                          }
                        },
                        child: Text("Done")),
                    ],
                  ),
                ],
              )
            ),
          ],
        ),
      )
    );
  }
}
