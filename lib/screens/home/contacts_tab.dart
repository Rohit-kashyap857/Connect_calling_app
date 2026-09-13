import 'package:connect_call_assignment/screens/home/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/core_providers.dart';
import 'widgets/empty_state.dart';
import 'widgets/error_state.dart';
import 'widgets/glass_container.dart';
import 'widgets/mini_call_button.dart';

class ContactsTab extends ConsumerWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).currentUser?.uid;

    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<UserModel>>(
      stream: ref.watch(userRepositoryProvider).watchContacts(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Unable to load contacts',
            detail: '${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        final contacts = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Contacts',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddContactSheet(context, ref, uid),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? const EmptyState(
                icon: Icons.person_add_alt_1_rounded,
                title: 'No contacts yet',
                subtitle:
                'Tap Add to find a ConnectCall user and add them to your contacts.',
              )
                  : RefreshIndicator(
                color: AppColors.primaryPulse,
                backgroundColor: context.colors.surfaceContainer,
                onRefresh: () async {
                  await Future<void>.delayed(
                    const Duration(milliseconds: 300),
                  );
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final user = contacts[index];

                    return _AnimatedContactCard(
                      user: user,
                      index: index,
                      onVoiceCall: () =>
                          _call(context, ref, user, CallType.voice),
                      onVideoCall: () =>
                          _call(context, ref, user, CallType.video),
                      onDelete: () =>
                          _confirmRemoveContact(context, ref, uid, user),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddContactSheet(
      BuildContext context,
      WidgetRef ref,
      String myUid,
      ) async {
    final searchController = TextEditingController();
    var query = '';
    var searching = false;
    var results = <UserModel>[];

    final added = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.colors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> search() async {
              final value = searchController.text.trim();

              setSheetState(() {
                query = value;
                searching = value.isNotEmpty;
                results = [];
              });

              if (value.isEmpty) return;

              try {
                final found = await ref
                    .read(userRepositoryProvider)
                    .searchUsers(myUid, value);

                if (!context.mounted) return;

                setSheetState(() {
                  results = found;
                  searching = false;
                });
              } catch (e) {
                if (!context.mounted) return;

                setSheetState(() {
                  searching = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.errorContainer,
                    content: Text(
                      'Unable to search users: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            }

            Future<void> addUser(UserModel user) async {
              try {
                await ref.read(userRepositoryProvider).addContact(
                  myUid: myUid,
                  contactUid: user.uid,
                );

                if (!context.mounted) return;

                HapticFeedback.lightImpact();

                Navigator.of(sheetContext).pop(true);
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.errorContainer,
                    content: Text(
                      'Unable to add contact: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add Contact',
                              style: TextStyle(
                                color: context.colors.onSurface,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // The modal route owns the keyboard/focus lifecycle.
                              // Do not unfocus and pop in a post-frame callback.
                              Navigator.of(sheetContext).pop(false);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: false,
                        style: TextStyle(
                          color: context.colors.onSurface,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => search(),
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          hintStyle: TextStyle(
                            color: context.colors.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            onPressed: search,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          filled: true,
                          fillColor: context.colors.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: searching
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                            : query.isEmpty
                            ? const EmptyState(
                          icon: Icons.search_rounded,
                          title: 'Find a user',
                          subtitle:
                          'Enter a phone number to find a ConnectCall user.',
                        )
                            : results.isEmpty
                            ? const EmptyState(
                          icon: Icons.person_search_rounded,
                          title: 'No users found',
                          subtitle:
                          'Check the phone number and try again.',
                        )
                            : ListView.builder(
                          itemCount: results.length,
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          itemBuilder: (context, index) {
                            final user = results[index];

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: GlassContainer(
                                child: ListTile(
                                  contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: UserAvatar(
                                    user: user,
                                  ),
                                  title: Text(
                                    user.fullName.isEmpty
                                        ? 'User'
                                        : user.fullName,
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                      context.colors.onSurface,
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user.phoneNumber ?? 'Phone number unavailable',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.colors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Add contact',
                                    onPressed: () =>
                                        addUser(user),
                                    icon: const Icon(
                                      Icons
                                          .person_add_rounded,
                                      color:
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();

    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Contact added successfully'),
        ),
      );
    }
  }

  Future<void> _confirmRemoveContact(
      BuildContext context,
      WidgetRef ref,
      String myUid,
      UserModel user,
      ) async {
    final name = user.fullName.isEmpty ? 'this user' : user.fullName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.colors.surfaceContainer,
          title: Text(
            'Remove contact?',
            style: TextStyle(color: dialogContext.colors.onSurface),
          ),
          content: Text(
            'Remove $name from your contacts? Your call history will not be deleted.',
            style: TextStyle(
              color: dialogContext.colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(userRepositoryProvider).removeContact(
        myUid: myUid,
        contactUid: user.uid,
      );

      if (!context.mounted) return;

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$name removed from contacts'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorContainer,
          content: Text(
            'Unable to remove contact: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _call(
      BuildContext context,
      WidgetRef ref,
      UserModel user,
      CallType type,
      ) async {
    try {
      await ref.read(callControllerProvider.notifier).startCall(
        calleeId: user.uid,
        chatId: user.uid,
        type: type,
      );

      if (context.mounted) {
        context.push('/calls/active');
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorContainer,
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Call failed: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _AnimatedContactCard extends StatefulWidget {
  const _AnimatedContactCard({
    required this.user,
    required this.index,
    required this.onVoiceCall,
    required this.onVideoCall,
    required this.onDelete,
  });

  final UserModel user;
  final int index;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback onDelete;

  @override
  State<_AnimatedContactCard> createState() => _AnimatedContactCardState();
}

class _AnimatedContactCardState extends State<_AnimatedContactCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * 70),
          () {
        if (mounted) {
          controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(controller.value);

        return Opacity(
          opacity: controller.value,
          child: Transform.translate(
            offset: Offset(
              0,
              25 * (1 - curved),
            ),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(user: widget.user),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName.isEmpty
                            ? 'User'
                            : widget.user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.user.isOnline
                                  ? AppColors.tertiary
                                  : AppColors.slate500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.user.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: widget.user.isOnline
                                  ? AppColors.tertiary
                                  : context.colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                MiniCallButton(
                  icon: Icons.call_rounded,
                  color: AppColors.tertiary,
                  onTap: widget.onVoiceCall,
                ),
                const SizedBox(width: 8),
                MiniCallButton(
                  icon: Icons.videocam_rounded,
                  color: AppColors.primaryPulse,
                  onTap: widget.onVideoCall,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Remove contact',
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.person_remove_alt_1_rounded,
                    color: AppColors.error,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}