import 'package:flutter/material.dart';
import 'package:aiaprtd_member/core/providers/earnings_provider.dart';

class EarningTripTile extends StatelessWidget {
  final TripModel trip;
  final bool isDark;

  const EarningTripTile({
    super.key,
    required this.trip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.cardTheme.color ?? theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final bool isBooking = trip.type == 'booking';
    final bool isCancelled = trip.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCancelled
                  ? Colors.red.withValues(alpha: 0.1)
                  : isBooking
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_rounded
                  : (isBooking ? Icons.smartphone_rounded : Icons.hail_rounded),
              color: isCancelled
                  ? Colors.red
                  : (isBooking ? Colors.blue : Colors.orange),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBooking ? "App Booking" : "Road Pickup",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    isCancelled
                        ? Text(
                      trip.cancelBy == 'passenger' ? "Passenger Cancelled" : "Driver Cancelled",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    )
                        : Text(
                      "LKR ${trip.fare.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "ID: ${trip.id}",
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.blue.shade200 : Colors.blue.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  "${trip.date.year}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.day.toString().padLeft(2, '0')} • ${trip.date.hour.toString().padLeft(2, '0')}:${trip.date.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.trip_origin_rounded, size: 12, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.startAddress,
                        style: TextStyle(fontSize: 12, color: subTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: Colors.red.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.endAddress,
                        style: TextStyle(fontSize: 12, color: subTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}