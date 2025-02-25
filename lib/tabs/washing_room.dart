import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data_class/patient_exam.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Map<String, String> recentDisinfectantChangeDates = {
    '1호기': '00/00',
    '2호기': '00/00',
    '3호기': '00/00',
    '4호기': '00/00',
    '5호기': '00/00',
  };
  Map<String, int> washingMachineCounts = {
    '1호기': 0,
    '2호기': 0,
    '3호기': 0,
    '4호기': 0,
    '5호기': 0,
  };

  Map<String, int> machineAfterChangeCounts = {
    '1호기': 0,
    '2호기': 0,
    '3호기': 0,
    '4호기': 0,
    '5호기': 0,
  };

  final Map<String, String> GSFmachine = {
    '073': 'KG391K073',
    '180': '5G391K180',
    '153': '5G391K153',
    '256': '7G391K256',
    '257': '7G391K257',
    '259': '7G391K259',
    '407': '2G348K407',
    '405': '2G348K405',
    '390': '2G348K390',
    '333': '2G348K333',
    '694': '5G348K694',
  };

  final Map<String, String> CSFmachine = {
    '039': '7C692K039',
    '166': '6C692K166',
    '098': '5C692K098',
    '219': '1C664K219',
    '379': '1C665K379',
    '515': '1C666K515',
  };

  List<String> encouragingComments = [
    '와우~굿잡^^',
    '늘 감사합니다~',
    '쌤 최고에요!!',
    "으쌰~홧팅!!",
    "내시경실 홧팅!!",
    "환타스틱!!",
    "고고씽~",
    "쉬엄쉬엄해요~",
    "이 은혜를 어찌갚죠?!",
  ];
  int unwashedScopesCount = 0;
  int plannedExamCount = 0;
  String buttonText = '검사';
  String selectedWashingCharger = '소독실무자';
  bool _isSaving = false;

  Map<String, List<Map<String, dynamic>>> machineToPatientsMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateTime.now();
    _fetchWashingMachineData();
    _fetchRecentDisinfectantChangeDates();
    _getCurrentUserEmail();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      if (mounted) {
        setState(() {
          selectedWashingCharger = settingsProvider.selectedWashingCharger;
        });
      }
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    selectedWashingCharger = settingsProvider.selectedWashingCharger;
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
                  _buildSaveButton(context),
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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildCustomButton(
            context,
            buttonText,
            onPressed: () => _showTestedPeoplePopup(context),
            onLongPress: _updateButtonText,
          ),
        ),
        Expanded(
          child: _buildCustomButton(
            context,
            selectedScope,
            onPressed: () => _showScopePopup(context),
            onLongPress: () => setState(() => selectedScope = '기기세척'),
            backgroundColor: Colors.blue.shade600,
          ),
        ),
        Expanded(child: _buildDateButton(context)),
      ],
    );
  }

  Widget _buildCustomButton(
    BuildContext context,
    String name, {
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(name)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.blue[50],
          foregroundColor: Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: () => _selectDate(context),
        onLongPress:
            () => setState(() {
              _selectedDate = DateTime.now();
              _fetchWashingMachineData();
            }),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_getFormattedDate()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[100],
          foregroundColor: Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  String _getFormattedDate() {
    if (_selectedDate == null) return '오늘';
    return _isToday(_selectedDate!)
        ? '오늘'
        : DateFormat('yy/MM/dd').format(_selectedDate!);
  }

  bool _isToday(DateTime date) {
    final DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildWashingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          [
            '1호기',
            '2호기',
            '3호기',
            '4호기',
            '5호기',
          ].map((name) => _buildWashingButton(context, name)).toList(),
    );
  }

  Widget _buildWashingButton(BuildContext context, String name) {
    String patientsCount = washingMachineCounts[name].toString();
    String recentDate = recentDisinfectantChangeDates[name] ?? '00/00';
    int afterChangeCount = machineAfterChangeCounts[name] ?? 0;

    if (recentDate != '00/00') {
      DateTime parsedDate = DateTime.parse(recentDate);
      recentDate = DateFormat('M월d일').format(parsedDate);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed:
              () => setState(
                () =>
                    selectedWashingMachine =
                        selectedWashingMachine == name ? '' : name,
              ),
          onLongPress: () => _showDisinfectantChangePopup(context, name),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedWashingMachine == name
                    ? Colors.orange[100]
                    : Colors.yellow[100],
            foregroundColor: Colors.black87,
            padding: EdgeInsets.all(16.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 4.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  recentDate,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              SizedBox(height: 4.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$patientsCount / $afterChangeCount',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWashingDataLists() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            [
              '1호기',
              '2호기',
              '3호기',
              '4호기',
              '5호기',
            ].map((name) => _buildWashingDataList(context, name)).toList(),
      ),
    );
  }

  Widget _buildWashingDataList(BuildContext context, String name) {
    List<Map<String, dynamic>> sortedData = [];
    if (washingMachineData.containsKey(name)) {
      sortedData = List.from(washingMachineData[name]!);
      sortedData.sort(
        (a, b) => DateFormat('HH:mm')
            .parse(b['washingTime'])
            .compareTo(DateFormat('HH:mm').parse(a['washingTime'])),
      );
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

  void _showSummaryPopup(BuildContext context, Map<String, dynamic> data) {
    String newWashingTime = data['washingTime'];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
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
                      '세척기록',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      '이름: ${data['name']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '세척기계: ${data['washingMachine']} / Scope: ${data['scopeName']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            DateFormat('HH:mm').parse(newWashingTime),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            newWashingTime =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '세척 시간',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[700],
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              newWashingTime,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _updateSummary(
                              context,
                              data['uniqueDocName'],
                              data['examType'],
                              data['washingMachine'],
                              newWashingTime,
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text('확인'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _deleteSummary(
                              context,
                              data['uniqueDocName'],
                              data['examType'],
                              data['washingMachine'],
                              data['scopeName'],
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            '삭제',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
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
      },
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
          onPressed: () => _showSummaryPopup(context, data),
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

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: ElevatedButton(
              onPressed:
                  selectedWashingCharger == '소독실무자'
                      ? null
                      : () => _saveToFirestore(context),
              child: Text('저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () => _showWashingChargerPopup(context),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(selectedWashingCharger),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateButtonText() {
    if (mounted) {
      setState(() {
        selectedPatientScope = '검사';
        if (unwashedScopesCount == 0 && plannedExamCount == 0) {
          buttonText =
              encouragingComments[Random().nextInt(encouragingComments.length)];
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
    Map<String, int> tempAfterChangeCounts = {
      '1호기': 0,
      '2호기': 0,
      '3호기': 0,
      '4호기': 0,
      '5호기': 0,
    };

    machineToPatientsMap.forEach((machine, patients) {
      tempAfterChangeCounts[machine] = patients.length;
    });

    if (mounted) {
      setState(() {
        machineAfterChangeCounts = tempAfterChangeCounts;
      });
    }
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
    final List<String> washingRoomPeople = settingsProvider.washingRoomPeople;

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
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: washingRoomPeople.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          washingRoomPeople[index],
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          settingsProvider.setSelectedWashingCharger(
                            washingRoomPeople[index],
                          );
                          Navigator.of(context).pop();
                        },
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

  void _showScopePopup(BuildContext context) {
    final List<String> allScopes = [...GSFmachine.keys, ...CSFmachine.keys];

    tempSelectedScope = selectedScope;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
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
                      '기기 목록',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          allScopes.map((scope) {
                            final bool isSelected = scope == tempSelectedScope;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  tempSelectedScope = scope;
                                  isDeviceCleaning = false;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      isSelected
                                          ? Colors.blue.shade50
                                          : Colors.white,
                                ),
                                child: Center(
                                  child: Text(
                                    scope,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.blue
                                              : Colors.black87,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(tempSelectedScope);
                            if (mounted) {
                              setState(() {
                                selectedScope = tempSelectedScope!;
                                isDeviceCleaning = true;
                              });
                            }
                          },
                          child: Text('확인'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
      },
    ).then((selectedScope) {
      if (selectedScope != null) {
        if (mounted) {
          setState(() {
            this.selectedScope = selectedScope;
            isDeviceCleaning = true;
          });
        }
      }
    });
  }

  Future<void> _showTestedPeoplePopup(BuildContext context) async {
    final String dateKey =
        _selectedDate == null
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('examDate', isEqualTo: dateKey)
        .get(GetOptions(source: Source.server));

    people =
        querySnapshot.docs
            .map((doc) {
              String name = doc['name'];
              if (name == '기기세척') return null;

              List<Map<String, dynamic>> exams = [];

              void addExams(String type, Map<String, dynamic>? examData) {
                if (examData != null && examData['scopes'] != null) {
                  Map<String, dynamic> scopesMap =
                      examData['scopes'] as Map<String, dynamic>;
                  scopesMap.forEach((key, value) {
                    exams.add({
                      'type': type,
                      'scope': key,
                      'washingMachine': value['washingMachine'] ?? '',
                    });
                  });
                }
              }

              addExams('위', doc['GSF']);
              addExams('대장', doc['CSF']);
              addExams('S상', doc['sig']);

              if (exams.isEmpty) return null;

              return {
                'name': name,
                'id': doc['id'],
                'gender': doc['gender'],
                'age': doc['age'],
                'examTime': doc['examTime'],
                'exams': exams,
                'uniqueDocName': doc['uniqueDocName'],
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();

    final List<Map<String, dynamic>> nullWashingMachinePeople =
        people.where((person) {
          return person['exams'].any((exam) => exam['washingMachine'] == '');
        }).toList();

    final List<Map<String, dynamic>> notNullWashingMachinePeople =
        people.where((person) {
          return person['exams'].every((exam) => exam['washingMachine'] != '');
        }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
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
                  '검사 받은 사람 목록',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                Flexible(
                  child:
                      people.isEmpty
                          ? Center(child: Text('해당 날짜에 검사받은 사람이 없습니다.'))
                          : ListView(
                            shrinkWrap: true,
                            children: [
                              ...nullWashingMachinePeople.map(
                                (person) => _buildPersonTile(context, person),
                              ),
                              if (nullWashingMachinePeople.isNotEmpty &&
                                  notNullWashingMachinePeople.isNotEmpty)
                                Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                ),
                              ...notNullWashingMachinePeople.map(
                                (person) => _buildPersonTile(context, person),
                              ),
                            ],
                          ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('닫기', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonTile(BuildContext context, Map<String, dynamic> person) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${person['name']} (${person['id']}) ${person['gender']}/${person['age']}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              '검사 시간: ${person['examTime']}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  person['exams'].map<Widget>((exam) {
                    final bool hasWashingMachine = exam['washingMachine'] != '';
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasWashingMachine
                                ? Colors.green.shade100
                                : Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            selectedPatientScope =
                                '${person['name']} (${exam['type']} ${exam['scope']})';
                            buttonText = selectedPatientScope;
                          });
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '${exam['type']} ${exam['scope']}',
                        style: TextStyle(
                          color: hasWashingMachine ? Colors.black : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
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
          washingMachineData[washingMachine]!.add({
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
    final String uniqueDocName =
        '기기세척_${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}';

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
      uniqueDocName: uniqueDocName,
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
              FirebaseFirestore.instance
                  .collection('patients')
                  .doc(uniqueDocName),
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
                washingMachineData[washingMachine]!.insert(0, {
                  'name': patient.name,
                  'scope': GSFmachine.containsKey(selectedScope) ? '위' : '대장',
                  'scopeName': selectedScope,
                  'washingTime': washingTime,
                  'uniqueDocName': uniqueDocName,
                  'examType':
                      GSFmachine.containsKey(selectedScope) ? 'GSF' : 'CSF',
                  'washingMachine': washingMachine,
                });

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
      if (e is TimeoutException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 지연으로 저장에 실패했습니다. 다시 시도해 주세요.')),
        );
      } else {
        print('Error saving device cleaning data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기기세척 데이터 저장 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
      Map<String, int> tempCounts = {
        '1호기': 0,
        '2호기': 0,
        '3호기': 0,
        '4호기': 0,
        '5호기': 0,
      };

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
          washingMachineCounts = tempCounts;
          unwashedScopesCount = tempUnwashedCount;
          plannedExamCount = tempPlannedExamCount;
          _updateButtonText();
        });
      }

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
        tempData[washingMachine]!.add({
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

  Future<void> _fetchRecentDisinfectantChangeDates() async {
    for (String machineName in recentDisinfectantChangeDates.keys) {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('washingMachines')
          .doc(machineName)
          .get(GetOptions(source: Source.server));

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> dates = data['disinfectantChangeDate'] ?? {};

        if (dates.isNotEmpty) {
          // 날짜 키값을 DateTime으로 변환하여 정렬
          List<String> dateKeys = dates.keys.toList();
          dateKeys.sort(
            (a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)),
          );

          if (dateKeys.isNotEmpty) {
            if (mounted) {
              setState(() {
                recentDisinfectantChangeDates[machineName] = dateKeys.first;
              });
            }
          }
        }
      }
    }
    _fetchPatientsAfterRecentDisinfectantChange();
  }

  Future<void> _fetchPatientsAfterRecentDisinfectantChange() async {
    try {
      Map<String, List<Map<String, dynamic>>> tempmachineToPatientsMap = {};
      Map<String, int> tempAfterChangeCounts = {
        '1호기': 0,
        '2호기': 0,
        '3호기': 0,
        '4호기': 0,
        '5호기': 0,
      };

      for (String machineName in recentDisinfectantChangeDates.keys) {
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
          machineAfterChangeCounts = tempAfterChangeCounts;
        });
      }
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
              tempmachineToPatientsMap[machineName]!.add({
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

  void _showDisinfectantChangePopup(
    BuildContext context,
    String machineName,
  ) async {
    Map<String, String> changeDates = {};
    final Color oceanBlue = Color(0xFF1A5F7A);
    final Color seafoamGreen = Color(0xFF57C5B6);

    try {
      DocumentSnapshot docSnapshot =
          await FirebaseFirestore.instance
              .collection('washingMachines')
              .doc(machineName)
              .get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? rawData =
            docSnapshot.data() as Map<String, dynamic>?;
        if (rawData != null && rawData['disinfectantChangeDate'] != null) {
          Map<String, dynamic> dates =
              rawData['disinfectantChangeDate'] as Map<String, dynamic>;
          changeDates = dates.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        }
      }

      List<String> sortedKeys =
          changeDates.keys.toList()
            ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

      DateTime selectedDate = DateTime.now();

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$machineName 소독액 교환일',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: oceanBlue,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add, size: 18),
                        label: Text('교환일 추가', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: seafoamGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final settingsProvider =
                              Provider.of<SettingsProvider>(
                                context,
                                listen: false,
                              );
                          final List<String> disinfectants =
                              settingsProvider.washerNames;

                          final String?
                          selectedDisinfectant = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(16),
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
                                        '소독액 선택',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: oceanBlue,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.4,
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children:
                                                disinfectants.map((
                                                  disinfectant,
                                                ) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4.0,
                                                        ),
                                                    child: InkWell(
                                                      onTap:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(disinfectant),
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 12,
                                                              horizontal: 16,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.blue[50],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                Colors
                                                                    .blue[200]!,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          disinfectant,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text(
                                          '취소',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (selectedDisinfectant != null) {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                              if (pickedTime != null) {
                                setState(() {
                                  selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  String dateTimeKey =
                                      selectedDate.toIso8601String();
                                  changeDates[dateTimeKey] =
                                      selectedDisinfectant;

                                  // 정렬된 키 목록 업데이트
                                  sortedKeys =
                                      changeDates.keys.toList()..sort(
                                        (a, b) => DateTime.parse(
                                          b,
                                        ).compareTo(DateTime.parse(a)),
                                      );
                                });

                                // Firebase에 저장하고 데이터 새로고침
                                await _saveDisinfectantChangeDate(
                                  machineName,
                                  selectedDate,
                                  selectedDisinfectant,
                                  Map<String, String>.from(changeDates),
                                );
                              }
                            }
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            String dateKey = sortedKeys[index];
                            String? disinfectantType = changeDates[dateKey];
                            if (disinfectantType == null)
                              return SizedBox.shrink();

                            DateTime dateTime = DateTime.parse(dateKey);
                            String formattedDate = DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(dateTime);

                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: ListTile(
                                title: Text(formattedDate),
                                subtitle: Text(disinfectantType),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    bool confirmDelete =
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('삭제 확인'),
                                              content: Text(
                                                '이 소독액 교환 기록을 삭제하시겠습니까?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text('취소'),
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                ),
                                                TextButton(
                                                  child: Text('삭제'),
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                ),
                                              ],
                                            );
                                          },
                                        ) ??
                                        false;

                                    if (confirmDelete) {
                                      setState(() {
                                        changeDates.remove(dateKey);
                                      });

                                      // 빈 맵이면 null로 설정하여 필드 자체를 삭제
                                      final dataToUpdate =
                                          changeDates.isEmpty
                                              ? {'disinfectantChangeDate': null}
                                              : {
                                                'disinfectantChangeDate':
                                                    changeDates,
                                              };

                                      await FirebaseFirestore.instance
                                          .collection('washingMachines')
                                          .doc(machineName)
                                          .set(dataToUpdate);

                                      // 데이터 새로고침
                                      await _fetchRecentDisinfectantChangeDates();
                                      await _fetchWashingMachineData();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '소독액 교환일이 성공적으로 삭제되었습니다!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '닫기',
                            style: TextStyle(fontSize: 16, color: Colors.blue),
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
    } catch (e) {
      print('Error in _showDisinfectantChangePopup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('소독액 교환일 데이터를 불러오는 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _saveDisinfectantChangeDate(
    String machineName,
    DateTime date,
    String disinfectantName,
    Map<String, String> changeDates,
  ) async {
    try {
      // Firebase에 직접 업데이트
      await FirebaseFirestore.instance
          .collection('washingMachines')
          .doc(machineName)
          .set({
            'disinfectantChangeDate': changeDates,
          }); // SetOptions(merge: true) 제거하여 전체 문서를 덮어쓰기

      // 데이터 새로고침
      await _fetchRecentDisinfectantChangeDates();
      await _fetchWashingMachineData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('소독액 교환일이 성공적으로 업데이트되었습니다!')));
    } catch (e) {
      print('Error saving disinfectant change date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('소독액 교환일 저장 중 오류가 발생했습니다: ${e.toString()}')),
      );
    }
  }
}
