import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/core_providers.dart';
import 'utils/call_history_utils.dart';
import 'widgets/empty_state.dart';
import 'widgets/error_state.dart';
import 'widgets/glass_container.dart';
import 'widgets/user_avatar.dart';

class CallHistoryTab extends ConsumerWidget {
  const CallHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(callHistoryProvider);
    final me = ref.watch(authServiceProvider).currentUser?.uid ?? '';

    return history.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
      error: (error, _) => ErrorState(
        message: 'Unable to load call history',
        detail: '$error',
      ),
      data: (calls) {
        if (calls.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No calls yet',
            subtitle: 'Your audio and video call history will appear here.',
          );
        }
        final Map<String, List<CallModel>> groupedCalls = {};

        for (final call in calls) {
          final otherUid = call.otherUid(me);

          groupedCalls.putIfAbsent(
            otherUid,
                () => [],
          );

          groupedCalls[otherUid]!.add(call);
        }
        for (final userCalls in groupedCalls.values) {
          userCalls.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
          );
        }

        // Users with latest calls first.
        final groupedEntries = groupedCalls.entries.toList();

        groupedEntries.sort(
              (a, b) => b.value.first.createdAt.compareTo(
            a.value.first.createdAt,
          ),
        );

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          itemCount: groupedEntries.length,
          itemBuilder: (context, index) {
            final otherUid = groupedEntries[index].key;
            final userCalls = groupedEntries[index].value;

            return _HomeUserCallHistoryCard(
              otherUid: otherUid,
              calls: userCalls,
              myUid: me,
            );
          },
        );
      },
    );
  }
}

