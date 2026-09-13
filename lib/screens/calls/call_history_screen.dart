import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/core_providers.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryProvider);
    final myUid =
        ref.watch(authServiceProvider).currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Call History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: $e',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                color: AppColors.error,
              ),
            ),
          ),
        ),
        data: (calls) {
          if (calls.isEmpty) {
            return Center(
              child: Text(
                'No calls yet',
                style: AppTextStyles.bodyMd(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            );
          }

          // Group calls by user.
          final Map<String, List<CallModel>> groupedCalls = {};

          for (final call in calls) {
            final otherUid = call.otherUid(myUid);

            groupedCalls.putIfAbsent(
              otherUid,
                  () => [],
            );

            groupedCalls[otherUid]!.add(call);
          }

          // Sort calls inside each user group.
          for (final callsForUser in groupedCalls.values) {
            callsForUser.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
            );
          }

          // Sort users by latest call.
          final groupedEntries = groupedCalls.entries.toList();

          groupedEntries.sort((a, b) {
            return b.value.first.createdAt.compareTo(
              a.value.first.createdAt,
            );
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final otherUid = groupedEntries[index].key;
              final userCalls = groupedEntries[index].value;

              return _UserCallHistoryTile(
                otherUid: otherUid,
                calls: userCalls,
                myUid: myUid,
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// USER HISTORY TILE
// ============================================================

class _UserCallHistoryTile extends ConsumerWidget {
  const _UserCallHistoryTile({
    required this.otherUid,
    required this.calls,
    required this.myUid,
  });

  final String otherUid;
  final List<CallModel> calls;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream =
    ref.watch(userRepositoryProvider).watchProfile(otherUid);

    final latestCall = calls.first;

    return StreamBuilder(
      stream: userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        final userName = user?.fullName.isNotEmpty == true
            ? user!.fullName
            : 'Unknown User';

        final isOutgoing = latestCall.isCaller(myUid);

        final latestType = latestCall.type == CallType.video
            ? 'Video call'
            : 'Audio call';

        final latestStatus =
        _statusText(latestCall.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(
              AppRadius.lg,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                AppRadius.lg,
              ),
              onTap: () {
                _showUserCallHistory(
                  context,
                  ref,
                  userName: userName,
                  calls: calls,
                  myUid: myUid,
                );
              },
              onLongPress: () {
                _confirmDeleteUserHistory(
                  context,
                  ref,
                  userName: userName,
                  myUid: myUid,
                  otherUid: otherUid,
                  callCount: calls.length,
                );
              },

              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: user?.photoUrl.isNotEmpty == true
                            ? CachedNetworkImage(
                          imageUrl: user!.photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) {
                            return _avatarFallback(context);
                          },
                        )
                            : _avatarFallback(context),
                      ),
                    ),

                    const SizedBox(width: 13),

                    // User information
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headlineMd(
                              color: context.colors.onSurface,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: [
                              Icon(
                                isOutgoing
                                    ? Icons.call_made_rounded
                                    : Icons.call_received_rounded,
                                size: 15,
                                color: isOutgoing
                                    ? AppColors.primary
                                    : AppColors.tertiary,
                              ),

                              const SizedBox(width: 5),

                              Flexible(
                                child: Text(
                                  isOutgoing
                                      ? 'Outgoing'
                                      : 'Incoming',
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  AppTextStyles.bodySm(
                                    color: AppColors
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              Text(
                                '•',
                                style: AppTextStyles.bodySm(
                                  color: AppColors
                                      .onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(width: 6),

                              Flexible(
                                child: Text(
                                  latestType,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  AppTextStyles.bodySm(
                                    color: AppColors
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(
                                latestCall.type ==
                                    CallType.video
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                size: 14,
                                color: AppColors
                                    .onSurfaceVariant,
                              ),

                              const SizedBox(width: 5),

                              Flexible(
                                child: Text(
                                  DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(
                                    latestCall.createdAt,
                                  ),
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  AppTextStyles.bodySm(
                                    color: AppColors
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 7),

                              Text(
                                latestStatus,
                                style:
                                AppTextStyles.bodySm(
                                  color: _statusColor(
                                    latestCall.status,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Number of calls
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                        AppColors.primaryTonal20,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${calls.length}',
                        style: AppTextStyles.bodySm(
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Delete complete user history.
                    IconButton(
                      tooltip: 'Delete call history',
                      onPressed: () {
                        _confirmDeleteUserHistory(
                          context,
                          ref,
                          userName: userName,
                          myUid: myUid,
                          otherUid: otherUid,
                          callCount: calls.length,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      color: context.colors.surfaceContainerHigh,
      child: Icon(
        Icons.person_rounded,
        color: context.colors.onSurfaceVariant,
        size: 27,
      ),
    );
  }
  Future<void> _confirmDeleteUserHistory(
      BuildContext context,
      WidgetRef ref, {
        required String userName,
        required String myUid,
        required String otherUid,
        required int callCount,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
          context.colors.surfaceContainerLow,

          title: Text(
            'Delete call history?',
            style: AppTextStyles.headlineMd(
              color: context.colors.onSurface,
            ),
          ),

          content: Text(
            'Delete all $callCount call${callCount == 1 ? '' : 's'} '
                'with $userName?\n\n'
                'This action cannot be undone.',
            style: AppTextStyles.bodyMd(
              color: context.colors.onSurfaceVariant,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMd(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                'Delete All',
                style: AppTextStyles.bodyMd(
                  color: AppColors.error,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(callRepositoryProvider)
          .deleteUserCallHistory(
        myUid: myUid,
        otherUid: otherUid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Call history with $userName deleted',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete call history: $e',
          ),
        ),
      );
    }
  }

  void _showUserCallHistory(
      BuildContext context,
      WidgetRef ref, {
        required String userName,
        required List<CallModel> calls,
        required String myUid,
      }) {
    final selectedCallIds = <String>{};

    showModalBottomSheet(
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
            final isSelectionMode =
                selectedCallIds.isNotEmpty;

            final allSelected =
                calls.isNotEmpty &&
                    selectedCallIds.length == calls.length;

            void toggleCallSelection(String callId) {
              setSheetState(() {
                if (selectedCallIds.contains(callId)) {
                  selectedCallIds.remove(callId);
                } else {
                  selectedCallIds.add(callId);
                }
              });
            }

            void selectAll() {
              setSheetState(() {
                if (allSelected) {
                  selectedCallIds.clear();
                } else {
                  selectedCallIds
                    ..clear()
                    ..addAll(
                      calls.map((call) => call.id),
                    );
                }
              });
            }

            Future<void> deleteSelectedCalls() async {
              if (selectedCallIds.isEmpty) return;

              final count = selectedCallIds.length;

              final confirmed =
              await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    backgroundColor:
                    context.colors.surfaceContainerLow,

                    title: Text(
                      'Delete selected calls?',
                      style: AppTextStyles.headlineMd(
                        color: context.colors.onSurface,
                      ),
                    ),

                    content: Text(
                      count == 1
                          ? 'Delete this call?'
                          : 'Delete these $count calls?\n\n'
                          'This action cannot be undone.',
                      style: AppTextStyles.bodyMd(
                        color:
                        context.colors.onSurfaceVariant,
                      ),
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(false);
                        },
                        child: Text(
                          'Cancel',
                          style:
                          AppTextStyles.bodyMd(
                            color: AppColors
                                .onSurfaceVariant,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(true);
                        },
                        child: Text(
                          'Delete',
                          style:
                          AppTextStyles.bodyMd(
                            color:
                            AppColors.error,
                          ).copyWith(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmed != true) return;

              try {
                final repository =
                ref.read(callRepositoryProvider);

                for (final callId
                in selectedCallIds.toList()) {
                  await repository.deleteCall(callId);
                }

                if (!context.mounted) return;

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      count == 1
                          ? 'Call deleted'
                          : '$count calls deleted',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete calls: $e',
                    ),
                  ),
                );
              }
            }

            Future<void> deleteAllUserCalls() async {
              final confirmed =
              await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    backgroundColor:
                    context.colors.surfaceContainerLow,

                    title: Text(
                      'Delete all calls?',
                      style: AppTextStyles.headlineMd(
                        color: context.colors.onSurface,
                      ),
                    ),

                    content: Text(
                      'Delete all ${calls.length} calls '
                          'with $userName?',
                      style: AppTextStyles.bodyMd(
                        color:
                        context.colors.onSurfaceVariant,
                      ),
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(true);
                        },
                        child: Text(
                          'Delete All',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmed != true) return;

              try {
                await ref
                    .read(callRepositoryProvider)
                    .deleteUserCallHistory(
                  myUid: myUid,
                  otherUid: calls.first.otherUid(
                    myUid,
                  ),
                );

                if (!context.mounted) return;

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Call history with $userName deleted',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete history: $e',
                    ),
                  ),
                );
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (
                  context,
                  scrollController,
                  ) {
                return SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Drag handle
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors
                              .onSurfaceVariant
                              .withValues(alpha: 0.4),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Header
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            if (isSelectionMode)
                              IconButton(
                                tooltip:
                                'Cancel selection',
                                onPressed: () {
                                  setSheetState(() {
                                    selectedCallIds
                                        .clear();
                                  });
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color:
                                  context.colors.onSurface,
                                ),
                              )
                            else
                              const SizedBox(
                                width: 48,
                              ),

                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    isSelectionMode
                                        ? '${selectedCallIds.length} selected'
                                        : userName,
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    textAlign:
                                    TextAlign.center,
                                    style:
                                    AppTextStyles
                                        .headlineMd(
                                      color: AppColors
                                          .onSurface,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '${calls.length} call${calls.length == 1 ? '' : 's'}',
                                    style:
                                    AppTextStyles
                                        .bodySm(
                                      color: AppColors
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isSelectionMode) ...[
                              IconButton(
                                tooltip: allSelected
                                    ? 'Clear selection'
                                    : 'Select all',
                                onPressed: selectAll,
                                icon: Icon(
                                  allSelected
                                      ? Icons
                                      .deselect_rounded
                                      : Icons
                                      .select_all_rounded,
                                  color:
                                  AppColors.primary,
                                ),
                              ),

                              IconButton(
                                tooltip:
                                'Delete selected',
                                onPressed:
                                deleteSelectedCalls,
                                icon: const Icon(
                                  Icons
                                      .delete_outline_rounded,
                                  color:
                                  AppColors.error,
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                tooltip:
                                'Delete all history',
                                onPressed:
                                deleteAllUserCalls,
                                icon: const Icon(
                                  Icons
                                      .delete_outline_rounded,
                                  color:
                                  AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Specific call history
                      Expanded(
                        child: ListView.builder(
                          controller:
                          scrollController,
                          padding:
                          const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            24,
                          ),
                          itemCount: calls.length,
                          itemBuilder:
                              (context, index) {
                            final call = calls[index];

                            return _IndividualCallTile(
                              call: call,
                              myUid: myUid,
                              isSelected:
                              selectedCallIds
                                  .contains(
                                call.id,
                              ),
                              isSelectionMode:
                              isSelectionMode,
                              onLongPress: () {
                                HapticFeedback
                                    .mediumImpact();

                                toggleCallSelection(
                                  call.id,
                                );
                              },
                              onTap: isSelectionMode
                                  ? () {
                                toggleCallSelection(
                                  call.id,
                                );
                              }
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _statusText(
      CallStatus status,
      ) {
    switch (status) {
      case CallStatus.missed:
        return 'Missed';

      case CallStatus.declined:
        return 'Declined';

      case CallStatus.ended:
        return 'Completed';

      case CallStatus.ringing:
        return 'Ringing';

      case CallStatus.connecting:
        return 'Connecting';

      case CallStatus.ongoing:
        return 'Ongoing';
    }
  }

  static Color _statusColor(
      CallStatus status,
      ) {
    switch (status) {
      case CallStatus.missed:
      case CallStatus.declined:
        return AppColors.error;

      case CallStatus.ended:
        return AppColors.tertiary;

      case CallStatus.ringing:
      case CallStatus.connecting:
      case CallStatus.ongoing:
        return AppColors.primary;
    }
  }
}

// ============================================================
// INDIVIDUAL CALL TILE
// ============================================================

class _IndividualCallTile extends StatelessWidget {
  const _IndividualCallTile({
    required this.call,
    required this.myUid,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onLongPress,
    this.onTap,
  });

  final CallModel call;
  final String myUid;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = call.isCaller(myUid);

    final isMissed =
        call.status == CallStatus.missed;

    final isDeclined =
        call.status == CallStatus.declined;

    final isVideo =
        call.type == CallType.video;

    final baseColor =
    isMissed || isDeclined
        ? AppColors.error
        : isOutgoing
        ? AppColors.primary
        : AppColors.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryTonal20
            : context.colors.surfaceContainerLow,
        borderRadius:
        BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Selection checkbox
                if (isSelectionMode) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors
                            .onSurfaceVariant,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                        : null,
                  ),

                  const SizedBox(width: 12),
                ],

                // Call icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    baseColor.withValues(
                      alpha: 0.14,
                    ),
                  ),
                  child: Icon(
                    isOutgoing
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    color: baseColor,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isOutgoing
                                  ? 'Outgoing'
                                  : 'Incoming',
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style:
                              AppTextStyles.headlineMd(
                                color:
                                isMissed ||
                                    isDeclined
                                    ? AppColors
                                    .error
                                    : AppColors
                                    .onSurface,
                              ),
                            ),
                          ),

                          const SizedBox(width: 7),

                          Icon(
                            isVideo
                                ? Icons
                                .videocam_rounded
                                : Icons.call_rounded,
                            size: 16,
                            color: AppColors
                                .onSurfaceVariant,
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(
                          call.createdAt,
                        ),
                        style:
                        AppTextStyles.bodySm(
                          color: AppColors
                              .onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Text(
                            _statusText(
                              call.status,
                            ),
                            style:
                            AppTextStyles.bodySm(
                              color:
                              isMissed ||
                                  isDeclined
                                  ? AppColors
                                  .error
                                  : AppColors
                                  .tertiary,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Flexible(
                            child: Text(
                              isVideo
                                  ? 'Video call'
                                  : 'Audio call',
                              overflow:
                              TextOverflow.ellipsis,
                              style:
                              AppTextStyles.bodySm(
                                color: AppColors
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),

                          if (call.durationSeconds >
                              0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${_formatDuration(call.durationSeconds)}',
                              style:
                              AppTextStyles.bodySm(
                                color: AppColors
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _statusText(
      CallStatus status,
      ) {
    switch (status) {
      case CallStatus.missed:
        return 'Missed';

      case CallStatus.declined:
        return 'Declined';

      case CallStatus.ended:
        return 'Completed';

      case CallStatus.ringing:
        return 'Ringing';

      case CallStatus.connecting:
        return 'Connecting';

      case CallStatus.ongoing:
        return 'Ongoing';
    }
  }

  static String _formatDuration(
      int seconds,
      ) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }
}