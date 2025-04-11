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

    try {
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
    } catch (e) {
      print("대화상자 에러: $e");
    }
  }

  void _showBxSelectionDialog() {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Bx 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[800],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 20),
            content: Container(
              width: double.maxFinite,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children:
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
                    ].map((value) {
                      return SizedBox(
                        width: 60,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                widget.selectedBx == value
                                    ? Colors.indigoAccent
                                    : Colors.white,
                            foregroundColor:
                                widget.selectedBx == value
                                    ? Colors.white
                                    : Colors.black87,
                            elevation: widget.selectedBx == value ? 2 : 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    widget.selectedBx == value
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                              ),
                            ),
                          ),
                          onPressed: () {
                            widget.onSelectedBxChanged(value);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('취소', style: TextStyle(fontSize: 15)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Bx 대화상자 에러: $e");
    }
  }

  void _showPolypectomySelectionDialog() {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Polypectomy 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo[800],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 20),
            content: Container(
              width: double.maxFinite,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children:
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
                    ].map((value) {
                      return SizedBox(
                        width: 60,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                widget.selectedPolypectomy == value
                                    ? Colors.indigoAccent
                                    : Colors.white,
                            foregroundColor:
                                widget.selectedPolypectomy == value
                                    ? Colors.white
                                    : Colors.black87,
                            elevation:
                                widget.selectedPolypectomy == value ? 2 : 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    widget.selectedPolypectomy == value
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                              ),
                            ),
                          ),
                          onPressed: () {
                            widget.onSelectedPolypectomyChanged(value);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('취소', style: TextStyle(fontSize: 15)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Polypectomy 대화상자 에러: $e");
    }
  }

  Widget _machineButton(String key) {
    try {
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
    } catch (e) {
      print("기계 버튼 에러: $e");
      return SizedBox.shrink(); // 오류 발생 시 빈 위젯 반환
    }
  }

  @override
  void dispose() {
    _shortNameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
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
                ElevatedButton(
                  onPressed: _showPolypectomySelectionDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    'polypectomy: ${widget.selectedPolypectomy ?? '없음'}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                // Spacer(),
                Wrap(
                  spacing: -13,
                  runSpacing: 0,
                  children:
                      ['1', '2', '3', '4']
                          .map(
                            (value) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
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
                          )
                          .toList(),
                ),
              ],
            ),
            Divider(color: Colors.black),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _showBxSelectionDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    'Bx: ${widget.selectedBx}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                //Spacer(),
                Wrap(
                  spacing: -13,
                  runSpacing: 0,
                  children:
                      ['1', '2', '3']
                          .map(
                            (value) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      widget.selectedBx == value
                                          ? Colors.blueAccent
                                          : Colors.white60,
                                  padding: EdgeInsets.zero,
                                  shape: CircleBorder(),
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
                Text(
                  '|',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 6),
                Row(
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () {
                        widget.onEmergencyChanged(!widget.csfDetails.emergency);
                      },
                      child: Text('응급', style: TextStyle(fontSize: 14)),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.csfDetails.stoolOB =
                              !(widget.csfDetails.stoolOB ?? false);
                        });
                      },
                      child: Text('StoolOB', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.black),
            SizedBox(height: 10),
            Text(
              'Scopes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 0,
              runSpacing: 2,
              children: [
                ...widget.CSFmachine.keys.map((key) {
                  return _machineButton(key);
                }).toList(),
              ],
            ),
          ],
        ),
      );
    } catch (e, stack) {
      print("CSFFormWidget 빌드 오류: $e");
      print("스택 트레이스: $stack");

      // 간단한 오류 UI 반환
      return Card(
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                "대장내시경 데이터를 표시하는 중 오류가 발생했습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text("기본 정보만 표시합니다", style: TextStyle(color: Colors.grey[600])),
              Divider(),
              Text("BX: ${widget.selectedBx}"),
              Text("Polypectomy: ${widget.selectedPolypectomy ?? '없음'}"),
              Text("응급: ${widget.csfDetails.emergency ? '예' : '아니오'}"),
            ],
          ),
        ),
      );
    }
  }
}
