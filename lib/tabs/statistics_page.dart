import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data_class/patient_exam.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:syncfusion_officechart/officechart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../provider/patient_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../provider/settings_provider.dart';
import 'package:fl_chart/fl_chart.dart';

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

  Map<String, String> scopyFullName = {
    '039': '7C692K039',
    '073': 'KG391K073',
    '098': '5C692K098',
    '153': '5G391K153',
    '166': '6C692K166',
    '180': '5G391K180',
    '219': '1C664K219',
    '256': '7G391K256',
    '257': '7G391k257',
    '259': '7G391K259',
    '333': '2G348K333',
    '379': '1C665K379',
    '390': '2G348K390',
    '405': '2G348K405',
    '407': '2G348K407',
    '515': '1C666K515',
    '694': '5G348K694',
  };

  Map<String, String> washingMachinesFullName = {
    '1호기': "G0423102",
    '2호기': 'G0423103',
    '3호기': 'G0423104',
    '4호기': 'G0417099',
    '5호기': 'I0210032',
  };

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

  void createDisinfectantChangeLogExcel() async {
    setState(() {
      isLoading = true;
    });

    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String? selectedMachine; // null로 초기화
          List<DateTime> changeDates = [];
          Set<DateTime> selectedDates = {};

          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '세척기별 소독액 일지',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: oceanBlue,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedMachine,
                            isExpanded: true,
                            hint: Text(
                              "세척기 선택",
                              style: TextStyle(color: oceanBlue),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: oceanBlue),
                            style: TextStyle(color: oceanBlue, fontSize: 16),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedMachine = newValue!;
                                selectedDates.clear();
                                fetchChangeDates(selectedMachine!).then((
                                  dates,
                                ) {
                                  setState(() {
                                    changeDates = dates;
                                    changeDates.sort(
                                      (a, b) => b.compareTo(a),
                                    ); // Sort dates in descending order
                                  });
                                });
                              });
                            },
                            items:
                                [
                                  '1호기',
                                  '2호기',
                                  '3호기',
                                  '4호기',
                                  '5호기',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: changeDates.length,
                          itemBuilder: (context, index) {
                            DateTime date = changeDates[index];
                            bool isSelected = selectedDates.contains(date);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isSelected ? oceanBlue : Colors.grey[300],
                                  foregroundColor:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedDates.remove(date);
                                    } else {
                                      selectedDates.add(date);
                                    }
                                  });
                                },
                                child: Text(
                                  DateFormat('yyyy/MM/dd HH:mm').format(date),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('취소'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: oceanBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('확인'),
                            onPressed: () {
                              if (selectedMachine != null &&
                                  selectedDates.isNotEmpty) {
                                createExcelFile(
                                  selectedMachine!,
                                  selectedDates.toList(),
                                );
                                Navigator.of(context).pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '세척기를 선택하고 적어도 하나의 날짜를 선택해주세요.',
                                    ),
                                  ),
                                );
                              }
                            },
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

  Future<List<DateTime>> fetchChangeDates(String machineName) async {
    // Fetch disinfectant change dates from Firestore
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('washingMachines') // Updated collection name
            .doc(machineName)
            .get();

    if (doc.exists) {
      Map<String, dynamic> datesMap = doc['disinfectantChangeDate'];
      List<DateTime> dates =
          datesMap.keys
              .map((dateString) {
                try {
                  return DateTime.parse(dateString);
                } catch (e) {
                  print('Error parsing date: $dateString');
                  return null;
                }
              })
              .where((date) => date != null)
              .cast<DateTime>()
              .toList();
      return dates;
    }
    return [];
  }

  void createExcelFile(String machineName, List<DateTime> changeDates) async {
    final xls.Workbook workbook = xls.Workbook();

    for (int i = 0; i < changeDates.length; i++) {
      DateTime changeDate = changeDates[i];
      xls.Worksheet sheet;

      if (i == 0) {
        // 첫 번째 시트 재사용
        sheet = workbook.worksheets[0];
      } else {
        // 새 시트 추가
        sheet = workbook.worksheets.add();
      }

      String sanitizedName = DateFormat('yyyy-MM-dd HHmm').format(changeDate);
      sheet.name = sanitizedName;

      // 시트 설정 및 데이터 채우기
      setupBasicStructure(sheet, machineName, changeDate);
      await fillData(sheet, machineName, changeDate);
    }

    // 나머지 코드 (파일 저장 등)
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String path = (await getApplicationDocumentsDirectory()).path;
    final String fileName =
        '내시경소독액교환점검표_${machineName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final String filePath = '$path/$fileName';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // 이메일 전송 다이얼로그 표시
    _showSendEmailDialog(filePath, '내시경 소독액 교환 점검표');
  }

  void setupBasicStructure(
    xls.Worksheet sheet,
    String machineName,
    DateTime changeDate,
  ) {
    sheet.pageSetup.orientation = xls.ExcelPageOrientation.landscape;
    // 1행: 제목
    sheet.getRangeByName('A1:J1').merge();
    sheet.getRangeByName('A1').setText('내시경 소독액 교환 점검표');
    sheet.getRangeByName('A1').cellStyle.hAlign = xls.HAlignType.center;

    // 2-3행: 소독제 정보
    sheet.getRangeByName('A2:B3').merge();
    sheet.getRangeByName('A2').setText('소독제명(성분명)');
    sheet.getRangeByName('C2:E3').merge();
    sheet.getRangeByName('C2').setText('페라플루디액 1제 + 2제(0.2% 과아세트산)');

    // 2행: 소독제 교체주기
    sheet.getRangeByName('F2:G2').merge();
    sheet.getRangeByName('F2').setText('소독제 교체주기');
    sheet.getRangeByName('H2:J2').merge();
    sheet.getRangeByName('H2').setText('28day, 80cycle 이하');

    // 4-5행: 세척기 정보
    sheet.getRangeByName('A4:B5').merge();
    sheet.getRangeByName('A4').setText('세척기($machineName)');
    sheet.getRangeByName('C4:E5').merge();
    sheet
        .getRangeByName('C4')
        .setText(washingMachinesFullName[machineName] ?? '');

    // 3-4행: 소독제 교체일
    sheet.getRangeByName('F3:G4').merge();
    sheet.getRangeByName('F3').setText('소독제 교체일');
    sheet.getRangeByName('H3').setText('주입일');
    sheet.getRangeByName('I3:J3').merge();
    sheet
        .getRangeByName('I3')
        .setText(DateFormat('yy년 MM월 dd일').format(changeDate));
    sheet.getRangeByName('H4').setText('배출일');
    sheet.getRangeByName('I4:J4').merge();
    sheet
        .getRangeByName('I4')
        .setText(
          DateFormat('yy년 MM월 dd일').format(changeDate.add(Duration(days: 28))),
        );

    // 6행: 추가 정보
    sheet.getRangeByName('A6:D6').merge();
    sheet.getRangeByName('A6').setText('생검용 겸자 : 일회용 사용(O)');
    sheet.getRangeByName('E6:G6').merge();
    sheet.getRangeByName('E6').setText('부속기구 소독: EO 가스 소독(O)');

    sheet.getRangeByName('H5:J5').merge();
    sheet
        .getRangeByName('H5')
        .setText('28일 안에 80회 초과시, 테스트스트립 결과 500ppm 이하시 교체');
    sheet.getRangeByName('H5').cellStyle.fontSize = 9;

    // 6행: 소독액 유효농도 측정
    sheet.getRangeByName('H6:J6').merge();
    sheet.getRangeByName('H6').setText('소독액 유효농도 측정: 매일 (P:적절, F:부적절)');

    // 7-8행: 표 헤더
    sheet.getRangeByName('A7:A8').merge();
    sheet.getRangeByName('A7').setText('날짜');
    sheet.getRangeByName('B7:B8').merge();
    sheet.getRangeByName('B7').setText('내시경건수');
    sheet.getRangeByName('C7:H7').merge();
    sheet.getRangeByName('C7').setText('소독 단계별 실시건수');
    sheet.getRangeByName('C8').setText('(전)세척');
    sheet.getRangeByName('D8').setText('소독');
    sheet.getRangeByName('E8').setText('헹굼.검조');
    sheet.getRangeByName('F8').setText('보관');
    sheet.getRangeByName('G8').setText('부속기구 소독');
    sheet.getRangeByName('H8').setText('송수병,연결기구소독');
    sheet.getRangeByName('I7:I8').merge();
    sheet.getRangeByName('I7').setText('최소유효농도측정(P/F)');
    sheet.getRangeByName('J7:J8').merge();
    sheet.getRangeByName('J7').setText('소독실무자');

    // 모든 셀에 테두리 추가
    sheet.getRangeByName('A1:J8').cellStyle.borders.all.lineStyle =
        xls.LineStyle.thin;

    // 텍스트 정렬
    sheet.getRangeByName('A1:J8').cellStyle.hAlign = xls.HAlignType.center;
    sheet.getRangeByName('A1:J8').cellStyle.vAlign = xls.VAlignType.center;
  }

  Future<void> fillData(
    xls.Worksheet sheet,
    String machineName,
    DateTime changeDate,
  ) async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('patients')
            .where(
              'examDate',
              isGreaterThanOrEqualTo: DateFormat(
                'yyyy-MM-dd',
              ).format(changeDate),
            )
            .orderBy('examDate')
            .get();

    Map<String, int> dailyCounts = {};
    Map<String, String> dailyWashingChargers = {};
    int totalCount = 0;
    DateTime? lastWashDate;

    for (var doc in querySnapshot.docs) {
      if (totalCount >= 80) break;

      void checkEndoscopy(String type) {
        if (doc[type] != null) {
          doc[type]['scopes'].forEach((scopeName, scopeData) {
            if (scopeData['washingMachine'] == machineName) {
              String examDate = doc['examDate'];
              String washingTime = scopeData['washingTime'];
              DateTime washDateTime = DateTime.parse('$examDate $washingTime');

              if (washDateTime.isAfter(changeDate)) {
                String formattedDate = DateFormat(
                  'yy-MM-dd',
                ).format(washDateTime);
                dailyCounts[formattedDate] =
                    (dailyCounts[formattedDate] ?? 0) + 1;

                String? washingCharger = scopeData['washingCharger'];
                if (washingCharger != null) {
                  dailyWashingChargers[formattedDate] = washingCharger;
                }

                totalCount++;
                lastWashDate = washDateTime;
              }
            }
          });
        }
      }

      checkEndoscopy('GSF');
      checkEndoscopy('CSF');
      checkEndoscopy('sig');
    }

    int rowIndex = 9;
    List<String> sortedDates = dailyCounts.keys.toList();
    sortedDates.sort((a, b) {
      DateTime dateA = DateFormat('yy-MM-dd').parse(a);
      DateTime dateB = DateFormat('yy-MM-dd').parse(b);
      return dateA.compareTo(dateB);
    });

    String lastWashingCharger = '';
    for (var date in sortedDates) {
      int count = dailyCounts[date]!;
      sheet.getRangeByIndex(rowIndex, 1).setText(date);
      sheet.getRangeByIndex(rowIndex, 2).setNumber(count.toDouble());

      // Fill in the same number for columns C to G
      for (int col = 3; col <= 7; col++) {
        sheet.getRangeByIndex(rowIndex, col).setNumber(count.toDouble());
      }

      // Set 1 for column H (송수병,연결기구소독)
      sheet.getRangeByIndex(rowIndex, 8).setNumber(1);

      // Set 'P' for column I (최소유효농도측정)
      sheet.getRangeByIndex(rowIndex, 9).setText('P');

      // Set washingCharger for column J
      lastWashingCharger = dailyWashingChargers[date] ?? lastWashingCharger;
      sheet.getRangeByIndex(rowIndex, 10).setText(lastWashingCharger);

      rowIndex++;
    }

    // 배출일 기록
    if (lastWashDate != null) {
      sheet
          .getRangeByName('I4')
          .setText(DateFormat('yy년 MM월 dd일').format(lastWashDate!));
    }

    // 전체 셀에 좌우 가운데 정렬 적용
    sheet.getRangeByName('A1:J$rowIndex').cellStyle.hAlign =
        xls.HAlignType.center;

    // 전체 셀에 테두리 적용
    sheet.getRangeByName('A1:J$rowIndex').cellStyle.borders.all.lineStyle =
        xls.LineStyle.thin;

    // 열 너비 설정
    sheet.getRangeByName('A1:J1').columnWidth = 10; // 모든 열의 기본 너비를 10으로 설정
    sheet.getRangeByName('C1:C1').columnWidth = 8;
    sheet.getRangeByName('D1:D1').columnWidth = 6;
    sheet.getRangeByName('E1:E1').columnWidth = 10;
    sheet.getRangeByName('F1:F1').columnWidth = 4;
    sheet.getRangeByName('G1:G1').columnWidth = 12;
    sheet.getRangeByName('H1:H1').columnWidth = 16;
    sheet.getRangeByName('I1:I1').columnWidth = 16;

    // C2:E3 셀 병합 및 폰트 크기 설정
    sheet.getRangeByName('C2:E3').merge();
    sheet.getRangeByName('C2:E3').cellStyle.fontSize = 8;

    // I7:I8 셀 병합 및 폰트 크기 설정
    sheet.getRangeByName('I7:I8').merge();
    sheet.getRangeByName('I7:I8').cellStyle.fontSize = 8;
  }

  Future<void> _createDoctorStatisticsExcel() async {
    setState(() {
      isLoading = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final Map<String, String> doctorMap = settingsProvider.doctorMap;

      // 임상/검진 의사 분류
      List<String> clinicalDoctors = [];
      List<String> screeningDoctors = [];
      doctorMap.forEach((doctor, type) {
        if (type == '임상') {
          clinicalDoctors.add(doctor);
        } else if (type == '검진') {
          screeningDoctors.add(doctor);
        }
      });

      final xls.Workbook workbook = xls.Workbook();
      final xls.Worksheet sheet = workbook.worksheets[0];

      final startOfMonth = startDate ?? DateTime.now();
      final endOfMonth = endDate ?? DateTime.now();
      final yearMonth = '${startOfMonth.year}년 ${startOfMonth.month}월';

      sheet.getRangeByName('A1:M1').merge();
      sheet.getRangeByName('A1').setText('$yearMonth 내시경 과별 통계');
      sheet.getRangeByName('A1').cellStyle.fontSize = 14;
      sheet.getRangeByName('A1').cellStyle.bold = true;

      sheet.getRangeByIndex(1, 1).columnWidth = 25;

      for (int i = 2; i <= 13; i++) {
        sheet.getRangeByIndex(1, i).columnWidth = 12;
      }

      sheet.getRangeByName('B2:E2').merge();
      sheet.getRangeByName('B2').setText('위내시경');
      sheet.getRangeByName('F2').setText('PEG');
      sheet.getRangeByName('G2:J2').merge();
      sheet.getRangeByName('G2').setText('대장내시경(용종절제술 시행한 검사)');
      sheet.getRangeByName('K2').setText('S상 결장경');
      sheet.getRangeByName('L2').setText('합계');
      sheet.getRangeByName('M2').setText('검진 합계');

      sheet.getRangeByName('B3:C3').merge();
      sheet.getRangeByName('B3').setText('외래');
      sheet.getRangeByName('D3:E3').merge();
      sheet.getRangeByName('D3').setText('검진');
      sheet.getRangeByName('F2:F4').merge();
      sheet.getRangeByName('G3:H3').merge();
      sheet.getRangeByName('G3').setText('외래');
      sheet.getRangeByName('I3:J3').merge();
      sheet.getRangeByName('I3').setText('검진');
      sheet.getRangeByName('K2:K4').merge();
      sheet.getRangeByName('L2:L4').merge();
      sheet.getRangeByName('M2:M4').merge();

      sheet.getRangeByName('B4').setText('비수면');
      sheet.getRangeByName('C4').setText('수면');
      sheet.getRangeByName('D4').setText('비수면');
      sheet.getRangeByName('E4').setText('수면');
      sheet.getRangeByName('G4').setText('비수면');
      sheet.getRangeByName('H4').setText('수면');
      sheet.getRangeByName('I4').setText('비수면');
      sheet.getRangeByName('J4').setText('수면');

      var headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.backColor = '#D9E1F2';
      headerStyle.hAlign = xls.HAlignType.center;
      headerStyle.vAlign = xls.VAlignType.center;
      headerStyle.bold = true;

      var contentStyle = workbook.styles.add('ContentStyle');
      contentStyle.hAlign = xls.HAlignType.center;
      contentStyle.vAlign = xls.VAlignType.center;

      sheet.getRangeByName('A2:M4').cellStyle = headerStyle;

      // 의사 목록 구성
      List<String> doctors = [
        ...clinicalDoctors,
        '소화기내과 합계',
        ...screeningDoctors,
        '총합계',
      ];

      for (int i = 0; i < doctors.length; i++) {
        sheet.getRangeByIndex(i + 5, 1).setText(doctors[i]);
        sheet.getRangeByIndex(i + 5, 1).cellStyle = contentStyle;
        if (doctors[i].contains('합계')) {
          sheet.getRangeByIndex(i + 5, 1).cellStyle.bold = true;
        }
      }

      List<Patient> patients = await queryPatientsByDate(
        startOfMonth,
        endOfMonth,
      );

      Map<String, List<int>> doctorTotals = {};
      Map<String, List<int>> doctorPolypCounts = {};
      for (String doctor in doctors) {
        doctorTotals[doctor] = List.filled(13, 0);
        doctorPolypCounts[doctor] = List.filled(13, 0);
      }

      for (int i = 0; i < doctors.length; i++) {
        String doctor = doctors[i];
        List<Patient> doctorPatients;

        if (doctor == '소화기내과 합계') {
          doctorPatients =
              patients
                  .where((p) => clinicalDoctors.contains(p.doctor))
                  .toList();
        } else if (doctor == '총합계') {
          doctorPatients = patients;
        } else {
          doctorPatients = patients.where((p) => p.doctor == doctor).toList();
        }

        for (int j = 2; j <= 11; j++) {
          int count = _getCount(doctorPatients, doctor, j);
          if (j >= 7 && j <= 10) {
            // 대장내시경 열
            int polypCount = _getPolypCount(doctorPatients, doctor, j);
            sheet.getRangeByIndex(i + 5, j).setText('$count ($polypCount)');
            doctorPolypCounts[doctor]![j - 2] = polypCount;
          } else {
            sheet.getRangeByIndex(i + 5, j).setValue(count);
          }
          sheet.getRangeByIndex(i + 5, j).cellStyle = contentStyle;
          doctorTotals[doctor]![j - 2] = count;
        }

        // 합계 (L열) 계산
        int sum =
            doctorTotals[doctor]!.sublist(0, 4).reduce((a, b) => a + b) +
            doctorTotals[doctor]!.sublist(5).reduce((a, b) => a + b);
        sheet.getRangeByIndex(i + 5, 12).setValue(sum);
        doctorTotals[doctor]![10] = sum;

        // 검진 합계 (M열) 계산
        int screeningSum =
            doctorTotals[doctor]![2] +
            doctorTotals[doctor]![3] +
            doctorTotals[doctor]![7] +
            doctorTotals[doctor]![8];
        sheet.getRangeByIndex(i + 5, 13).setValue(screeningSum);
        doctorTotals[doctor]![11] = screeningSum;
      }

      // 소화기내과 합계 계산
      int gastroIndex = doctors.indexOf('소화기내과 합계');
      for (int j = 2; j <= 13; j++) {
        int sum = 0;
        int polypSum = 0;
        for (String doctor in clinicalDoctors) {
          sum += doctorTotals[doctor]![j - 2];
          if (j >= 7 && j <= 10) {
            polypSum += doctorPolypCounts[doctor]![j - 2];
          }
        }
        if (j >= 7 && j <= 10) {
          sheet.getRangeByIndex(gastroIndex + 5, j).setText('$sum ($polypSum)');
          doctorPolypCounts['소화기내과 합계']![j - 2] = polypSum;
        } else {
          sheet.getRangeByIndex(gastroIndex + 5, j).setValue(sum);
        }
        doctorTotals['소화기내과 합계']![j - 2] = sum;
      }

      // 총합계 계산 (소화기내과 합계 + 검진 의사)
      int totalIndex = doctors.indexOf('총합계');
      for (int j = 2; j <= 13; j++) {
        int sum = doctorTotals['소화기내과 합계']![j - 2];
        int polypSum = 0;
        for (String doctor in screeningDoctors) {
          sum += doctorTotals[doctor]![j - 2];
          if (j >= 7 && j <= 10) {
            polypSum += doctorPolypCounts[doctor]![j - 2];
          }
        }
        if (j >= 7 && j <= 10) {
          sheet.getRangeByIndex(totalIndex + 5, j).setText('$sum ($polypSum)');
        } else {
          sheet.getRangeByIndex(totalIndex + 5, j).setValue(sum);
        }
        doctorTotals['총합계']![j - 2] = sum;
      }

      // 합계와 소화기내과 합계, 총합계가 만나는 셀들의 스타일 설정
      var highlightStyle = workbook.styles.add('HighlightStyle');
      highlightStyle.bold = true;
      highlightStyle.backColor = '#FFC000'; // 주황색 배경
      highlightStyle.hAlign = xls.HAlignType.center;
      highlightStyle.vAlign = xls.VAlignType.center;

      // 소화기내과 합계 행
      sheet.getRangeByIndex(gastroIndex + 5, 12).cellStyle =
          highlightStyle; // 합계
      sheet.getRangeByIndex(gastroIndex + 5, 13).cellStyle =
          highlightStyle; // 검진 합계

      // 총합계 행
      sheet.getRangeByIndex(totalIndex + 5, 12).cellStyle =
          highlightStyle; // 합계
      sheet.getRangeByIndex(totalIndex + 5, 13).cellStyle =
          highlightStyle; // 검진 합계

      var borderStyle = workbook.styles.add('BorderStyle');
      borderStyle.borders.all.lineStyle = xls.LineStyle.thin;
      sheet
          .getRangeByName('A1:M${totalIndex + 5}')
          .cellStyle
          .borders
          .all
          .lineStyle = xls.LineStyle.thin;

      sheet.getRangeByName('A1:M${totalIndex + 5}').cellStyle.hAlign =
          xls.HAlignType.center;
      sheet.getRangeByName('A1:M${totalIndex + 5}').cellStyle.vAlign =
          xls.VAlignType.center;

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final String path = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          '월별과별통계_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      final String filePath = '$path/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      String subject = '${startOfMonth.year}년 ${startOfMonth.month}월 과장 통계';
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

  int _getPolypCount(List<Patient> patients, String doctor, int column) {
    String examType = 'CSF';
    String gumjinType = (column == 7 || column == 8) ? '외래' : '검진';
    String sleepType = (column == 7 || column == 9) ? '일반' : '수면';

    return patients.where((p) {
      var exam = p.CSF;
      return exam != null &&
          exam.gumjinOrNot == gumjinType &&
          exam.sleepOrNot == sleepType &&
          exam.examDetail.polypectomy != '없음';
    }).length;
  }

  int _getCount(List<Patient> patients, String doctor, int column) {
    switch (column) {
      case 2:
        return _countEndoscopy(patients, 'GSF', '외래', '일반');
      case 3:
        return _countEndoscopy(patients, 'GSF', '외래', '수면');
      case 4:
        return _countEndoscopy(patients, 'GSF', '검진', '일반');
      case 5:
        return _countEndoscopy(patients, 'GSF', '검진', '수면');
      case 6:
        return _countPEG(patients);
      case 7:
        return _countEndoscopy(patients, 'CSF', '외래', '일반');
      case 8:
        return _countEndoscopy(patients, 'CSF', '외래', '수면');
      case 9:
        return _countEndoscopy(patients, 'CSF', '검진', '일반');
      case 10:
        return _countEndoscopy(patients, 'CSF', '검진', '수면');
      case 11:
        return _countSig(patients);
      default:
        return 0;
    }
  }

  int _countEndoscopy(
    List<Patient> patients,
    String examType,
    String gumjinType,
    String sleepType,
  ) {
    return patients.where((p) {
      var exam = examType == 'GSF' ? p.GSF : p.CSF;
      return exam != null &&
          exam.cancel != true && // 취소된 검사는 제외
          exam.gumjinOrNot == gumjinType &&
          exam.sleepOrNot == (sleepType == '수면' ? '수면' : '일반');
    }).length;
  }

  int _countPEG(List<Patient> patients) {
    return patients
        .where(
          (p) =>
              p.GSF != null &&
              p.GSF!.cancel != true && // 취소된 검사는 제외
              p.GSF!.examDetail.PEG == true,
        )
        .length;
  }

  int _countSig(List<Patient> patients) {
    return patients
        .where(
          (p) => p.sig != null && p.sig!.cancel != true, // 취소된 검사는 제외
        )
        .length;
  }

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

  Future<void> _createWashingMachineAndScopesExcelFile() async {
    if (startDate != null && endDate != null) {
      setState(() {
        isLoading = true;
        progressValue = 0.0; // Reset progress value
        progressMessage = 'Initializing...'; // Initial message
      });

      try {
        // Step 1: Fetch machine data
        setState(() {
          progressValue = 0.2;
          progressMessage = 'Fetching machine data...';
        });
        // ... fetch machine data ...

        // Step 2: Fetch patient data
        setState(() {
          progressValue = 0.4;
          progressMessage = 'Fetching patient data...';
        });
        // ... fetch patient data ...

        // Step 3: Process data
        setState(() {
          progressValue = 0.6;
          progressMessage = 'Processing data...';
        });
        // ... process data ...

        // Step 4: Create Excel file
        setState(() {
          progressValue = 0.8;
          progressMessage = 'Creating Excel file...';
        });
        // ... create Excel file ...

        // Step 5: Finalize
        setState(() {
          progressValue = 1.0;
          progressMessage = 'Finalizing...';
        });
        // ... finalize ...

        // 세척기 정보를 가져옵니다.
        Map<String, List<DateTime>> machineData =
            await fetchMachineDisinfectantDates();

        // 각 세척기의 가장 최근 소독액 교환 날짜를 찾습니다.
        Map<String, DateTime> lastChangeDates = {};
        for (var entry in machineData.entries) {
          lastChangeDates[entry.key] = entry.value
              .where((date) => date.isBefore(startDate!))
              .reduce((a, b) => a.isAfter(b) ? a : b);
        }

        // 가장 이른 소독액 교환 날짜부터 endDate까지의 환자 데이터를 가져옵니다.
        DateTime earliestDate = lastChangeDates.values.reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
        List<Patient> patients = await queryPatientsByDate(
          earliestDate,
          endDate!,
        );

        final settingsProvider = Provider.of<SettingsProvider>(
          context,
          listen: false,
        );
        final String selectedWashingCharger =
            settingsProvider.selectedWashingCharger;

        final xls.Workbook workbook = xls.Workbook();
        final xls.Worksheet sheet = workbook.worksheets[0];
        sheet.pageSetup.orientation = xls.ExcelPageOrientation.landscape;

        // 제목 행 추가 및 셀 병합
        sheet.getRangeByName('A1:H1').merge();
        String title =
            '수검자별 내시경 세척 및 소독 일지(${DateFormat('yyyy년 M월').format(DateTime.now())})';
        sheet.getRangeByName('A1').setText(title);
        sheet.getRangeByName('A1').cellStyle.hAlign = xls.HAlignType.center;
        sheet.getRangeByName('A1').cellStyle.fontSize = 14;
        sheet.getRangeByName('A1').cellStyle.bold = true;

        // 헤더 행 추가
        List<String> headers = [
          '날짜',
          '등록번호',
          '이름',
          '담당의',
          '내시경고유번호',
          '시간',
          '세척기번호',
          '소독실무자',
        ];
        for (int i = 0; i < headers.length; i++) {
          sheet.getRangeByIndex(2, i + 1).setText(headers[i]);
          sheet.getRangeByIndex(2, i + 1).cellStyle.hAlign =
              xls.HAlignType.center;
          sheet.getRangeByIndex(2, i + 1).cellStyle.bold = true;
        }

        List<Map<String, dynamic>> allScopeData = [];

        for (Patient patient in patients) {
          void addEndoscopyData(Endoscopy? endoscopy, String examType) {
            if (endoscopy != null) {
              endoscopy.scopes.forEach((scopeName, scopeData) {
                allScopeData.add({
                  'patient': patient,
                  'examType': examType,
                  'scopeName': scopeName,
                  'scopeData': scopeData,
                });
              });
            }
          }

          addEndoscopyData(patient.GSF, 'GSF');
          addEndoscopyData(patient.CSF, 'CSF');
          addEndoscopyData(patient.sig, 'sig');
        }

        // allScopeData를 날짜와 시간으로 정렬
        allScopeData.sort((a, b) {
          int dateComparison = a['patient'].examDate.compareTo(
            b['patient'].examDate,
          );
          if (dateComparison != 0) return dateComparison;
          return (a['scopeData']['washingTime'] ?? '').compareTo(
            b['scopeData']['washingTime'] ?? '',
          );
        });

        int rowIndex = 3;
        String currentDate = '';
        Map<String, int> scopeUsage = {};
        Map<String, int> machineUsage = {};
        int dailyScopeCount = 0;
        int dailyMachineCount = 0;

        Map<String, Map<String, int>> scopeUsageCount = {};

        for (var data in allScopeData) {
          Patient patient = data['patient'];

          // startDate 이전의 데이터는 세척 횟수 계산에만 사용하고 엑셀에는 추가하지 않습니다.
          if (patient.examDate.isBefore(startDate!)) {
            continue;
          }

          String examType = data['examType'];
          String scopeName = data['scopeName'];
          Map<String, String> scopeData = data['scopeData'];

          String scopeNumber = scopyFullName[scopeName] ?? '';
          String washingMachineNumber =
              washingMachinesFullName[scopeData['washingMachine']] ?? '';
          String washingTime = scopeData['washingTime'] ?? '';
          String washingCharger =
              scopeData['washingCharger'] ?? selectedWashingCharger;

          String formattedDate = DateFormat('M월 d일').format(patient.examDate);
          String examDate = DateFormat('yyyy-MM-dd').format(patient.examDate);

          if (!scopeUsageCount.containsKey(examDate)) {
            scopeUsageCount[examDate] = {};
          }
          if (!scopeUsageCount[examDate]!.containsKey(scopeNumber)) {
            scopeUsageCount[examDate]![scopeNumber] = 0;
          }
          scopeUsageCount[examDate]![scopeNumber] =
              (scopeUsageCount[examDate]![scopeNumber] ?? 0) + 1;

          // 여기에서 scopeNumber와 사용 횟수를 결합합니다.
          String scopeNumberWithCount =
              '$scopeNumber/${scopeUsageCount[examDate]![scopeNumber]}';

          if (formattedDate != currentDate) {
            if (currentDate != '') {
              // 날짜가 바뀌면 총 사용 수 추가
              sheet.getRangeByIndex(rowIndex, 1).setText('총 사용 건수');
              sheet.getRangeByIndex(rowIndex, 1).cellStyle.hAlign =
                  xls.HAlignType.center;
              sheet
                  .getRangeByIndex(rowIndex, 5)
                  .setText(dailyScopeCount.toString());
              sheet.getRangeByIndex(rowIndex, 5).cellStyle.hAlign =
                  xls.HAlignType.center;
              sheet
                  .getRangeByIndex(rowIndex, 7)
                  .setText(dailyMachineCount.toString());
              sheet.getRangeByIndex(rowIndex, 7).cellStyle.hAlign =
                  xls.HAlignType.center;
              sheet
                  .getRangeByName('A$rowIndex:H$rowIndex')
                  .cellStyle
                  .borders
                  .all
                  .lineStyle = xls.LineStyle.double;
              rowIndex++;
            }
            currentDate = formattedDate;
            dailyScopeCount = 0;
            dailyMachineCount = 0;
            sheet.getRangeByIndex(rowIndex, 1).setText(formattedDate);
          }

          sheet.getRangeByIndex(rowIndex, 2).setText(patient.id);
          sheet.getRangeByIndex(rowIndex, 3).setText(patient.name);
          sheet.getRangeByIndex(rowIndex, 4).setText(patient.doctor);
          sheet.getRangeByIndex(rowIndex, 5).setText(scopeNumberWithCount);
          sheet.getRangeByIndex(rowIndex, 6).setText(washingTime);

          // 세척 횟수를 계산합니다.
          int washCount = 0;
          if (washingTime.isNotEmpty) {
            DateTime washDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(
              '${DateFormat('yyyy-MM-dd').format(patient.examDate)} $washingTime',
            );
            String machineName = scopeData['washingMachine']!;
            if (machineData.containsKey(machineName)) {
              washCount = await calculateWashCount(
                machineName,
                washDateTime,
                machineData[machineName]!,
                allScopeData,
              );
            }
          }

          sheet
              .getRangeByIndex(rowIndex, 7)
              .setText('$washingMachineNumber / $washCount');
          sheet.getRangeByIndex(rowIndex, 8).setText(washingCharger);

          // 모든 셀에 대해 가운데 정렬 적용
          for (int i = 1; i <= 8; i++) {
            sheet.getRangeByIndex(rowIndex, i).cellStyle.hAlign =
                xls.HAlignType.center;
            sheet.getRangeByIndex(rowIndex, i).cellStyle.borders.all.lineStyle =
                xls.LineStyle.thin;
          }

          rowIndex++;

          // Scope 및 세척기 사용량 집계 (기기세척 제외)
          if (!patient.name.contains('기기세척')) {
            scopeUsage[scopeNumber] = (scopeUsage[scopeNumber] ?? 0) + 1;
            dailyScopeCount++;
          }
          machineUsage[washingMachineNumber] =
              (machineUsage[washingMachineNumber] ?? 0) + 1;
          dailyMachineCount++;
        }

        // 마지막 날짜의 총 사용 수 추가
        sheet.getRangeByIndex(rowIndex, 1).setText('총 사용 건수');
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.hAlign =
            xls.HAlignType.center;
        sheet.getRangeByIndex(rowIndex, 5).setText(dailyScopeCount.toString());
        sheet.getRangeByIndex(rowIndex, 5).cellStyle.hAlign =
            xls.HAlignType.center;
        sheet
            .getRangeByIndex(rowIndex, 7)
            .setText(dailyMachineCount.toString());
        sheet.getRangeByIndex(rowIndex, 7).cellStyle.hAlign =
            xls.HAlignType.center;
        sheet
            .getRangeByName('A$rowIndex:H$rowIndex')
            .cellStyle
            .borders
            .all
            .lineStyle = xls.LineStyle.double;

        rowIndex += 4;

        // Scope 사용 건수 테이블 생성
        sheet.getRangeByIndex(rowIndex, 1).setText('Scope 사용 건수');
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = true;
        rowIndex++;

        int scopeStartRow = rowIndex;
        int totalScopeUsage = 0;
        scopeUsage.forEach((scope, count) {
          sheet.getRangeByIndex(rowIndex, 1).setText(scope);
          sheet.getRangeByIndex(rowIndex, 2).setText(count.toString());
          sheet.getRangeByName('A$rowIndex:B$rowIndex').cellStyle.hAlign =
              xls.HAlignType.center;
          sheet
              .getRangeByName('A$rowIndex:B$rowIndex')
              .cellStyle
              .borders
              .all
              .lineStyle = xls.LineStyle.thin;
          totalScopeUsage += count;
          rowIndex++;
        });
        int scopeEndRow = rowIndex - 1;

        // 총 사용 건수 추가
        sheet.getRangeByIndex(rowIndex, 1).setText('총 사용 건수');
        sheet.getRangeByIndex(rowIndex, 2).setText('$totalScopeUsage개');
        sheet.getRangeByName('A$rowIndex:B$rowIndex').cellStyle.hAlign =
            xls.HAlignType.center;
        sheet
            .getRangeByName('A$rowIndex:B$rowIndex')
            .cellStyle
            .borders
            .all
            .lineStyle = xls.LineStyle.thin;
        sheet.getRangeByName('A$rowIndex:B$rowIndex').cellStyle.bold = true;
        rowIndex += 2;

        // 세척기 사용 건수 테이블 생성
        sheet.getRangeByIndex(rowIndex, 1).setText('세척기 사용 건수');
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = true;
        rowIndex++;

        int machineStartRow = rowIndex;
        int totalMachineUsage = 0;
        machineUsage.forEach((machine, count) {
          sheet.getRangeByIndex(rowIndex, 1).setText(machine);
          sheet.getRangeByIndex(rowIndex, 2).setText(count.toString());
          sheet.getRangeByName('A$rowIndex:B$rowIndex').cellStyle.hAlign =
              xls.HAlignType.center;
          sheet
              .getRangeByName('A$rowIndex:B$rowIndex')
              .cellStyle
              .borders
              .all
              .lineStyle = xls.LineStyle.thin;
          totalMachineUsage += count;
          rowIndex++;
        });
        int machineEndRow = rowIndex - 1;

        // 총 사용 건수 추가
        sheet.getRangeByIndex(rowIndex, 1).setText('총 사용 건수');
        sheet.getRangeByIndex(rowIndex, 2).setText('$totalMachineUsage개');
        sheet.getRangeByName('A$rowIndex:B$rowIndex').cellStyle.hAlign =
            xls.HAlignType.center;
        sheet
            .getRangeByName('A$rowIndex:B$rowIndex')
            .cellStyle
            .borders
            .all
            .lineStyle = xls.LineStyle.thin;
        sheet.getRangeByName('A$rowIndex:B$rowIndex').cellStyle.bold = true;

        // 열 너비 자동 조정
        sheet.autoFitColumn(1);
        sheet.autoFitColumn(2);
        sheet.autoFitColumn(3);
        sheet.autoFitColumn(4);
        sheet.autoFitColumn(5);
        sheet.autoFitColumn(6);
        sheet.autoFitColumn(7);
        sheet.autoFitColumn(8);

        // 차트 생성
        final ChartCollection charts = ChartCollection(sheet);

        // Scope 사용 건수 차트
        final Chart scopeChart = charts.add();
        scopeChart.chartType = ExcelChartType.bar;
        scopeChart.dataRange = sheet.getRangeByName(
          'A$scopeStartRow:B$scopeEndRow',
        );
        scopeChart.isSeriesInRows = false;
        scopeChart.chartTitle = 'Scope 사용 건수';
        scopeChart.chartTitleArea.bold = true;
        scopeChart.topRow = scopeStartRow;
        scopeChart.bottomRow = scopeEndRow + 15;
        scopeChart.leftColumn = 4;
        scopeChart.rightColumn = 10;

        // 세척기 사용 건수 차트
        final Chart machineChart = charts.add();
        machineChart.chartType = ExcelChartType.bar;
        machineChart.dataRange = sheet.getRangeByName(
          'A$machineStartRow:B$machineEndRow',
        );
        machineChart.isSeriesInRows = false;
        machineChart.chartTitle = '세척기 사용 건수';
        machineChart.chartTitleArea.bold = true;
        machineChart.topRow = machineStartRow;
        machineChart.bottomRow = machineEndRow + 15;
        machineChart.leftColumn = 4;
        machineChart.rightColumn = 10;

        final List<int> bytes = workbook.saveAsStream();
        workbook.dispose();

        final String path = (await getApplicationDocumentsDirectory()).path;
        final String fileName =
            '내시경세척및소독일지_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final String filePath = '$path/$fileName';
        final File file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        String subject = '${startDate!.year}년 ${startDate!.month}월 세척&소독일지';
        _showSendEmailDialog(filePath, subject);
      } catch (e) {
        print('Error creating Excel file: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('엑셀 파일 생성 중 오류가 발생했습니다.')));
      } finally {
        setState(() {
          isLoading = false;
          progressMessage = ''; // Clear message when done
        });
      }
    }
  }

  Map<String, int> cumulativeWashCounts = {};

  Future<Map<String, List<DateTime>>> fetchMachineDisinfectantDates() async {
    Map<String, List<DateTime>> machineData = {};
    for (int i = 1; i <= 5; i++) {
      String machineName = '$i호기';
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('washingMachines')
              .doc(machineName)
              .get();

      if (doc.exists) {
        Map<String, dynamic> datesMap = doc['disinfectantChangeDate'] ?? {};
        List<DateTime> dates =
            datesMap.keys
                .map((dateString) {
                  try {
                    return DateTime.parse(dateString);
                  } catch (e) {
                    print('Error parsing date: $dateString');
                    return null;
                  }
                })
                .where((date) => date != null)
                .cast<DateTime>()
                .toList();
        dates.sort((a, b) => b.compareTo(a)); // 날짜를 내림차순으로 정렬
        machineData[machineName] = dates;
      }
    }
    return machineData;
  }

  Future<int> calculateWashCount(
    String machineName,
    DateTime washingTime,
    List<DateTime> changeDates,
    List<Map<String, dynamic>> allScopeData,
  ) async {
    // 세척 시간보다 이전인 가장 최근 교환 날짜를 찾습니다.
    DateTime lastChangeDate = changeDates.firstWhere(
      (date) => date.isBefore(washingTime),
      orElse: () => changeDates.last,
    );

    // 세척액 종류를 확인합니다
    DocumentSnapshot machineDoc =
        await FirebaseFirestore.instance
            .collection('washingMachines')
            .doc(machineName)
            .get();

    Map<String, dynamic> disinfectantChangeDate = Map<String, dynamic>.from(
      machineDoc['disinfectantChangeDate'] ?? {},
    );

    // lastChangeDate를 yyyy-MM-dd 형식의 문자열로 변환
    String changeDateStr = DateFormat('yyyy-MM-dd').format(lastChangeDate);
    String disinfectantType =
        disinfectantChangeDate[changeDateStr] ?? '페라플루디액 1제 + 2제(0.2% 과아세트산)';

    int maxCount = disinfectantType == 'O-프탈알데하이드' ? 60 : 80;

    // 마지막 교환 날짜 이후부터 현재 세척 시간까지의 세척 횟수를 계산합니다.
    int count = 1;
    for (var data in allScopeData) {
      if (data['scopeData']['washingMachine'] == machineName) {
        DateTime dataWashTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          '${DateFormat('yyyy-MM-dd').format(data['patient'].examDate)} ${data['scopeData']['washingTime']}',
        );
        if (dataWashTime.isAfter(lastChangeDate) &&
            dataWashTime.isBefore(washingTime)) {
          count++;
          if (count > maxCount) {
            count = 1;
          }
        } else if (dataWashTime.isAtSameMomentAs(washingTime)) {
          break;
        }
      }
    }
    return count;
  }

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
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        email = prefs.getString('emailAddress') ?? '';
      });
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

      _showSummaryDialog(context, patients);
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

      _showRoomSummaryDialog(context, patients);
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
    List<Patient> currentPatients = patients;
    FirebaseFirestore.instance.collection('settings').doc('doctors').get().then((
      docSnapshot,
    ) {
      if (docSnapshot.exists) {
        Map<String, dynamic> doctorMap = docSnapshot.data()?['doctorMap'] ?? {};
        List<String> doctorNames = doctorMap.keys.toList();
        Set<String> combinedDoctors = Set<String>.from(doctors);
        combinedDoctors.addAll(doctorNames);
        combinedDoctors.remove('의사');
        List<String> updatedDoctors = combinedDoctors.toList()..sort();

        String currentDoctor = selectedDoctor;
        if (!updatedDoctors.contains(currentDoctor)) {
          currentDoctor = updatedDoctors.isNotEmpty ? updatedDoctors[0] : '의사';
        }

        // 변수들을 StatefulBuilder 외부에서 선언
        Map<String, dynamic> stats = {};

        // 통계 계산 함수를 Future로 변경
        Future<Map<String, dynamic>> calculateStats(String doctor) async {
          currentPatients = await queryPatientsByDateAndDoctor(
            startDate!,
            endDate!,
            doctor,
          );
          List<Patient> filteredPatients =
              currentPatients.where((p) => p.doctor == doctor).toList();

          int gsfGumjin =
              filteredPatients
                  .where((p) => p.GSF != null && p.GSF!.gumjinOrNot == '검진')
                  .length;
          int gsfNonGumjin =
              filteredPatients
                  .where((p) => p.GSF != null && p.GSF!.gumjinOrNot == '외래')
                  .length;

          int csfGumjin =
              filteredPatients
                  .where((p) => p.CSF != null && p.CSF!.gumjinOrNot == '검진')
                  .length;
          int csfGumjinNoPolyp =
              filteredPatients
                  .where(
                    (p) =>
                        p.CSF != null &&
                        p.CSF!.gumjinOrNot == '검진' &&
                        p.CSF!.examDetail.polypectomy == '없음',
                  )
                  .length;
          int csfGumjinWithPolyp = csfGumjin - csfGumjinNoPolyp;

          int csfNonGumjin =
              filteredPatients
                  .where((p) => p.CSF != null && p.CSF!.gumjinOrNot == '외래')
                  .length;
          int csfNonGumjinNoPolyp =
              filteredPatients
                  .where(
                    (p) =>
                        p.CSF != null &&
                        p.CSF!.gumjinOrNot == '외래' &&
                        p.CSF!.examDetail.polypectomy == '없음',
                  )
                  .length;
          int csfNonGumjinWithPolyp = csfNonGumjin - csfNonGumjinNoPolyp;

          int totalLowerEndoscopies = csfNonGumjin + csfGumjin;
          int polypectomyCount =
              filteredPatients
                  .where(
                    (p) =>
                        p.CSF != null && p.CSF!.examDetail.polypectomy != '없음',
                  )
                  .length;
          double polypDetectionRate =
              totalLowerEndoscopies > 0
                  ? (polypectomyCount / totalLowerEndoscopies) * 100
                  : 0;
          int totalEndoscopies =
              gsfGumjin + gsfNonGumjin + totalLowerEndoscopies;

          return {
            'gsfGumjin': gsfGumjin,
            'gsfNonGumjin': gsfNonGumjin,
            'csfGumjin': csfGumjin,
            'csfGumjinNoPolyp': csfGumjinNoPolyp,
            'csfGumjinWithPolyp': csfGumjinWithPolyp,
            'csfNonGumjin': csfNonGumjin,
            'csfNonGumjinNoPolyp': csfNonGumjinNoPolyp,
            'csfNonGumjinWithPolyp': csfNonGumjinWithPolyp,
            'totalLowerEndoscopies': totalLowerEndoscopies,
            'polypectomyCount': polypectomyCount,
            'polypDetectionRate': polypDetectionRate,
            'totalEndoscopies': totalEndoscopies,
          };
        }

        // 초기 통계 계산
        calculateStats(currentDoctor).then((initialStats) {
          stats = initialStats;

          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  String dateRangeText =
                      '${DateFormat('yy/MM/dd').format(startDate!)} ~ ${DateFormat('yy/MM/dd').format(endDate!)}';

                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '의사별 통계',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: oceanBlue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: seafoamGreen.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: oceanBlue.withAlpha((0.3 * 255).round()),
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: currentDoctor,
                              isExpanded: true,
                              underline: SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: oceanBlue,
                              ),
                              items:
                                  updatedDoctors.map((String doctor) {
                                    return DropdownMenuItem<String>(
                                      value: doctor,
                                      child: Text(doctor),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) async {
                                if (newValue != null) {
                                  // 새로운 의사에 대한 통계 계산
                                  Map<String, dynamic> newStats =
                                      await calculateStats(newValue);
                                  setState(() {
                                    currentDoctor = newValue;
                                    stats = newStats;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              dateRangeText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildStatisticItem(
                            '위내시경',
                            '검진: ${stats['gsfGumjin']}',
                            '외래: ${stats['gsfNonGumjin']}',
                          ),
                          _buildStatisticItem(
                            '대장내시경',
                            '검진: ${stats['csfGumjin']} (${stats['csfGumjinNoPolyp']}/${stats['csfGumjinWithPolyp']})',
                            '외래: ${stats['csfNonGumjin']} (${stats['csfNonGumjinNoPolyp']}/${stats['csfNonGumjinWithPolyp']})',
                          ),
                          _buildStatisticItem(
                            '용종 발견율',
                            '${stats['polypDetectionRate'].toStringAsFixed(2)}%',
                            '',
                            color: Colors.blue,
                          ),
                          _buildStatisticItem(
                            '총 내시경 개수',
                            stats['totalEndoscopies'].toString(),
                            '',
                            color: Colors.red,
                          ),
                          SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
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
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '닫기',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
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
        });
      } else {
        _showResultsDialogWithCurrentDoctors(context, patients);
      }
    });
  }

  void _showResultsDialogWithCurrentDoctors(
    BuildContext context,
    List<Patient> patients,
  ) {
    String currentDoctor = selectedDoctor;

    // Ensure selected doctor is in the list
    if (!doctors.contains(currentDoctor)) {
      currentDoctor = doctors.isNotEmpty ? doctors[0] : '의사';
    }

    // Show dialog with existing doctors list
    // (Insert similar dialog code as above but using doctors instead of updatedDoctors)
    // ...
  }

  Widget _buildStatisticItem(
    String label,
    String value1,
    String value2, {
    Color color = Colors.black,
  }) {
    bool isSingleLine = ['위내시경', '용종 발견율', '총 내시경 개수'].contains(label);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSingleLine)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: oceanBlue,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    value2.isEmpty ? value1 : '$value1 / $value2',
                    style: TextStyle(fontSize: 14, color: color),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: oceanBlue,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value1,
                        style: TextStyle(fontSize: 14, color: color),
                      ),
                    ),
                    if (value2.isNotEmpty)
                      Expanded(
                        child: Text(
                          value2,
                          style: TextStyle(fontSize: 14, color: color),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          if (label == '대장내시경')
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '* (용종절제술 무 / 용종절제술 유)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSummaryDialog(BuildContext context, List<Patient> patients) {
    String dateRangeText =
        '(${DateFormat('yyyy/MM/dd').format(startDate!)} - ${DateFormat('yyyy/MM/dd').format(endDate!)})';

    int gsfGumjin =
        patients
            .where((p) => p.GSF != null && p.GSF!.gumjinOrNot == '검진')
            .length;
    int gsfNonGumjin =
        patients
            .where((p) => p.GSF != null && p.GSF!.gumjinOrNot == '외래')
            .length;
    int csfGumjin =
        patients
            .where((p) => p.CSF != null && p.CSF!.gumjinOrNot == '검진')
            .length;
    int csfNonGumjin =
        patients
            .where((p) => p.CSF != null && p.CSF!.gumjinOrNot == '외래')
            .length;
    int sigCount = patients.where((p) => p.sig != null).length;

    List<TableRow> rows1 = [
      TableRow(
        children: [
          TableCell(child: Center(child: Text(''))),
          TableCell(child: Center(child: Text('검진'))),
          TableCell(child: Center(child: Text('외래'))),
          TableCell(child: Center(child: Text('총합수'))),
        ],
      ),
      _buildTableRow('위내시경', gsfGumjin, gsfNonGumjin),
      _buildTableRow('대장내시경', csfGumjin, csfNonGumjin),
    ];

    if (sigCount > 0) {
      rows1.add(_buildTableRow('S상 결장경', 0, sigCount));
    }

    rows1.add(
      _buildTableRow(
        '총합수',
        gsfGumjin + csfGumjin,
        gsfNonGumjin + csfNonGumjin + sigCount,
      ),
    );

    int gsfBxCount =
        patients
            .where((p) => p.GSF != null && p.GSF!.examDetail.Bx != '없음')
            .length;
    int gsfBxTotal = patients
        .where((p) => p.GSF != null)
        .fold(0, (sum, p) => sum + (int.tryParse(p.GSF!.examDetail.Bx) ?? 0));

    int gsfPolypCount =
        patients
            .where(
              (p) => p.GSF != null && p.GSF!.examDetail.polypectomy != '없음',
            )
            .length;
    int gsfPolypTotal = patients
        .where((p) => p.GSF != null)
        .fold(
          0,
          (sum, p) => sum + (int.tryParse(p.GSF!.examDetail.polypectomy) ?? 0),
        );

    int csfBxCount =
        patients
            .where((p) => p.CSF != null && p.CSF!.examDetail.Bx != '없음')
            .length;
    int csfBxTotal = patients
        .where((p) => p.CSF != null)
        .fold(0, (sum, p) => sum + (int.tryParse(p.CSF!.examDetail.Bx) ?? 0));

    int csfPolypCount =
        patients
            .where(
              (p) => p.CSF != null && p.CSF!.examDetail.polypectomy != '없음',
            )
            .length;
    int csfPolypTotal = patients
        .where((p) => p.CSF != null)
        .fold(
          0,
          (sum, p) => sum + (int.tryParse(p.CSF!.examDetail.polypectomy) ?? 0),
        );

    String formatCount(int count, int total) {
      if (count == 0) return '0';
      return '$count ($total)';
    }

    List<List<String>> table1Data = [
      ['', '검진', '외래', '총합수'],
      [
        '위내시경',
        gsfGumjin.toString(),
        gsfNonGumjin.toString(),
        (gsfGumjin + gsfNonGumjin).toString(),
      ],
      [
        '대장내시경',
        csfGumjin.toString(),
        csfNonGumjin.toString(),
        (csfGumjin + csfNonGumjin).toString(),
      ],
      ['S상결장경', '0', sigCount.toString(), sigCount.toString()],
      [
        '총합수',
        (gsfGumjin + csfGumjin).toString(),
        (gsfNonGumjin + csfNonGumjin + sigCount).toString(),
        (gsfGumjin + gsfNonGumjin + csfGumjin + csfNonGumjin + sigCount)
            .toString(),
      ],
    ];

    List<List<String>> table2Data = [
      ['', 'Bx', '절제술', 'CLO'],
      [
        '위내시경',
        formatCount(gsfBxCount, gsfBxTotal),
        formatCount(gsfPolypCount, gsfPolypTotal),
        patients
            .where((p) => p.GSF != null && p.GSF!.examDetail.CLO == true)
            .length
            .toString(),
      ],
      [
        '대장내시경',
        formatCount(csfBxCount, csfBxTotal),
        formatCount(csfPolypCount, csfPolypTotal),
        '',
      ],
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '검사 요약',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: oceanBlue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    dateRangeText,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  _buildSummaryTable(table1Data),
                  SizedBox(height: 24),
                  _buildSummaryTable(table2Data),
                  SizedBox(height: 24),
                  Text(
                    '환자 목록',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: oceanBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      return PatientListTile(
                        patient: patients[index],
                        tabController: widget.tabController,
                      );
                    },
                  ),
                  SizedBox(height: 24),
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '닫기',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showYearComparisonDialog() async {
    List<int> selectedYears = [];
    String selectedType = '전체'; // '전체', '외래', '검진'
    bool isCumulative = false; // 누적 표시 여부를 추적하는 새 변수

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
                            isCumulative: isCumulative, // 새 파라미터 전달
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

  Widget _buildSummaryTable(List<List<String>> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          columnWidths: {
            0: FlexColumnWidth(2),
            for (var i = 1; i < data[0].length; i++) i: FlexColumnWidth(1),
          },
          children:
              data.asMap().entries.map((entry) {
                int idx = entry.key;
                List<String> row = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color:
                        idx == 0 ? seafoamGreen.withOpacity(0.1) : Colors.white,
                  ),
                  children:
                      row.asMap().entries.map((cellEntry) {
                        int cellIdx = cellEntry.key;
                        String cellData = cellEntry.value;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Center(
                            child: Text(
                              cellData,
                              style: TextStyle(
                                fontSize: idx == 0 ? 14 : 13,
                                fontWeight:
                                    idx == 0 || cellIdx == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    idx == 0 || cellIdx == 0
                                        ? oceanBlue
                                        : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                );
              }).toList(),
        ),
      ),
    );
  }

  void _showRoomSummaryDialog(BuildContext context, List<Patient> patients) {
    String dateRangeText =
        '(${DateFormat('yyyy/MM/dd').format(startDate!)} - ${DateFormat('yyyy/MM/dd').format(endDate!)})';

    Map<String, Map<String, Map<String, int>>> roomData = {
      '1': {},
      '2': {},
      '3': {},
    };
    Map<String, Map<String, int>> totalData = {
      '1': {'G': 0, 'C': 0, 'S': 0}, // S 추가
      '2': {'G': 0, 'C': 0, 'S': 0}, // S 추가
      '3': {'G': 0, 'C': 0, 'S': 0}, // S 추가
    };

    DateTime currentDate = startDate!;
    while (!currentDate.isAfter(endDate!)) {
      String formattedCurrentDate = DateFormat(
        'yyyy-MM-dd',
      ).format(currentDate);
      for (String room in ['1', '2', '3']) {
        roomData[room]![formattedCurrentDate] = {
          'G': 0,
          'C': 0,
          'S': 0,
        }; // S 추가
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    for (Patient patient in patients) {
      String examDate = DateFormat('yyyy-MM-dd').format(patient.examDate);
      if (patient.Room.isNotEmpty &&
          roomData.containsKey(patient.Room) &&
          roomData[patient.Room]!.containsKey(examDate)) {
        if (patient.GSF != null) {
          roomData[patient.Room]![examDate]!['G'] =
              (roomData[patient.Room]![examDate]!['G'] ?? 0) + 1;
          totalData[patient.Room]!['G'] =
              (totalData[patient.Room]!['G'] ?? 0) + 1;
        }
        if (patient.CSF != null) {
          roomData[patient.Room]![examDate]!['C'] =
              (roomData[patient.Room]![examDate]!['C'] ?? 0) + 1;
          totalData[patient.Room]!['C'] =
              (totalData[patient.Room]!['C'] ?? 0) + 1;
        }
        if (patient.sig != null) {
          // S상결장경 데이터 추가
          roomData[patient.Room]![examDate]!['S'] =
              (roomData[patient.Room]![examDate]!['S'] ?? 0) + 1;
          totalData[patient.Room]!['S'] =
              (totalData[patient.Room]!['S'] ?? 0) + 1;
        }
      }
    }

    List<List<String>> tableData = [
      ['날짜', '1번방', '2번방', '3번방'],
    ];

    String formatRoomData(Map<String, int> data) {
      List<String> parts = [];
      if (data['G']! > 0) parts.add(data['G'].toString());
      if (data['C']! > 0) parts.add(data['C'].toString());
      if (data['S']! > 0) parts.add(data['S'].toString());
      return parts.isEmpty ? '' : parts.join('/');
    }

    currentDate = startDate!;
    while (!currentDate.isAfter(endDate!)) {
      String formattedCurrentDate = DateFormat(
        'yyyy-MM-dd',
      ).format(currentDate);
      tableData.add([
        DateFormat('MM/dd').format(currentDate),
        formatRoomData(roomData['1']![formattedCurrentDate]!),
        formatRoomData(roomData['2']![formattedCurrentDate]!),
        formatRoomData(roomData['3']![formattedCurrentDate]!),
      ]);
      currentDate = currentDate.add(Duration(days: 1));
    }

    tableData.add([
      '총합',
      formatRoomData(totalData['1']!),
      formatRoomData(totalData['2']!),
      formatRoomData(totalData['3']!),
    ]);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '방별 요약(위/대장/S상)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: oceanBlue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  dateRangeText,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildRoomSummaryTable(tableData),
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
                    onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildRoomSummaryTable(List<List<String>> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double tableWidth = constraints.maxWidth;
        double dateColumnWidth = tableWidth * 0.25; // 날짜 열에 25% 할당
        double roomColumnWidth = (tableWidth - dateColumnWidth) / 3; // 나머지를 3등분

        return Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          columnWidths: {
            0: FixedColumnWidth(dateColumnWidth),
            1: FixedColumnWidth(roomColumnWidth),
            2: FixedColumnWidth(roomColumnWidth),
            3: FixedColumnWidth(roomColumnWidth),
          },
          children:
              data.asMap().entries.map((entry) {
                int index = entry.key;
                List<String> row = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color:
                        index == 0
                            ? seafoamGreen.withOpacity(0.1)
                            : (index % 2 == 0
                                ? Colors.grey[100]
                                : Colors.white),
                  ),
                  children:
                      row.asMap().entries.map((cellEntry) {
                        int cellIndex = cellEntry.key;
                        String cell = cellEntry.value;
                        return TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                cell,
                                style: TextStyle(
                                  fontWeight:
                                      index == 0 || cellIndex == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      index == 0 || cellIndex == 0
                                          ? oceanBlue
                                          : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              }).toList(),
        );
      },
    );
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
                    onPressed: () => Navigator.of(context).pop(),
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

  void _showDoctorSelectionDialog(BuildContext context, List<String> doctors) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '의사 선택',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: oceanBlue,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      //print(doctors[index]);
                      // Skip the placeholder "의사" option
                      if (doctors[index] == '의사') return SizedBox.shrink();

                      return ListTile(
                        title: Text(
                          doctors[index],
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: oceanBlue,
                          size: 16,
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();

                          // Set the selected doctor and query patients
                          setState(() {
                            selectedDoctor = doctors[index];
                          });

                          if (startDate != null && endDate != null) {
                            setState(() {
                              isLoading = true;
                            });

                            setState(() {
                              isLoading = false;
                            });

                            _queryPatients();
                          }
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
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
                              _showDoctorSelectionDialog(context, doctors);
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
                            onPressed: _createWashingMachineAndScopesExcelFile,
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
                            onPressed: createDisinfectantChangeLogExcel,
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
                            onPressed: _createDoctorStatisticsExcel,
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

class PatientListTile extends StatelessWidget {
  final Patient patient;
  final TabController tabController;

  const PatientListTile({
    Key? key,
    required this.patient,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String truncateName(String name) {
      if (name.length <= 4) {
        return name;
      } else {
        return name.substring(0, 4) + '...';
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '${truncateName(patient.name)}(${patient.gender}/${patient.age})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: oceanBlue,
                      ),
                    ),
                    SizedBox(width: 2),
                    if (patient.GSF != null) _buildDetailBox('G', patient.GSF!),
                    if (patient.CSF != null) _buildDetailBox('C', patient.CSF!),
                    if (patient.sig != null) _buildDetailBox('S', patient.sig!),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Text(
            'at ${DateFormat('yy/MM/dd').format(patient.examDate)} by ${patient.doctor}',
            style: TextStyle(fontSize: 14),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEndoscopyDetails(patient.GSF, '위내시경'),
                  _buildEndoscopyDetails(patient.CSF, '대장내시경'),
                  _buildEndoscopyDetails(patient.sig, 'S상 결장경'),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      style: seafoamButtonStyle,
                      onPressed: () {
                        Provider.of<PatientProvider>(
                          context,
                          listen: false,
                        ).setPatient(patient);
                        Navigator.of(context).pop();
                        tabController.animateTo(0);
                      },
                      child: Text('수정'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          trailing: SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildDetailBox(String prefix, Endoscopy endoscopy) {
    List<String> details = [];
    if (endoscopy.examDetail.Bx != '없음') details.add('Bx');
    if (endoscopy.examDetail.polypectomy != '없음') details.add('P');
    if (endoscopy.examDetail.CLO == true) {
      String cloResult = endoscopy.examDetail.CLOResult ?? '';
      if (cloResult == '+') {
        details.add('CLO 양성');
      } else if (cloResult == '-') {
        details.add('CLO 음성');
      } else {
        details.add('CLO 미정');
      }
    }
    return Container(
      margin: EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: seafoamGreen),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        details.isEmpty ? prefix : '$prefix(${details.join(',')})',
        style: TextStyle(fontSize: 12, color: oceanBlue),
      ),
    );
  }

  Widget _buildEndoscopyDetails(Endoscopy? endoscopy, String title) {
    if (endoscopy == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${endoscopy.gumjinOrNot}/${endoscopy.sleepOrNot})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: oceanBlue,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              endoscopy.scopes.keys
                  .map(
                    (scope) => Chip(
                      label: Text(scope),
                      backgroundColor: seafoamGreen.withOpacity(0.3),
                    ),
                  )
                  .toList(),
        ),
        SizedBox(height: 8),
        if (endoscopy.examDetail.Bx.isNotEmpty &&
            endoscopy.examDetail.Bx != '없음')
          _buildDetailItem(
            Icons.content_paste,
            '조직검사: ${endoscopy.examDetail.Bx}',
          ),
        if (endoscopy.examDetail.polypectomy.isNotEmpty &&
            endoscopy.examDetail.polypectomy != '없음')
          _buildDetailItem(
            Icons.attach_file,
            '용종절제술: ${endoscopy.examDetail.polypectomy}',
          ),
        if (endoscopy.examDetail.emergency)
          _buildDetailItem(Icons.warning, '응급'),
        if (endoscopy.examDetail.CLO == true &&
            endoscopy.examDetail.CLOResult == "+")
          _buildDetailItem(Icons.science, 'CLO 양성'),
        if (endoscopy.examDetail.CLO == true &&
            endoscopy.examDetail.CLOResult == "-")
          _buildDetailItem(Icons.science, 'CLO 음성'),
        if (endoscopy.examDetail.CLO == true &&
            endoscopy.examDetail.CLOResult == "")
          _buildDetailItem(Icons.science, 'CLO 미정'),
        if (endoscopy.examDetail.PEG == true)
          _buildDetailItem(Icons.business_center, 'PEG 시행'),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: oceanBlue),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

class YearComparisonChart extends StatelessWidget {
  final Map<int, Map<String, List<int>>> yearlyData;
  final String selectedType;
  final bool isCumulative;

  const YearComparisonChart({
    Key? key,
    required this.yearlyData,
    required this.selectedType,
    required this.isCumulative,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              lineBarsData: _createLineBarsData(),
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

  List<LineChartBarData> _createLineBarsData() {
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
