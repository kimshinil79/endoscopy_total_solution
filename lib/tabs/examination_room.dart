import 'package:flutter/material.dart';
import '../widgets/forms/GSF_form_widget.dart';
import '../widgets/forms/CSF_form_widget.dart';
import '../widgets/forms/Sig_form_widget.dart';
import '../data_class/patient_exam.dart';
import '../widgets/common/camera_screen.dart';
import '../provider/patient_provider.dart';
import '../provider/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';
import '../widgets/examination_room/patient_card_CLOResult.dart';
import '../widgets/examination_room/clo_patient_list_dialog.dart';
import '../widgets/examination_room/exam_list_dialog.dart';
import '../widgets/examination_room/doctor_selection_dialog.dart';
import '../widgets/examination_room/room_selection_dialog.dart';
//import '../widgets/text_form_examination_room.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import '../widgets/recording_button.dart';

class ExaminationRoom extends StatefulWidget {
  @override
  _ExaminationRoomState createState() => _ExaminationRoomState();
}

class _ExaminationRoomState extends State<ExaminationRoom>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _shortNameController = TextEditingController();
  final _fullNameController = TextEditingController();

  final TextEditingController patientIDController = TextEditingController();
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  String uniqueDocName = '';
  String id = '';
  String name = '';
  String gender = 'M';
  int age = 0;
  DateTime birthday = DateTime.now();
  DateTime selectedDate = DateTime.now();
  String selectedTime = DateFormat.Hm().format(DateTime.now());

  bool endoscopyChecked = true;
  bool colonoscopyChecked = false;
  bool sigmoidoscopyChecked = false;
  String selectedRoom = '검사실';
  String selectedDoctor = '의사';

  List<String> rooms = ['검사실', '1', '2', '3'];
  List<String> doctors = ['의사'];

  String gsfGumjinOrNot = '';
  String gsfSleepOrNot = '';

  String csfGumjinOrNot = '';
  String csfSleepOrNot = '';

  String sigGumjinOrNot = '외래';
  String sigSleepOrNot = '일반';

  ExaminationDetails gsfDetails = ExaminationDetails(
    Bx: '없음',
    polypectomy: '없음',
    emergency: false,
    CLO: false,
    PEG: false,
  );
  ExaminationDetails csfDetails = ExaminationDetails(
    Bx: '없음',
    polypectomy: '없음',
    emergency: false,
  );
  ExaminationDetails sigDetails = ExaminationDetails(
    Bx: '없음',
    polypectomy: '없음',
    emergency: false,
  );

  Map<String, Map<String, String>> selectedGsScopes = {};
  Map<String, Map<String, String>> selectedCsScopes = {};
  Map<String, Map<String, String>> selectedSigScopes = {};
  bool cloChecked = false;
  bool etcChecked = false;

  Map<String, String> GSFmachine = {
    '073': 'KG391K073',
    '153': '5G391K153',
    '180': '5G391K180',
    '256': '7G391K256',
    '257': '7G391K257',
    '259': '7G391K259',
    '333': '2G348K333',
    '390': '2G348K390',
    '405': '2G348K405',
    '407': '2G348K407',
    '694': '5G348K694',
  };

  Map<String, String> CSFmachine = {
    '039': '7C692K039',
    '098': '5C692K098',
    '166': '6C692K166',
    '219': '1C664K219',
    '379': '1C665K379',
    '515': '1C666K515',
  };

  Map<String, String> Sigmachine = {'219': '1C664K219', '694': '5G348K694'};

  bool gsfCancelled = false;
  bool csfCancelled = false;
  bool sigCancelled = false;

  PatientProvider? _patientProvider;
  late SettingsProvider _settingsProvider;

  bool _isAuthorizedUser = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked.format(context);
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _textFormInExamRoom(
    String title,
    TextInputType keyboardType,
    TextEditingController controller, {
    required void Function(String?) onSaved,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orangeAccent, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orangeAccent, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSaved: onSaved,
          ),
          if (controller.text.isEmpty)
            Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 7)),
    end: DateTime.now(),
  );

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _dateRange,
    );
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showCLOResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('CLO 결과 선택'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Text('양성'),
                onPressed: () {
                  setState(() {
                    gsfDetails = ExaminationDetails(
                      Bx: gsfDetails.Bx,
                      polypectomy: gsfDetails.polypectomy,
                      emergency: gsfDetails.emergency,
                      CLO: gsfDetails.CLO,
                      CLOResult: '+',
                      PEG: gsfDetails.PEG,
                      stoolOB: gsfDetails.stoolOB,
                    );
                  });
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('음성'),
                onPressed: () {
                  setState(() {
                    gsfDetails = ExaminationDetails(
                      Bx: gsfDetails.Bx,
                      polypectomy: gsfDetails.polypectomy,
                      emergency: gsfDetails.emergency,
                      CLO: gsfDetails.CLO,
                      CLOResult: '-',
                      PEG: gsfDetails.PEG,
                      stoolOB: gsfDetails.stoolOB,
                    );
                  });
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('미정'),
                onPressed: () {
                  setState(() {
                    gsfDetails = ExaminationDetails(
                      Bx: gsfDetails.Bx,
                      polypectomy: gsfDetails.polypectomy,
                      emergency: gsfDetails.emergency,
                      CLO: gsfDetails.CLO,
                      CLOResult: '',
                      PEG: gsfDetails.PEG,
                      stoolOB: gsfDetails.stoolOB,
                    );
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _patientProvider = Provider.of<PatientProvider>(context, listen: false);
      _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      _patientProvider?.addListener(_onPatientDataChange);
      _onPatientDataChange();
      _settingsProvider?.loadSettings();
      _patientProvider?.countTodayExam();
      _checkUserAuthorization();
    });
    _loadPreferences();
  }

  void _checkUserAuthorization() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == 'alienpro@naver.com') {
      setState(() {
        _isAuthorizedUser = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    countTodayExam();
  }

  @override
  void dispose() {
    _shortNameController.dispose();
    _fullNameController.dispose();
    _patientProvider?.removeListener(_onPatientDataChange);
    super.dispose();
  }

  Future<Map<String, String>> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String room = prefs.getString('selectedRoom') ?? '검사실';
    String doctor = prefs.getString('selectedDoctor') ?? '의사';

    // 이전 형식의 데이터를 새 형식으로 변환
    switch (room) {
      case '1번방':
        room = '1';
        break;
      case '2번방':
        room = '2';
        break;
      case '3번방':
        room = '3';
        break;
      default:
        room = rooms.contains(room) ? room : '검사실';
    }

    return {'room': room, 'doctor': doctor};
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedRoom', selectedRoom);
    prefs.setString('selectedDoctor', selectedDoctor);
  }

  void _onPatientDataChange() async {
    Patient? patient =
        Provider.of<PatientProvider>(context, listen: false).patient;
    if (patient != null) {
      Map<String, String> prefs = await _loadPreferences();

      setState(() {
        uniqueDocName = patient.uniqueDocName;
        id = patient.id;
        name = patient.name;
        gender = patient.gender;
        age = patient.age;
        birthday = patient.birthday;
        selectedDate = patient.examDate;
        selectedTime = patient.examTime;

        // Room과 doctor 정보 설정
        if (patient.Room == null || patient.Room == '검사실') {
          selectedRoom = prefs['room'] ?? '검사실';
        } else {
          selectedRoom = patient.Room!;
        }

        if (patient.doctor == null || patient.doctor == '의사') {
          selectedDoctor = prefs['doctor'] ?? '의사';
        } else {
          selectedDoctor = patient.doctor!;
        }

        patientIDController.text = patient.id;
        patientNameController.text = patient.name;
        genderController.text = patient.gender;
        ageController.text = patient.age.toString();
        birthdayController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(patient.birthday);

        // Update GSF form details
        if (patient.GSF != null) {
          endoscopyChecked = true;
          gsfGumjinOrNot = patient.GSF!.gumjinOrNot;
          gsfSleepOrNot = patient.GSF!.sleepOrNot;
          gsfDetails = patient.GSF!.examDetail;
          selectedGsScopes = patient.GSF!.scopes;
        } else {
          endoscopyChecked = false;
          gsfGumjinOrNot = '';
          gsfSleepOrNot = '';
          gsfDetails = ExaminationDetails(
            Bx: '없음',
            polypectomy: '없음',
            emergency: false,
            CLO: false,
            PEG: false,
          );
          selectedGsScopes = {};
        }

        // Update CSF form details
        if (patient.CSF != null) {
          colonoscopyChecked = true;
          csfGumjinOrNot = patient.CSF!.gumjinOrNot;
          csfSleepOrNot = patient.CSF!.sleepOrNot;
          csfDetails = patient.CSF!.examDetail;
          selectedCsScopes = patient.CSF!.scopes;
        } else {
          colonoscopyChecked = false;
          csfGumjinOrNot = '';
          csfSleepOrNot = '';
          csfDetails = ExaminationDetails(
            Bx: '없음',
            polypectomy: '없음',
            emergency: false,
          );
          selectedCsScopes = {};
        }

        // Update Sig form details
        if (patient.sig != null) {
          sigmoidoscopyChecked = true;
          sigGumjinOrNot = patient.sig!.gumjinOrNot;
          sigSleepOrNot = patient.sig!.sleepOrNot;
          sigDetails = patient.sig!.examDetail;
          selectedSigScopes = patient.sig!.scopes;
        } else {
          sigmoidoscopyChecked = false;
          sigGumjinOrNot = '외래';
          sigSleepOrNot = '일반';
          sigDetails = ExaminationDetails(
            Bx: '없음',
            polypectomy: '없음',
            emergency: false,
          );
          selectedSigScopes = {};
        }
      });
    }
  }

  void _addGSFScope(String shortName, String fullName) {
    setState(() {
      GSFmachine[shortName] = fullName;
    });
  }

  void _addCSFScope(String shortName, String fullName) {
    setState(() {
      CSFmachine[shortName] = fullName;
    });
  }

  void _addSigScope(String shortName, String fullName) {
    setState(() {
      Sigmachine[shortName] = fullName;
    });
  }

  bool _canShowSaveButton() {
    if (endoscopyChecked && selectedGsScopes.isEmpty) {
      return false;
    }
    if (colonoscopyChecked && selectedCsScopes.isEmpty) {
      return false;
    }
    if (sigmoidoscopyChecked && selectedSigScopes.isEmpty) {
      return false;
    }
    if (selectedRoom == '검사실' || selectedDoctor == '의사') {
      return false;
    }
    return true;
  }

  void countTodayExam() async {
    DateTime today = DateTime.now();
    String formattedToday = DateFormat('yyyy-MM-dd').format(today);

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .where('examDate', isEqualTo: formattedToday)
            .get();

    int count = querySnapshot.docs.where((doc) => doc['name'] != '기기세척').length;

    _patientProvider?.setNumberOfExams(count);
  }

  Future<List<Patient>> fetchTodayPatients() async {
    DateTime today = DateTime.now();
    String formattedToday = DateFormat('yyyy-MM-dd').format(today);

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .where('examDate', isEqualTo: formattedToday)
            .get();

    return querySnapshot.docs
        .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Patient>> fetchPatientsByDate(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .where('examDate', isEqualTo: formattedDate)
            .get();

    return querySnapshot.docs
        .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  void _resetForm() {
    setState(() {
      patientIDController.clear();
      patientNameController.clear();
      gender = 'M';
      ageController.clear();
      birthdayController.clear();
      selectedDate = DateTime.now();
      selectedTime = DateFormat.Hm().format(DateTime.now());
      endoscopyChecked = true;
      colonoscopyChecked = false;
      sigmoidoscopyChecked = false;
      selectedRoom = '검사실';
      selectedDoctor = '의사';
      gsfGumjinOrNot = '';
      gsfSleepOrNot = '';
      csfGumjinOrNot = '';
      csfSleepOrNot = '';
      sigGumjinOrNot = '외래';
      sigSleepOrNot = '일반';
      gsfDetails = ExaminationDetails(
        Bx: '없음',
        polypectomy: '없음',
        emergency: false,
        CLO: false,
        PEG: false,
      );
      csfDetails = ExaminationDetails(
        Bx: '없음',
        polypectomy: '없음',
        emergency: false,
      );
      sigDetails = ExaminationDetails(
        Bx: '없음',
        polypectomy: '없음',
        emergency: false,
      );
      selectedGsScopes.clear();
      selectedCsScopes.clear();
      selectedSigScopes.clear();
      etcChecked = false;
    });
    _patientProvider?.setPatient(null);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Patient patient,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red[400],
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '환자 삭제',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${patient.name} (${patient.id})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${patient.gender}/${patient.age}세',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  '정말 삭제하시겠습니까?',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('patients')
                            .doc(patient.uniqueDocName)
                            .delete();
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        ExamListDialog.show(
                          context,
                          date,
                          fetchPatientsByDate,
                          _patientProvider,
                          _showEditPatientPopup,
                          _showDeleteConfirmation,
                          _loadPreferences,
                        );
                        countTodayExam();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 16,
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
  }

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.Hm();
    return format.format(dt);
  }

  Future<void> _savePatientData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(uniqueDocName);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception("Patient document does not exist!");
        }

        final Map<String, dynamic> currentData =
            docSnapshot.data() as Map<String, dynamic>;

        // Update document name with new patient name
        final dateFormat = DateFormat('yyyyMMddHHmmss');
        final formattedDate = dateFormat.format(selectedDate);

        // Helper function to merge scopes
        Map<String, Map<String, String>> mergeScopes(
          Map<String, Map<String, String>> newScopes,
          Map<String, dynamic>? existingScopes,
        ) {
          Map<String, Map<String, String>> mergedScopes = {};
          newScopes.forEach((key, value) {
            mergedScopes[key] = {
              'washingMachine': '',
              'washingTime': '',
              'washingCharger': '',
              ...value,
            };
          });
          existingScopes?.forEach((key, value) {
            if (mergedScopes.containsKey(key)) {
              mergedScopes[key]!['washingMachine'] =
                  value['washingMachine'] ?? '';
              mergedScopes[key]!['washingTime'] = value['washingTime'] ?? '';
              mergedScopes[key]!['washingCharger'] =
                  value['washingCharger'] ?? '';
            }
          });
          return mergedScopes;
        }

        // Update GSF data
        if (endoscopyChecked) {
          currentData['GSF'] = {
            'gumjinOrNot': gsfGumjinOrNot,
            'sleepOrNot': gsfSleepOrNot,
            'scopes': mergeScopes(
              selectedGsScopes,
              currentData['GSF']?['scopes'],
            ),
            'examDetail': gsfDetails.toMap(),
          };
        }

        // Update CSF data
        if (colonoscopyChecked) {
          currentData['CSF'] = {
            'gumjinOrNot': csfGumjinOrNot,
            'sleepOrNot': csfSleepOrNot,
            'scopes': mergeScopes(
              selectedCsScopes,
              currentData['CSF']?['scopes'],
            ),
            'examDetail': csfDetails.toMap(),
          };
        }

        // Update sig data
        if (sigmoidoscopyChecked) {
          currentData['sig'] = {
            'gumjinOrNot': sigGumjinOrNot,
            'sleepOrNot': sigSleepOrNot,
            'scopes': mergeScopes(
              selectedSigScopes,
              currentData['sig']?['scopes'],
            ),
            'examDetail': sigDetails.toMap(),
          };
        }

        // Update basic information
        currentData['name'] = name;
        currentData['id'] = id;
        currentData['gender'] = gender;
        currentData['age'] = age;
        currentData['Room'] = selectedRoom;
        currentData['doctor'] = selectedDoctor;
        currentData['birthday'] = DateFormat('yyyy-MM-dd').format(birthday);
        currentData['examDate'] = DateFormat('yyyy-MM-dd').format(selectedDate);
        currentData['examTime'] = DateFormat.Hm().format(DateTime.now());

        transaction.update(docRef, currentData);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('환자 정보가 성공적으로 업데이트되었습니다!')));
      await _savePreferences(); // Add this line to save room and doctor preferences
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  void _onRoomChanged(String? newValue) {
    setState(() {
      selectedRoom = newValue!;
    });
  }

  void _onDoctorChanged(String? newValue) {
    setState(() {
      selectedDoctor = newValue!;
    });
  }

  Future<void> _editDateAndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          DateTime.parse(
            '${selectedDate.toIso8601String().split('T')[0]}T$selectedTime',
          ),
        ),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDate = pickedDate;
          selectedTime =
              '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  Future<void> _updateDateAndTimeInFirestore() async {
    if (uniqueDocName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(uniqueDocName)
          .update({
            'examDate': DateFormat('yyyy-MM-dd').format(selectedDate),
            'examTime': selectedTime,
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('날짜와 시간이 성공적으로 업데이트되었습니다!')));
    }
  }

  void _showCancelConfirmationDialog(
    String examType,
    bool isCancelled,
    Function(bool) onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[400],
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                '검사 취소 확인',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '여러가지 이유로 검사가 취소된 경우 선택하는 버튼입니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  '검사는 취소되었지만 내시경 세척 기록은 남겨야 하는 경우 선택합니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  '선택하시겠습니까?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                onConfirm(false);
                Navigator.of(context).pop();
              },
              child: Text(
                '아니오',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  onConfirm(true);
                  Navigator.of(context).pop();
                },
                child: Text(
                  '네',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  void _showEditPatientPopup(
    BuildContext context,
    Patient patient,
    DateTime date,
  ) {
    TextEditingController nameController = TextEditingController(
      text: patient.name,
    );
    TextEditingController idController = TextEditingController(
      text: patient.id,
    );
    String genderValue = patient.gender;
    DateTime birthdayValue = patient.birthday;

    // 검사 종류 체크박스 상태
    bool hasGSF = patient.GSF != null;
    bool hasCSF = patient.CSF != null;
    bool hasSig = patient.sig != null;

    // 위내시경 검진/외래 상태
    String gsfGumjinOrNotValue = hasGSF ? patient.GSF!.gumjinOrNot : '검진';
    String gsfSleepOrNotValue = hasGSF ? patient.GSF!.sleepOrNot : '수면';

    // 대장내시경 검진/외래 상태
    String csfGumjinOrNotValue = hasCSF ? patient.CSF!.gumjinOrNot : '검진';
    String csfSleepOrNotValue = hasCSF ? patient.CSF!.sleepOrNot : '수면';

    // S상결장경 검진/외래 상태
    String sigGumjinOrNotValue = hasSig ? patient.sig!.gumjinOrNot : '외래';
    String sigSleepOrNotValue = hasSig ? patient.sig!.sleepOrNot : '일반';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '환자 정보 편집',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[600]),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // 기본 정보 섹션
                      Text(
                        '기본 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      labelText: '이름',
                                      labelStyle: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: idController,
                                    decoration: InputDecoration(
                                      labelText: '등록번호',
                                      labelStyle: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                // Text(
                                //   '성별: ',
                                //   style: TextStyle(
                                //     fontSize: 16,
                                //     color: Colors.grey[700],
                                //   ),
                                // ),
                                // SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text('남'),
                                  selected: genderValue == 'M',
                                  onSelected: (selected) {
                                    setState(() {
                                      genderValue = 'M';
                                    });
                                  },
                                  selectedColor: Colors.blue[100],
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color:
                                        genderValue == 'M'
                                            ? Colors.blue[800]
                                            : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text('여'),
                                  selected: genderValue == 'F',
                                  onSelected: (selected) {
                                    setState(() {
                                      genderValue = 'F';
                                    });
                                  },
                                  selectedColor: Colors.blue[100],
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color:
                                        genderValue == 'F'
                                            ? Colors.blue[800]
                                            : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                ElevatedButton(
                                  onPressed: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: birthdayValue,
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime.now(),
                                          locale: const Locale('ko', 'KR'),
                                        );
                                    if (picked != null) {
                                      setState(() {
                                        birthdayValue = picked;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[50],
                                    foregroundColor: Colors.blue[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '생일: ${DateFormat('yy/MM/dd').format(birthdayValue)}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // 검사 종류 섹션
                      Text(
                        '검사 종류',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            // 위내시경 섹션
                            _buildExamSection(
                              '위내시경',
                              hasGSF,
                              (value) => setState(() => hasGSF = value!),
                              gsfGumjinOrNotValue,
                              (value) =>
                                  setState(() => gsfGumjinOrNotValue = value!),
                              gsfSleepOrNotValue,
                              (value) =>
                                  setState(() => gsfSleepOrNotValue = value!),
                            ),
                            Divider(height: 24),
                            // 대장내시경 섹션
                            _buildExamSection(
                              '대장내시경',
                              hasCSF,
                              (value) => setState(() => hasCSF = value!),
                              csfGumjinOrNotValue,
                              (value) =>
                                  setState(() => csfGumjinOrNotValue = value!),
                              csfSleepOrNotValue,
                              (value) =>
                                  setState(() => csfSleepOrNotValue = value!),
                            ),
                            Divider(height: 24),
                            // S상결장경 섹션
                            _buildExamSection(
                              'S상결장경',
                              hasSig,
                              (value) => setState(() => hasSig = value!),
                              sigGumjinOrNotValue,
                              (value) =>
                                  setState(() => sigGumjinOrNotValue = value!),
                              sigSleepOrNotValue,
                              (value) =>
                                  setState(() => sigSleepOrNotValue = value!),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // 버튼 섹션
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // 나이 계산
                              int age =
                                  DateTime.now().year - birthdayValue.year;
                              if (DateTime.now().month < birthdayValue.month ||
                                  (DateTime.now().month ==
                                          birthdayValue.month &&
                                      DateTime.now().day < birthdayValue.day)) {
                                age--;
                              }

                              // 데이터 수정
                              try {
                                final docRef = FirebaseFirestore.instance
                                    .collection('patients')
                                    .doc(patient.uniqueDocName);

                                await FirebaseFirestore.instance.runTransaction(
                                  (transaction) async {
                                    final docSnapshot = await transaction.get(
                                      docRef,
                                    );

                                    if (!docSnapshot.exists) {
                                      throw Exception(
                                        "Patient document does not exist!",
                                      );
                                    }

                                    // 기존 데이터 가져오기
                                    Map<String, dynamic> currentData =
                                        docSnapshot.data()
                                            as Map<String, dynamic>;

                                    // 기본 정보 업데이트
                                    Map<String, dynamic> updateData = {
                                      'name': nameController.text,
                                      'id': idController.text,
                                      'gender': genderValue,
                                      'birthday': DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(birthdayValue),
                                      'age': age,
                                    };

                                    // 위내시경 데이터 업데이트
                                    if (hasGSF) {
                                      Map<String, dynamic> gsfData =
                                          currentData['GSF']
                                              as Map<String, dynamic>? ??
                                          {};
                                      gsfData['gumjinOrNot'] =
                                          gsfGumjinOrNotValue;
                                      gsfData['sleepOrNot'] =
                                          gsfSleepOrNotValue;
                                      updateData['GSF'] = gsfData;
                                    } else {
                                      updateData['GSF'] = null;
                                    }

                                    // 대장내시경 데이터 업데이트
                                    if (hasCSF) {
                                      Map<String, dynamic> csfData =
                                          currentData['CSF']
                                              as Map<String, dynamic>? ??
                                          {};
                                      csfData['gumjinOrNot'] =
                                          csfGumjinOrNotValue;
                                      csfData['sleepOrNot'] =
                                          csfSleepOrNotValue;
                                      updateData['CSF'] = csfData;
                                    } else {
                                      updateData['CSF'] = null;
                                    }

                                    // S상결장경 데이터 업데이트
                                    if (hasSig) {
                                      Map<String, dynamic> sigData =
                                          currentData['sig']
                                              as Map<String, dynamic>? ??
                                          {};
                                      sigData['gumjinOrNot'] =
                                          sigGumjinOrNotValue;
                                      sigData['sleepOrNot'] =
                                          sigSleepOrNotValue;
                                      updateData['sig'] = sigData;
                                    } else {
                                      updateData['sig'] = null;
                                    }

                                    transaction.update(docRef, updateData);
                                  },
                                );

                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                ExamListDialog.show(
                                  context,
                                  date,
                                  fetchPatientsByDate,
                                  _patientProvider,
                                  _showEditPatientPopup,
                                  _showDeleteConfirmation,
                                  _loadPreferences,
                                );
                              } catch (e) {
                                print("Error updating patient: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('환자 정보 업데이트 중 오류가 발생했습니다.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '저장',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExamSection(
    String title,
    bool isChecked,
    Function(bool?) onChanged,
    String gumjinOrNotValue,
    Function(String?) onGumjinChanged,
    String sleepOrNotValue,
    Function(String?) onSleepChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isChecked ? Colors.blue[800] : Colors.grey[700],
            ),
          ),
          value: isChecked,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.blue[800],
        ),
        if (isChecked) ...[
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '검진/외래',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('검진'),
                      selected: gumjinOrNotValue == '검진',
                      onSelected: (selected) => onGumjinChanged('검진'),
                      selectedColor: Colors.blue[100],
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color:
                            gumjinOrNotValue == '검진'
                                ? Colors.blue[800]
                                : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('외래'),
                      selected: gumjinOrNotValue == '외래',
                      onSelected: (selected) => onGumjinChanged('외래'),
                      selectedColor: Colors.blue[100],
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color:
                            gumjinOrNotValue == '외래'
                                ? Colors.blue[800]
                                : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '수면/일반',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('수면'),
                      selected: sleepOrNotValue == '수면',
                      onSelected: (selected) => onSleepChanged('수면'),
                      selectedColor: Colors.blue[100],
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color:
                            sleepOrNotValue == '수면'
                                ? Colors.blue[800]
                                : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('일반'),
                      selected: sleepOrNotValue == '일반',
                      onSelected: (selected) => onSleepChanged('일반'),
                      selectedColor: Colors.blue[100],
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color:
                            sleepOrNotValue == '일반'
                                ? Colors.blue[800]
                                : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<PatientProvider, SettingsProvider>(
      builder: (context, patientProvider, settingProvider, child) {
        final patient = patientProvider.patient;
        final numberOfExams = patientProvider.numberOfExams;
        rooms = settingProvider.rooms;
        doctors = settingProvider.doctors;
        GSFmachine = Map<String, String>.from(settingProvider.gsfScopes);
        GSFmachine = SplayTreeMap.from(GSFmachine);
        CSFmachine = Map<String, String>.from(settingProvider.csfScopes);
        CSFmachine = SplayTreeMap.from(CSFmachine);
        Sigmachine = Map<String, String>.from(settingProvider.sigScopes);
        Sigmachine = SplayTreeMap.from(Sigmachine);

        if (patient != null && selectedRoom == '검사실') {
          selectedRoom = patient.Room ?? '검사실';
        }
        if (patient != null && selectedDoctor == '의사') {
          selectedDoctor = patient.doctor ?? '의사';
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(5.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _resetForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(
                                    color: Colors.redAccent,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                '초기화',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            //RecordingButton(),
                          ],
                        ),
                        Row(
                          // 나머지 버튼들을 Row로 감싸서 우측에 배치
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                List<Patient> cloPatients =
                                    await CLOPatientListDialog.fetchCLOPatients(
                                      _dateRange,
                                    );
                                CLOPatientListDialog.show(
                                  context,
                                  cloPatients,
                                  _dateRange,
                                  (DateTimeRange newRange) {
                                    setState(() {
                                      _dateRange = newRange;
                                    });
                                  },
                                  _patientProvider,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.redAccent,
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: CircleBorder(),
                              ),
                              child: Text('CLO'),
                            ),
                            Text('|'),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: () {
                                countTodayExam();
                              },
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ExamListDialog.show(
                                  context,
                                  DateTime.now(),
                                  fetchPatientsByDate,
                                  _patientProvider,
                                  _showEditPatientPopup,
                                  _showDeleteConfirmation,
                                  _loadPreferences,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                '${numberOfExams}명',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // SizedBox(height: 2),
                    Divider(),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _textFormInExamRoom(
                            '환자번호',
                            TextInputType.text,
                            patientIDController,
                            onSaved: (value) => id = value ?? "",
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _textFormInExamRoom(
                            '이름',
                            TextInputType.text,
                            patientNameController,
                            onSaved: (value) => name = value ?? "",
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Colors.orangeAccent,
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                gender = gender == 'M' ? 'F' : 'M';
                              });
                            },
                            child: Text(
                              gender == 'M' ? '남' : '여',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: 45, // 다른 폼 필드와 동일한 높이
                            child: ElevatedButton(
                              onPressed: _editDateAndTime,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Colors.orangeAccent,
                                    width: 1,
                                  ),
                                ),
                                backgroundColor: Colors.grey[50],
                                padding: EdgeInsets.zero, // 내부 패딩 제거
                              ),
                              child: Center(
                                // 텍스트를 중앙에 배치
                                child: Text(
                                  '${DateFormat('yy/MM/dd').format(selectedDate)} ${selectedTime}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _textFormInExamRoom(
                            '나이',
                            TextInputType.number,
                            ageController,
                            onSaved: (value) => age = int.parse(value ?? "0"),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _textFormInExamRoom(
                            '생일',
                            TextInputType.datetime,
                            birthdayController,
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                try {
                                  birthday = DateFormat(
                                    'yyyy-MM-dd',
                                  ).parse(value);
                                } catch (e) {
                                  // Handle invalid date format (optional)
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 추가
                      children: [
                        Container(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                endoscopyChecked = !endoscopyChecked;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  endoscopyChecked
                                      ? Colors.indigoAccent
                                      : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(
                                    endoscopyChecked ? 0 : 8,
                                  ),
                                  bottomRight: Radius.circular(
                                    endoscopyChecked ? 0 : 8,
                                  ),
                                ),
                                side: BorderSide(
                                  color:
                                      endoscopyChecked
                                          ? Colors.indigoAccent
                                          : Colors.grey[400]!,
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min, // 추가
                              children: [
                                Text(
                                  '위내시경',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color:
                                        endoscopyChecked
                                            ? Colors.white
                                            : Colors.grey[800],
                                  ),
                                ),
                                if (endoscopyChecked)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (gsfCancelled) {
                                          setState(() {
                                            gsfCancelled = false;
                                          });
                                        } else {
                                          _showCancelConfirmationDialog(
                                            '위내시경',
                                            gsfCancelled,
                                            (bool confirmed) {
                                              setState(() {
                                                gsfCancelled = confirmed;
                                              });
                                            },
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            gsfCancelled
                                                ? Colors.red
                                                : Colors.white,
                                        foregroundColor:
                                            gsfCancelled
                                                ? Colors.white
                                                : Colors.indigoAccent,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        minimumSize: Size(50, 25),
                                        textStyle: TextStyle(fontSize: 12),
                                        side: BorderSide(
                                          color:
                                              gsfCancelled
                                                  ? Colors.red
                                                  : Colors.indigoAccent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text('취소'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          // 드롭다운 버튼들을 Row로 감싸기
                          children: [
                            Container(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  RoomSelectionDialog.show(
                                    context,
                                    rooms,
                                    selectedRoom,
                                    (String room) {
                                      setState(() {
                                        selectedRoom = room;
                                      });
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.blueAccent),
                                  ),
                                  elevation: 2,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      RoomSelectionDialog.getRoomDisplayName(
                                        selectedRoom,
                                      ),
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  DoctorSelectionDialog.show(
                                    context,
                                    doctors,
                                    selectedDoctor,
                                    (String doctor) {
                                      setState(() {
                                        selectedDoctor = doctor;
                                      });
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.blueAccent),
                                  ),
                                  elevation: 2,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedDoctor,
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (endoscopyChecked)
                      Container(
                        child: GSFFormWidget(
                          etcChecked: etcChecked,
                          onEtcChanged: (bool? newValue) {
                            setState(() {
                              etcChecked = newValue!;
                            });
                          },
                          selectedBx: gsfDetails.Bx,
                          onSelectedBxChanged: (String? newValue) {
                            setState(() {
                              gsfDetails = ExaminationDetails(
                                Bx: newValue!,
                                polypectomy: gsfDetails.polypectomy,
                                emergency: gsfDetails.emergency,
                                CLO: gsfDetails.CLO,
                                CLOResult: gsfDetails.CLOResult,
                                PEG: gsfDetails.PEG,
                                stoolOB: gsfDetails.stoolOB,
                              );
                            });
                          },
                          gsfDetails: gsfDetails,
                          onGsfDetailsChanged: (
                            ExaminationDetails updatedDetails,
                          ) {
                            setState(() {
                              gsfDetails = updatedDetails;
                            });
                          },
                          onEmergencyChanged: (bool? newValue) {
                            setState(() {
                              gsfDetails = ExaminationDetails(
                                Bx: gsfDetails.Bx,
                                polypectomy: gsfDetails.polypectomy,
                                emergency: newValue!,
                                CLO: gsfDetails.CLO,
                                CLOResult: gsfDetails.CLOResult,
                                PEG: gsfDetails.PEG,
                                stoolOB: gsfDetails.stoolOB,
                              );
                            });
                          },
                          selectedPolypectomy: gsfDetails.polypectomy,
                          onSelectedPolypectomyChanged: (String? newValue) {
                            setState(() {
                              gsfDetails = ExaminationDetails(
                                Bx: gsfDetails.Bx,
                                polypectomy: newValue!,
                                emergency: gsfDetails.emergency,
                                CLO: gsfDetails.CLO,
                                CLOResult: gsfDetails.CLOResult,
                                PEG: gsfDetails.PEG,
                                stoolOB: gsfDetails.stoolOB,
                              );
                            });
                          },
                          GSFmachine: GSFmachine,
                          selectedScopes: selectedGsScopes,
                          onScopeSelected: (String scope) {
                            setState(() {
                              if (selectedGsScopes.containsKey(scope)) {
                                selectedGsScopes.remove(scope);
                              } else {
                                selectedGsScopes[scope] = {
                                  'washingMachine': '',
                                  'washingTime': '',
                                };
                              }
                            });
                          },
                          onAddScope: _addGSFScope,
                          gsfGumjinOrNot: gsfGumjinOrNot,
                          onGsfGumjinChanged: (String? newValue) {
                            setState(() {
                              gsfGumjinOrNot = newValue!;
                            });
                          },
                          gsfSleepOrNot: gsfSleepOrNot,
                          onGsfSleepChanged: (String? newValue) {
                            setState(() {
                              gsfSleepOrNot = newValue!;
                            });
                          },
                          patient: _patientProvider?.patient,
                          onCLOResultPressed: _showCLOResultDialog,
                        ),
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                colonoscopyChecked = !colonoscopyChecked;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  colonoscopyChecked
                                      ? Colors.teal
                                      : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(
                                    colonoscopyChecked ? 0 : 8,
                                  ),
                                  bottomRight: Radius.circular(
                                    colonoscopyChecked ? 0 : 8,
                                  ),
                                ),
                                side: BorderSide(
                                  color:
                                      colonoscopyChecked
                                          ? Colors.teal
                                          : Colors.grey[400]!,
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '대장내시경',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color:
                                        colonoscopyChecked
                                            ? Colors.white
                                            : Colors.grey[800],
                                  ),
                                ),
                                if (colonoscopyChecked)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (csfCancelled) {
                                          setState(() {
                                            csfCancelled = false;
                                          });
                                        } else {
                                          _showCancelConfirmationDialog(
                                            '대장내시경',
                                            csfCancelled,
                                            (bool confirmed) {
                                              setState(() {
                                                csfCancelled = confirmed;
                                              });
                                            },
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            csfCancelled
                                                ? Colors.red
                                                : Colors.white,
                                        foregroundColor:
                                            csfCancelled
                                                ? Colors.white
                                                : Colors.teal,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        minimumSize: Size(50, 25),
                                        textStyle: TextStyle(fontSize: 12),
                                        side: BorderSide(
                                          color:
                                              csfCancelled
                                                  ? Colors.red
                                                  : Colors.teal,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text('취소'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (colonoscopyChecked)
                      CSFFormWidget(
                        selectedBx: csfDetails.Bx,
                        onSelectedBxChanged: (String? newValue) {
                          setState(() {
                            csfDetails.Bx = newValue!;
                          });
                        },
                        csfDetails: csfDetails,
                        onEmergencyChanged: (bool? newValue) {
                          setState(() {
                            csfDetails.emergency = newValue!;
                          });
                        },
                        selectedPolypectomy: csfDetails.polypectomy,
                        onSelectedPolypectomyChanged: (String? newValue) {
                          setState(() {
                            csfDetails.polypectomy = newValue!;
                          });
                        },
                        CSFmachine: CSFmachine,
                        selectedScopes: selectedCsScopes,
                        onScopeSelected: (scope) {
                          setState(() {
                            if (selectedCsScopes.containsKey(scope)) {
                              selectedCsScopes.remove(scope);
                            } else {
                              selectedCsScopes[scope] = {
                                'washingMachine': '',
                                'washingTime': '',
                              };
                            }
                          });
                        },
                        onAddScope: _addCSFScope,
                        csfGumjinOrNot: csfGumjinOrNot,
                        onCsfGumjinChanged: (String? newValue) {
                          setState(() {
                            csfGumjinOrNot = newValue!;
                          });
                        },
                        csfSleepOrNot: csfSleepOrNot,
                        onCsfSleepChanged: (String? newValue) {
                          setState(() {
                            csfSleepOrNot = newValue!;
                          });
                        },
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                sigmoidoscopyChecked = !sigmoidoscopyChecked;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sigmoidoscopyChecked
                                      ? Colors.blueGrey
                                      : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(
                                    sigmoidoscopyChecked ? 0 : 8,
                                  ),
                                  bottomRight: Radius.circular(
                                    sigmoidoscopyChecked ? 0 : 8,
                                  ),
                                ),
                                side: BorderSide(
                                  color:
                                      sigmoidoscopyChecked
                                          ? Colors.blueGrey
                                          : Colors.grey[400]!,
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'S상결장경',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color:
                                        sigmoidoscopyChecked
                                            ? Colors.white
                                            : Colors.grey[800],
                                  ),
                                ),
                                if (sigmoidoscopyChecked)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (sigCancelled) {
                                          setState(() {
                                            sigCancelled = false;
                                          });
                                        } else {
                                          _showCancelConfirmationDialog(
                                            'S상결장경',
                                            sigCancelled,
                                            (bool confirmed) {
                                              setState(() {
                                                sigCancelled = confirmed;
                                              });
                                            },
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            sigCancelled
                                                ? Colors.red
                                                : Colors.white,
                                        foregroundColor:
                                            sigCancelled
                                                ? Colors.white
                                                : Colors.blueGrey,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        minimumSize: Size(50, 25),
                                        textStyle: TextStyle(fontSize: 12),
                                        side: BorderSide(
                                          color:
                                              sigCancelled
                                                  ? Colors.red
                                                  : Colors.blueGrey,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text('취소'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (sigmoidoscopyChecked)
                      SigFormWidget(
                        selectedBx: sigDetails.Bx,
                        onSelectedBxChanged: (String? newValue) {
                          setState(() {
                            sigDetails.Bx = newValue!;
                          });
                        },
                        sigDetails: sigDetails,
                        onEmergencyChanged: (bool? newValue) {
                          setState(() {
                            sigDetails.emergency = newValue!;
                          });
                        },
                        selectedPolypectomy: sigDetails.polypectomy,
                        onSelectedPolypectomyChanged: (String? newValue) {
                          setState(() {
                            sigDetails.polypectomy = newValue!;
                          });
                        },
                        Sigmachine: Sigmachine,
                        selectedScopes: selectedSigScopes,
                        onScopeSelected: (scope) {
                          setState(() {
                            if (selectedSigScopes.containsKey(scope)) {
                              selectedSigScopes.remove(scope);
                            } else {
                              selectedSigScopes[scope] = {
                                'washingMachine': '',
                                'washingTime': '',
                              };
                            }
                          });
                        },
                        onAddScope: _addSigScope,
                      ),
                    SizedBox(height: 20),
                    if (_canShowSaveButton())
                      Center(
                        child: Row(
                          children: [
                            Expanded(child: SizedBox()), // 왼쪽 여백
                            Container(
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.5, // 화면 너비의 50%
                              child: ElevatedButton(
                                onPressed: _savePatientData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 10,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  '저장',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Expanded(child: SizedBox()), // 오른쪽 여백
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraScreen()),
              );
            },
            backgroundColor: Colors.orange,
            child: Icon(Icons.camera_alt, color: Colors.white),
          ),
        );
      },
    );
  }
}
