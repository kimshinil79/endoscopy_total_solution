import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data_class/patient_exam.dart';
import 'patient_card_CLOResult.dart';
import '../../provider/patient_provider.dart';

class CLOPatientListDialog {
  static void show(
    BuildContext context,
    List<Patient> patients,
    DateTimeRange dateRange,
    Function(DateTimeRange) onDateRangeChanged,
    PatientProvider? patientProvider,
  ) {
    int patientCount = patients.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'CLO 결과 미입력자',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[400],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$patientCount명',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        onTap: () async {
                          final DateTimeRange? picked =
                              await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                                initialDateRange: dateRange,
                              );
                          if (picked != null && picked != dateRange) {
                            onDateRangeChanged(picked);
                            List<Patient> newPatients = await fetchCLOPatients(
                              picked,
                            );
                            setState(() {
                              patients = newPatients;
                              patientCount = patients.length;
                            });
                          }
                        },
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.blue[400],
                        ),
                        title: Text(
                          '검색 기간',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('yyyy-MM-dd').format(dateRange.start)} ~ ${DateFormat('yyyy-MM-dd').format(dateRange.end)}',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child:
                            patients.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green[400],
                                        size: 48,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'CLO 결과 미입력자가 없습니다',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: patients.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: PatientCard(
                                        key: ValueKey(
                                          patients[index].uniqueDocName,
                                        ),
                                        patient: patients[index],
                                        onSave: (
                                          patient,
                                          result,
                                          resetState,
                                        ) async {
                                          await _saveCLOResult(
                                            context,
                                            patient,
                                            result,
                                          );
                                          if (result == '+' || result == '-') {
                                            setState(() {
                                              patients.removeAt(index);
                                              patientCount = patients.length;
                                            });
                                          } else {
                                            resetState();
                                          }
                                        },
                                        onPatientSelect: (selectedPatient) {
                                          patientProvider?.setPatient(
                                            selectedPatient,
                                          );
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            '닫기',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<List<Patient>> fetchCLOPatients(DateTimeRange dateRange) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .where(
                'examDate',
                isGreaterThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(dateRange.start),
              )
              .where(
                'examDate',
                isLessThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(dateRange.end),
              )
              .get();

      List<Patient> cloPatients =
          querySnapshot.docs
              .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
              .where(
                (patient) =>
                    patient.GSF != null &&
                    patient.GSF!.examDetail.CLO == true &&
                    (patient.GSF!.examDetail.CLOResult == null ||
                        patient.GSF!.examDetail.CLOResult?.isEmpty != false),
              )
              .toList();

      print('Found ${cloPatients.length} CLO patients'); // 디버깅을 위한 로그

      return cloPatients;
    } catch (e) {
      print('Error fetching CLO patients: $e'); // 에러 로깅
      return [];
    }
  }

  static Future<void> _saveCLOResult(
    BuildContext context,
    Patient patient,
    String result,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patient.uniqueDocName)
          .update({'GSF.examDetail.CLOResult': result});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CLO 결과가 성공적으로 저장되었습니다.')));
    } catch (e) {
      print('Error saving CLO result: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CLO 결과 저장 중 오류가 발생했습니다.')));
    }
  }
}
