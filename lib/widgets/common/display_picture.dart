import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data_class/patient_exam.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider/patient_provider.dart';
import '../../main.dart';
import 'package:uuid/uuid.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  DisplayPictureScreen({required this.imagePath});

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool _isSaving = false;
  bool _isStoolOB = false;

  String patientID = "";
  String patientName = "";
  String gender = "";
  String age = "";
  String birthday = "";

  late TextEditingController patientIDController;
  late TextEditingController patientNameController;
  late TextEditingController genderController;
  late TextEditingController ageController;
  late TextEditingController birthdayController;
  bool _isProcessing = true;
  bool _isCheckedEndoscopy = false;
  bool _isCheckedColonoscopy = false;
  bool _isCheckedSig = false;
  String _visitTypeEndoscopy = '';
  String _procedureTypeEndoscopy = '';
  String _visitTypeColonoscopy = '';
  String _procedureTypeColonoscopy = '';
  Map<String, Map<String, String>> _selectedGsfScopes = {};
  Map<String, Map<String, String>> _selectedCsfScopes = {};
  Map<String, Map<String, String>> _selectedSifScopes = {};
  late PatientProvider _patientProvider;

  @override
  void initState() {
    super.initState();
    _patientProvider = Provider.of<PatientProvider>(context, listen: false);
    patientIDController = TextEditingController();
    patientNameController = TextEditingController();
    genderController = TextEditingController();
    ageController = TextEditingController();
    birthdayController = TextEditingController();
    _processImage();
  }

  @override
  void dispose() {
    patientIDController.dispose();
    patientNameController.dispose();
    genderController.dispose();
    ageController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  void countTodayExam() async {
    DateTime today = DateTime.now();
    String formattedToday = DateFormat('yyyy-MM-dd').format(today);
    String startOfDay = '${formattedToday}T00:00:00.000000';
    String endOfDay = '${formattedToday}T23:59:59.999999';

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .where('examDate', isGreaterThanOrEqualTo: startOfDay)
            .where('examDate', isLessThanOrEqualTo: endOfDay)
            .get();

    _patientProvider.setNumberOfExams(querySnapshot.docs.length);
  }

  List<String> extractInfo(String inputString, String divider) {
    List<String> parts = inputString.split(divider);
    if (parts.length > 1) {
      return parts;
    } else {
      return ["info", "no Data"];
    }
  }

  Future<void> _processImage() async {
    final inputImage = InputImage.fromFilePath(widget.imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          if (line.text.contains("환자번호")) {
            patientID = extractInfo(line.text, ": ")[1];
            List<String> charList = patientID.split("");

            for (int i = 0; i < patientID.length; i++) {
              if (charList[i] == 'O' || charList[i] == 'o') {
                charList[i] = '0';
              }
              if (charList[i] == " ") {
                charList[i] = '';
              }
            }
            if (charList.length > 1 && charList[1].toUpperCase() == "B") {
              charList[1] = "8";
            }

            patientID = charList.join('');
          }
          if (line.text.contains("이름")) {
            patientName = extractInfo(line.text, ": ")[1];
          }
          if (line.text.contains("성별/나이")) {
            final List<String> genderAge = extractInfo(
              extractInfo(line.text, ": ")[1],
              "/",
            );
            gender = genderAge[0].trim();
            age = genderAge[1].trim();
          }
          if (line.text.contains("생년월일")) {
            birthday = extractInfo(line.text, ": ")[1].replaceAll(' ', '');
          }
        }
      }

      setState(() {
        patientIDController.text = patientID;
        patientNameController.text = patientName;
        genderController.text = gender;
        ageController.text = age;
        birthdayController.text = birthday;
        _isProcessing = false;
        _validateInputs();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    } finally {
      textRecognizer.close();
    }
  }

  void _validateInputs() {
    List<String> invalidFields = [];

    // 이름 검증
    if (patientNameController.text.isEmpty ||
        patientNameController.text.contains('Data')) {
      invalidFields.add('이름');
    }

    // 성별 검증
    if (genderController.text.isEmpty ||
        !['M', 'F'].contains(genderController.text)) {
      invalidFields.add('성별');
    }

    // 나이 검증
    if (ageController.text.isEmpty ||
        int.tryParse(ageController.text) == null) {
      invalidFields.add('나이');
    }

    // 환자번호 검증
    if (patientIDController.text.isEmpty ||
        patientIDController.text.contains(' ') ||
        patientIDController.text.contains('Data')) {
      invalidFields.add('환자번호');
    }

    // 생년월일 검증
    if (birthdayController.text.isEmpty ||
        !_isValidDateFormat(birthdayController.text) ||
        birthdayController.text.contains('Data')) {
      invalidFields.add('생년월일');
    }

    if (invalidFields.isNotEmpty) {
      _showInvalidFieldsDialog(invalidFields);
    }
  }

  bool _isValidDateFormat(String input) {
    try {
      List<String> parts = input.split('/');
      if (parts.length != 3) return false;

      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int day = int.parse(parts[2]);

      if (year < 1900 || year > DateTime.now().year) return false;
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  void _showInvalidFieldsDialog(List<String> invalidFields) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('입력 오류'),
          content: Container(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('다음 항목을 확인해 주세요:'),
                SizedBox(height: 10),
                ...invalidFields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '• $field',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  bool _isSaveButtonEnabled() {
    // 아무 검사도 선택되지 않았을 경우
    if (!_isCheckedEndoscopy && !_isCheckedColonoscopy && !_isCheckedSig) {
      return false;
    }

    // 위내시경이 선택된 경우
    if (_isCheckedEndoscopy) {
      if (_visitTypeEndoscopy.isEmpty || _procedureTypeEndoscopy.isEmpty) {
        return false;
      }
    }

    // 대장내시경이 선택된 경우
    if (_isCheckedColonoscopy) {
      if (_visitTypeColonoscopy.isEmpty || _procedureTypeColonoscopy.isEmpty) {
        return false;
      }
    }

    // 모든 조건을 만족한 경우
    return true;
  }

  Future<void> _saveToFirestore(BuildContext context) async {
    if (_isSaving) return; // 이미 저장 중이면 함수 종료

    setState(() {
      _isSaving = true; // 저장 프로세스 시작
    });

    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      // Firestore에서 같은 날짜, 같은 이름을 가진 환자 검색
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .where('examDate', isEqualTo: today)
              .where('name', isEqualTo: patientNameController.text)
              .where('id', isEqualTo: patientIDController.text)
              .get();

      // 중복된 환자가 있는 경우
      if (querySnapshot.docs.isNotEmpty) {
        // 팝업창 표시
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('중복된 환자'),
              content: Text('동일한 환자번호와 이름을 가진 환자가 오늘 이미 저장되어 있습니다.'),
              actions: <Widget>[
                TextButton(
                  child: Text('확인'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return; // 함수 종료
      }

      Endoscopy? endoscopyData =
          _isCheckedEndoscopy
              ? Endoscopy(
                gumjinOrNot: _visitTypeEndoscopy,
                sleepOrNot: _procedureTypeEndoscopy,
                scopes: _selectedGsfScopes,
                examDetail: ExaminationDetails(
                  Bx: '없음',
                  polypectomy: '없음',
                  emergency: false,
                  CLO: false,
                  PEG: false,
                ),
              )
              : null;

      Endoscopy? colonoscopyData =
          _isCheckedColonoscopy
              ? Endoscopy(
                gumjinOrNot: _visitTypeColonoscopy,
                sleepOrNot: _procedureTypeColonoscopy,
                scopes: _selectedCsfScopes,
                examDetail: ExaminationDetails(
                  Bx: '없음',
                  polypectomy: '없음',
                  emergency: false,
                  stoolOB: _isStoolOB,
                ),
              )
              : null;

      Endoscopy? sigData =
          _isCheckedSig
              ? Endoscopy(
                gumjinOrNot: '외래',
                sleepOrNot: '일반',
                scopes: _selectedSifScopes,
                examDetail: ExaminationDetails(
                  Bx: '없음',
                  polypectomy: '없음',
                  emergency: false,
                ),
              )
              : null;

      final formatter = DateFormat('yyyy/MM/dd');
      DateTime birthday = formatter.parse(birthdayController.text);

      final formattForFireBaseUniqueName = DateFormat('yyyyMMddHHmmss');
      final formattedDate = formattForFireBaseUniqueName.format(now);
      final uid = Uuid().v4(); // Generate a unique ID
      final documentName =
          "${patientNameController.text}_${formattedDate}_${uid}";
      final uniqueDocName =
          documentName; // uniqueDocName을 documentName과 동일하게 설정

      final examTime24 = formatTimeOfDay(TimeOfDay.now());

      Patient patient = Patient(
        uniqueDocName: uniqueDocName,
        id: patientIDController.text,
        name: patientNameController.text,
        gender: genderController.text,
        age: int.parse(ageController.text),
        Room: '검사실',
        birthday: birthday,
        doctor: '의사',
        examDate: now,
        examTime: '',
        GSF: endoscopyData,
        CSF: colonoscopyData,
        sig: sigData,
      );

      // 문서 이름에 uniqueDocName이 포함되어 있는지 확인
      if (!documentName.contains(uid)) {
        throw Exception('문서 이름에 고유 ID가 포함되어 있지 않습니다.');
      }

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(documentName)
          .set(patient.toMap());
      _patientProvider.setPatient(patient);
      await _patientProvider.refreshExamCount();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장이 완료되었습니다.')));
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해 주세요.')));
    } finally {
      setState(() {
        _isSaving = false; // 저장 프로세스 종료
      });
    }
  }

  Widget _buildStoolOBButton() {
    return ElevatedButton(
      child: Text('StoolOB'),
      onPressed: () {
        setState(() {
          _isStoolOB = !_isStoolOB;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isStoolOB ? Colors.redAccent : Colors.grey[300],
        foregroundColor: _isStoolOB ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('정보 확인', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _isProcessing
                ? CircularProgressIndicator()
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildTextField(patientNameController, '이름'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(genderController, '성별'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(ageController, '나이'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildTextField(patientIDController, '환자번호'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: _buildTextField(birthdayController, '생년월일'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildExamTypeSection('위내시경', _isCheckedEndoscopy, (
                        value,
                      ) {
                        setState(() {
                          _isCheckedEndoscopy = value ?? false;
                        });
                      }),
                      if (_isCheckedEndoscopy) ...[
                        SizedBox(height: 10),
                        _buildButtonGroup(
                          '검진',
                          '외래',
                          '수면',
                          '일반',
                          _visitTypeEndoscopy,
                          _procedureTypeEndoscopy,
                          (value) {
                            setState(() {
                              _visitTypeEndoscopy = value;
                            });
                          },
                          (value) {
                            setState(() {
                              _procedureTypeEndoscopy = value;
                            });
                          },
                        ),
                      ],
                      SizedBox(height: 2),
                      Divider(),
                      SizedBox(height: 2),
                      _buildExamTypeSection('대장내시경', _isCheckedColonoscopy, (
                        value,
                      ) {
                        setState(() {
                          _isCheckedColonoscopy = value ?? false;
                        });
                      }),
                      if (_isCheckedColonoscopy) ...[
                        SizedBox(height: 10),
                        _buildButtonGroup(
                          '검진',
                          '외래',
                          '수면',
                          '일반',
                          _visitTypeColonoscopy,
                          _procedureTypeColonoscopy,
                          (value) {
                            setState(() {
                              _visitTypeColonoscopy = value;
                            });
                          },
                          (value) {
                            setState(() {
                              _procedureTypeColonoscopy = value;
                            });
                          },
                        ),
                        if (_visitTypeColonoscopy == '검진') ...[
                          SizedBox(height: 10),
                          _buildStoolOBButton(),
                        ],
                      ],
                      SizedBox(height: 2),
                      Divider(),
                      SizedBox(height: 2),
                      _buildExamTypeSection('S상 결장경', _isCheckedSig, (value) {
                        setState(() {
                          _isCheckedSig = value ?? false;
                        });
                      }),
                      SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isSaveButtonEnabled() && !_isSaving
                                  ? () => _saveToFirestore(context)
                                  : null,
                          child:
                              _isSaving
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text('저장'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildExamTypeSection(
    String title,
    bool isChecked,
    Function(bool?) onChanged,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Checkbox(
          value: isChecked,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildButtonGroup(
    String option1,
    String option2,
    String option3,
    String option4,
    String selectedValue1,
    String selectedValue2,
    Function(String) onChanged1,
    Function(String) onChanged2,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            child: Text(option1),
            onPressed: () => onChanged1(option1),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedValue1 == option1 ? Colors.blue : Colors.grey[300],
              foregroundColor:
                  selectedValue1 == option1 ? Colors.white : Colors.black,
            ),
          ),
        ),
        SizedBox(width: 5),
        Expanded(
          child: ElevatedButton(
            child: Text(option2),
            onPressed: () => onChanged1(option2),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedValue1 == option2 ? Colors.blue : Colors.grey[300],
              foregroundColor:
                  selectedValue1 == option2 ? Colors.white : Colors.black,
            ),
          ),
        ),
        SizedBox(width: 5),
        Text('|', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(width: 5),
        Expanded(
          child: ElevatedButton(
            child: Text(option3),
            onPressed: () => onChanged2(option3),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedValue2 == option3 ? Colors.blue : Colors.grey[300],
              foregroundColor:
                  selectedValue2 == option3 ? Colors.white : Colors.black,
            ),
          ),
        ),
        SizedBox(width: 5),
        Expanded(
          child: ElevatedButton(
            child: Text(option4),
            onPressed: () => onChanged2(option4),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedValue2 == option4 ? Colors.blue : Colors.grey[300],
              foregroundColor:
                  selectedValue2 == option4 ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

String formatTimeOfDay(TimeOfDay time) {
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  final format = DateFormat.Hm();
  return format.format(dt);
}
