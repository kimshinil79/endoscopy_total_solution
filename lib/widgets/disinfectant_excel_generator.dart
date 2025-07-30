import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';

class DisinfectantExcelGenerator {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void show(
    BuildContext context,
    VoidCallback setLoadingTrue,
    VoidCallback setLoadingFalse,
    Function(String, String) showSendEmailDialog,
  ) async {
    setLoadingTrue();

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
                                  showSendEmailDialog,
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
      setLoadingFalse();
    }
  }

  static Future<List<DateTime>> fetchChangeDates(String machineName) async {
    // Fetch disinfectant change dates from Firestore
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('washingMachines') // Updated collection name
              .doc(machineName)
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final datesData = data['disinfectantChangeDate'];

        if (datesData != null && datesData is Map) {
          Map<String, dynamic> datesMap = Map<String, dynamic>.from(datesData);
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
      }
    } catch (e) {
      print('Error fetching change dates: $e');
    }
    return [];
  }

  static void createExcelFile(
    String machineName,
    List<DateTime> changeDates,
    Function(String, String) showSendEmailDialog,
  ) async {
    final xls.Workbook workbook = xls.Workbook();

    // Get washingMachinesFullName from Firebase
    DocumentSnapshot settingsDoc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('washingMachines')
            .get();

    Map<String, String> washingMachinesFullName = {};
    try {
      if (settingsDoc.exists && settingsDoc.data() != null) {
        final data = settingsDoc.data();
        if (data is Map<String, dynamic>) {
          washingMachinesFullName = Map<String, String>.from(data);
        }
      }
    } catch (e) {
      print('Error loading washing machine names: $e');
      // Use default names if Firebase data is not available
      washingMachinesFullName = {
        '1호기': 'Olympus OER-4 201510 F5CAS00063',
        '2호기': 'Olympus OER-4 201510 F5CAS00012',
        '3호기': 'Olympus OER-4 201510 F5CAS00065',
        '4호기': 'Olympus OER-4 201510 F5CAS00011',
        '5호기': 'Olympus OER-4 201510 F5CAS00025',
      };
    }

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
      setupBasicStructure(
        sheet,
        machineName,
        changeDate,
        washingMachinesFullName,
      );
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
    showSendEmailDialog(filePath, '내시경 소독액 교환 점검표');
  }

  static void setupBasicStructure(
    xls.Worksheet sheet,
    String machineName,
    DateTime changeDate,
    Map<String, String> washingMachinesFullName,
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

  static Future<void> fillData(
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
        try {
          final docData = doc.data() as Map<String, dynamic>?;
          if (docData != null && docData[type] != null) {
            final examData = docData[type];
            if (examData is Map && examData['scopes'] != null) {
              final scopes = examData['scopes'] as Map<String, dynamic>;
              scopes.forEach((scopeName, scopeData) {
                if (scopeData is Map &&
                    scopeData['washingMachine'] == machineName) {
                  try {
                    String examDate = docData['examDate']?.toString() ?? '';
                    String washingTime =
                        scopeData['washingTime']?.toString() ?? '';

                    if (examDate.isNotEmpty && washingTime.isNotEmpty) {
                      DateTime washDateTime = DateTime.parse(
                        '$examDate $washingTime',
                      );

                      if (washDateTime.isAfter(changeDate)) {
                        String formattedDate = DateFormat(
                          'yy-MM-dd',
                        ).format(washDateTime);
                        dailyCounts[formattedDate] =
                            (dailyCounts[formattedDate] ?? 0) + 1;

                        String? washingCharger =
                            scopeData['washingCharger']?.toString();
                        if (washingCharger != null &&
                            washingCharger.isNotEmpty) {
                          dailyWashingChargers[formattedDate] = washingCharger;
                        }

                        totalCount++;
                        lastWashDate = washDateTime;
                      }
                    }
                  } catch (e) {
                    print('Error parsing datetime for $type: $e');
                  }
                }
              });
            }
          }
        } catch (e) {
          print('Error processing $type data: $e');
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
}
