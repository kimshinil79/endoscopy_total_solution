import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data_class/patient_exam.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../provider/settings_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/statistics/disinfectant_excel_generator.dart';
import '../widgets/statistics/doctor_statistics_excel_generator.dart';
import '../widgets/statistics/washing_machine_scopes_excel_generator.dart';
import '../widgets/statistics/room_summary_dialog.dart';
import '../widgets/statistics/summary_dialog.dart';
import '../widgets/statistics/statistics_doctor_selection_dialog.dart';
import '../widgets/statistics/results_dialog.dart';
import '../widgets/statistics/results_dialog_with_current_doctors.dart';

// 색상 팔레트 정의
final Color oceanBlue = Color(0xFF1A5F7A);
final Color seafoamGreen = Color(0xFF57C5B6);
final Color sandyBeige = Color(0xFFEEE3CB);
final Color coralOrange = Color(0xFFF79327);
final Color lavenderPurple = Color(0xFF9B59B6);
final Color turquoiseBlue = Color(0xFF3498DB);

// 버튼 스타일 정의
final ButtonStyle oceanButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: oceanBlue,
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  elevation: 3,
);

final ButtonStyle seafoamButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: seafoamGreen,
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  elevation: 3,
);

class StatisticsPage extends StatefulWidget {
  final TabController tabController;

  StatisticsPage({required this.tabController});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime? startDate;
  DateTime? endDate;
  bool showSearch = false;
  bool showSummary = false;
  bool showRoomSummary = false;
  DateTime? summaryStartDate;
  DateTime? summaryEndDate;

  String email = '';

  List<String> doctors = ['의사'];
  String selectedDoctor = '의사';
  String selectedRoomForSearch = '전체';

  // 빈 Map으로 초기화
  Map<String, String> scopyFullName = {};
  Map<String, String> washingMachinesFullName = {};

  bool showDetailSearch = false;
  bool isGSFSelected = false;
  bool isCSFSelected = false;
  bool isSigSelected = false;
  bool isConfirmButtonEnabled = false;

  Map<String, bool> gsfOptions = {
    '외래': false,
    '검진': false,
    '수면': false,
    '일반': false,
    'Bx': false,
    'CLO': false,
    'CLO 양성': false,
    'Polypectomy': false,
    'PEG': false,
    '응급': false,
  };
  Map<String, bool> csfOptions = {
    '외래': false,
    '검진': false,
    '수면': false,
    '일반': false,
    'Bx': false,
    'Polypectomy': false,
    '응급': false,
  };

  Map<String, bool> sigOptions = {
    'Bx': false,
    'Polypectomy': false,
    '응급': false,
  };

  bool isLoading = false; // Add a loading state variable

  double progressValue = 0.0; // Add a progress value variable
  String progressMessage = ''; // Add a progress message variable

  void _fillData(
    xls.Worksheet sheet,
    int row,
    int col,
    List<Patient> patients,
    String examType,
    String gumjinType,
    String sleepType,
  ) {
    int count =
        patients.where((p) {
          var exam = examType == 'GSF' ? p.GSF : p.CSF;
          return exam != null &&
              exam.gumjinOrNot == gumjinType &&
              exam.sleepOrNot == (sleepType == '수면' ? '수면' : '일반');
        }).length;
    sheet.getRangeByIndex(row, col).setValue(count);
  }

  void _fillPEGData(
    xls.Worksheet sheet,
    int row,
    int col,
    List<Patient> patients,
  ) {
    int count = patients.where((p) => p.GSF?.examDetail.PEG == true).length;
    sheet.getRangeByIndex(row, col).setValue(count);
  }

  void _fillSigData(
    xls.Worksheet sheet,
    int row,
    int col,
    List<Patient> patients,
  ) {
    int count = patients.where((p) => p.sig != null).length;
    sheet.getRangeByIndex(row, col).setValue(count);
  }

  Map<String, int> _getCountForDoctorForExcel(
    List<Patient> patients,
    String doctor,
    String category,
    String subCategory,
    bool isSig,
  ) {
    int total = 0;
    int polyp = 0;

    for (var p in patients) {
      if (p.doctor != doctor) continue;

      if (category == '위내시경' && p.GSF != null) {
        if (p.GSF!.gumjinOrNot == (subCategory == '외래' ? '외래' : '검진')) {
          total++;
        }
      } else if (category == '대장내시경') {
        if (isSig) {
          if (p.sig != null) {
            total++;
            if (p.sig!.examDetail.polypectomy != '없음') polyp++;
          }
        } else if (p.CSF != null) {
          if (p.CSF!.gumjinOrNot == (subCategory == '외래' ? '외래' : '검진')) {
            total++;
            if (p.CSF!.examDetail.polypectomy != '없음') polyp++;
          }
        }
      }
    }

    return {'total': total, 'polyp': polyp};
  }

  int _getCountForDoctor(
    List<Patient> patients,
    String doctor,
    String category,
    String subCategory,
    bool isSig,
  ) {
    return patients.where((p) {
      if (p.doctor != doctor) return false;
      if (category == '위내시경') {
        return p.GSF != null &&
            p.GSF!.gumjinOrNot == (subCategory == '외래' ? '외래' : '검진');
      } else if (category == '대장내시경') {
        if (isSig) {
          return p.sig != null;
        } else {
          return p.CSF != null &&
              p.CSF!.gumjinOrNot == (subCategory == '외래' ? '외래' : '검진');
        }
      }
      return false;
    }).length;
  }

  Map<String, int> cumulativeWashCounts = {};

