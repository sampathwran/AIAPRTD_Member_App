import 'package:flutter/material.dart';

class ScheduledButton extends StatelessWidget {
  final VoidCallback onTap;
  const ScheduledButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.calendar_month, color: colorScheme.primary),
        ),
        title: Text(
          "Scheduled Bookings",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1, // Limit to one line
          overflow: TextOverflow.ellipsis, // Add ellipsis if text is too long
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color),
        onTap: onTap,
      ),
    );
  }
}