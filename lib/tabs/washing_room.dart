import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data_class/patient_exam.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../widgets/tested_people_popup.dart';
import '../widgets/washing_room_top_row.dart';
import '../widgets/washing_machine_buttons.dart';
import '../widgets/disinfectant_change_popup.dart';
import '../widgets/scope_selection_popup.dart';
import '../widgets/summary_popup.dart';
import '../widgets/save_button_row.dart';

class WashingRoom extends StatefulWidget {
  @override
  _WashingRoomState createState() => _WashingRoomState();
}

class _WashingRoomState extends State<WashingRoom> with WidgetsBindingObserver {
  String? currentUserEmail;
  DateTime? _selectedDate;
  String selectedScope = '기기세척';
  bool isDeviceCleaning = false;
  String? tempSelectedScope;
  String selectedPatientScope = '검사';
  String selectedWashingMachine = '';
  List<Map<String, dynamic>> people = [];
  Map<String, List<Map<String, dynamic>>> washingMachineData = {};

  // We'll now get these from SettingsProvider instead of managing them locally
  List<String> get washingMachineNames =>
      Provider.of<SettingsProvider>(context, listen: false).washingMachineNames;
  Map<String, String> get recentDisinfectantChangeDates =>
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).recentDisinfectantChangeDates;
  Map<String, int> get washingMachineCounts =>
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).washingMachineCounts;
  Map<String, int> get machineAfterChangeCounts =>
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).machineAfterChangeCounts;

  Map<String, String> GSFmachine = {};
  Map<String, String> CSFmachine = {};

  int unwashedScopesCount = 0;
  int plannedExamCount = 0;
  String buttonText = '검사';
  bool _isSaving = false;

  Map<String, List<Map<String, dynamic>>> machineToPatientsMap = {};

  // Get selectedWashingCharger from provider instead of storing locally
  String get selectedWashingCharger =>
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).selectedWashingCharger;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateTime.now();
    _getCurrentUserEmail();
    _fetchMachineMaps();

    // Ensure SettingsProvider is initialized before fetching data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      // Load settings first to ensure washing machine names are available
      settingsProvider.loadSettings().then((_) {
        _fetchWashingMachineData(); // This will use the data from SettingsProvider
      });
    });
  }

  void _getCurrentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          currentUserEmail = user.email;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchWashingMachineData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the SettingsProvider changes
    Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildTopRow(),
                if ((selectedPatientScope != '검사' || isDeviceCleaning) &&
                    selectedWashingMachine.isNotEmpty)
                  SaveButtonRow(
                    selectedWashingCharger: selectedWashingCharger,
                    onSave: () => _saveToFirestore(context),
                    onWashingChargerPressed:
                        () => _showWashingChargerPopup(context),
                  ),
                Divider(thickness: 2, color: Colors.brown),
                SizedBox(height: 8.0),
                _buildWashingButtons(),
                Expanded(child: _buildWashingDataLists()),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return WashingRoomTopRow(
      buttonText: buttonText,
      selectedScope: selectedScope,
      selectedDate: _selectedDate,
      onTestedPeoplePressed: () {
        TestedPeoplePopup.show(context, _selectedDate, (
          Map<String, dynamic> person,
          String name,
          String examInfo,
        ) {
          if (mounted) {
            setState(() {
              selectedPatientScope = '$name ($examInfo)';
              buttonText = selectedPatientScope;
              // people 리스트를 업데이트하여 저장 시 사용할 수 있도록 함
              people = [person];
            });
          }
        });
      },
      onScopePressed:
          () => ScopeSelectionPopup.show(
            context,
            GSFmachine,
            CSFmachine,
            selectedScope,
            (String scope) {
              if (mounted) {
                setState(() {
                  selectedScope = scope;
                  isDeviceCleaning = true;
                });
              }
            },
          ),
      onScopeLongPress: () => setState(() => selectedScope = '기기세척'),
      onUpdateButtonText: _updateButtonText,
      onDatePressed: () => _selectDate(context),
      onDateLongPress:
          () => setState(() {
            _selectedDate = DateTime.now();
            _fetchWashingMachineData();
          }),
    );
  }

  Widget _buildWashingButtons() {
    return WashingMachineButtons(
      washingMachineNames: washingMachineNames,
      washingMachineCounts: washingMachineCounts,
      recentDisinfectantChangeDates: recentDisinfectantChangeDates,
      machineAfterChangeCounts: machineAfterChangeCounts,
      selectedWashingMachine: selectedWashingMachine,
      onMachineSelected: (String name) {
        setState(() {
          selectedWashingMachine = selectedWashingMachine == name ? '' : name;
        });
      },
      onMachineLongPress: (String name) {
        DisinfectantChangePopup.show(
          context,
          name,
          () => _fetchWashingMachineData(),
        );
      },
    );
  }

  Widget _buildWashingDataLists() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            washingMachineNames
                .map((name) => _buildWashingDataList(context, name))
                .toList(),
      ),
    );
  }

  Widget _buildWashingDataList(BuildContext context, String name) {
    List<Map<String, dynamic>> sortedData = [];
    if (washingMachineData.containsKey(name)) {
      final data = washingMachineData[name];
      if (data != null) {
        sortedData = List.from(data);
        sortedData.sort(
          (a, b) => DateFormat('HH:mm')
              .parse(b['washingTime'])
              .compareTo(DateFormat('HH:mm').parse(a['washingTime'])),
        );
      }
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            SizedBox(height: 4.0),
            ...sortedData
                .map((data) => _buildSummaryButton(context, data))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryButton(BuildContext context, Map<String, dynamic> data) {
    String truncateName(String name) {
      return name.length > 3 ? name.substring(0, 2) + '...' : name;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 100, maxWidth: 100),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: ElevatedButton(
          onPressed:
              () => SummaryPopup.show(
                context,
                data,
                _updateSummary,
                _deleteSummary,
              ),
          child: Column(
            children: [
              Text(
                '${data['scope'] ?? ''}${data['scopeName'] ?? ''}',
                style: TextStyle(color: Colors.black87),
              ),
              Text(
                data['washingTime'] ?? '',
                style: TextStyle(color: Colors.black87),
              ),
              Text(
                truncateName(data['name'] ?? ''),
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[50],
            foregroundColor: Colors.black87,
            padding: EdgeInsets.all(4.0),
            minimumSize: Size(double.infinity, 40),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  void _updateButtonText() {
    if (mounted) {
      setState(() {
        selectedPatientScope = '검사';
        if (unwashedScopesCount == 0 && plannedExamCount == 0) {
          final settingsProvider = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          String randomComment =
              settingsProvider.encouragingComments[Random().nextInt(
                settingsProvider.encouragingComments.length,
              )];
          randomComment = randomComment.replaceAll(
            '누구야',
            selectedWashingCharger,
          );
          buttonText = randomComment;
        } else {
          buttonText =
              '검사 (미세척: $unwashedScopesCount / 검사예정: $plannedExamCount)';
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
        });
      }
      _fetchWashingMachineData();
    }
  }

  Future<void> _updateSummary(
    BuildContext context,
    String uniqueDocName,
    String examType,
    String washingMachine,
    String newTime,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(uniqueDocName);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception("Patient document does not exist!");
        }

        final Map<String, dynamic> data =
            docSnapshot.data() as Map<String, dynamic>;
        final Map<String, dynamic> examData = data[examType] ?? {};
        final Map<String, dynamic> scopes = examData['scopes'] ?? {};

        bool updated = false;
        scopes.forEach((key, value) {
          if (value['washingMachine'] == washingMachine) {
            value['washingTime'] = newTime;
            updated = true;
          }
        });

        if (!updated) {
          throw Exception(
            "No matching scope found for the given washing machine",
          );
        }

        transaction.update(docRef, {
          '$examType.scopes': scopes,
          'logs': FieldValue.arrayUnion([
            {
              'email': currentUserEmail,
              'action': 'update_time',
              'timestamp': DateTime.now(),
            },
          ]),
        });
      });

      if (mounted) {
        var machineList = washingMachineData[washingMachine];
        if (machineList != null) {
          var item = machineList.firstWhere(
            (data) =>
                data['uniqueDocName'] == uniqueDocName &&
                data['examType'] == examType,
            orElse: () => <String, dynamic>{},
          );
          if (item.isNotEmpty) {
            item['washingTime'] = newTime;
          }
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('세척 시간이 성공적으로 업데이트되었습니다!')));

      // 데이터를 다시 불러와 UI를 갱신합니다.
      await _fetchWashingMachineData();
    } catch (e) {
      print('Error updating summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업데이트 중 오류가 발생했습니다: ${e.toString()}')),
      );
    }
  }

  void _updateWashingMachineAfterChangeCounts() {
    Map<String, int> tempAfterChangeCounts = {};

    // Initialize with 0 counts for all machines
    for (var machineName in washingMachineNames) {
      tempAfterChangeCounts[machineName] = 0;
    }

    machineToPatientsMap.forEach((machine, patients) {
      if (tempAfterChangeCounts.containsKey(machine)) {
        tempAfterChangeCounts[machine] = patients.length;
      }
    });

    // Update counts in SettingsProvider
    Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).updateMachineAfterChangeCounts(tempAfterChangeCounts);
  }

  Future<void> _deleteSummary(
    BuildContext context,
    String uniqueDocName,
    String examType,
    String washingMachine,
    String scopeName,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(uniqueDocName);
      final docSnapshot = await docRef.get(GetOptions(source: Source.server));
      final Map<String, dynamic> scopes = Map<String, dynamic>.from(
        docSnapshot[examType]['scopes'],
      );

      if (uniqueDocName.startsWith('기기세척')) {
        await docRef.delete();
        if (mounted) {
          setState(() {
            var machineList = washingMachineData[washingMachine];
            if (machineList != null) {
              machineList.removeWhere(
                (data) => data['uniqueDocName'] == uniqueDocName,
              );
            }
          });
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('기기세척 문서가 성공적으로 삭제되었습니다!')));
      } else {
        if (scopes.containsKey(scopeName)) {
          scopes[scopeName] = {'washingMachine': '', 'washingTime': ''};

          await docRef.update({
            '$examType.scopes': scopes,
            'logs': FieldValue.arrayUnion([
              {
                'email': currentUserEmail,
                'action': 'delete',
                'timestamp': DateTime.now(),
              },
            ]),
          });

          if (mounted) {
            setState(() {
              var machineList = washingMachineData[washingMachine];
              if (machineList != null) {
                machineList.removeWhere(
                  (data) =>
                      data['uniqueDocName'] == uniqueDocName &&
                      data['scopeName'] == scopeName,
                );
              }
            });
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('기록이 성공적으로 삭제되었습니다!')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('해당 scope을 찾을 수 없습니다.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: ${e.toString()}')),
      );
    }
    _fetchWashingMachineData();
  }

  void _showWashingChargerPopup(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    // 소독실무자를 리스트에 추가
    final List<String> washingRoomPeople = [
      ...settingsProvider.washingRoomPeople,
    ];
    final String currentSelectedCharger =
        settingsProvider.selectedWashingCharger;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '소독실무자 선택',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  constraints: BoxConstraints(maxHeight: 400, minWidth: 300),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: washingRoomPeople.length,
                    itemBuilder: (context, index) {
                      final String name = washingRoomPeople[index];
                      final bool isSelected = name == currentSelectedCharger;

                      return InkWell(
                        onTap: () {
                          settingsProvider.setSelectedWashingCharger(name);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? Colors.blue.shade700
                                            : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveToFirestore(BuildContext context) async {
    try {
      if (isDeviceCleaning) {
        await _saveDeviceCleaningData();
      } else {
        await _savePatientData(context);
      }
      await _fetchWashingMachineData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: ${e.toString()}')),
      );
    }
  }

  Future<void> _savePatientData(BuildContext context) async {
    if (mounted) {
      setState(() => _isSaving = true);
    }

    final selectedPersonName = selectedPatientScope.split('(')[0].trim();
    final selectedPerson = people.firstWhere(
      (person) => person['name'] == selectedPersonName,
      orElse: () => <String, Object>{},
    );

    if (selectedPerson.isEmpty) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선택된 환자를 찾을 수 없습니다.')));
      return;
    }

    final washingMachine = selectedWashingMachine;
    final washingTime = DateFormat('HH:mm').format(DateTime.now());

    final String examType =
        selectedPatientScope.contains('위')
            ? 'GSF'
            : selectedPatientScope.contains('대장')
            ? 'CSF'
            : 'sig';

    final docRef = FirebaseFirestore.instance
        .collection('patients')
        .doc(selectedPerson['uniqueDocName']);
    final scopeName = selectedPatientScope
        .split('(')[1]
        .split(' ')[1]
        .replaceAll(')', '');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception("Patient document does not exist!");
        }

        final Map<String, dynamic> currentData =
            docSnapshot.data() as Map<String, dynamic>;
        final Map<String, dynamic> examData = currentData[examType] ?? {};
        final Map<String, dynamic> currentScopes = examData['scopes'] ?? {};

        // 현재 scope 데이터를 유지하면서 새로운 데이터만 업데이트
        if (washingMachine.isNotEmpty && washingTime.isNotEmpty) {
          currentScopes[scopeName] = {
            ...currentScopes[scopeName] ?? {},
            'washingMachine': washingMachine,
            'washingTime': washingTime,
            'washingCharger': selectedWashingCharger,
          };

          // 전체 문서를 덮어쓰는 대신 필요한 필드만 업데이트
          transaction.update(docRef, {
            '$examType.scopes': currentScopes,
            'logs': FieldValue.arrayUnion([
              {
                'email': currentUserEmail,
                'action': 'save',
                'timestamp': DateTime.now(),
              },
            ]),
          });
        } else {
          throw Exception("WashingMachine or WashingTime is empty!");
        }
      });

      // 저장 후 데이터 확인
      final updatedDoc = await docRef.get(GetOptions(source: Source.server));
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final updatedExamData = updatedData[examType] as Map<String, dynamic>;
      final updatedScopes = updatedExamData['scopes'] as Map<String, dynamic>;

      if (updatedScopes[scopeName] == null ||
          updatedScopes[scopeName]['washingMachine'] != washingMachine ||
          updatedScopes[scopeName]['washingTime'] != washingTime) {
        throw Exception("Data was not saved correctly");
      }

      if (mounted) {
        setState(() {
          if (!washingMachineData.containsKey(washingMachine)) {
            washingMachineData[washingMachine] = [];
          }
          final data = washingMachineData[washingMachine];
          if (data != null) {
            data.add({
              'name': selectedPerson['name'],
              'scope':
                  examType == 'GSF'
                      ? '위'
                      : examType == 'CSF'
                      ? '대장'
                      : 'S상',
              'scopeName': scopeName,
              'washingTime': washingTime,
              'uniqueDocName': selectedPerson['uniqueDocName'],
              'examType': examType,
              'washingMachine': washingMachine,
            });
          }
          selectedPatientScope = '검사';
          selectedWashingMachine = '';
          _updateButtonText();
        });
      }

      print('Patient data saved successfully: ${selectedPerson['name']}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('환자 데이터가 성공적으로 저장되었습니다!')));
    } catch (e) {
      print('Error saving patient data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('환자 데이터 저장 중 오류가 발생했습니다: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    // 데이터를 다시 불러와 UI를 갱신합니다.
    await _fetchWashingMachineData();
  }

  Future<void> _saveDeviceCleaningData() async {
    if (mounted) {
      setState(() => _isSaving = true);
    }

    final washingMachine = selectedWashingMachine;
    final DateTime now = DateTime.now();
    final String washingTime = DateFormat('HH:mm').format(now);
    final String uid = Uuid().v4();
    final String documentName =
        '기기세척_${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}_${uid}';

    final ExaminationDetails examDetail = ExaminationDetails(
      Bx: '없음',
      polypectomy: '없음',
      emergency: false,
    );

    final Map<String, String> scopeDetail = {
      'washingTime': washingTime,
      'washingMachine': washingMachine,
      'washingCharger': selectedWashingCharger,
    };

    final Endoscopy endoscopy = Endoscopy(
      gumjinOrNot: '',
      sleepOrNot: '',
      examDetail: examDetail,
      scopes: {selectedScope: scopeDetail},
    );

    final Patient patient = Patient(
      uniqueDocName: uid,
      id: '',
      name: '기기세척',
      gender: '',
      age: 0,
      Room: '',
      birthday: now,
      doctor: '',
      examDate: now,
      examTime: DateFormat('HH:mm').format(now),
      GSF: GSFmachine.containsKey(selectedScope) ? endoscopy : null,
      CSF: CSFmachine.containsKey(selectedScope) ? endoscopy : null,
    );

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
            transaction.set(
              FirebaseFirestore.instance.collection('patients').doc(uid),
              {
                ...patient.toMap(),
                'logs': [
                  {
                    'email': currentUserEmail,
                    'action': 'save',
                    'timestamp': DateTime.now(),
                  },
                ],
              },
            );
          })
          .timeout(Duration(seconds: 10))
          .then((_) {
            if (mounted) {
              setState(() {
                if (!washingMachineData.containsKey(washingMachine)) {
                  washingMachineData[washingMachine] = [];
                }
                final data = washingMachineData[washingMachine];
                if (data != null) {
                  data.insert(0, {
                    'name': patient.name,
                    'scope': GSFmachine.containsKey(selectedScope) ? '위' : '대장',
                    'scopeName': selectedScope,
                    'washingTime': washingTime,
                    'uniqueDocName': uid,
                    'examType':
                        GSFmachine.containsKey(selectedScope) ? 'GSF' : 'CSF',
                    'washingMachine': washingMachine,
                  });
                }

                selectedPatientScope = '검사';
                selectedScope = '기기세척';
                selectedWashingMachine = '';
                isDeviceCleaning = false;
              });
            }

            print('Device cleaning data saved successfully');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('기기세척 데이터가 성공적으로 저장되었습니다!')));
          });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchWashingMachineData() async {
    try {
      final String dateKey =
          _selectedDate == null
              ? DateFormat('yyyy-MM-dd').format(DateTime.now())
              : DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('examDate', isGreaterThanOrEqualTo: dateKey)
          .get(GetOptions(source: Source.server));

      Map<String, List<Map<String, dynamic>>> tempData = {};
      Map<String, int> tempCounts = {};

      // Initialize counts with 0 for all machines
      for (var machineName in washingMachineNames) {
        tempCounts[machineName] = 0;
      }

      int tempUnwashedCount = 0;
      int tempPlannedExamCount = 0;

      for (var doc in querySnapshot.docs) {
        if (doc['examDate'] == dateKey) {
          String name = doc['name'];
          _processExamData(doc, name, 'GSF', tempData, tempCounts);
          _processExamData(doc, name, 'CSF', tempData, tempCounts);
          _processExamData(doc, name, 'sig', tempData, tempCounts);

          int unwashedScopes = _checkForUnwashedScopes(doc);
          tempUnwashedCount += unwashedScopes;

          if (unwashedScopes == 0 &&
              name != '기기세척' &&
              (doc['GSF'] == null || doc['GSF']['scopes'].isEmpty) &&
              (doc['CSF'] == null || doc['CSF']['scopes'].isEmpty) &&
              (doc['sig'] == null || doc['sig']['scopes'].isEmpty)) {
            tempPlannedExamCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          washingMachineData = tempData;
          unwashedScopesCount = tempUnwashedCount;
          plannedExamCount = tempPlannedExamCount;
          _updateButtonText();
        });
      }

      // Update counts in SettingsProvider
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).updateWashingMachineCounts(tempCounts);

      await _fetchPatientsAfterRecentDisinfectantChange();
      _updateWashingMachineAfterChangeCounts();
    } catch (e) {
      print('Error fetching washing machine data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 불러오기 중 오류가 발생했습니다.')));
    }
  }

  void _processExamData(
    DocumentSnapshot doc,
    String name,
    String examType,
    Map<String, List<Map<String, dynamic>>> tempData,
    Map<String, int> tempCounts,
  ) {
    if (doc[examType] != null && doc[examType]['scopes'] != null) {
      for (var scope in doc[examType]['scopes'].keys.toList()) {
        String washingMachine =
            doc[examType]['scopes'][scope]['washingMachine'] ?? '';
        String washingTime =
            doc[examType]['scopes'][scope]['washingTime'] ?? '';
        String scopeName = scope;

        // 미세척 scope도 데이터에 포함
        if (washingMachine.isEmpty) {
          washingMachine = '미세척';
        }

        tempData[washingMachine] = tempData[washingMachine] ?? [];
        final data = tempData[washingMachine];
        if (data != null) {
          data.add({
            'name': name,
            'scope':
                examType == 'GSF'
                    ? '위'
                    : examType == 'CSF'
                    ? '대장'
                    : 'S상',
            'scopeName': scopeName,
            'washingTime': washingTime,
            'uniqueDocName': doc['uniqueDocName'],
            'examType': examType,
            'washingMachine': washingMachine,
          });
        }
        if (washingMachine.isNotEmpty && washingMachine != '미세척') {
          tempCounts[washingMachine] = (tempCounts[washingMachine] ?? 0) + 1;
        }
      }
    }
  }

  int _checkForUnwashedScopes(DocumentSnapshot doc) {
    int unwashedCount = 0;
    bool hasAnyScope = false;
    void checkScopes(Map<String, dynamic>? examData) {
      if (examData != null && examData['scopes'] != null) {
        Map<String, dynamic> scopes = examData['scopes'];
        if (scopes.isNotEmpty) {
          hasAnyScope = true;
          scopes.forEach((scopeName, scopeData) {
            if (scopeData['washingMachine'] == '') {
              unwashedCount++;
            }
          });
        }
      }
    }

    checkScopes(doc['GSF']);
    checkScopes(doc['CSF']);
    checkScopes(doc['sig']);

    return unwashedCount;
  }

  Future<void> _fetchPatientsAfterRecentDisinfectantChange() async {
    try {
      Map<String, List<Map<String, dynamic>>> tempmachineToPatientsMap = {};
      Map<String, int> tempAfterChangeCounts = {};

      // Initialize counts with 0 for all machines
      for (var machineName in washingMachineNames) {
        tempAfterChangeCounts[machineName] = 0;
      }

      for (String machineName in washingMachineNames) {
        String recentChangeDateStr =
            recentDisinfectantChangeDates[machineName] ?? '00/00';
        if (recentChangeDateStr != '00/00') {
          DateTime recentChangeDate = DateFormat(
            'yyyy-MM-dd',
          ).parse(recentChangeDateStr);

          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('patients')
              .where(
                'examDate',
                isGreaterThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(recentChangeDate),
              )
              .get(GetOptions(source: Source.server));

          for (var doc in querySnapshot.docs) {
            Patient patient = Patient.fromMap(
              doc.data() as Map<String, dynamic>,
            );
            _processPatientDataForAfterChange(
              patient,
              machineName,
              recentChangeDate,
              tempmachineToPatientsMap,
              tempAfterChangeCounts,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          machineToPatientsMap = tempmachineToPatientsMap;
        });
      }

      // Update counts in SettingsProvider
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).updateMachineAfterChangeCounts(tempAfterChangeCounts);
    } catch (e) {
      print('Error fetching patients: $e');
    }
  }

  void _processPatientDataForAfterChange(
    Patient patient,
    String machineName,
    DateTime recentChangeDate,
    Map<String, List<Map<String, dynamic>>> tempmachineToPatientsMap,
    Map<String, int> tempAfterChangeCounts,
  ) {
    void processEndoscopy(Endoscopy? endoscopy, String examType) {
      if (endoscopy != null) {
        endoscopy.scopes.forEach((scopeName, scopeData) {
          String washingMachine = scopeData['washingMachine'] ?? '';
          String washingTimeStr = scopeData['washingTime'] ?? '';

          if (washingMachine == machineName && washingTimeStr.isNotEmpty) {
            DateTime washingDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(
              '${DateFormat('yyyy-MM-dd').format(patient.examDate)} $washingTimeStr',
            );

            if (washingDateTime.isAfter(recentChangeDate)) {
              if (!tempmachineToPatientsMap.containsKey(machineName)) {
                tempmachineToPatientsMap[machineName] = [];
              }
              final data = tempmachineToPatientsMap[machineName];
              if (data != null) {
                data.add({
                  'name': patient.name,
                  'id': patient.id,
                  'gender': patient.gender,
                  'age': patient.age,
                  'examDate': DateFormat('yyyy-MM-dd').format(patient.examDate),
                  'examTime': patient.examTime,
                  'washingTime': washingTimeStr,
                  'uniqueDocName': patient.uniqueDocName,
                  'scope':
                      examType == 'GSF'
                          ? '위'
                          : examType == 'CSF'
                          ? '대장'
                          : 'S상',
                  'scopeName': scopeName,
                });
              }
              tempAfterChangeCounts[machineName] =
                  (tempAfterChangeCounts[machineName] ?? 0) + 1;
            }
          }
        });
      }
    }

    processEndoscopy(patient.GSF, 'GSF');
    processEndoscopy(patient.CSF, 'CSF');
    processEndoscopy(patient.sig, 'sig');
  }

  Future<void> _fetchMachineMaps() async {
    try {
      // Fetch GSF machines
      DocumentSnapshot gsfDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('GSFName')
              .get();

      if (gsfDoc.exists) {
        Map<String, dynamic> gsfData = gsfDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            GSFmachine = Map<String, String>.from(gsfData['gsfMap'] ?? {});
          });
        }
      }

      // Fetch CSF machines
      DocumentSnapshot csfDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('CSFName')
              .get();

      if (csfDoc.exists) {
        Map<String, dynamic> csfData = csfDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            CSFmachine = Map<String, String>.from(csfData['csfMap'] ?? {});
          });
        }
      }
    } catch (e) {
      print('Error fetching machine maps: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('기기 목록을 불러오는 중 오류가 발생했습니다.')));
    }
  }
}
