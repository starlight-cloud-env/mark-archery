import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/grouped_card.dart';
import '../widgets/ios_tab_bar.dart';
import 'splash_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'manage_templates_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _archerFuture;

  @override
  void initState() {
    super.initState();
    _archerFuture = _fetchArcher();
  }

  Future<Map<String, dynamic>> _fetchArcher() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('archers')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  void _refresh() {
    setState(() {
      _archerFuture = _fetchArcher();
    });
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      isDestructive: false,
    );

    if (!confirmed) return;

    await supabase.auth.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(body: _buildBody(context, theme));
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _archerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Text(
                'Could not load profile: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        final archer = snapshot.data!;
        final name = archer['name'] as String;
        final email = archer['email'] as String;

        return CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Profile')),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom + iosTabBarHeight + 16,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: theme.textTheme.titleLarge),
                              Text(
                                email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text('Account', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GroupedCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(CupertinoIcons.pencil),
                            title: const Text('Edit Profile'),
                            trailing: const Icon(
                              CupertinoIcons.chevron_forward,
                            ),
                            onTap: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfileScreen(currentName: name),
                                ),
                              );
                              if (changed == true) {
                                _refresh();
                              }
                            },
                          ),
                          const GroupedCardDivider(),
                          ListTile(
                            leading: const Icon(CupertinoIcons.lock),
                            title: const Text('Change Password'),
                            trailing: const Icon(
                              CupertinoIcons.chevron_forward,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Preferences', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GroupedCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(CupertinoIcons.square_list),
                            title: const Text('Default Scoring Templates'),
                            trailing: const Icon(
                              CupertinoIcons.chevron_forward,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageTemplatesScreen(),
                                ),
                              );
                            },
                          ),
                          const GroupedCardDivider(),
                          ListTile(
                            leading: const Icon(CupertinoIcons.bell),
                            title: const Text('Notifications'),
                            trailing: const Icon(
                              CupertinoIcons.chevron_forward,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Legal', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GroupedCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(CupertinoIcons.shield),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(
                              CupertinoIcons.arrow_up_right_square,
                              size: 18,
                            ),
                            onTap: () => _openLink(
                              'https://markarchery.app/privacy.html',
                            ),
                          ),
                          const GroupedCardDivider(),
                          ListTile(
                            leading: const Icon(CupertinoIcons.doc_text),
                            title: const Text('Terms of Service'),
                            trailing: const Icon(
                              CupertinoIcons.arrow_up_right_square,
                              size: 18,
                            ),
                            onTap: () =>
                                _openLink('https://markarchery.app/terms.html'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    OutlinedButton.icon(
                      onPressed: () => _handleSignOut(context),
                      icon: const Icon(CupertinoIcons.square_arrow_right),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
