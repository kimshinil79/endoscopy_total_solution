import 'package:flutter/material.dart';
import '../data_class/patient_exam.dart';

class CSFFormWidget extends StatefulWidget {
  final String selectedBx;
  final Function(String?) onSelectedBxChanged;
  final ExaminationDetails csfDetails;
  final Function(bool?) onEmergencyChanged;
  final String? selectedPolypectomy;
  final Function(String?) onSelectedPolypectomyChanged;
  final Map<String, String> CSFmachine;
  final Map<String, Map<String, String>> selectedScopes;
  final Function(String) onScopeSelected;
  final Function(String, String) onAddScope;
  final String csfGumjinOrNot;
  final Function(String?) onCsfGumjinChanged;
  final String csfSleepOrNot;
  final Function(String?) onCsfSleepChanged;
  final Patient? patient;

  CSFFormWidget({
    required this.selectedBx,
    required this.onSelectedBxChanged,
    required this.csfDetails,
    required this.onEmergencyChanged,
    required this.selectedPolypectomy,
    required this.onSelectedPolypectomyChanged,
    required this.CSFmachine,
    required this.selectedScopes,
    required this.onScopeSelected,
    required this.onAddScope,
    required this.csfGumjinOrNot,
    required this.onCsfGumjinChanged,
    required this.csfSleepOrNot,
    required this.onCsfSleepChanged,
    this.patient,
  });

  @override
  _CSFFormWidgetState createState() => _CSFFormWidgetState();
}

class _CSFFormWidgetState extends State<CSFFormWidget> {
  @override
  void didUpdateWidget(CSFFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient != oldWidget.patient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (widget.patient?.CSF != null) {
            widget.onCsfGumjinChanged(widget.patient!.CSF!.gumjinOrNot);
            widget.onCsfSleepChanged(widget.patient!.CSF!.sleepOrNot);
          }
        });
      });
    }
  }

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
        border: Border.all(color: Colors.teal, width: 2),
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
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.csfGumjinOrNot == '검진'
                                      ? Colors.blue
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onCsfGumjinChanged('검진'),
                            child: Text(
                              '검진',
                              style: TextStyle(
                                color:
                                    widget.csfGumjinOrNot == '검진'
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.csfGumjinOrNot == '외래'
                                      ? Colors.blue
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onCsfGumjinChanged('외래'),
                            child: Text(
                              '외래',
                              style: TextStyle(
                                color:
                                    widget.csfGumjinOrNot == '외래'
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                '|',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.csfSleepOrNot == '수면'
                                      ? Colors.green
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onCsfSleepChanged('수면'),
                            child: Text(
                              '수면',
                              style: TextStyle(
                                color:
                                    widget.csfSleepOrNot == '수면'
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.csfSleepOrNot == '일반'
                                      ? Colors.green
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onCsfSleepChanged('일반'),
                            child: Text(
                              '일반',
                              style: TextStyle(
                                color:
                                    widget.csfSleepOrNot == '일반'
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.black),
          Row(
            children: [
              Text(
                'Polypectomy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                      '6',
                      '7',
                      '8',
                      '9',
                      '10',
                      '11',
                      '12',
                      '13',
                      '14',
                      '15',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
              Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children:
                    ['1', '2', '3']
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.selectedPolypectomy == value
                                        ? Colors.blueAccent
                                        : Colors.white60,
                                shape: CircleBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                if (widget.selectedPolypectomy == value) {
                                  // 이미 선택된 버튼을 다시 누르면 선택 해제
                                  widget.onSelectedPolypectomyChanged('없음');
                                } else {
                                  // 다른 버튼을 누르면 해당 버튼 선택
                                  widget.onSelectedPolypectomyChanged(value);
                                }
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color:
                                        widget.selectedPolypectomy == value
                                            ? Colors.white
                                            : Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
          Divider(color: Colors.black),
          Row(
            children: [
              Text('Bx', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Wrap(
                spacing: -7,
                runSpacing: 0,
                children:
                    ['1', '2', '3']
                        .map(
                          (value) => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.selectedBx == value
                                      ? Colors.blueAccent
                                      : Colors.white60,
                              shape: CircleBorder(),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              if (widget.selectedBx == value) {
                                // 이미 선택된 버튼을 다시 누르면 선택 해제
                                widget.onSelectedBxChanged('없음');
                              } else {
                                // 다른 버튼을 누르면 해당 버튼 선택
                                widget.onSelectedBxChanged(value);
                              }
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color:
                                      widget.selectedBx == value
                                          ? Colors.white
                                          : Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              SizedBox(width: 4),
              Text(
                '|',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.csfDetails.emergency
                                  ? Colors.redAccent
                                  : Colors.grey[300],
                          foregroundColor:
                              widget.csfDetails.emergency
                                  ? Colors.white
                                  : Colors.grey[600],
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          widget.onEmergencyChanged(
                            !widget.csfDetails.emergency,
                          );
                        },
                        child: Text('응급', style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (widget.csfDetails.stoolOB ?? false)
                                  ? Colors.redAccent
                                  : Colors.grey[300],
                          foregroundColor:
                              (widget.csfDetails.stoolOB ?? false)
                                  ? Colors.white
                                  : Colors.grey[600],
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          setState(() {
                            widget.csfDetails.stoolOB =
                                !(widget.csfDetails.stoolOB ?? false);
                          });
                        },
                        child: Text('StoolOB', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
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
              ...widget.CSFmachine.keys.map((key) {
                return _machineButton(key);
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
