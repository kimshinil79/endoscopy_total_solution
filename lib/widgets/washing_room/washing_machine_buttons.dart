import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WashingMachineButtons extends StatelessWidget {
  final List<String> washingMachineNames;
  final Map<String, int> washingMachineCounts;
  final Map<String, String> recentDisinfectantChangeDates;
  final Map<String, int> machineAfterChangeCounts;
  final String selectedWashingMachine;
  final Function(String) onMachineSelected;
  final Function(String) onMachineLongPress;

  const WashingMachineButtons({
    Key? key,
    required this.washingMachineNames,
    required this.washingMachineCounts,
    required this.recentDisinfectantChangeDates,
    required this.machineAfterChangeCounts,
    required this.selectedWashingMachine,
    required this.onMachineSelected,
    required this.onMachineLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          washingMachineNames
              .map((name) => _buildWashingButton(context, name))
              .toList(),
    );
  }

  Widget _buildWashingButton(BuildContext context, String name) {
    String patientsCount = washingMachineCounts[name].toString();
    String recentDate = recentDisinfectantChangeDates[name] ?? '00/00';
    int afterChangeCount = machineAfterChangeCounts[name] ?? 0;

    if (recentDate != '00/00') {
      DateTime parsedDate = DateTime.parse(recentDate);
      recentDate = DateFormat('M월d일').format(parsedDate);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => onMachineSelected(name),
          onLongPress: () => onMachineLongPress(name),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedWashingMachine == name
                    ? Colors.orange[100]
                    : Colors.yellow[100],
            foregroundColor: Colors.black87,
            padding: EdgeInsets.all(16.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 4.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  recentDate,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              SizedBox(height: 4.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$patientsCount / $afterChangeCount',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
