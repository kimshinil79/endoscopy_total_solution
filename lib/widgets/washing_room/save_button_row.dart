import 'package:flutter/material.dart';

class SaveButtonRow extends StatelessWidget {
  final String selectedWashingCharger;
  final VoidCallback onSave;
  final VoidCallback onWashingChargerPressed;

  const SaveButtonRow({
    Key? key,
    required this.selectedWashingCharger,
    required this.onSave,
    required this.onWashingChargerPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: ElevatedButton(
              onPressed: onSave,
              child: Text('저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: onWashingChargerPressed,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(selectedWashingCharger),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
