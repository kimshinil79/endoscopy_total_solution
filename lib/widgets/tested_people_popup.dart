import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data_class/patient_exam.dart';

class TestedPeoplePopup {
  static Future<void> show(
    BuildContext context,
    DateTime? selectedDate,
    Function(Map<String, dynamic>, String, String) onPatientSelected,
  ) async {
    final String dateKey =
        selectedDate == null
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : DateFormat('yyyy-MM-dd').format(selectedDate);

    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('examDate', isEqualTo: dateKey)
        .get(GetOptions(source: Source.server));

    List<Map<String, dynamic>> people =
        querySnapshot.docs
            .map((doc) {
              String name = doc['name'];
              if (name == '기기세척') return null;

              List<Map<String, dynamic>> exams = [];

              void addExams(String type, Map<String, dynamic>? examData) {
                if (examData != null && examData['scopes'] != null) {
                  Map<String, dynamic> scopesMap =
                      examData['scopes'] as Map<String, dynamic>;
                  scopesMap.forEach((key, value) {
                    exams.add({
                      'type': type,
                      'scope': key,
                      'washingMachine': value['washingMachine'] ?? '',
                    });
                  });
                }
              }

              addExams('위', doc['GSF']);
              addExams('대장', doc['CSF']);
              addExams('S상', doc['sig']);

              if (exams.isEmpty) return null;

              return {
                'name': name,
                'id': doc['id'],
                'gender': doc['gender'],
                'age': doc['age'],
                'examTime': doc['examTime'],
                'exams': exams,
                'uniqueDocName': doc['uniqueDocName'],
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();

    final List<Map<String, dynamic>> nullWashingMachinePeople =
        people.where((person) {
          return person['exams'].any((exam) => exam['washingMachine'] == '');
        }).toList();

    final List<Map<String, dynamic>> notNullWashingMachinePeople =
        people.where((person) {
          return person['exams'].every((exam) => exam['washingMachine'] != '');
        }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '검사 받은 사람 목록',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                Flexible(
                  child:
                      people.isEmpty
                          ? Center(child: Text('해당 날짜에 검사받은 사람이 없습니다.'))
                          : ListView(
                            shrinkWrap: true,
                            children: [
                              ...nullWashingMachinePeople.map(
                                (person) => _buildPersonTile(
                                  context,
                                  person,
                                  onPatientSelected,
                                ),
                              ),
                              if (nullWashingMachinePeople.isNotEmpty &&
                                  notNullWashingMachinePeople.isNotEmpty)
                                Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                ),
                              ...notNullWashingMachinePeople.map(
                                (person) => _buildPersonTile(
                                  context,
                                  person,
                                  onPatientSelected,
                                ),
                              ),
                            ],
                          ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('닫기', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPersonTile(
    BuildContext context,
    Map<String, dynamic> person,
    Function(Map<String, dynamic>, String, String) onPatientSelected,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${person['name']} (${person['id']}) ${person['gender']}/${person['age']}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              '검사 시간: ${person['examTime']}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  person['exams'].map<Widget>((exam) {
                    final bool hasWashingMachine = exam['washingMachine'] != '';
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasWashingMachine
                                ? Colors.green.shade100
                                : Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        onPatientSelected(
                          person,
                          person['name'],
                          '${exam['type']} ${exam['scope']}',
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '${exam['type']} ${exam['scope']}',
                        style: TextStyle(
                          color: hasWashingMachine ? Colors.black : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
