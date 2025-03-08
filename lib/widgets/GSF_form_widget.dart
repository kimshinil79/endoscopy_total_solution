import 'package:flutter/material.dart';
import '../data_class/patient_exam.dart';

class GSFFormWidget extends StatefulWidget {
  final bool etcChecked;
  final Function(bool?) onEtcChanged;
  final String selectedBx;
  final Function(String?) onSelectedBxChanged;
  final ExaminationDetails gsfDetails;
  final Function(ExaminationDetails) onGsfDetailsChanged;
  final Function(bool?) onEmergencyChanged;
  final String? selectedPolypectomy;
  final Function(String?) onSelectedPolypectomyChanged;
  final Map<String, String> GSFmachine;
  final Map<String, Map<String, String>> selectedScopes;
  final Function(String) onScopeSelected;
  final Function(String, String) onAddScope;
  final String gsfGumjinOrNot;
  final Function(String?) onGsfGumjinChanged;
  final String gsfSleepOrNot;
  final Function(String?) onGsfSleepChanged;
  final Patient? patient;
  final Function() onCLOResultPressed;

  GSFFormWidget({
    required this.etcChecked,
    required this.onEtcChanged,
    required this.selectedBx,
    required this.onSelectedBxChanged,
    required this.gsfDetails,
    required this.onGsfDetailsChanged,
    required this.onEmergencyChanged,
    required this.selectedPolypectomy,
    required this.onSelectedPolypectomyChanged,
    required this.GSFmachine,
    required this.selectedScopes,
    required this.onScopeSelected,
    required this.onAddScope,
    required this.gsfGumjinOrNot,
    required this.onGsfGumjinChanged,
    required this.gsfSleepOrNot,
    required this.onGsfSleepChanged,
    this.patient,
    required this.onCLOResultPressed,
  });

  @override
  _GSFFormWidgetState createState() => _GSFFormWidgetState();
}

