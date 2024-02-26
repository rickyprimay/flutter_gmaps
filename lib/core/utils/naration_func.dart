import 'package:intl/intl.dart';
import 'package:VehiLoc/core/model/response_daily.dart';

String formatTime(int timestamp) {
  return DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
}

String formatNaration(JdetailsItem item) {
  if (item.type == 1) {
    String duration = formatDuration(item.enddt - item.startdt);
    return 'Stopped $duration at';
  } else if (item.type == 2) {
    double distanceKm = item.distance / 1000;
    return 'Moved ${distanceKm.toStringAsFixed(2)} km for ${formatDuration(item.enddt - item.startdt)}';
  } else {
    return 'Unknown event';
  }
}

String formatDuration(int durationSeconds) {
  int hours = durationSeconds ~/ 3600;
  int minutes = (durationSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '$hours hr ${minutes} mins';
  } else {
    return '${minutes} mins';
  }
}
