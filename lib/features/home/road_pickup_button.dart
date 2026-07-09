import 'package:flutter/material.dart';

class RoadPickupButton extends StatelessWidget {
  final VoidCallback onTap;
  const RoadPickupButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.directions_car, color: colorScheme.primary),
        ),
        title: Text("Road Pickup", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color),
        onTap: onTap,
      ),
    );
  }
}