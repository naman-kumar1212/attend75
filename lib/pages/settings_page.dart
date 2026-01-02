import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/responsive.dart';
import '../utils/animations.dart';
import 'settings/appearance_settings.dart';
import 'settings/attendance_settings.dart';
import 'settings/data_management.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    // Calculate the top padding required to clear the transparent app bar
    final topPadding = responsive.contentPaddingWithNav.top;
    final horizontalPadding = responsive.pagePadding.left;

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInAnimation(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize your app preferences',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  dividerColor: Colors.transparent, // Clean look
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.palette), text: 'Appearance'),
                    Tab(icon: Icon(LucideIcons.target), text: 'Attendance'),
                    Tab(icon: Icon(LucideIcons.database), text: 'Data'),
                  ],
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            SlideInUpAnimation(
              delay: const Duration(milliseconds: 200),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16, // Top spacing from TabBar
                  horizontalPadding,
                  responsive.bottomNavPadding, // Dynamic bottom padding
                ),
                child: const AppearanceSettings(),
              ),
            ),
            SlideInUpAnimation(
              delay: const Duration(milliseconds: 200),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  responsive.bottomNavPadding, // Dynamic bottom padding
                ),
                child: const AttendanceSettingsWidget(),
              ),
            ),
            SlideInUpAnimation(
              delay: const Duration(milliseconds: 200),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  responsive.bottomNavPadding, // Dynamic bottom padding
                ),
                child: const DataManagement(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor.withValues(
        alpha: 0.95,
      ), // Slight transparency for glass feel? Or solid.
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return true; // Force rebuild to update colors on theme switch
  }
}