class _HomeUserCallHistoryCard extends ConsumerWidget {
  const _HomeUserCallHistoryCard({
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

    return StreamBuilder<UserModel?>(
      stream: userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        final userName = user?.fullName.isNotEmpty == true
            ? user!.fullName
            : 'Unknown User';

        final isOutgoing = latestCall.isCaller(myUid);

        final isVideo = latestCall.type == CallType.video;

        final isMissed = latestCall.status == CallStatus.missed ||
            latestCall.status == CallStatus.declined;

        final statusText = CallHistoryUtils.statusLabel(latestCall.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassContainer(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
              
                // User avatar
                leading: user != null
                    ? UserAvatar(user: user)
                    : Container(
                  width: 55,
                  height: 55,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              
                // User name + latest call
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
              
                    if (calls.length > 1)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPulse.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${calls.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              
                    const SizedBox(width: 4),
              
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.onSurfaceVariant,
                      size: 21,
                    ),
                  ],
                ),
              
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      Icon(
                        isOutgoing
                            ? Icons.call_made_rounded
                            : Icons.call_received_rounded,
                        size: 14,
                        color: isOutgoing
                            ? AppColors.primary
                            : AppColors.tertiary,
                      ),
              
                      const SizedBox(width: 5),
              
                      Text(
                        isOutgoing ? 'Outgoing' : 'Incoming',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              
                      const SizedBox(width: 5),
              
                      Text(
                        '•',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
              
                      const SizedBox(width: 5),
              
                      Icon(
                        isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                        size: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
              
                      const SizedBox(width: 4),
              
                      Text(
                        isVideo ? 'Video' : 'Audio',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
              
                      const SizedBox(width: 6),
              
                      Expanded(
                        child: Text(
                          '${CallHistoryUtils.formatDate(latestCall.createdAt)} • $statusText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMissed
                                ? AppColors.error
                                : context.colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
                trailing: IconButton(
                  tooltip: 'Delete call history',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  onPressed: () => _confirmDeleteUserHistory(
                    context,
                    ref,
                    userName,
                    myUid,
                    otherUid,
                  ),
                ),
              
                onTap: () {
                  _showHomeUserCallHistory(
                    context,
                    ref,
                    userName,
                    calls,
                    myUid,
                    otherUid,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _confirmDeleteUserHistory(
    BuildContext context,
    WidgetRef ref,
    String userName,
    String myUid,
    String otherUid,
    ) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: dialogContext.colors.surfaceContainer,
        title: Text(
          'Delete call history?',
          style: TextStyle(color: dialogContext.colors.onSurface),
        ),
        content: Text(
          'Delete all call history with $userName? This cannot be undone.',
          style: TextStyle(color: dialogContext.colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(callRepositoryProvider).deleteUserCallHistory(
      myUid: myUid,
      otherUid: otherUid,
    );

    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surfaceContainerHigh,
        content: Text(
          'Call history with $userName deleted',
          style: TextStyle(color: context.colors.onSurface),
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.errorContainer,
        content: Text(
          'Unable to delete call history: $e',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteSingleCall(
    BuildContext context,
    CallModel call,
    ) async {
  final type = call.type == CallType.video ? 'video' : 'audio';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: dialogContext.colors.surfaceContainer,
        title: Text(
          'Delete this call?',
          style: TextStyle(color: dialogContext.colors.onSurface),
        ),
        content: Text(
          'Delete this $type call from your history? This cannot be undone.',
          style: TextStyle(color: dialogContext.colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

void _showHomeUserCallHistory(
    BuildContext context,
    WidgetRef ref,
    String userName,
    List<CallModel> calls,
    String myUid,
    String otherUid,
    ) {
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
          final currentCalls = List<CallModel>.from(calls)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          Future<void> deleteOne(CallModel call) async {
            final confirmed = await _confirmDeleteSingleCall(context, call);
            if (!confirmed || !context.mounted) return;

            try {
              await ref.read(callRepositoryProvider).deleteCall(call.id);

              if (!context.mounted) return;
              setSheetState(() {
                currentCalls.removeWhere((item) => item.id == call.id);
              });
              HapticFeedback.mediumImpact();

              if (currentCalls.isEmpty && context.mounted) {
                Navigator.pop(context);
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Call deleted'),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.errorContainer,
                  content: Text(
                    'Unable to delete call: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          }

          Future<void> deleteAll() async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  backgroundColor: dialogContext.colors.surfaceContainer,
                  title: Text(
                    'Delete all calls?',
                    style: TextStyle(color: dialogContext.colors.onSurface),
                  ),
                  content: Text(
                    'Delete all ${currentCalls.length} call${currentCalls.length == 1 ? '' : 's'} with $userName? This cannot be undone.',
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
                        'Delete all',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                );
              },
            );

            if (confirmed != true || !context.mounted) return;

            try {
              await ref.read(callRepositoryProvider).deleteUserCallHistory(
                myUid: myUid,
                otherUid: otherUid,
              );

              if (!context.mounted) return;
              HapticFeedback.mediumImpact();
              Navigator.pop(context);

              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('All call history deleted'),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.errorContainer,
                  content: Text(
                    'Unable to delete call history: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

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

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentCalls.length} call${currentCalls.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete all call history',
                        onPressed: currentCalls.isEmpty ? null : deleteAll,
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (currentCalls.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                    child: Text(
                      'No call history with this user.',
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24,
                      ),
                      itemCount: currentCalls.length,
                      itemBuilder: (context, index) {
                        final call = currentCalls[index];
                        final isOutgoing = call.isCaller(myUid);
                        final isVideo = call.type == CallType.video;
                        final isError = call.status == CallStatus.missed ||
                            call.status == CallStatus.declined;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            child: ListTile(
                              leading: Icon(
                                isOutgoing
                                    ? Icons.call_made_rounded
                                    : Icons.call_received_rounded,
                                color: isError
                                    ? AppColors.error
                                    : isOutgoing
                                    ? AppColors.primary
                                    : AppColors.tertiary,
                              ),
                              title: Text(
                                '${isOutgoing ? 'Outgoing' : 'Incoming'} • '
                                    '${isVideo ? 'Video' : 'Audio'}',
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${CallHistoryUtils.formatDate(call.createdAt)} • '
                                    '${CallHistoryUtils.statusLabel(call.status)}',
                                style: TextStyle(
                                  color: isError
                                      ? AppColors.error
                                      : context.colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete call',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 21,
                                ),
                                onPressed: () => deleteOne(call),
                              ),
                            ),
                          ),
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
}

/// Legacy single-call row widget. Not referenced by the current tab
/// (which uses the grouped [_HomeUserCallHistoryCard] instead), kept
/// here unchanged so nothing from the original file is lost.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.call,
    required this.isOutgoing,
  });

  final CallModel call;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final missed = call.status == CallStatus.missed;
    final ended = call.status == CallStatus.ended;

    final icon =
    call.type == CallType.video ? Icons.videocam_rounded : Icons.call_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (missed
                  ? AppColors.error
                  : isOutgoing
                  ? AppColors.primaryPulse
                  : AppColors.tertiary)
                  .withValues(alpha: 0.14),
            ),
            child: Icon(
              isOutgoing ? Icons.call_made_rounded : Icons.call_received,
              color: missed
                  ? AppColors.error
                  : isOutgoing
                  ? AppColors.primary
                  : AppColors.tertiary,
            ),
          ),
          title: Row(
            children: [
              Text(
                isOutgoing ? 'Outgoing call' : 'Incoming call',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '${call.status.name} • ${_formatDate(call.createdAt)}',
              style: TextStyle(
                color: missed
                    ? AppColors.error
                    : ended
                    ? AppColors.onSurfaceVariant
                    : AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month ${hour}:$minute';
  }
}