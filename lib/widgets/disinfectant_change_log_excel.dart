import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:syncfusion_officechart/officechart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class DisinfectantChangeLogExcel {
  static const Color oceanBlue = Color(0xFF1A5F7A);

  static const Map<String, String> washingMachinesFullName = {
    '1호기': 'SOLUSCOPE STERIL 10 AUTO',
    '2호기': 'SOLUSCOPE STERIL 10 AUTO',
    '3호기': 'SOLUSCOPE STERIL 10 AUTO',
    '4호기': 'SOLUSCOPE STERIL 10 AUTO',
    '5호기': 'SOLUSCOPE STERIL 10 AUTO',
  };

  static void show(
    BuildContext context,
    Function(bool) setLoading,
    Function(BuildContext, String, String) showSendEmailDialog,
  ) async {
    setLoading(true);

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
                                _fetchChangeDates(selectedMachine!).then((
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
                                _createExcelFile(
                                  context,
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
      setLoading(false);
    }
  }

  static Future<List<DateTime>> _fetchChangeDates(String machineName) async {
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

  static void _createExcelFile(
    BuildContext context,
    String machineName,
    List<DateTime> changeDates,
    Function(BuildContext, String, String) showSendEmailDialog,
  ) async {
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
      _setupBasicStructure(sheet, machineName, changeDate);
      await _fillData(sheet, machineName, changeDate);
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
    showSendEmailDialog(context, filePath, '내시경 소독액 교환 점검표');
  }

  static void _setupBasicStructure(
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
    sheet.getRangeByName('A6').setText('사용량 확인(소독액 보충 또는 교체 시)');
    sheet.getRangeByName('E6:J6').merge();
    sheet
        .getRangeByName('E6')
        .setText('10L/3.1L = 3.2배 (1제), 10L/0.9L = 11.1배 (2제)');

    // 테이블 헤더 설정
    final List<String> headers = [
      '일자',
      '시간',
      '온도(℃)',
      'MRC\n확인',
      '소독액\n농도\n(ppm)',
      '세척\n사이클\n수',
      '누적\n사이클\n수',
      '점검자',
      '특이\n사항',
      '확인자\n서명',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(7, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.hAlign = xls.HAlignType.center;
      cell.cellStyle.vAlign = xls.VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = xls.LineStyle.thin;
      cell.cellStyle.color = '#E8E8E8';
    }
  }

  static Future<void> _fillData(
    xls.Worksheet sheet,
    String machineName,
    DateTime changeDate,
  ) async {
    DateTime startDate = changeDate;
    DateTime endDate = changeDate.add(Duration(days: 28));

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .where(
                'examDate',
                isGreaterThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(startDate),
              )
              .where(
                'examDate',
                isLessThan: DateFormat('yyyy-MM-dd').format(endDate),
              )
              .get();

      Map<String, int> dailyCounts = {};
      Map<String, Set<String>> dailyInspectors = {};

      for (var doc in querySnapshot.docs) {
        String examDate = doc['examDate'];

        // GSF, CSF, sig 스코프들을 모두 확인
        ['GSF', 'CSF', 'sig'].forEach((examType) {
          if (doc[examType] != null && doc[examType]['scopes'] != null) {
            Map<String, dynamic> scopes = doc[examType]['scopes'];
            scopes.forEach((scopeName, scopeData) {
              if (scopeData['washingMachine'] == machineName) {
                dailyCounts[examDate] = (dailyCounts[examDate] ?? 0) + 1;
                if (scopeData['washingCharger'] != null) {
                  dailyInspectors[examDate] ??= <String>{};
                  dailyInspectors[examDate]!.add(scopeData['washingCharger']);
                }
              }
            });
          }
        });
      }

      int row = 8;
      int cumulativeCount = 0;
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        int dayCount = dailyCounts[dateKey] ?? 0;
        cumulativeCount += dayCount;

        // 날짜
        sheet
            .getRangeByIndex(row, 1)
            .setText(DateFormat('MM/dd').format(currentDate));
        sheet.getRangeByIndex(row, 1).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 시간 (빈 칸)
        sheet.getRangeByIndex(row, 2).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 온도 (빈 칸)
        sheet.getRangeByIndex(row, 3).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // MRC 확인 (빈 칸)
        sheet.getRangeByIndex(row, 4).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 소독액 농도 (빈 칸)
        sheet.getRangeByIndex(row, 5).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 세척 사이클 수
        if (dayCount > 0) {
          sheet.getRangeByIndex(row, 6).setNumber(dayCount.toDouble());
        }
        sheet.getRangeByIndex(row, 6).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 누적 사이클 수
        sheet.getRangeByIndex(row, 7).setNumber(cumulativeCount.toDouble());
        sheet.getRangeByIndex(row, 7).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 점검자
        if (dailyInspectors[dateKey] != null) {
          String inspectors = dailyInspectors[dateKey]!.join(', ');
          sheet.getRangeByIndex(row, 8).setText(inspectors);
        }
        sheet.getRangeByIndex(row, 8).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 특이사항 (빈 칸)
        sheet.getRangeByIndex(row, 9).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        // 확인자 서명 (빈 칸)
        sheet.getRangeByIndex(row, 10).cellStyle.borders.all.lineStyle =
            xls.LineStyle.thin;

        currentDate = currentDate.add(Duration(days: 1));
        row++;
      }

      // 컬럼 너비 조정
      sheet.setColumnWidthInPixels(1, 60); // 일자
      sheet.setColumnWidthInPixels(2, 60); // 시간
      sheet.setColumnWidthInPixels(3, 70); // 온도
      sheet.setColumnWidthInPixels(4, 60); // MRC 확인
      sheet.setColumnWidthInPixels(5, 80); // 소독액 농도
      sheet.setColumnWidthInPixels(6, 70); // 세척 사이클 수
      sheet.setColumnWidthInPixels(7, 70); // 누적 사이클 수
      sheet.setColumnWidthInPixels(8, 80); // 점검자
      sheet.setColumnWidthInPixels(9, 100); // 특이사항
      sheet.setColumnWidthInPixels(10, 80); // 확인자 서명
    } catch (e) {
      print('Error filling data: $e');
    }
  }
}
