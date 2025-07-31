import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WashingRoomTopRow extends StatelessWidget {
  final String buttonText;
  final String selectedScope;
  final DateTime? selectedDate;
  final VoidCallback onTestedPeoplePressed;
  final VoidCallback onScopePressed;
  final VoidCallback onScopeLongPress;
  final VoidCallback onUpdateButtonText;
  final VoidCallback onDatePressed;
  final VoidCallback onDateLongPress;

  const WashingRoomTopRow({
    Key? key,
    required this.buttonText,
    required this.selectedScope,
    required this.selectedDate,
    required this.onTestedPeoplePressed,
    required this.onScopePressed,
    required this.onScopeLongPress,
    required this.onUpdateButtonText,
    required this.onDatePressed,
    required this.onDateLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildCustomButton(
            context,
            buttonText,
            onPressed: onTestedPeoplePressed,
            onLongPress: onUpdateButtonText,
          ),
        ),
        Expanded(
          child: _buildCustomButton(
            context,
            selectedScope,
            onPressed: onScopePressed,
            onLongPress: onScopeLongPress,
            backgroundColor: Colors.blue.shade600,
          ),
        ),
        Expanded(child: _buildDateButton(context)),
      ],
    );
  }

  Widget _buildCustomButton(
    BuildContext context,
    String name, {
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.2),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.blue[50],
          foregroundColor: Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onDatePressed,
        onLongPress: onDateLongPress,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_getFormattedDate()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[100],
          foregroundColor: Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  String _getFormattedDate() {
    if (selectedDate == null) return '오늘';
    return _isToday(selectedDate!)
        ? '오늘'
        : DateFormat('yy/MM/dd').format(selectedDate!);
  }

  bool _isToday(DateTime date) {
    final DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
