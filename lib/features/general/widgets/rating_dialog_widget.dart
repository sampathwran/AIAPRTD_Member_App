import 'package:flutter/material.dart';

class RatingDialogWidget extends StatefulWidget {
  final String title;
  final bool isRatingDriver; // Determines which default reason chips to show
  final Function(int rating, List<String> selectedChips, String customReason) onSubmit;
  final bool isSubmitting;

  const RatingDialogWidget({
    super.key,
    required this.title,
    required this.isRatingDriver,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<RatingDialogWidget> createState() => _RatingDialogWidgetState();
}

class _RatingDialogWidgetState extends State<RatingDialogWidget> {
  int _currentRating = 5;
  final TextEditingController _reasonController = TextEditingController();
  final Set<String> _selectedChips = {};

  List<String> get _currentChips {
    if (widget.isRatingDriver) {
      if (_currentRating == 5) {
        return ["Safe Driving", "Clean Vehicle", "Friendly", "On Time"];
      } else {
        return ["Reckless Driving", "Dirty Vehicle", "Rude", "Late", "Other"];
      }
    } else {
      if (_currentRating == 5) {
        return ["Polite", "On Time", "Clean", "Good Communication"];
      } else {
        return ["Rude", "Late", "Made a mess", "Bad Communication", "Other"];
      }
    }
  }

  @override
  void didUpdateWidget(RatingDialogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If rating changed externally (not applicable here, but good practice)
  }

  void _onStarTapped(int index) {
    setState(() {
      _currentRating = index + 1;
      _selectedChips.clear(); // Clear chips when rating changes because chips change
    });
  }

  void _onChipToggled(String chipText) {
    setState(() {
      if (_selectedChips.contains(chipText)) {
        _selectedChips.remove(chipText);
      } else {
        _selectedChips.add(chipText);
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How was your experience?"),
            const SizedBox(height: 20),
            
            // Stars
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _currentRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () => _onStarTapped(index),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            
            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _currentChips.map((chipText) {
                final isSelected = _selectedChips.contains(chipText);
                return ChoiceChip(
                  label: Text(chipText, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (_) => _onChipToggled(chipText),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Custom Reason TextField
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Anything else to add? (Optional)",
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isSubmitting)
          const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ))
        else
          ElevatedButton(
            onPressed: () {
              widget.onSubmit(_currentRating, _selectedChips.toList(), _reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, 
              minimumSize: const Size(double.infinity, 50), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("SUBMIT RATING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
      ],
    );
  }
}
