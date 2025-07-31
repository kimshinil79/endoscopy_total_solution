import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:collection';
import '../widgets/settings/doctor_editor.dart';
import '../widgets/settings/room_editor.dart';
import '../widgets/settings/washing_machine_editor.dart';
import '../widgets/settings/disinfectant_editor.dart';
import '../widgets/settings/scope_editor.dart';
import '../widgets/settings/washing_room_people_editor.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _finalUploadFromJson(BuildContext context) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/patients(29).json',
      );
      final List<dynamic> patientsJson = json.decode(jsonString);
      await Firebase.initializeApp();
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      for (var patientData in patientsJson) {
        final patient = _convertToPatientImproved(patientData);
        await firestore
            .collection('patients')
            .doc(patient.uniqueDocName)
            .set(patient.toMap());
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('새로운 환자 데이터가 성공적으로 업로드되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  Patient _convertToPatient(Map<String, dynamic> data) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    String name = data['이름'] ?? '';
    String examDate = data['날짜'] ?? '';
    String uniqueId = data['id'] ?? '';
    String uniqueDocName = '${name}_${examDate}_${uniqueId}';
    DateTime birthday;
    try {
      birthday = DateFormat('yyyyMMdd').parse(data['생일'] ?? '');
    } catch (e) {
      birthday = DateTime.now();
    }
    DateTime parsedExamDate;
    try {
      parsedExamDate = dateFormat.parse(examDate);
    } catch (e) {
      parsedExamDate = DateTime.now();
    }
    return Patient(
      uniqueDocName: uniqueDocName,
      id: data['환자번호'] ?? '',
      name: name,
      gender: data['성별'] ?? '',
      age: int.tryParse(data['나이'] ?? '') ?? 0,
      Room: data['Room'] ?? '',
      birthday: birthday,
      doctor: data['의사'] ?? '',
      examDate: parsedExamDate,
      examTime: data['시간'] ?? '',
      GSF: _convertToEndoscopy(data, 'GSF'),
      CSF: _convertToEndoscopy(data, 'CSF'),
      sig: _convertToEndoscopy(data, 'sig'),
    );
  }

  Patient _convertToPatientImproved(Map<String, dynamic> data) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    String name = data['이름'] ?? '';
    String examDate = data['날짜'] ?? '';
    String uniqueId = data['id'] ?? '';
    String uniqueDocName = '${name}_${examDate}_${uniqueId}';
    DateTime birthday;
    try {
      birthday = DateFormat('yyyyMMdd').parse(data['생일'] ?? '');
    } catch (e) {
      birthday = DateTime.now();
    }
    DateTime parsedExamDate;
    try {
      parsedExamDate = dateFormat.parse(examDate);
    } catch (e) {
      parsedExamDate = DateTime.now();
    }
    return Patient(
      uniqueDocName: uniqueDocName,
      id: data['환자번호'] ?? '',
      name: name,
      gender: data['성별'] ?? '',
      age: int.tryParse(data['나이'] ?? '') ?? 0,
      Room: data['Room'] ?? '',
      birthday: birthday,
      doctor: data['의사'] ?? '',
      examDate: parsedExamDate,
      examTime: data['시간'] ?? '',
      GSF: _convertToEndoscopyImproved(data, 'GSF'),
      CSF: _convertToEndoscopyImproved(data, 'CSF'),
      sig: _convertToEndoscopyImproved(data, 'sig'),
    );
  }

  Endoscopy? _convertToEndoscopy(Map<String, dynamic> data, String type) {
    String gumjinOrNot = '';
    String sleepOrNot = '';
    Map<String, dynamic>? scopeData;
    switch (type) {
      case 'GSF':
        gumjinOrNot = data['위검진_외래'] ?? '';
        sleepOrNot = data['위수면_일반'] ?? '';
        scopeData = data['위내시경'];
        break;
      case 'CSF':
        gumjinOrNot = data['대장검진_외래'] ?? '';
        sleepOrNot = data['대장수면_일반'] ?? '';
        scopeData = data['대장내시경'];
        break;
      case 'sig':
        scopeData = data['sig'];
        break;
    }
    scopeData ??= {};
    return Endoscopy(
      gumjinOrNot: gumjinOrNot,
      sleepOrNot: sleepOrNot,
      scopes: _convertScopes(scopeData),
      examDetail: _convertExamDetails(data, type),
    );
  }

  Endoscopy? _convertToEndoscopyImproved(
    Map<String, dynamic> data,
    String type,
  ) {
    String gumjinOrNot = '';
    String sleepOrNot = '';
    Map<String, dynamic>? scopeData;
    switch (type) {
      case 'GSF':
        gumjinOrNot = data['위검진_외래'] ?? '';
        sleepOrNot = data['위수면_일반'] ?? '';
        scopeData = data['위내시경'];
        break;
      case 'CSF':
        gumjinOrNot = data['대장검진_외래'] ?? '';
        sleepOrNot = data['대장수면_일반'] ?? '';
        scopeData = data['대장내시경'];
        break;
      case 'sig':
        scopeData = data['sig'];
        break;
    }
    if (scopeData == null || scopeData.isEmpty) {
      return null;
    }
    return Endoscopy(
      gumjinOrNot: gumjinOrNot,
      sleepOrNot: sleepOrNot,
      scopes: _convertScopesImproved(scopeData),
      examDetail: _convertExamDetailsImproved(data, type),
    );
  }

  Map<String, Map<String, String>> _convertScopes(
    Map<String, dynamic> scopeData,
  ) {
    return scopeData.map((key, value) {
      if (value is Map) {
        return MapEntry(
          key,
          Map<String, String>.from(
            value.map((k, v) => MapEntry(k, v.toString())),
          ),
        );
      } else {
        return MapEntry(key, <String, String>{});
      }
    });
  }

  Map<String, Map<String, String>> _convertScopesImproved(
    Map<String, dynamic> scopeData,
  ) {
    return scopeData.map((key, value) {
      if (value is Map) {
        return MapEntry(
          key,
          Map<String, String>.from(
            value.map((k, v) {
              if (k == '세척시간' && v is String && v.contains(' ')) {
                return MapEntry('washingTime', v.split(' ')[1]);
              } else if (k == '세척기계') {
                return MapEntry('washingMachine', v.toString());
              } else {
                return MapEntry(k, v.toString());
              }
            }),
          ),
        );
      } else {
        return MapEntry(key, <String, String>{});
      }
    });
  }

  ExaminationDetails _convertExamDetails(
    Map<String, dynamic> data,
    String type,
  ) {
    String bx = '';
    String polypectomy = '';
    bool emergency = false;
    bool? clo;
    bool? peg;
    switch (type) {
      case 'GSF':
        bx = data['위조직'] ?? '';
        polypectomy = data['위절제술'] ?? '';
        emergency = data['위응급'] ?? false;
        clo = data['CLO'];
        peg = data['PEG'];
        break;
      case 'CSF':
        bx = data['대장조직'] ?? '';
        polypectomy = data['대장절제술'] ?? '';
        emergency = data['대장응급'] ?? false;
        break;
      case 'sig':
        bx = data['sig조직'] ?? '';
        polypectomy = data['sig절제술'] ?? '';
        emergency = data['sig응급'] ?? false;
        break;
    }
    return ExaminationDetails(
      Bx: bx,
      polypectomy: polypectomy,
      emergency: emergency,
      CLO: clo,
      PEG: peg,
    );
  }

  ExaminationDetails _convertExamDetailsImproved(
    Map<String, dynamic> data,
    String type,
  ) {
    String bx = '';
    String polypectomy = '';
    bool emergency = false;
    bool? clo;
    bool? peg;
    switch (type) {
      case 'GSF':
        bx = data['위조직'] ?? '';
        polypectomy = data['위절제술'] ?? '';
        emergency = data['위응급'] ?? false;
        clo = data['CLO'];
        peg = data['PEG'];
        break;
      case 'CSF':
        bx = data['대장조직'] ?? '';
        polypectomy = data['대장절제술'] ?? '';
        emergency = data['대장응급'] ?? false;
        break;
      case 'sig':
        bx = data['sig조직'] ?? '';
        polypectomy = data['sig절제술'] ?? '';
        emergency = data['sig응급'] ?? false;
        break;
    }
    bx = bx == '0' ? '없음' : bx;
    polypectomy = polypectomy == '0' ? '없음' : polypectomy;
    return ExaminationDetails(
      Bx: bx,
      polypectomy: polypectomy,
      emergency: emergency,
      CLO: clo,
      PEG: peg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.logout, size: 18),
            label: Text('로그아웃'),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: TextButton.styleFrom(foregroundColor: Color(0xFF5C6BC0)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      '의사 명단',
                      Icons.people,
                      Colors.blue,
                      () {
                        DoctorEditor.showDoctorList(context);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      '소독 실무자',
                      Icons.shower_outlined,
                      Colors.green,
                      () {
                        WashingRoomPeopleEditor.showWashingRoomPeopleList(
                          context,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      '검사실',
                      Icons.meeting_room,
                      Colors.orange,
                      () {
                        RoomEditor.showRoomList(context);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      '세척기',
                      Icons.local_laundry_service_outlined,
                      Colors.purple,
                      () {
                        WashingMachineEditor.showWashingMachineList(context);
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      'Gastroscopy',
                      Icons.gesture,
                      Colors.red,
                      () {
                        ScopeEditor.showScopeList(context, 'gsf');
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      'Colonoscopy',
                      Icons.gesture,
                      Colors.teal,
                      () {
                        ScopeEditor.showScopeList(context, 'csf');
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      'Sigmoidoscopy',
                      Icons.gesture,
                      Colors.indigo,
                      () {
                        ScopeEditor.showScopeList(context, 'sig');
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      '소독액',
                      Icons.sanitizer,
                      Colors.brown,
                      () {
                        DisinfectantEditor.showDisinfectantList(context);
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildSettingsCard(
                      context,
                      '힘 내             ',
                      Icons.favorite,
                      Colors.pink,
                      () {
                        _showEncouragingCommentsDialog(context);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showEncouragingCommentsDialog(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    TextEditingController newCommentController = TextEditingController();

    // Firebase에서 최신 데이터 로드
    await settingsProvider.loadSettings();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(20),
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
                      '격려 멘트 관리',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),
                    Flexible(
                      child: Consumer<SettingsProvider>(
                        builder: (context, provider, child) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: provider.encouragingComments.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: Text(
                                    provider.encouragingComments[index],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => _editEncouragingComment(
                                              context,
                                              index,
                                              provider
                                                  .encouragingComments[index],
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteEncouragingComment(
                                              context,
                                              index,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: newCommentController,
                      decoration: InputDecoration(
                        labelText: "새로운 격려 멘트",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () async {
                            if (newCommentController.text.isNotEmpty) {
                              try {
                                await settingsProvider.addEncouragingComment(
                                  newCommentController.text,
                                );
                                newCommentController.clear();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('격려 멘트 추가 중 오류가 발생했습니다.'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('닫기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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

  void _editEncouragingComment(
    BuildContext context,
    int index,
    String currentComment,
  ) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    TextEditingController controller = TextEditingController(
      text: currentComment,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
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
                  '격려 멘트 수정',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "격려 멘트",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('취소'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          try {
                            await settingsProvider.updateEncouragingComment(
                              index,
                              controller.text,
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('격려 멘트 수정 중 오류가 발생했습니다.')),
                            );
                          }
                        }
                      },
                      child: Text('확인'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
  }

  void _deleteEncouragingComment(BuildContext context, int index) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final commentToDelete = settingsProvider.encouragingComments[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
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
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 50,
                ),
                SizedBox(height: 16),
                Text(
                  '격려 멘트 삭제',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    commentToDelete,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '이 격려 멘트를 삭제하시겠습니까?',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('취소'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await settingsProvider.deleteEncouragingComment(
                            index,
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('격려 멘트 삭제 중 오류가 발생했습니다.')),
                          );
                        }
                      },
                      child: Text('삭제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
  }
}

Widget _buildSettingsCard(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    margin: EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            SizedBox(width: 20),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class Patient {
  String uniqueDocName;
  String id;
  String name;
  String gender;
  int age;
  String Room;
  DateTime birthday;
  String doctor;
  DateTime examDate;
  String examTime;
  Endoscopy? GSF;
  Endoscopy? CSF;
  Endoscopy? sig;

  Patient({
    required this.uniqueDocName,
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.Room,
    required this.birthday,
    required this.doctor,
    required this.examDate,
    required this.examTime,
    this.GSF,
    this.CSF,
    this.sig,
  });

  Map<String, dynamic> toMap() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return {
      'uniqueDocName': uniqueDocName,
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'Room': Room,
      'birthday': dateFormat.format(birthday),
      'doctor': doctor,
      'examDate': dateFormat.format(examDate),
      'examTime': examTime,
      'GSF': GSF?.toMap(),
      'CSF': CSF?.toMap(),
      'sig': sig?.toMap(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      uniqueDocName: map['uniqueDocName'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      Room: map['Room'] ?? '',
      birthday:
          map['birthday'] != null
              ? DateTime.parse(map['birthday'])
              : DateTime.now(),
      doctor: map['doctor'] ?? '',
      examDate:
          map['examDate'] != null
              ? DateTime.parse(map['examDate'])
              : DateTime.now(),
      examTime: map['examTime'] ?? '',
      GSF: map['GSF'] != null ? Endoscopy.fromMap(map['GSF']) : null,
      CSF: map['CSF'] != null ? Endoscopy.fromMap(map['CSF']) : null,
      sig: map['sig'] != null ? Endoscopy.fromMap(map['sig']) : null,
    );
  }
}

class Endoscopy {
  String gumjinOrNot;
  String sleepOrNot;
  Map<String, Map<String, String>> scopes;
  ExaminationDetails examDetail;

  Endoscopy({
    required this.gumjinOrNot,
    required this.sleepOrNot,
    required this.scopes,
    required this.examDetail,
  });

  factory Endoscopy.fromMap(Map<String, dynamic> map) {
    return Endoscopy(
      gumjinOrNot: map['gumjinOrNot'] as String,
      sleepOrNot: map['sleepOrNot'] as String,
      scopes: (map['scopes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
      ),
      examDetail: ExaminationDetails.fromMap(
        map['examDetail'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gumjinOrNot': gumjinOrNot,
      'sleepOrNot': sleepOrNot,
      'scopes': scopes,
      'examDetail': examDetail.toMap(),
    };
  }
}

class ExaminationDetails {
  String Bx;
  String polypectomy;
  bool emergency;
  bool? CLO;
  bool? PEG;

  ExaminationDetails({
    required this.Bx,
    required this.polypectomy,
    required this.emergency,
    this.CLO,
    this.PEG,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'Bx': Bx,
      'polypectomy': polypectomy,
      'emergency': emergency,
    };
    if (CLO != null) {
      data['CLO'] = CLO;
    }
    if (PEG != null) {
      data['PEG'] = PEG;
    }
    return data;
  }

  factory ExaminationDetails.fromMap(Map<String, dynamic> map) {
    return ExaminationDetails(
      Bx: map['Bx'] ?? '',
      polypectomy: map['polypectomy'] ?? '',
      emergency: map['emergency'] ?? false,
      CLO: map['CLO'],
      PEG: map['PEG'],
    );
  }
}
