import '../../../models/call_model.dart';

/// Small formatting helpers shared by the call-history UI.
class CallHistoryUtils {
  const CallHistoryUtils._();

  static String statusLabel(CallStatus status) {
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

  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[date.month - 1];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$month ${date.day}, $hour:$minute $period';
  }
}