class _GSFFormWidgetState extends State<GSFFormWidget> {
  final TextEditingController _shortNameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool isAddButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _shortNameController.addListener(_updateAddButtonState);
    _fullNameController.addListener(_updateAddButtonState);
  }

  void _updateAddButtonState() {
    setState(() {
      isAddButtonEnabled =
          _shortNameController.text.isNotEmpty &&
          _fullNameController.text.isNotEmpty;
    });
  }

  @override
  void didUpdateWidget(GSFFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient != oldWidget.patient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (widget.patient?.GSF != null) {
            widget.onGsfGumjinChanged(widget.patient!.GSF!.gumjinOrNot);
            widget.onGsfSleepChanged(widget.patient!.GSF!.sleepOrNot);
          }
        });
      });
    }
  }

  void _showAddScopeDialog() {
    _shortNameController.clear();
    _fullNameController.clear();

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
                  ),
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(labelText: '전체 이름'),
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

  void _showBxSelectionDialog() {
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
                  ['없음', '1', '2', '3', '4', '5', '6', '7', '8', '9'].map((
                    value,
                  ) {
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
  }

  void _showPolypectomySelectionDialog() {
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
                  ['없음', '1', '2', '3', '4', '5'].map((value) {
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
  }

  String _getCLOResultText(String? result) {
    if (result == null || result.isEmpty) {
      return '미정';
    } else if (result == '+') {
      return '양성';
    } else if (result == '-') {
      return '음성';
    } else {
      return result; // 다른 값이 있을 경우 그대로 표시
    }
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
    _shortNameController.removeListener(_updateAddButtonState);
    _fullNameController.removeListener(_updateAddButtonState);
    _shortNameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.indigoAccent, width: 2),
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
                                  widget.gsfGumjinOrNot == '검진'
                                      ? Colors.blue
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onGsfGumjinChanged('검진'),
                            child: Text(
                              '검진',
                              style: TextStyle(
                                color:
                                    widget.gsfGumjinOrNot == '검진'
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
                                  widget.gsfGumjinOrNot == '외래'
                                      ? Colors.blue
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onGsfGumjinChanged('외래'),
                            child: Text(
                              '외래',
                              style: TextStyle(
                                color:
                                    widget.gsfGumjinOrNot == '외래'
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
                                  widget.gsfSleepOrNot == '수면'
                                      ? Colors.green
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onGsfSleepChanged('수면'),
                            child: Text(
                              '수면',
                              style: TextStyle(
                                color:
                                    widget.gsfSleepOrNot == '수면'
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
                                  widget.gsfSleepOrNot == '일반'
                                      ? Colors.green
                                      : Colors.white60,
                            ),
                            onPressed: () => widget.onGsfSleepChanged('일반'),
                            child: Text(
                              '일반',
                              style: TextStyle(
                                color:
                                    widget.gsfSleepOrNot == '일반'
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
              //Text('Bx', style: TextStyle(fontWeight: FontWeight.bold)),
              //SizedBox(width: 8),
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
              Wrap(
                spacing: -13,
                runSpacing: 0,
                children:
                    ['1', '2', '3']
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: ElevatedButton(
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
                                  widget.onSelectedBxChanged('없음');
                                } else {
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.gsfDetails.CLO == true
                          ? Colors.redAccent
                          : Colors.grey[300],
                  foregroundColor:
                      widget.gsfDetails.CLO == true
                          ? Colors.white
                          : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(2),
                  minimumSize: Size(40, 24), // 버튼의 최소 크기를 설정
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 탭 영역을 줄임
                ),
                onPressed: () {
                  final updatedDetails = ExaminationDetails(
                    Bx: widget.gsfDetails.Bx,
                    polypectomy: widget.gsfDetails.polypectomy,
                    emergency: widget.gsfDetails.emergency,
                    CLO: !(widget.gsfDetails.CLO ?? false),
                    CLOResult: widget.gsfDetails.CLOResult,
                    PEG: widget.gsfDetails.PEG,
                    stoolOB: widget.gsfDetails.stoolOB,
                  );
                  widget.onGsfDetailsChanged(updatedDetails);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'CLO',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 4),
              if (widget.gsfDetails.CLO ?? false)
                GestureDetector(
                  onTap: widget.onCLOResultPressed,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getCLOResultText(widget.gsfDetails.CLOResult),
                      style: TextStyle(color: Colors.white, fontSize: 15),
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
              ...widget.GSFmachine.keys.map((key) {
                return _machineButton(key);
              }).toList(),
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
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.gsfDetails.emergency
                          ? Colors.redAccent
                          : Colors.grey[300],
                  foregroundColor:
                      widget.gsfDetails.emergency
                          ? Colors.white
                          : Colors.grey[600],
                ),
                onPressed: () {
                  final updatedDetails = ExaminationDetails(
                    Bx: widget.gsfDetails.Bx,
                    polypectomy: widget.gsfDetails.polypectomy,
                    emergency: !widget.gsfDetails.emergency,
                    CLO: widget.gsfDetails.CLO,
                    CLOResult: widget.gsfDetails.CLOResult,
                    PEG: widget.gsfDetails.PEG,
                    stoolOB: widget.gsfDetails.stoolOB,
                  );
                  widget.onGsfDetailsChanged(updatedDetails);
                },
                child: Text('응급'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.gsfDetails.PEG ?? false
                          ? Colors.blueAccent
                          : Colors.grey[300],
                  foregroundColor:
                      widget.gsfDetails.PEG ?? false
                          ? Colors.white
                          : Colors.grey[600],
                ),
                onPressed: () {
                  final updatedDetails = ExaminationDetails(
                    Bx: widget.gsfDetails.Bx,
                    polypectomy: widget.gsfDetails.polypectomy,
                    emergency: widget.gsfDetails.emergency,
                    CLO: widget.gsfDetails.CLO,
                    CLOResult: widget.gsfDetails.CLOResult,
                    PEG: !(widget.gsfDetails.PEG ?? false),
                    stoolOB: widget.gsfDetails.stoolOB,
                  );
                  widget.onGsfDetailsChanged(updatedDetails);
                },
                child: Text('PEG'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
