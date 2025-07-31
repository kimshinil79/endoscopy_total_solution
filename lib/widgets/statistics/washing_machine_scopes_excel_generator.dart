import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:syncfusion_officechart/officechart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import '../../data_class/patient_exam.dart';

class WashingMachineScopesExcelGenerator {
  static Future<void> create(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    Future<List<Patient>> Function(DateTime, DateTime) queryPatientsByDate,
    VoidCallback setLoadingTrue,
    VoidCallback setLoadingFalse,
    Function(String, String) showSendEmailDialog,
    Function(double) updateProgress,
    Function(String) updateProgressMessage,
  ) async {
    setLoadingTrue();
    updateProgress(0.0);
    updateProgressMessage('Initializing...');

    try {
      // Step 1: Fetch machine data
      updateProgress(0.2);
      updateProgressMessage('Fetching machine data...');

      // 세척기 매핑 정보를 다시 로드합니다.
      DocumentSnapshot washingMachineSnapshot =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('washingMachines')
              .get();

      Map<String, String> currentWashingMachinesFullName = {};
      if (washingMachineSnapshot.exists) {
        try {
          final data = washingMachineSnapshot.data() as Map<String, dynamic>?;
          if (data != null && data['washingMachineMap'] != null) {
            Map<String, dynamic> machineMap = data['washingMachineMap'];
            currentWashingMachinesFullName = Map<String, String>.from(
              machineMap,
            );
          }
        } catch (e) {
          print('Error loading washing machine mapping: $e');
        }
      }

      // 세척기 정보를 가져옵니다.
      Map<String, List<DateTime>> machineData =
          await fetchMachineDisinfectantDates();

      // 각 세척기의 가장 최근 소독액 교환 날짜를 찾습니다.
      Map<String, DateTime> lastChangeDates = {};
      for (var entry in machineData.entries) {
        try {
          lastChangeDates[entry.key] = entry.value
              .where((date) => date.isBefore(startDate))
              .reduce((a, b) => a.isAfter(b) ? a : b);
        } catch (e) {
          print('Error finding last change date for ${entry.key}: $e');
        }
      }

      // Step 2: Fetch patient data
      updateProgress(0.4);
      updateProgressMessage('Fetching patient data...');

      // 가장 이른 소독액 교환 날짜부터 endDate까지의 환자 데이터를 가져옵니다.
      DateTime earliestDate =
          lastChangeDates.values.isNotEmpty
              ? lastChangeDates.values.reduce((a, b) => a.isBefore(b) ? a : b)
              : startDate.subtract(Duration(days: 30));
      List<Patient> patients = await queryPatientsByDate(earliestDate, endDate);

      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final String selectedWashingCharger =
          settingsProvider.selectedWashingCharger;

      // Get scope full names from SettingsProvider (like the original code)
      Map<String, String> scopyFullName = {};
      Map<String, String> gsfMap = settingsProvider.gsfScopes;
      Map<String, String> csfMap = settingsProvider.csfScopes;
      Map<String, String> sigMap = settingsProvider.sigScopes;

      // Merge all scope maps
      gsfMap.forEach((key, value) {
        scopyFullName[key] = value;
      });
      csfMap.forEach((key, value) {
        scopyFullName[key] = value;
      });
      sigMap.forEach((key, value) {
        scopyFullName[key] = value;
      });

      print('Loaded scopes from SettingsProvider:');
      print('GSF scopes: ${gsfMap.keys.toList()}');
      print('CSF scopes: ${csfMap.keys.toList()}');
      print('Sig scopes: ${sigMap.keys.toList()}');
      print('Total scopyFullName: ${scopyFullName.keys.toList()}');

      // Step 3: Process data
      updateProgress(0.6);
      updateProgressMessage('Processing data...');

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

      // Step 4: Create Excel file
      updateProgress(0.8);
      updateProgressMessage('Creating Excel file...');

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
        if (patient.examDate.isBefore(startDate)) {
          continue;
        }

        String examType = data['examType'];
        String scopeName = data['scopeName'];
        Map<String, dynamic> scopeData = Map<String, dynamic>.from(
          data['scopeData'],
        );

        String scopeNumber = scopyFullName[scopeName] ?? '';
        String washingMachineNumber =
            currentWashingMachinesFullName[scopeData['washingMachine']] ?? '';

        // 디버깅: 스코프 번호가 비어있을 때 로그 출력
        if (scopeNumber.isEmpty) {
          print('스코프 번호가 비어있음:');
          print('scopeName: $scopeName');
          print('examType: $examType');
          print('scopyFullName keys: ${scopyFullName.keys.toList()}');
          print('scopyFullName values: ${scopyFullName.values.toList()}');
          // scopeName을 그대로 사용하거나 기본값 설정
          scopeNumber = scopeName.isNotEmpty ? scopeName : 'Unknown';
        }

        // 디버깅: 세척기 번호가 비어있을 때 로그 출력
        if (washingMachineNumber.isEmpty) {
          print('세척기 번호가 비어있음:');
          print('scopeData[washingMachine]: ${scopeData['washingMachine']}');
          print(
            'currentWashingMachinesFullName keys: ${currentWashingMachinesFullName.keys.toList()}',
          );
          print(
            'currentWashingMachinesFullName values: ${currentWashingMachinesFullName.values.toList()}',
          );
        }

        String washingTime = scopeData['washingTime']?.toString() ?? '';
        String washingCharger =
            scopeData['washingCharger']?.toString() ?? selectedWashingCharger;

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
          try {
            DateTime washDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(
              '${DateFormat('yyyy-MM-dd').format(patient.examDate)} $washingTime',
            );
            String machineName = scopeData['washingMachine']?.toString() ?? '';
            if (machineData.containsKey(machineName)) {
              washCount = await calculateWashCount(
                machineName,
                washDateTime,
                machineData[machineName]!,
                allScopeData,
              );
            }
          } catch (e) {
            print('Error calculating wash count: $e');
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
      sheet.getRangeByIndex(rowIndex, 7).setText(dailyMachineCount.toString());
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

      // Step 5: Finalize
      updateProgress(1.0);
      updateProgressMessage('Finalizing...');

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final String path = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          '내시경세척및소독일지_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final String filePath = '$path/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      String subject = '${startDate.year}년 ${startDate.month}월 세척&소독일지';
      showSendEmailDialog(filePath, subject);
    } catch (e) {
      print('Error creating Excel file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('엑셀 파일 생성 중 오류가 발생했습니다.')));
    } finally {
      setLoadingFalse();
      updateProgressMessage(''); // Clear message when done
    }
  }

  static Future<Map<String, List<DateTime>>>
  fetchMachineDisinfectantDates() async {
    Map<String, List<DateTime>> machineData = {};
    for (int i = 1; i <= 5; i++) {
      String machineName = '$i호기';
      try {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection('washingMachines')
                .doc(machineName)
                .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final datesData = data['disinfectantChangeDate'];

          if (datesData != null && datesData is Map) {
            Map<String, dynamic> datesMap = Map<String, dynamic>.from(
              datesData,
            );
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
      } catch (e) {
        print('Error fetching machine data for $machineName: $e');
      }
    }
    return machineData;
  }

  static Future<int> calculateWashCount(
    String machineName,
    DateTime washingTime,
    List<DateTime> changeDates,
    List<Map<String, dynamic>> allScopeData,
  ) async {
    try {
      // 세척 시간보다 이전인 가장 최근 교환 날짜를 찾습니다.
      DateTime lastChangeDate = changeDates.firstWhere(
        (date) => date.isBefore(washingTime),
        orElse:
            () =>
                changeDates.isNotEmpty
                    ? changeDates.last
                    : DateTime.now().subtract(Duration(days: 30)),
      );

      // 세척액 종류를 확인합니다
      DocumentSnapshot machineDoc =
          await FirebaseFirestore.instance
              .collection('washingMachines')
              .doc(machineName)
              .get();

      Map<String, dynamic> disinfectantChangeDate = {};
      if (machineDoc.exists && machineDoc.data() != null) {
        final data = machineDoc.data() as Map<String, dynamic>;
        if (data['disinfectantChangeDate'] != null) {
          disinfectantChangeDate = Map<String, dynamic>.from(
            data['disinfectantChangeDate'],
          );
        }
      }

      // lastChangeDate를 yyyy-MM-dd 형식의 문자열로 변환
      String changeDateStr = DateFormat('yyyy-MM-dd').format(lastChangeDate);
      String disinfectantType =
          disinfectantChangeDate[changeDateStr] ?? '페라플루디액 1제 + 2제(0.2% 과아세트산)';

      int maxCount = disinfectantType == 'O-프탈알데하이드' ? 60 : 80;

      // 마지막 교환 날짜 이후부터 현재 세척 시간까지의 세척 횟수를 계산합니다.
      int count = 1;
      for (var data in allScopeData) {
        try {
          final scopeData = data['scopeData'] as Map<String, dynamic>;
          if (scopeData['washingMachine'] == machineName) {
            String washingTimeStr = scopeData['washingTime']?.toString() ?? '';
            if (washingTimeStr.isNotEmpty) {
              DateTime dataWashTime = DateFormat('yyyy-MM-dd HH:mm').parse(
                '${DateFormat('yyyy-MM-dd').format(data['patient'].examDate)} $washingTimeStr',
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
        } catch (e) {
          print('Error processing scope data in calculateWashCount: $e');
        }
      }
      return count;
    } catch (e) {
      print('Error in calculateWashCount: $e');
      return 1;
    }
  }
}
