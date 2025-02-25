// patient_provider.dart
import 'package:flutter/foundation.dart';
import '../data_class/patient_exam.dart'; // 환자 데이터 모델 import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class PatientProvider extends ChangeNotifier {
  Patient? _patient;
  int _numberOfExams = 0;

  Patient? get patient => _patient;
  int get numberOfExams => _numberOfExams;

  void setPatient(Patient? patient) {
    _patient = patient;
    notifyListeners();
  }

  void setNumberOfExams(int count) {
    _numberOfExams = count;
    notifyListeners();
  }

  Future<void> refreshExamCount() async {
    await countTodayExam();
    notifyListeners();
  }

  Future<void> countTodayExam() async {
    DateTime today = DateTime.now();
    String formattedToday = DateFormat('yyyy-MM-dd').format(today);

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('examDate', isEqualTo: formattedToday)
        .get();

    int count = querySnapshot.docs
        .where((doc) => doc['name'] != '기기세척')
        .length;

    _numberOfExams = count;
  }
}
