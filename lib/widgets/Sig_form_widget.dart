import 'package:flutter/material.dart';
import '../data_class/patient_exam.dart';

class SigFormWidget extends StatefulWidget {
  final String selectedBx;
  final Function(String?) onSelectedBxChanged;
  final ExaminationDetails sigDetails;
  final Function(bool?) onEmergencyChanged;
  final String? selectedPolypectomy;
  final Function(String?) onSelectedPolypectomyChanged;
  final Map<String, String> Sigmachine;
  final Map<String, Map<String, String>>
  selectedScopes; // Changed to Map<String, Map<String, String>>
  final Function(String) onScopeSelected;
  final Function(String, String) onAddScope;

  SigFormWidget({
    required this.selectedBx,
    required this.onSelectedBxChanged,
    required this.sigDetails,
    required this.onEmergencyChanged,
    required this.selectedPolypectomy,
    required this.onSelectedPolypectomyChanged,
    required this.Sigmachine,
    required this.selectedScopes,
    required this.onScopeSelected,
    required this.onAddScope,
  });

  @override
  _SigFormWidgetState createState() => _SigFormWidgetState();
}

class _SigFormWidgetState extends State<SigFormWidget> {
  final TextEditingController _shortNameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  void _showAddScopeDialog() {
    bool isAddButtonEnabled = false;

    void _updateAddButtonState() {
      setState(() {
        isAddButtonEnabled =
            _shortNameController.text.isNotEmpty &&
            _fullNameController.text.isNotEmpty;
      });
    }

    _shortNameController.addListener(_updateAddButtonState);
    _fullNameController.addListener(_updateAddButtonState);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('내시경 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _shortNameController,
                    decoration: InputDecoration(labelText: '축약 이름'),
                    onChanged: (value) {
                      setState(() {
                        isAddButtonEnabled =
                            value.isNotEmpty &&
                            _fullNameController.text.isNotEmpty;
                      });
                    },
                  ),
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(labelText: '전체 이름'),
                    onChanged: (value) {
                      setState(() {
                        isAddButtonEnabled =
                            value.isNotEmpty &&
                            _shortNameController.text.isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('취소'),
                ),
                TextButton(
                  onPressed:
                      isAddButtonEnabled
                          ? () {
                            widget.onAddScope(
                              _shortNameController.text,
                              _fullNameController.text,
                            );
                            _shortNameController.clear();
                            _fullNameController.clear();
                            Navigator.of(context).pop();
                          }
                          : null,
                  child: Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _radioButtonInExamRoom(
    String title,
    String value,
    String groupValue,
    void Function(String?) onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 2.0,
          ), // Add padding to the right of the Text
          child: Text(title),
        ),
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _machineButton(String key) {
    bool isSelected = widget.selectedScopes.containsKey(key);
    return GestureDetector(
      onTap: () {
        widget.onScopeSelected(key);
      },
      child: Container(
        margin: EdgeInsets.all(4.0),
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigoAccent : Colors.white,
          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          key,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shortNameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Bx'),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: widget.selectedBx,
                onChanged: widget.onSelectedBxChanged,
                items:
                    [
                      '없음',
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
              Spacer(),
              Text('Polypectomy'),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: widget.selectedPolypectomy,
                onChanged: widget.onSelectedPolypectomyChanged,
                items:
                    [
                      '없음',
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
              Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.sigDetails.emergency
                          ? Colors.redAccent
                          : Colors.grey[300],
                  foregroundColor:
                      widget.sigDetails.emergency
                          ? Colors.white
                          : Colors.grey[600],
                  padding: EdgeInsets.zero, // Remove padding
                ),
                onPressed: () {
                  widget.onEmergencyChanged(!widget.sigDetails.emergency);
                },
                child: Text(
                  '응급',
                  style: TextStyle(fontSize: 16), // Increase font size
                ),
              ),
            ],
          ),
          Divider(color: Colors.black),
          SizedBox(height: 10),
          Text(
            'Scopes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            children: [
              ...widget.Sigmachine.keys.map((key) {
                return _machineButton(key);
              }).toList(),
              // IconButton(
              //   icon: Icon(Icons.add),
              //   onPressed: _showAddScopeDialog,
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