  Future<void> _createExamSummaryExcel() async {
    setState(() {
      isLoading = true;
    });

    try {
      final xls.Workbook workbook = xls.Workbook();
      final xls.Worksheet sheet = workbook.worksheets[0];

      // 페이지 설정
      sheet.pageSetup.orientation = xls.ExcelPageOrientation.landscape;
      sheet.pageSetup.topMargin = 0.25;
      sheet.pageSetup.bottomMargin = 0.25;
      sheet.pageSetup.leftMargin = 0.25;
      sheet.pageSetup.rightMargin = 0.25;

      // 스타일 정의
      var titleStyle = workbook.styles.add('titleStyle');
      titleStyle.fontSize = 15;
      titleStyle.bold = true;

      var headerStyle = workbook.styles.add('headerStyle');
      headerStyle.fontSize = 11;
      headerStyle.bold = true;

      var contentStyle = workbook.styles.add('contentStyle');
      contentStyle.fontSize = 11;

      int rowIndex = 1;
      String currentMonth = '';

      List<Patient> patients = await queryPatientsByDate(startDate!, endDate!);

      // 날짜별로 환자를 그룹화하고 examTime으로 정렬
      Map<String, List<Patient>> patientsByDate = {};
      for (var patient in patients) {
        String date = DateFormat('yyyy-MM-dd').format(patient.examDate);
        if (!patientsByDate.containsKey(date)) {
          patientsByDate[date] = [];
        }
        patientsByDate[date]!.add(patient);
      }

      // 각 날짜 그룹 내에서 examTime으로 정렬
      patientsByDate.forEach((date, patientList) {
        patientList.sort((a, b) => a.examTime.compareTo(b.examTime));
      });

      // 날짜순으로 정렬된 키 목록 생성
      List<String> sortedDates = patientsByDate.keys.toList()..sort();

      for (var date in sortedDates) {
        List<Patient> dailyPatients = patientsByDate[date]!;
        String monthYear = DateFormat('yyyy년 M월').format(DateTime.parse(date));
        String formattedDate = DateFormat('M월 d일').format(DateTime.parse(date));

        if (monthYear != currentMonth) {
          if (currentMonth != '') {
            rowIndex++; // 빈 줄 추가
          }
          sheet.getRangeByIndex(rowIndex, 1, rowIndex, 6).merge();
          sheet.getRangeByIndex(rowIndex, 1).setText('환자별 검사 요약 ($monthYear)');
          sheet.getRangeByIndex(rowIndex, 1).cellStyle = titleStyle;
          rowIndex++;

          // 헤더 추가
          var headers = ['날짜', '등록번호', '이름', '성별/나이', '의사', '요약'];
          for (int i = 0; i < headers.length; i++) {
            sheet.getRangeByIndex(rowIndex, i + 1).setText(headers[i]);
            sheet.getRangeByIndex(rowIndex, i + 1).cellStyle = headerStyle;
          }
          rowIndex++;

          currentMonth = monthYear;
        }

        int dateMergeStartIndex = rowIndex;

        for (var patient in dailyPatients) {
          sheet.getRangeByIndex(rowIndex, 1).setText(formattedDate);
          sheet.getRangeByIndex(rowIndex, 2).setText(patient.id);
          sheet.getRangeByIndex(rowIndex, 3).setText(patient.name);
          sheet
              .getRangeByIndex(rowIndex, 4)
              .setText('${patient.gender}/${patient.age}');
          sheet.getRangeByIndex(rowIndex, 5).setText(patient.doctor);

          String summary = _generateSummary(patient);
          sheet.getRangeByIndex(rowIndex, 6).setText(summary);

          for (int i = 1; i <= 6; i++) {
            sheet.getRangeByIndex(rowIndex, i).cellStyle = contentStyle;
          }

          rowIndex++;
        }

        // 날짜 셀 병합
        if (dateMergeStartIndex < rowIndex - 1) {
          sheet
              .getRangeByIndex(dateMergeStartIndex, 1, rowIndex - 1, 1)
              .merge();
        }
      }

      // 열 너비 설정
      sheet.autoFitColumn(1); // 날짜
      sheet.autoFitColumn(2); // 등록번호
      sheet.getRangeByName('C1:C$rowIndex').columnWidth = 8; // 이름
      sheet.getRangeByName('D1:D$rowIndex').columnWidth = 8; // 성별/나이
      sheet.autoFitColumn(5); // 의사
      sheet.getRangeByName('F1:F$rowIndex').columnWidth =
          80; // 요약 (가로 방향이므로 더 넓게 설정)

      // 모든 셀에 테두리 추가 및 정렬
      var range = sheet.getRangeByName('A1:F$rowIndex');
      range.cellStyle.borders.all.lineStyle = xls.LineStyle.thin;
      range.cellStyle.hAlign = xls.HAlignType.center;
      range.cellStyle.vAlign = xls.VAlignType.center;

      // 엑셀 파일 저장
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final String path = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          '환자별검사요약_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      final String filePath = '$path/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      String subject =
          '환자별 검사 요약 (${DateFormat('yyyy년 M월').format(startDate!)})';
      _showSendEmailDialog(filePath, subject);
    } catch (e) {
      print('Error creating Excel file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('엑셀 파일 생성 중 오류가 발생했습니다.')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _generateSummary(Patient patient) {
    List<String> summary = [];

    if (patient.GSF != null) {
      List<String> gsfDetails = ['[E]'];

      if (patient.GSF!.cancel == true) {
        gsfDetails.add('검사 취소');
        if (patient.GSF!.scopes.isNotEmpty) {
          gsfDetails.add('scope: ${patient.GSF!.scopes.keys.join('/')}');
        }
      } else {
        // 검진/외래 및 수면/일반 정보 추가
        String examType =
            '${patient.GSF!.gumjinOrNot}&${patient.GSF!.sleepOrNot}';
        gsfDetails.add(examType);

        if (patient.GSF!.examDetail.Bx != '없음')
          gsfDetails.add('Bx: ${patient.GSF!.examDetail.Bx}');
        if (patient.GSF!.examDetail.polypectomy != '없음')
          gsfDetails.add('polypectomy: ${patient.GSF!.examDetail.polypectomy}');
        if (patient.GSF!.examDetail.CLO == true) {
          if (patient.GSF!.examDetail.CLOResult != '') {
            gsfDetails.add('CLO: ${patient.GSF!.examDetail.CLOResult}');
          } else {
            gsfDetails.add('CLO');
          }
        }
        if (patient.GSF!.scopes.isNotEmpty) {
          gsfDetails.add('scope: ${patient.GSF!.scopes.keys.join('/')}');
        }
      }
      summary.add(gsfDetails.join(', '));
    }

    if (patient.CSF != null) {
      List<String> csfDetails = ['[C]'];

      if (patient.CSF!.cancel == true) {
        csfDetails.add('검사 취소');
        if (patient.CSF!.scopes.isNotEmpty) {
          csfDetails.add('scope: ${patient.CSF!.scopes.keys.join('/')}');
        }
      } else {
        // 검진/외래 및 수면/일반 정보 추가, stoolOB 정보 포함
        String examType = patient.CSF!.gumjinOrNot;
        if (examType == '검진' &&
            patient.CSF!.examDetail.stoolOB != null &&
            patient.CSF!.examDetail.stoolOB == true) {
          examType += '(stoolOB:+)';
        }
        examType += '&${patient.CSF!.sleepOrNot}';
        csfDetails.add(examType);

        if (patient.CSF!.examDetail.Bx != '없음')
          csfDetails.add('Bx: ${patient.CSF!.examDetail.Bx}');
        if (patient.CSF!.examDetail.polypectomy != '없음')
          csfDetails.add('polypectomy: ${patient.CSF!.examDetail.polypectomy}');
        if (patient.CSF!.scopes.isNotEmpty) {
          csfDetails.add('scope: ${patient.CSF!.scopes.keys.join('/')}');
        }
      }
      summary.add(csfDetails.join(', '));
    }

    if (patient.sig != null) {
      List<String> sigDetails = ['[S]'];

      if (patient.sig!.cancel == true) {
        sigDetails.add('검사 취소');
        if (patient.sig!.scopes.isNotEmpty) {
          sigDetails.add('scope: ${patient.sig!.scopes.keys.join('/')}');
        }
      } else {
        if (patient.sig!.examDetail.Bx != '없음')
          sigDetails.add('Bx: ${patient.sig!.examDetail.Bx}');
        if (patient.sig!.examDetail.polypectomy != '없음')
          sigDetails.add('polypectomy: ${patient.sig!.examDetail.polypectomy}');
        if (patient.sig!.scopes.isNotEmpty) {
          sigDetails.add('scope: ${patient.sig!.scopes.keys.join('/')}');
        }
      }
      summary.add(sigDetails.join(', '));
    }

    return summary.join(' / ');
  }

  void _showSendEmailDialog(String filePath, String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('lastUsedEmail') ?? '';
    final TextEditingController emailController = TextEditingController(
      text: savedEmail,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이메일 전송',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: oceanBlue,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: '이메일 주소 입력',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: TextStyle(color: oceanBlue),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '취소',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oceanBlue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        String email = emailController.text.trim();
                        if (email.isNotEmpty) {
                          try {
                            // 이메일 주소 저장
                            await prefs.setString('lastUsedEmail', email);

                            final Email emailMessage = Email(
                              body: '',
                              subject: subject,
                              recipients: [email],
                              attachmentPaths: [filePath],
                            );
                            await FlutterEmailSender.send(emailMessage);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('이메일이 성공적으로 전송되었습니다.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('이메일 전송에 실패했습니다.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('이메일 주소를 입력해주세요.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Text(
                        '전송',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
    summaryStartDate = now;
    summaryEndDate = now;
    isConfirmButtonEnabled = selectedDoctor != '의사';
    _loadSettingsData(); // 설정 데이터 로드
    _loadDoctorsFromProvider(); // Provider에서 의사 목록 로드
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        email = prefs.getString('emailAddress') ?? '';
      });
    });
  }

  // SettingsProvider에서 데이터 로드하는 메서드 추가
  void _loadSettingsData() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // GSF, CSF, SIG 스코프 정보 로드
    Map<String, String> gsfMap = settingsProvider.gsfScopes;
    Map<String, String> csfMap = settingsProvider.csfScopes;
    Map<String, String> sigMap = settingsProvider.sigScopes;

    // scopyFullName 맵 초기화
    setState(() {
      // 모든 스코프 맵 병합
      scopyFullName = {};
      gsfMap.forEach((key, value) {
        scopyFullName[key] = value;
      });
      csfMap.forEach((key, value) {
        scopyFullName[key] = value;
      });
      sigMap.forEach((key, value) {
        scopyFullName[key] = value;
      });

      // washingMachinesFullName 로드
      FirebaseFirestore.instance
          .collection('settings')
          .doc('washingMachines')
          .get()
          .then((snapshot) {
            if (snapshot.exists) {
              Map<String, dynamic> machineMap =
                  (snapshot.data()
                      as Map<String, dynamic>)['washingMachineMap'] ??
                  {};

              setState(() {
                washingMachinesFullName = Map<String, String>.from(machineMap);
              });
            }
          });
    });
  }

  // Provider에서 의사 목록을 로드하는 메서드 추가
  void _loadDoctorsFromProvider() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    setState(() {
      doctors = settingsProvider.doctors;

      // selectedDoctor가 새로운 목록에 없으면 첫 번째 의사로 설정
      if (!doctors.contains(selectedDoctor)) {
        selectedDoctor =
            doctors.isNotEmpty && doctors.length > 1
                ? doctors[1]
                : '의사'; // '의사' 다음의 첫 번째 실제 의사
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: startDate!, end: endDate!),
      saveText: '선택',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: oceanBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isStart,
    bool isSummary,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (isSummary
                  ? summaryStartDate ?? DateTime.now()
                  : startDate ?? DateTime.now())
              : (isSummary
                  ? summaryEndDate ?? DateTime.now()
                  : endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          if (isSummary) {
            summaryStartDate = picked;
          } else {
            startDate = picked;
          }
        } else {
          if (isSummary) {
            summaryEndDate = picked;
          } else {
            endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _queryPatients() async {
    if (startDate != null && endDate != null && selectedDoctor.isNotEmpty) {
      setState(() {
        isLoading = true; // Set loading to true when starting the query
      });

      List<Patient> patients = await queryPatientsByDateAndDoctor(
        startDate!,
        endDate!,
        selectedDoctor,
      );

      setState(() {
        isLoading = false; // Set loading to false when query is complete
      });

      _showResultsDialog(context, patients);
    }
  }

  Future<void> _querySummaryPatients() async {
    if (startDate != null && endDate != null) {
      setState(() {
        isLoading = true; // Set loading to true when starting the query
      });

      List<Patient> patients = await queryPatientsByDate(startDate!, endDate!);

      setState(() {
        isLoading = false; // Set loading to false when query is complete
      });

      SummaryDialog.show(
        context,
        patients,
        startDate!,
        endDate!,
        widget.tabController,
        (newStartDate, newEndDate) {
          setState(() {
            startDate = newStartDate;
            endDate = newEndDate;
          });
        },
      );
    }
  }

  Future<void> _queryRoomSummary() async {
    if (startDate != null && endDate != null) {
      setState(() {
        isLoading = true; // Set loading to true when starting the query
      });

      List<Patient> patients = await queryPatientsByDate(startDate!, endDate!);

      setState(() {
        isLoading = false; // Set loading to false when query is complete
      });

      RoomSummaryDialog.show(context, patients, startDate!, endDate!);
    }
  }

  Future<List<Patient>> queryPatientsByDateAndDoctor(
    DateTime startDate,
    DateTime endDate,
    String doctor,
  ) async {
    CollectionReference patientsRef = FirebaseFirestore.instance.collection(
      'patients',
    );

    String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    QuerySnapshot querySnapshot =
        await patientsRef
            .where('doctor', isEqualTo: doctor)
            .where('examDate', isGreaterThanOrEqualTo: formattedStartDate)
            .where('examDate', isLessThanOrEqualTo: formattedEndDate)
            .get();

    return querySnapshot.docs
        .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Patient>> queryPatientsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    CollectionReference patientsRef = FirebaseFirestore.instance.collection(
      'patients',
    );

    String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    QuerySnapshot querySnapshot =
        await patientsRef
            .where('examDate', isGreaterThanOrEqualTo: formattedStartDate)
            .where('examDate', isLessThanOrEqualTo: formattedEndDate)
            .get();

    return querySnapshot.docs
        .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  void _showResultsDialog(BuildContext context, List<Patient> patients) {
    showResultsDialog(
      context: context,
      patients: patients,
      startDate: startDate!,
      endDate: endDate!,
      selectedDoctor: selectedDoctor,
      doctors: doctors,
      onClose: () {
        setState(() {
          // Trigger rebuild of parent widget
        });
      },
    );
  }

  void _showResultsDialogWithCurrentDoctors(
    BuildContext context,
    List<Patient> patients,
  ) {
    showResultsDialogWithCurrentDoctors(
      context: context,
      patients: patients,
      startDate: startDate!,
      endDate: endDate!,
      selectedDoctor: selectedDoctor,
      doctors: doctors,
      onClose: () {
        setState(() {
          // Trigger rebuild of parent widget
        });
      },
    );
  }

  void _showYearComparisonDialog() async {
    List<int> selectedYears = [];
    String selectedType = '전체'; // '전체', '외래', '검진'
    bool isCumulative = false; // 누적 표시 여부를 추적하는 새 변수

    // 이전 달 데이터 확인 및 업데이트
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      // 이전 달의 statistics 데이터 확인
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('statistics')
              .doc(lastMonth.year.toString())
              .get();

      // 한자리 수 달을 두자리로 표시 (예: 3월 -> '03')
      String lastMonthKey = lastMonth.month.toString().padLeft(2, '0');
      bool needToUpdate = false;
      Map<String, dynamic> lastMonthData = {};

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey(lastMonthKey)) {
          needToUpdate = true;
        }
      } else {
        needToUpdate = true;
      }

      if (needToUpdate) {
        // 이전 달의 환자 데이터 조회
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection('patients')
                .where(
                  'examDate',
                  isGreaterThanOrEqualTo: DateFormat(
                    'yyyy-MM-dd',
                  ).format(lastMonth),
                )
                .where(
                  'examDate',
                  isLessThanOrEqualTo: DateFormat(
                    'yyyy-MM-dd',
                  ).format(lastMonthEnd),
                )
                .get();

        int outpatientCount = 0;
        int screeningCount = 0;

        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // GSF 데이터 확인
          if (data['GSF'] != null) {
            if (data['GSF']['gumjinOrNot'] == '외래') outpatientCount++;
            if (data['GSF']['gumjinOrNot'] == '검진') screeningCount++;
          }

          // CSF 데이터 확인
          if (data['CSF'] != null) {
            if (data['CSF']['gumjinOrNot'] == '외래') outpatientCount++;
            if (data['CSF']['gumjinOrNot'] == '검진') screeningCount++;
          }

          // sig 데이터 확인 (외래만 포함)
          if (data['sig'] != null) {
            if (data['sig']['gumjinOrNot'] == '외래') outpatientCount++;
          }
        }

        lastMonthData = {'외래': outpatientCount, '검진': screeningCount};

        // Firebase에 이전 달 데이터 업데이트
        await FirebaseFirestore.instance
            .collection('statistics')
            .doc(lastMonth.year.toString())
            .set({lastMonthKey: lastMonthData}, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating last month statistics: $e');
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '년도별 통계 비교',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: oceanBlue,
                        ),
                      ),
                      SizedBox(height: 24),
                      // 통계 유형 선택 버튼
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTypeButton('외래', selectedType, (val) {
                              setState(() => selectedType = val);
                            }),
                            _buildTypeButton('검진', selectedType, (val) {
                              setState(() => selectedType = val);
                            }),
                            _buildTypeButton('전체', selectedType, (val) {
                              setState(() => selectedType = val);
                            }),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      // 누적 버튼 추가 - 다른 스타일로 표시
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isCumulative
                                ? Icons.stacked_line_chart
                                : Icons.show_chart,
                            color:
                                isCumulative ? Colors.white : Colors.grey[700],
                          ),
                          label: Text(
                            '누적',
                            style: TextStyle(
                              color:
                                  isCumulative
                                      ? Colors.white
                                      : Colors.grey[700],
                              fontWeight:
                                  isCumulative
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isCumulative
                                    ? Colors.amber[700]
                                    : Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isCumulative
                                        ? Colors.amber[700]!
                                        : Colors.grey[700]!,
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              isCumulative = !isCumulative;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        '비교할 년도 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      // 년도 선택 그리드
                      Container(
                        height: 200,
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: DateTime.now().year - 2022,
                          itemBuilder: (context, index) {
                            int year = DateTime.now().year - index;
                            bool isSelected = selectedYears.contains(year);
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSelected
                                        ? Colors.redAccent[200]
                                        : Colors.grey[200],
                                foregroundColor:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                elevation: isSelected ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedYears.remove(year);
                                  } else {
                                    selectedYears.add(year);
                                  }
                                });
                              },
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('취소'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: oceanBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed:
                                selectedYears.isEmpty
                                    ? null
                                    : () {
                                      Navigator.of(context).pop();
                                      _showYearComparisonChart(
                                        selectedYears,
                                        selectedType,
                                        isCumulative, // 새 파라미터 전달
                                      );
                                    },
                            child: Text('차트 보기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildTypeButton(
    String type,
    String selectedType,
    Function(String) onSelect,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedType == type ? oceanBlue : Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => onSelect(type),
      child: Text(
        type,
        style: TextStyle(
          color: selectedType == type ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  void _showYearComparisonChart(
    List<int> years,
    String type,
    bool isCumulative,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });

      Map<int, Map<String, List<int>>> yearlyData = {};

      // 현재 연도와 월 가져오기
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      // Fetch data for each selected year
      for (int year in years) {
        yearlyData[year] = {};
        yearlyData[year]!['외래'] = List<int>.filled(12, 0);
        yearlyData[year]!['검진'] = List<int>.filled(12, 0);

        if (year == currentYear) {
          // 현재 연도의 statistics 데이터 조회
          DocumentSnapshot doc =
              await FirebaseFirestore.instance
                  .collection('statistics')
                  .doc(year.toString())
                  .get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // 현재 월을 제외한 모든 월의 데이터를 statistics에서 가져옴
            data.forEach((month, stats) {
              int monthIndex = int.parse(month) - 1;
              if (monthIndex < currentMonth - 1) {
                // 현재 월 이전의 데이터만 사용
                yearlyData[year]!['외래']![monthIndex] = stats['외래'] ?? 0;
                yearlyData[year]!['검진']![monthIndex] = stats['검진'] ?? 0;
              }
            });
          }

          // 현재 월의 데이터는 patients 컬렉션에서 직접 조회
          DateTime startOfMonth = DateTime(year, currentMonth, 1);
          DateTime endOfMonth = DateTime(year, currentMonth + 1, 0);

          QuerySnapshot querySnapshot =
              await FirebaseFirestore.instance
                  .collection('patients')
                  .where(
                    'examDate',
                    isGreaterThanOrEqualTo: DateFormat(
                      'yyyy-MM-dd',
                    ).format(startOfMonth),
                  )
                  .where(
                    'examDate',
                    isLessThanOrEqualTo: DateFormat(
                      'yyyy-MM-dd',
                    ).format(endOfMonth),
                  )
                  .get();

          int outpatientCount = 0;
          int screeningCount = 0;

          for (var doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // GSF 데이터 확인
            if (data['GSF'] != null) {
              if (data['GSF']['gumjinOrNot'] == '외래') outpatientCount++;
              if (data['GSF']['gumjinOrNot'] == '검진') screeningCount++;
            }

            // CSF 데이터 확인
            if (data['CSF'] != null) {
              if (data['CSF']['gumjinOrNot'] == '외래') outpatientCount++;
              if (data['CSF']['gumjinOrNot'] == '검진') screeningCount++;
            }

            // sig 데이터 확인
            if (data['sig'] != null) {
              // S상 결장경은 일반적으로 외래에 포함됨
              outpatientCount++;
            }
          }

          yearlyData[year]!['외래']![currentMonth - 1] = outpatientCount;
          yearlyData[year]!['검진']![currentMonth - 1] = screeningCount;
        } else {
          // 이전 연도는 statistics 컬렉션에서 전체 데이터 조회
          DocumentSnapshot doc =
              await FirebaseFirestore.instance
                  .collection('statistics')
                  .doc(year.toString())
                  .get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data.forEach((month, stats) {
              int monthIndex = int.parse(month) - 1;
              yearlyData[year]!['외래']![monthIndex] = stats['외래'] ?? 0;
              yearlyData[year]!['검진']![monthIndex] = stats['검진'] ?? 0;
            });
          }
        }
      }

      setState(() {
        isLoading = false;
      });

      // Show chart dialog
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '년도별 통계 비교${isCumulative ? ' (누적)' : ''}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: oceanBlue,
                      ),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width *
                              1.5, // 화면 너비의 1.5배
                          child: YearComparisonChart(
                            yearlyData: yearlyData,
                            selectedType: type,
                            isCumulative: isCumulative,
                            currentYear: currentYear,
                            currentMonth: currentMonth,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oceanBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '닫기',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      print('Error fetching statistics: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('통계 데이터를 불러오는 중 오류가 발생했습니다.')));
      setState(() {
        isLoading = false;
      });
    }
  }

  TableRow _buildTableRow(String label, int exam, int clinic) {
    return TableRow(
      children: [
        TableCell(child: Center(child: Text(label))),
        TableCell(child: Center(child: Text(exam.toString()))),
        TableCell(child: Center(child: Text(clinic.toString()))),
        TableCell(child: Center(child: Text((exam + clinic).toString()))),
      ],
    );
  }

  TableRow _buildTableRow2(
    String label,
    String bx,
    String polypectomy,
    String clo,
  ) {
    return TableRow(
      children: [
        TableCell(child: Center(child: Text(label))),
        TableCell(child: Center(child: Text(bx))),
        TableCell(child: Center(child: Text(polypectomy))),
        TableCell(child: Center(child: Text(clo))),
      ],
    );
  }

  Widget _buildRow(String label, String value, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: textStyle)],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsBox(String title, Map<String, bool> options) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: oceanBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.keys.map((String key) {
                  return SizedBox(
                    width:
                        (MediaQuery.of(context).size.width - 80) / 3, // 4개씩 배치
                    child: _buildCheckbox(key, options[key]!, (bool? value) {
                      setState(() {
                        options[key] = value!;
                      });
                    }),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  void _performDetailSearch() async {
    // 검색 로직 구현
    List<Patient> searchResults = await _searchPatients();
    _showSearchResultsDialog(context, searchResults);
  }

  Future<List<Patient>> _searchPatients() async {
    CollectionReference patientsRef = FirebaseFirestore.instance.collection(
      'patients',
    );

    // 날짜 형식 변환
    String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate!);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate!);

    // 모든 환자 데이터를 가져옵니다.
    QuerySnapshot querySnapshot = await patientsRef.get();

    List<Patient> patients =
        querySnapshot.docs
            .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

    return patients.where((patient) {
      // 날짜 범위 체크
      if (patient.examDate.isBefore(DateTime.parse(formattedStartDate)) ||
          patient.examDate.isAfter(DateTime.parse(formattedEndDate))) {
        return false;
      }

      // 의사 체크 (전체가 아닐 때만 필터링)
      if (selectedDoctor != '전체' && patient.doctor != selectedDoctor) {
        return false;
      }

      // 방 체크 (전체가 아닐 때만 필터링)
      if (selectedRoomForSearch != '전체' &&
          patient.Room != selectedRoomForSearch) {
        return false;
      }

      bool matchesGSF =
          !isGSFSelected ||
          (patient.GSF != null && _matchesOptions(patient.GSF!, gsfOptions));
      bool matchesCSF =
          !isCSFSelected ||
          (patient.CSF != null && _matchesOptions(patient.CSF!, csfOptions));
      bool matchesSig =
          !isSigSelected ||
          (patient.sig != null && _matchesOptions(patient.sig!, sigOptions));

      // 모든 선택된 조건을 만족해야 함
      return matchesGSF && matchesCSF && matchesSig;
    }).toList();
  }

  bool _matchesOptions(Endoscopy endoscopy, Map<String, bool> options) {
    for (var option in options.entries) {
      if (option.value) {
        switch (option.key) {
          case '외래':
          case '검진':
            if (endoscopy.gumjinOrNot != option.key) return false;
            break;
          case '수면':
          case '일반':
            if (endoscopy.sleepOrNot != option.key) return false;
            break;
          case 'Bx':
            if (endoscopy.examDetail.Bx == '없음') return false;
            break;
          case 'CLO':
            if (endoscopy.examDetail.CLO != true) return false;
            break;
          case 'CLO 양성':
            if (endoscopy.examDetail.CLOResult != '+') return false;
            break;
          case 'Polypectomy':
            if (endoscopy.examDetail.polypectomy == '없음') return false;
            break;
          case 'PEG':
            if (endoscopy.examDetail.PEG != true) return false;
            break;
          case '응급':
            if (!endoscopy.examDetail.emergency) return false;
            break;
        }
      }
    }
    return true;
  }

  void _showSearchResultsDialog(BuildContext context, List<Patient> patients) {
    String searchConditions = _getSearchConditionsText();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: const EdgeInsets.all(6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '검색 결과',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: oceanBlue,
                      ),
                    ),
                    Text(
                      '(${patients.length}명)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: oceanBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '검색 조건:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(searchConditions, style: TextStyle(fontSize: 16)),
                SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      return PatientListTile(
                        patient: patients[index],
                        tabController: widget.tabController,
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oceanBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      // Update parent state before closing dialog
                      this.setState(() {
                        // startDate and endDate are already updated in the dialog
                        // so we're just triggering a rebuild of the parent widget
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '닫기',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSearchConditionsText() {
    List<String> conditions = [];

    String dateCondition =
        startDate == endDate
            ? DateFormat('yyyy-MM-dd').format(startDate!)
            : '${DateFormat('yyyy-MM-dd').format(startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(endDate!)}';
    conditions.add('날짜: $dateCondition');

    if (selectedDoctor != '의사') {
      conditions.add('의사: $selectedDoctor');
    }

    if (selectedRoomForSearch != '') {
      conditions.add('방: ${selectedRoomForSearch}번방');
    }

    if (isGSFSelected) {
      List<String> gsfConditions =
          gsfOptions.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      if (gsfConditions.isNotEmpty) {
        conditions.add('위내시경: ${gsfConditions.join(", ")}');
      } else {
        conditions.add('위내시경');
      }
    }

    if (isCSFSelected) {
      List<String> csfConditions =
          csfOptions.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      if (csfConditions.isNotEmpty) {
        conditions.add('대장내시경: ${csfConditions.join(", ")}');
      } else {
        conditions.add('대장내시경');
      }
    }

    if (isSigSelected) {
      List<String> sigConditions =
          sigOptions.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      if (sigConditions.isNotEmpty) {
        conditions.add('S상 결장경: ${sigConditions.join(", ")}');
      } else {
        conditions.add('S상 결장경');
      }
    }

    return conditions.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final List<String> doctors = settingsProvider.doctors;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white.withOpacity(0.95),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, sandyBeige.withOpacity(0.3)],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              startDate == null || endDate == null
                                  ? '날짜를 선택해주세요'
                                  : '${DateFormat('yyyy-MM-dd').format(startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: oceanBlue,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: oceanBlue),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // 배경색을 흰색으로
                              foregroundColor: Colors.grey[600], // 글자색을 연한 회색으로
                              side: BorderSide(
                                color: Color.fromARGB(255, 1, 31, 75),
                                width: 2,
                              ), // 테두리 색상 추가
                              elevation: 0, // 그림자 제거
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            onPressed: () {
                              StatisticsDoctorSelectionDialog.show(
                                context,
                                doctors,
                                startDate,
                                endDate,
                                (selectedDoctorName) {
                                  setState(() {
                                    selectedDoctor = selectedDoctorName;
                                  });
                                },
                                _queryPatients,
                                (isLoading) {
                                  setState(() {
                                    this.isLoading = isLoading;
                                  });
                                },
                              );
                            },
                            child: Text(
                              '의사별 통계',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 8), // Add space between the buttons
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(
                                color: Color.fromARGB(255, 3, 57, 108),
                                width: 2,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            onPressed: _querySummaryPatients,
                            child: Text(
                              '검사 요약',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(
                                color: Color.fromARGB(255, 0, 91, 150),
                                width: 2,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            onPressed: _queryRoomSummary,
                            child: Text(
                              '방별 요약',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 8), // Add space between the buttons
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(
                                color: Color.fromARGB(255, 100, 151, 177),
                                width: 2,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            onPressed:
                                _showYearComparisonDialog, // Define this function
                            child: Text(
                              '년도 비교',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('메일 보내기', style: TextStyle(fontSize: 18)),
                        Icon(Icons.mail_outline_rounded),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                0,
                                76,
                                76,
                              ), // 깊은 버건디
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('세척기 & Scopes'),
                            ),
                            onPressed:
                                () => WashingMachineScopesExcelGenerator.create(
                                  context,
                                  startDate ??
                                      DateTime.now().subtract(
                                        Duration(days: 30),
                                      ),
                                  endDate ?? DateTime.now(),
                                  queryPatientsByDate,
                                  () => setState(() => isLoading = true),
                                  () => setState(() => isLoading = false),
                                  _showSendEmailDialog,
                                  (value) =>
                                      setState(() => progressValue = value),
                                  (message) =>
                                      setState(() => progressMessage = message),
                                ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                102,
                                178,
                                178,
                              ), // 진한 로즈
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('세척기별 일지'),
                            ),
                            onPressed:
                                () => DisinfectantExcelGenerator.show(
                                  context,
                                  () => setState(() => isLoading = true),
                                  () => setState(() => isLoading = false),
                                  _showSendEmailDialog,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                0,
                                128,
                                128,
                              ), // 중간 로즈
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('검사 요약'),
                            ),
                            onPressed: _createExamSummaryExcel,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                0,
                                102,
                                102,
                              ), // 연한 로즈
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('의사 통계'),
                            ),
                            onPressed:
                                () => DoctorStatisticsExcelGenerator.create(
                                  context,
                                  startDate ?? DateTime.now(),
                                  endDate ?? DateTime.now(),
                                  queryPatientsByDate,
                                  () => setState(() => isLoading = true),
                                  () => setState(() => isLoading = false),
                                  _showSendEmailDialog,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Divider(),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '세부 검색',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Checkbox(
                          value: showDetailSearch,
                          onChanged: (value) {
                            setState(() {
                              showDetailSearch = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    if (showDetailSearch) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: '의사',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedDoctor,
                              items:
                                  doctors.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedDoctor = newValue!;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Room',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedRoomForSearch,
                              items:
                                  ['전체', '1', '2', '3'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value == '전체' ? '전체' : '${value}번방',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedRoomForSearch = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          _buildCheckbox('위내시경', isGSFSelected, (value) {
                            setState(() {
                              isGSFSelected = value!;
                            });
                          }),
                          _buildCheckbox('대장내시경', isCSFSelected, (value) {
                            setState(() {
                              isCSFSelected = value!;
                            });
                          }),
                          _buildCheckbox('S상 결장경', isSigSelected, (value) {
                            setState(() {
                              isSigSelected = value!;
                            });
                          }),
                        ],
                      ),
                      if (isGSFSelected) _buildOptionsBox('위내시경', gsfOptions),
                      if (isCSFSelected) _buildOptionsBox('대장내시경', csfOptions),
                      if (isSigSelected) _buildOptionsBox('S상 결장경', sigOptions),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: oceanButtonStyle,
                        onPressed: _performDetailSearch,
                        child: Text('세부 검색 실행'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Column(
            children: [
              LinearProgressIndicator(
                value: progressValue, // Use the progress value
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(oceanBlue),
              ),
              SizedBox(height: 8),
              Text(
                progressMessage, // Display the progress message
                style: TextStyle(color: oceanBlue),
              ),
            ],
          ),
      ],
    );
  }
}

class YearComparisonChart extends StatelessWidget {
  final Map<int, Map<String, List<int>>> yearlyData;
  final String selectedType;
  final bool isCumulative;
  final int? currentYear;
  final int? currentMonth;

  const YearComparisonChart({
    Key? key,
    required this.yearlyData,
    required this.selectedType,
    required this.isCumulative,
    this.currentYear,
    this.currentMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current date if not provided
    final now = DateTime.now();
    final year = currentYear ?? now.year;
    final month = currentMonth ?? now.month;

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: isCumulative ? 1000 : 50, // 누적일 때 1000 단위
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text('${(value + 1).toInt()}월');
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: isCumulative ? 1000 : 50, // 누적일 때 1000 단위
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: _createLineBarsData(year, month),
            ),
          ),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 20,
          alignment: WrapAlignment.center,
          children: _buildLegendItems(),
        ),
      ],
    );
  }

  List<LineChartBarData> _createLineBarsData(
    int currentYear,
    int currentMonth,
  ) {
    List<LineChartBarData> bars = [];
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    int colorIndex = 0;
    yearlyData.forEach((year, typeData) {
      if (selectedType == '전체') {
        List<int> totalData = List.generate(12, (index) {
          // 현재 연도이고 현재 월 이후의 데이터는 0으로 설정
          if (year == currentYear && index >= currentMonth) {
            return 0;
          }
          if (isCumulative) {
            // 누적 데이터 계산
            int sum = 0;
            for (int i = 0; i <= index; i++) {
              sum += typeData['외래']![i] + typeData['검진']![i];
            }
            return sum;
          } else {
            return typeData['외래']![index] + typeData['검진']![index];
          }
        });

        bars.add(
          _createLineChartBarData(
            year,
            totalData,
            colors[colorIndex % colors.length],
            '전체',
          ),
        );
      } else if (selectedType == '외래') {
        List<int> outpatientData = List.generate(12, (index) {
          // 현재 연도이고 현재 월 이후의 데이터는 0으로 설정
          if (year == currentYear && index >= currentMonth) {
            return 0;
          }
          if (isCumulative) {
            // 누적 데이터 계산
            int sum = 0;
            for (int i = 0; i <= index; i++) {
              sum += typeData['외래']![i];
            }
            return sum;
          } else {
            return typeData['외래']![index];
          }
        });

        bars.add(
          _createLineChartBarData(
            year,
            outpatientData,
            colors[colorIndex % colors.length],
            '외래',
          ),
        );
      } else if (selectedType == '검진') {
        List<int> screeningData = List.generate(12, (index) {
          // 현재 연도이고 현재 월 이후의 데이터는 0으로 설정
          if (year == currentYear && index >= currentMonth) {
            return 0;
          }
          if (isCumulative) {
            // 누적 데이터 계산
            int sum = 0;
            for (int i = 0; i <= index; i++) {
              sum += typeData['검진']![i];
            }
            return sum;
          } else {
            return typeData['검진']![index];
          }
        });

        bars.add(
          _createLineChartBarData(
            year,
            screeningData,
            colors[colorIndex % colors.length],
            '검진',
          ),
        );
      }
      colorIndex += 1;
    });

    return bars;
  }

  List<Widget> _buildLegendItems() {
    List<Widget> legendItems = [];
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    int colorIndex = 0;
    yearlyData.forEach((year, typeData) {
      if (selectedType == '전체') {
        legendItems.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 2,
                color: colors[colorIndex % colors.length],
              ),
              SizedBox(width: 4),
              Text('${year}년 전체${isCumulative ? ' (누적)' : ''}'),
            ],
          ),
        );
      } else if (selectedType == '외래') {
        legendItems.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 2,
                color: colors[colorIndex % colors.length],
              ),
              SizedBox(width: 4),
              Text('${year}년 외래${isCumulative ? ' (누적)' : ''}'),
            ],
          ),
        );
      } else if (selectedType == '검진') {
        legendItems.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 2,
                color: colors[colorIndex % colors.length],
              ),
              SizedBox(width: 4),
              Text('${year}년 검진${isCumulative ? ' (누적)' : ''}'),
            ],
          ),
        );
      }
      colorIndex += 1;
    });

    return legendItems;
  }

  LineChartBarData _createLineChartBarData(
    int year,
    List<int> data,
    Color color,
    String type,
  ) {
    return LineChartBarData(
      spots:
          data.asMap().entries.where((entry) => entry.value > 0).map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.toDouble());
          }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class YearlyComparisonChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;

  YearlyComparisonChart({required this.barGroups});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Customize your bottom titles here
                    return Text('Year ${value.toInt()}');
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'Data: ${rod.toY.toString()}',
                    TextStyle(color: Colors.white),
                    children: [
                      TextSpan(
                        text: '\nAdditional Info',
                        style: TextStyle(color: Colors.grey[200], fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LegendItem(color: Colors.red, text: 'Data 1'),
            SizedBox(width: 10),
            LegendItem(color: Colors.green, text: 'Data 2'),
            SizedBox(width: 10),
            LegendItem(color: Colors.blue, text: 'Data 3'),
          ],
        ),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
