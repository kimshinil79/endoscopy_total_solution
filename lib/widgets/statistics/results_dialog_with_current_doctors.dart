import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data_class/patient_exam.dart';
import '../../provider/settings_provider.dart';

// 색상 팔레트 정의
final Color oceanBlue = Color(0xFF1A5F7A);
final Color seafoamGreen = Color(0xFF57C5B6);

class ResultsDialogWithCurrentDoctors extends StatefulWidget {
  final BuildContext context;
  final List<Patient> patients;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedDoctor;
  final List<String> doctors;
  final Function() onClose;

  const ResultsDialogWithCurrentDoctors({
    Key? key,
    required this.context,
    required this.patients,
    required this.startDate,
    required this.endDate,
    required this.selectedDoctor,
    required this.doctors,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ResultsDialogWithCurrentDoctors> createState() =>
      _ResultsDialogWithCurrentDoctorsState();
}

class _ResultsDialogWithCurrentDoctorsState
    extends State<ResultsDialogWithCurrentDoctors> {
  late List<Patient> currentPatients;
  late String currentDoctor;
  List<String> doctorsList = [];
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    currentPatients = widget.patients;
    currentDoctor = widget.selectedDoctor;

    // 의사 목록이 비어있거나 '의사'만 있으면 Firebase에서 다시 로드
    if (widget.doctors.length <= 1) {
      _loadDoctorsFromFirebase();
    } else {
      // 로컬 상태 초기화
      doctorsList = widget.doctors;

      // Ensure selected doctor is in the list
      if (!doctorsList.contains(currentDoctor)) {
        currentDoctor = doctorsList.isNotEmpty ? doctorsList[0] : '의사';
      }

      // 초기 통계 계산
      _calculateStats(currentDoctor).then((initialStats) {
        setState(() {
          stats = initialStats;
        });
      });
    }
  }

  // Provider에서 의사 목록을 로드하는 메서드
  void _loadDoctorsFromFirebase() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // Provider에서 의사 목록 가져오기
    List<String> providerDoctors = settingsProvider.doctors;

    setState(() {
      // 의사 목록 업데이트
      doctorsList = providerDoctors.isNotEmpty ? providerDoctors : ['의사'];

      // currentDoctor가 새로운 목록에 없으면 첫 번째 의사로 설정
      if (!doctorsList.contains(currentDoctor)) {
        currentDoctor =
            doctorsList.isNotEmpty && doctorsList.length > 1
                ? doctorsList[1]
                : '의사';
      }
    });

    // 통계 계산
    _calculateStats(currentDoctor).then((initialStats) {
      setState(() {
        stats = initialStats;
      });
    });
  }

  Future<Map<String, dynamic>> _calculateStats(String doctor) async {
    currentPatients = await _queryPatientsByDateAndDoctor(
      widget.startDate,
      widget.endDate,
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
              (p) => p.CSF != null && p.CSF!.examDetail.polypectomy != '없음',
            )
            .length;
    double polypDetectionRate =
        totalLowerEndoscopies > 0
            ? (polypectomyCount / totalLowerEndoscopies) * 100
            : 0;
    int totalEndoscopies = gsfGumjin + gsfNonGumjin + totalLowerEndoscopies;

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

  Future<List<Patient>> _queryPatientsByDateAndDoctor(
    DateTime startDate,
    DateTime endDate,
    String doctor,
  ) async {
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
              isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate),
            )
            .get();

    return querySnapshot.docs
        .map((doc) => Patient.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
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

  @override
  Widget build(BuildContext context) {
    String dateRangeText =
        '${DateFormat('yy/MM/dd').format(widget.startDate)} ~ ${DateFormat('yy/MM/dd').format(widget.endDate)}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: seafoamGreen.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: oceanBlue.withAlpha((0.3 * 255).round()),
                  width: 1,
                ),
              ),
              child: DropdownButton<String>(
                value:
                    doctorsList.contains(currentDoctor) ? currentDoctor : null,
                isExpanded: true,
                underline: SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: oceanBlue),
                hint: Text(currentDoctor),
                items:
                    doctorsList.isNotEmpty
                        ? doctorsList.map((String doctor) {
                          return DropdownMenuItem<String>(
                            value: doctor,
                            child: Text(doctor),
                          );
                        }).toList()
                        : [
                          DropdownMenuItem<String>(
                            value: '의사',
                            child: Text('의사'),
                          ),
                        ],
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    // 새로운 의사에 대한 통계 계산
                    Map<String, dynamic> newStats = await _calculateStats(
                      newValue,
                    );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    dateRangeText,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today, size: 18),
                    onPressed: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        initialDateRange: DateTimeRange(
                          start: widget.startDate,
                          end: widget.endDate,
                        ),
                      );
                      if (picked != null &&
                          picked !=
                              DateTimeRange(
                                start: widget.startDate,
                                end: widget.endDate,
                              )) {
                        setState(() {
                          // 새로운 날짜 범위에 대한 통계 계산
                          _calculateStats(currentDoctor).then((newStats) {
                            setState(() {
                              stats = newStats;
                            });
                          });
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            _buildStatisticItem(
              '위내시경',
              '검진: ${stats['gsfGumjin'] ?? 0}',
              '외래: ${stats['gsfNonGumjin'] ?? 0}',
            ),
            _buildStatisticItem(
              '대장내시경',
              '검진: ${stats['csfGumjin'] ?? 0} (${stats['csfGumjinNoPolyp'] ?? 0}/${stats['csfGumjinWithPolyp'] ?? 0})',
              '외래: ${stats['csfNonGumjin'] ?? 0} (${stats['csfNonGumjinNoPolyp'] ?? 0}/${stats['csfNonGumjinWithPolyp'] ?? 0})',
            ),
            _buildStatisticItem(
              '용종 발견율',
              '${(stats['polypDetectionRate'] ?? 0).toStringAsFixed(2)}%',
              '',
              color: Colors.blue,
            ),
            _buildStatisticItem(
              '총 내시경 개수',
              (stats['totalEndoscopies'] ?? 0).toString(),
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
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  widget.onClose();
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
  }
}

// Static method to show the dialog
void showResultsDialogWithCurrentDoctors({
  required BuildContext context,
  required List<Patient> patients,
  required DateTime startDate,
  required DateTime endDate,
  required String selectedDoctor,
  required List<String> doctors,
  required Function() onClose,
}) {
  showDialog(
    context: context,
    builder:
        (context) => ResultsDialogWithCurrentDoctors(
          context: context,
          patients: patients,
          startDate: startDate,
          endDate: endDate,
          selectedDoctor: selectedDoctor,
          doctors: doctors,
          onClose: onClose,
        ),
  );
}
