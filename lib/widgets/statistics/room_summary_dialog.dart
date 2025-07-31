import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data_class/patient_exam.dart';

class RoomSummaryDialog {
  static final Color oceanBlue = Color(0xFF1A5F7A);
  static final Color seafoamGreen = Color(0xFF2E7D3E);

  static void show(
    BuildContext context,
    List<Patient> patients,
    DateTime startDate,
    DateTime endDate,
  ) {
    String dateRangeText =
        '(${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)})';

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

    DateTime currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
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

    currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
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

  static Widget _buildRoomSummaryTable(List<List<String>> data) {
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
}
