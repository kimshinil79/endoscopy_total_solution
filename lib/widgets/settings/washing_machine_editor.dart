import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import 'dart:collection';

class WashingMachineEditor {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void showWashingMachineList(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot machinesDoc =
        await firestore.collection('settings').doc('washingMachines').get();
    Map<String, dynamic> machinesMap =
        (machinesDoc.data() as Map<String, dynamic>?)?['washingMachineMap'] ??
        {};
    machinesMap = SplayTreeMap.from(machinesMap);

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
                  '세척기 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: machinesMap.length,
                    itemBuilder: (context, index) {
                      String key = machinesMap.keys.elementAt(index);
                      return ElevatedButton(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(key),
                        ),
                        onPressed:
                            () => _editWashingMachine(
                              context,
                              key,
                              machinesMap[key],
                              machinesMap,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade100,
                          foregroundColor: Colors.purple.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('닫기'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('새 세척기 추가'),
                      onPressed:
                          () =>
                              _editWashingMachine(context, '', '', machinesMap),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
  }

  static void _editWashingMachine(
    BuildContext context,
    String abbreviation,
    String fullName,
    Map<String, dynamic> machinesMap,
  ) {
    TextEditingController abbreviationController = TextEditingController(
      text: abbreviation,
    );
    TextEditingController fullNameController = TextEditingController(
      text: fullName,
    );

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
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  abbreviation.isEmpty ? '새 세척기 추가' : '세척기 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: abbreviationController,
                  decoration: InputDecoration(
                    labelText: "축약어 (예: 1호기)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.short_text),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: "전체 이름 (예: G0423102)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (abbreviation.isNotEmpty)
                      ElevatedButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text('삭제'),
                        onPressed: () async {
                          machinesMap.remove(abbreviation);
                          await _updateWashingMachineList(context, machinesMap);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showWashingMachineList(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      label: Text('확인'),
                      onPressed: () async {
                        if (abbreviationController.text.isNotEmpty &&
                            fullNameController.text.isNotEmpty) {
                          if (abbreviation.isNotEmpty &&
                              abbreviation != abbreviationController.text) {
                            machinesMap.remove(abbreviation);
                          }
                          machinesMap[abbreviationController.text] =
                              fullNameController.text;
                          await _updateWashingMachineList(context, machinesMap);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showWashingMachineList(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.cancel),
                      label: Text('취소'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
  }

  static Future<void> _updateWashingMachineList(
    BuildContext context,
    Map<String, dynamic> machinesMap,
  ) async {
    var sortedEntries =
        machinesMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    var sortedMap = Map.fromEntries(sortedEntries);

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('settings').doc('washingMachines').set({
      'washingMachineMap': sortedMap,
    });

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.loadSettings();
  }
}
