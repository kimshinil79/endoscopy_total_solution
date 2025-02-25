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
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => widget.onPatientSelect(widget.patient),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                              ),
                              Icon(Icons.edit, size: 20, color: Colors.grey),
                            ],
                          ),
                          Text(
                              '${widget.patient.gender}/${widget.patient.age}세 ${DateFormat('yy년MM월dd일').format(widget.patient.examDate)}',
                              style: TextStyle(color: Colors.grey[600])
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text('양성'),
                  onPressed: () => setState(() => selectedResult = '+'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedResult == '+' ? Colors.redAccent : Colors.grey[300],
                    foregroundColor: selectedResult == '+' ? Colors.white : Colors.black,
                    shape: CircleBorder(),
                  ),
                ),
                ElevatedButton(
                  child: Text('음성'),
                  onPressed: () => setState(() => selectedResult = '-'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedResult == '-' ? Colors.green : Colors.grey[300],
                    foregroundColor: selectedResult == '-' ? Colors.white : Colors.black,
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                child: Text('저장'),
                onPressed: () {
                  widget.onSave(widget.patient, selectedResult, () {
                    setState(() {
                      selectedResult = '';
                    });
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}