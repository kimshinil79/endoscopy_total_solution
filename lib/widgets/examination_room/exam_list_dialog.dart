import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data_class/patient_exam.dart';
import '../../provider/patient_provider.dart';

class ExamListDialog {
  static void show(
    BuildContext context,
    DateTime initialDate,
    Future<List<Patient>> Function(DateTime) fetchPatientsByDate,
    PatientProvider? patientProvider,
    Function(BuildContext, Patient, DateTime) onEditPatient,
    Function(BuildContext, Patient, DateTime) onDeletePatient,
    Future<Map<String, dynamic>> Function() loadPreferences,
  ) async {
    DateTime currentDate = initialDate;

    Future<void> updatePatientList() async {
      List<Patient> patients = await fetchPatientsByDate(currentDate);
      List<Patient> emptyMachinesPatients =
          patients.where((p) {
            bool isEmpty = false;
            if (p.GSF != null && p.GSF!.scopes.isEmpty) isEmpty = true;
            if (p.CSF != null && p.CSF!.scopes.isEmpty) isEmpty = true;
            if (p.sig != null && p.sig!.scopes.isEmpty) isEmpty = true;
            return isEmpty;
          }).toList();
      List<Patient> filledMachinesPatients =
          patients.where((p) {
            bool isFilled = false;
            if (p.GSF != null && p.GSF!.scopes.isNotEmpty && p.name != '기기세척')
              isFilled = true;
            if (p.CSF != null && p.CSF!.scopes.isNotEmpty && p.name != '기기세척')
              isFilled = true;
            if (p.sig != null && p.sig!.scopes.isNotEmpty && p.name != '기기세척')
              isFilled = true;
            return isFilled;
          }).toList();

      int totalPatients =
          emptyMachinesPatients.length + filledMachinesPatients.length;

      // 동적 높이 계산
      double calculateDialogHeight() {
        double baseHeight = 200.0; // 기본 높이 (헤더, 버튼 등)
        double patientCardHeight = 120.0; // 각 환자 카드의 높이
        double maxHeight =
            MediaQuery.of(context).size.height * 0.95; // 최대 높이 (화면의 95%)

        double calculatedHeight =
            baseHeight +
            (emptyMachinesPatients.length * patientCardHeight) +
            (filledMachinesPatients.length * patientCardHeight);

        return calculatedHeight > maxHeight ? maxHeight : calculatedHeight;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  height: calculateDialogHeight(),
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
                          Text(
                            '검사 리스트(${totalPatients}명)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('yy/MM/dd').format(currentDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: currentDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    locale: const Locale('ko', 'KR'),
                                  );
                                  if (picked != null && picked != currentDate) {
                                    setState(() {
                                      currentDate = picked;
                                    });
                                    Navigator.of(context).pop();
                                    updatePatientList();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (emptyMachinesPatients.isNotEmpty)
                                GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  childAspectRatio: 0.7,
                                  children:
                                      emptyMachinesPatients
                                          .map(
                                            (patient) => _buildPatientCard(
                                              context,
                                              patient,
                                              currentDate,
                                              Colors.blueAccent[100]!,
                                              true,
                                              patientProvider,
                                              onEditPatient,
                                              onDeletePatient,
                                              loadPreferences,
                                            ),
                                          )
                                          .toList(),
                                ),
                              if (emptyMachinesPatients.isNotEmpty &&
                                  filledMachinesPatients.isNotEmpty)
                                Divider(),
                              ...filledMachinesPatients.map(
                                (patient) => _buildPatientCard(
                                  context,
                                  patient,
                                  currentDate,
                                  Colors.white30!,
                                  false,
                                  patientProvider,
                                  onEditPatient,
                                  onDeletePatient,
                                  loadPreferences,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

    updatePatientList();
  }

  static String _truncateName(String name, int maxLength) {
    if (name.length <= 4) {
      // 4글자 이하면 그대로 반환
      return name;
    }
    return '${name.substring(0, 4)}...'; // 4글자 초과시 4글자 + ... 처리
  }

  static Widget _buildPatientCard(
    BuildContext context,
    Patient patient,
    DateTime date,
    Color backgroundColor,
    bool isEmptyMachine,
    PatientProvider? patientProvider,
    Function(BuildContext, Patient, DateTime) onEditPatient,
    Function(BuildContext, Patient, DateTime) onDeletePatient,
    Future<Map<String, dynamic>> Function() loadPreferences,
  ) {
    if (isEmptyMachine) {
      String truncatedName = _truncateName(patient.name, 4);
      String doctorInfo =
          patient.doctor != null && patient.doctor != '의사'
              ? 'by ${patient.doctor}'
              : '';

      return Card(
        elevation: 3,
        margin: EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          onTap: () {
            _handleCardTap(context, patient, patientProvider, loadPreferences);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.blue.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 3.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          truncatedName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          patient.id,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          '${patient.gender}/${patient.age}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (doctorInfo.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Text(
                              doctorInfo,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[300],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.blue[600],
                          size: 12,
                        ),
                        onPressed: () => onEditPatient(context, patient, date),
                        padding: EdgeInsets.only(right: -10),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[300],
                          size: 12,
                        ),
                        onPressed:
                            () => onDeletePatient(context, patient, date),
                        padding: EdgeInsets.only(left: -10),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      String doctorInfo =
          patient.doctor != null && patient.doctor != '의사'
              ? 'by ${patient.doctor}'
              : '';

      return Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _handleCardTap(
                context,
                patient,
                patientProvider,
                loadPreferences,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              _truncateName(patient.name, 4),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue[700],
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              patient.id,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${patient.gender}/${patient.age}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (doctorInfo.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          doctorInfo,
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: Colors.blue[600],
                                size: 14,
                              ),
                              onPressed:
                                  () => onEditPatient(context, patient, date),
                              padding: EdgeInsets.only(right: -4),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                                size: 14,
                              ),
                              onPressed:
                                  () => onDeletePatient(context, patient, date),
                              padding: EdgeInsets.only(left: -4),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8),
                  Text(
                    _buildSubtitle(patient),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  static void _handleCardTap(
    BuildContext context,
    Patient patient,
    PatientProvider? patientProvider,
    Future<Map<String, dynamic>> Function() loadPreferences,
  ) async {
    print('Handling card tap for patient: ${patient.name}');
    print('Patient provider is null: ${patientProvider == null}');

    try {
      final prefs = await loadPreferences();

      if (!context.mounted) {
        print('Context is not mounted');
        return;
      }

      if (patient.Room == null ||
          patient.Room == '검사실' ||
          patient.doctor == null ||
          patient.doctor == '의사') {
        patient.Room = prefs['room'] ?? '검사실';
        patient.doctor = prefs['doctor'] ?? '의사';
      }

      patientProvider?.setPatient(patient);
      Navigator.of(context).pop();
    } catch (error) {
      print('Error in _handleCardTap: $error');
    }
  }

  static String _buildSubtitle(Patient patient) {
    StringBuffer subtitle = StringBuffer();

    if (patient.GSF != null) {
      subtitle.write(
        '위(${patient.GSF!.gumjinOrNot}, ${patient.GSF!.sleepOrNot}',
      );
      if (patient.GSF!.scopes.isNotEmpty) {
        subtitle.write(', ${patient.GSF!.scopes.keys.join(', ')}');
      }
      if (patient.GSF!.examDetail.Bx != '없음') {
        subtitle.write(', Bx:${patient.GSF!.examDetail.Bx}');
      }
      if (patient.GSF!.examDetail.CLO == true) {
        subtitle.write(', CLO');
      }
      subtitle.write(')');
    }

    if (patient.CSF != null) {
      if (subtitle.isNotEmpty) subtitle.write('\n');
      subtitle.write(
        '대장(${patient.CSF!.gumjinOrNot}, ${patient.CSF!.sleepOrNot}',
      );
      if (patient.CSF!.scopes.isNotEmpty) {
        subtitle.write(', ${patient.CSF!.scopes.keys.join(', ')}');
      }
      if (patient.CSF!.examDetail.Bx != '없음') {
        subtitle.write(', Bx:${patient.CSF!.examDetail.Bx}');
      }
      if (patient.CSF!.examDetail.polypectomy != '없음') {
        subtitle.write(', polypectomy:${patient.CSF!.examDetail.polypectomy}');
      }
      subtitle.write(')');
    }

    if (patient.sig != null) {
      if (subtitle.isNotEmpty) subtitle.write('\n');
      subtitle.write('sig(');
      if (patient.sig!.examDetail.Bx != '없음') {
        subtitle.write('Bx:${patient.sig!.examDetail.Bx}');
      }
      if (patient.sig!.examDetail.polypectomy != '없음') {
        if (subtitle.isNotEmpty && !subtitle.toString().endsWith('(')) {
          subtitle.write(', ');
        }
        subtitle.write('polypectomy:${patient.sig!.examDetail.polypectomy}');
      }
      subtitle.write(')');
    }

    return subtitle.toString();
  }
}
