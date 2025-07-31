import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data_class/patient_exam.dart';
import '../../provider/patient_provider.dart';

class SummaryDialog {
  static final Color oceanBlue = Color(0xFF1A5F7A);
  static final Color seafoamGreen = Color(0xFF2E7D3E);

  static ButtonStyle get seafoamButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: seafoamGreen,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  static void show(
    BuildContext context,
    List<Patient> patients,
    DateTime startDate,
    DateTime endDate,
    TabController tabController,
    Function(DateTime, DateTime) onDateRangeChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Date range text with the current dates
            String dateRangeText =
                '(${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)})';

            // Calculate statistics based on current patients list
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

            int gsfBxCount =
                patients
                    .where((p) => p.GSF != null && p.GSF!.examDetail.Bx != '없음')
                    .length;
            int gsfBxTotal = patients
                .where((p) => p.GSF != null)
                .fold(
                  0,
                  (sum, p) => sum + (int.tryParse(p.GSF!.examDetail.Bx) ?? 0),
                );

            int gsfPolypCount =
                patients
                    .where(
                      (p) =>
                          p.GSF != null &&
                          p.GSF!.examDetail.polypectomy != '없음',
                    )
                    .length;
            int gsfPolypTotal = patients
                .where((p) => p.GSF != null)
                .fold(
                  0,
                  (sum, p) =>
                      sum + (int.tryParse(p.GSF!.examDetail.polypectomy) ?? 0),
                );

            int csfBxCount =
                patients
                    .where((p) => p.CSF != null && p.CSF!.examDetail.Bx != '없음')
                    .length;
            int csfBxTotal = patients
                .where((p) => p.CSF != null)
                .fold(
                  0,
                  (sum, p) => sum + (int.tryParse(p.CSF!.examDetail.Bx) ?? 0),
                );

            int csfPolypCount =
                patients
                    .where(
                      (p) =>
                          p.CSF != null &&
                          p.CSF!.examDetail.polypectomy != '없음',
                    )
                    .length;
            int csfPolypTotal = patients
                .where((p) => p.CSF != null)
                .fold(
                  0,
                  (sum, p) =>
                      sum + (int.tryParse(p.CSF!.examDetail.polypectomy) ?? 0),
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
                    .where(
                      (p) => p.GSF != null && p.GSF!.examDetail.CLO == true,
                    )
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

            // Function to select a new date range and refresh the dialog
            Future<void> selectNewDateRange() async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                initialDateRange: DateTimeRange(start: startDate, end: endDate),
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
                // Update the date range
                startDate = picked.start;
                endDate = picked.end;

                // Query new patients data based on the updated date range
                List<Patient> newPatients = await queryPatientsByDate(
                  startDate,
                  endDate,
                );

                // Update the dialog with new data
                setState(() {
                  patients = newPatients;
                });

                // Notify parent about date range change
                onDateRangeChanged(startDate, endDate);
              }
            }

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
                      // Header row with title and close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '검사 요약',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: oceanBlue,
                            ),
                          ),
                          // Close button in the upper right corner
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[700]),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Date range text with calendar icon
                      Row(
                        children: [
                          Text(
                            dateRangeText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Calendar icon button to change date range
                          InkWell(
                            onTap: selectNewDateRange,
                            child: Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: oceanBlue,
                            ),
                          ),
                        ],
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
                            tabController: tabController,
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
      },
    );
  }

  static Future<List<Patient>> queryPatientsByDate(
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

  static Widget _buildSummaryTable(List<List<String>> data) {
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
                        color: SummaryDialog.oceanBlue,
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
                      style: SummaryDialog.seafoamButtonStyle,
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
        border: Border.all(color: SummaryDialog.seafoamGreen),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        details.isEmpty ? prefix : '$prefix(${details.join(',')})',
        style: TextStyle(fontSize: 12, color: SummaryDialog.oceanBlue),
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
            color: SummaryDialog.oceanBlue,
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
                      backgroundColor: SummaryDialog.seafoamGreen.withOpacity(
                        0.3,
                      ),
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
          Icon(icon, size: 16, color: SummaryDialog.oceanBlue),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}
