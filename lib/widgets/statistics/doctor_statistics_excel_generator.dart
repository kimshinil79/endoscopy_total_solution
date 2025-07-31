import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import '../../data_class/patient_exam.dart';

class DoctorStatisticsExcelGenerator {
  static Future<void> create(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    Future<List<Patient>> Function(DateTime, DateTime) queryPatientsByDate,
    VoidCallback setLoadingTrue,
    VoidCallback setLoadingFalse,
    Function(String, String) showSendEmailDialog,
  ) async {
    setLoadingTrue();

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

      final startOfMonth = startDate;
      final endOfMonth = endDate;
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
      showSendEmailDialog(filePath, subject);
    } catch (e) {
      print('Error creating Excel file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('엑셀 파일 생성 중 오류가 발생했습니다.')));
    } finally {
      setLoadingFalse();
    }
  }

  static int _getPolypCount(List<Patient> patients, String doctor, int column) {
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

  static int _getCount(List<Patient> patients, String doctor, int column) {
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

  static int _countEndoscopy(
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

  static int _countPEG(List<Patient> patients) {
    return patients
        .where(
          (p) =>
              p.GSF != null &&
              p.GSF!.cancel != true && // 취소된 검사는 제외
              p.GSF!.examDetail.PEG == true,
        )
        .length;
  }

  static int _countSig(List<Patient> patients) {
    return patients
        .where(
          (p) => p.sig != null && p.sig!.cancel != true, // 취소된 검사는 제외
        )
        .length;
  }
}
