import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data_class/patient_exam.dart';

class PatientCard extends StatefulWidget {
  final Patient patient;
  final Function(Patient, String, Function()) onSave;
  final Function(Patient) onPatientSelect;

  PatientCard({
    required Key key,
    required this.patient,
    required this.onSave,
    required this.onPatientSelect,
  }) : super(key: key);

  @override
  _PatientCardState createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  late String selectedResult;

  @override
  void initState() {
    super.initState();
    selectedResult = '';
  }

  String _truncateName(String name) {
    if (name.length <= 4) {
      return name;
    }
    return name.substring(0, 3) + '...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 환자 정보 섹션
          GestureDetector(
            onTap: () => widget.onPatientSelect(widget.patient),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_truncateName(widget.patient.name)} (${widget.patient.id})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue[900],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.patient.gender}/${widget.patient.age}세',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'yy년MM월dd일',
                          ).format(widget.patient.examDate),
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // CLO 결과 선택 섹션
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'CLO 결과 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultButton(
                      '양성',
                      '+',
                      Colors.red[400]!,
                      Icons.add_circle_outline,
                    ),
                    _buildResultButton(
                      '음성',
                      '-',
                      Colors.green[400]!,
                      Icons.remove_circle_outline,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        selectedResult.isEmpty
                            ? null
                            : () {
                              widget.onSave(widget.patient, selectedResult, () {
                                setState(() {
                                  selectedResult = '';
                                });
                              });
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedResult.isEmpty
                              ? Colors.grey[300]
                              : Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultButton(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    bool isSelected = selectedResult == value;
    return Container(
      width: 120,
      child: ElevatedButton(
        onPressed: () => setState(() => selectedResult = value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[100],
          foregroundColor: isSelected ? Colors.white : Colors.grey[600],
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? color : Colors.grey[300]!,
              width: 1,
            ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
