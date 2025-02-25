import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:collection';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _editDoctorList(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doctorsDoc =
        await firestore.collection('settings').doc('doctors').get();
    Map<String, dynamic> doctorMap =
        (doctorsDoc.data() as Map<String, dynamic>)['doctorMap'] ?? {};
    List<String> doctors = doctorMap.keys.toList();

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
                  '의사 명단 편집',
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
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            doctors[index],
                            style: TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed:
                            () => _editDoctor(
                              context,
                              doctors[index],
                              index,
                              doctors,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade900,
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
                      label: Text('새 의사 추가'),
                      onPressed: () => _editDoctor(context, '', -1, doctors),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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

  void _editDoctor(
    BuildContext context,
    String doctorName,
    int index,
    List<String> doctors,
  ) {
    TextEditingController controller = TextEditingController(text: doctorName);

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
                  index == -1 ? '새 의사 추가' : '의사 정보 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "의사 이름",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (index != -1)
                      ElevatedButton.icon(
                        label: Text('삭제'),
                        onPressed: () async {
                          doctors.removeAt(index);
                          await _updateDoctorList(doctors);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editDoctorList(context);
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
                      label: Text('확인'),
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          if (index == -1) {
                            doctors.add(controller.text);
                          } else {
                            doctors[index] = controller.text;
                          }
                          await _updateDoctorList(doctors);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editDoctorList(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
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

  Future<void> _updateDoctorList(List<String> doctors) async {
    doctors.sort((a, b) => a.compareTo(b)); // 오름차순 정렬
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('settings').doc('doctors').set({
      'docList': doctors,
    });

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.loadSettings();
  }

  void _editRoomList(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot roomsDoc =
        await firestore.collection('settings').doc('Rooms').get();
    List<String> rooms = List<String>.from(roomsDoc['roomList'] ?? []);

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
                  '검사실 편집',
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
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rooms[index],
                            style: TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed:
                            () =>
                                _editRoom(context, rooms[index], index, rooms),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                      label: Text('새 검사실 추가'),
                      onPressed: () => _editRoom(context, '', -1, rooms),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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

  void _editRoom(
    BuildContext context,
    String roomName,
    int index,
    List<String> rooms,
  ) {
    TextEditingController controller = TextEditingController(text: roomName);

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
                  index == -1 ? '새 검사실 추가' : '검사실 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "검사실 이름",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (index != -1)
                      ElevatedButton.icon(
                        label: Text('삭제'),
                        onPressed: () async {
                          rooms.removeAt(index);
                          await _updateRoomList(rooms);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editRoomList(context);
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
                      label: Text('확인'),
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          if (index == -1) {
                            rooms.add(controller.text);
                          } else {
                            rooms[index] = controller.text;
                          }
                          await _updateRoomList(rooms);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editRoomList(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
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

  Future<void> _updateRoomList(List<String> rooms) async {
    rooms.sort((a, b) => a.compareTo(b)); // 오름차순 정렬
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('settings').doc('Rooms').set({
      'roomList': rooms,
    });

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.loadSettings();
  }

  void _editWashingMachineList(BuildContext context) async {
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

  void _editWashingMachine(
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
                        label: Text('삭제'),
                        onPressed: () async {
                          machinesMap.remove(abbreviation);
                          await _updateWashingMachineList(machinesMap);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editWashingMachineList(context);
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
                          await _updateWashingMachineList(machinesMap);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editWashingMachineList(context);
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

  Future<void> _updateWashingMachineList(
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

  void _editDisinfectantList(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot disinfectantsDoc =
        await firestore.collection('settings').doc('washerNames').get();
    List<String> disinfectants = List<String>.from(
      disinfectantsDoc['washerNameList'] ?? [],
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
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '소독액 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: disinfectants.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(disinfectants[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.brown),
                            onPressed:
                                () => _editDisinfectant(
                                  context,
                                  disinfectants[index],
                                  index,
                                  disinfectants,
                                ),
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
                      label: Text('새 소독액 추가'),
                      onPressed:
                          () =>
                              _editDisinfectant(context, '', -1, disinfectants),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
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

  void _editDisinfectant(
    BuildContext context,
    String name,
    int index,
    List<String> disinfectants,
  ) {
    TextEditingController controller = TextEditingController(text: name);

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
                  index == -1 ? '새 소독액 추가' : '소독액 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "소독액 이름",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.sanitizer),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (index != -1)
                      ElevatedButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text('삭제'),
                        onPressed: () async {
                          disinfectants.removeAt(index);
                          await _updateDisinfectantList(disinfectants);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editDisinfectantList(context);
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
                        if (controller.text.isNotEmpty) {
                          if (index == -1) {
                            disinfectants.add(controller.text);
                          } else {
                            disinfectants[index] = controller.text;
                          }
                          await _updateDisinfectantList(disinfectants);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editDisinfectantList(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.close),
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

  Future<void> _updateDisinfectantList(List<String> disinfectants) async {
    disinfectants.sort((a, b) => a.compareTo(b));

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('settings').doc('washerNames').set({
      'washerNameList': disinfectants,
    });

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.loadSettings();
  }

  void _editScopeList(BuildContext context, String scopeType) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String docName;
    String mapField;
    String title;
    Color buttonColor;

    switch (scopeType) {
      case 'gsf':
        docName = 'GSFName';
        mapField = 'gsfMap';
        title = '위 Scopes 편집';
        buttonColor = Colors.red;
        break;
      case 'csf':
        docName = 'CSFName';
        mapField = 'csfMap';
        title = '대장 Scopes 편집';
        buttonColor = Colors.teal;
        break;
      case 'sig':
        docName = 'sigName';
        mapField = 'sigMap';
        title = 'S상 Scopes 편집';
        buttonColor = Colors.indigo;
        break;
      default:
        return;
    }

    DocumentSnapshot scopesDoc =
        await firestore.collection('settings').doc(docName).get();
    Map<String, dynamic> scopesMap =
        (scopesDoc.data() as Map<String, dynamic>?)?[mapField] ?? {};
    scopesMap = SplayTreeMap.from(scopesMap);

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
                  title,
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
                    itemCount: scopesMap.length,
                    itemBuilder: (context, index) {
                      String key = scopesMap.keys.elementAt(index);
                      return ElevatedButton(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            key,
                            style: TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed:
                            () => _editScope(
                              context,
                              key,
                              scopesMap[key],
                              scopesMap,
                              scopeType,
                              buttonColor,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: buttonColor, width: 1),
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
                      label: Text('새 Scope 추가'),
                      onPressed:
                          () => _editScope(
                            context,
                            '',
                            '',
                            scopesMap,
                            scopeType,
                            buttonColor,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
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

  void _editScope(
    BuildContext context,
    String abbreviation,
    String fullName,
    Map<String, dynamic> scopesMap,
    String scopeType,
    Color color,
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
                  abbreviation.isEmpty ? '새 Scope 추가' : 'Scope 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: abbreviationController,
                  decoration: InputDecoration(
                    labelText: "축약어",
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
                    labelText: "전체 이름",
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
                        label: Text('삭제'),
                        onPressed: () async {
                          scopesMap.remove(abbreviation);
                          await _updateScopeList(scopesMap, scopeType);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editScopeList(context, scopeType);
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
                      label: Text('확인'),
                      onPressed: () async {
                        if (abbreviationController.text.isNotEmpty &&
                            fullNameController.text.isNotEmpty) {
                          if (abbreviation.isNotEmpty &&
                              abbreviation != abbreviationController.text) {
                            scopesMap.remove(abbreviation);
                          }
                          scopesMap[abbreviationController.text] =
                              fullNameController.text;
                          await _updateScopeList(scopesMap, scopeType);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editScopeList(context, scopeType);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
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

  Future<void> _updateScopeList(
    Map<String, dynamic> scopesMap,
    String scopeType,
  ) async {
    print('before: $scopesMap');
    var sortedEntries =
        scopesMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    var sortedMap = Map.fromEntries(sortedEntries);
    print('after: $sortedMap');

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String docName;
    String mapField;
    switch (scopeType) {
      case 'gsf':
        docName = 'GSFName';
        mapField = 'gsfMap';
        break;
      case 'csf':
        docName = 'CSFName';
        mapField = 'csfMap';
        break;
      case 'sig':
        docName = 'sigName';
        mapField = 'sigMap';
        break;
      default:
        return;
    }

    await firestore.collection('settings').doc(docName).update({
      mapField: sortedMap,
    });

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.loadSettings();
  }

  void _editWashingRoomPeople(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot peopleDoc =
        await firestore.collection('settings').doc('washingRoomPeople').get();
    List<String> people = List<String>.from(
      peopleDoc['washingRoomPeopleList'] ?? [],
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
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '소독실무자 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(people[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => _editWasherCharger(
                                  context,
                                  people[index],
                                  index,
                                  people,
                                ),
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
                      label: Text('새 실무자 추가'),
                      onPressed:
                          () => _editWasherCharger(context, '', -1, people),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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

  void _editWasherCharger(
    BuildContext context,
    String name,
    int index,
    List<String> people,
  ) {
    TextEditingController controller = TextEditingController(text: name);

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
                  index == -1 ? '새 실무자 추가' : '실무자 편집',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "실무자 이름",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (index != -1)
                      ElevatedButton.icon(
                        label: Text('삭제'),
                        onPressed: () async {
                          people.removeAt(index);
                          await _updateWashingRoomPeopleList(people);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editWashingRoomPeople(context);
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
                      label: Text('확인'),
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          if (index == -1) {
                            people.add(controller.text);
                          } else {
                            people[index] = controller.text;
                          }
                          await _updateWashingRoomPeopleList(people);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _editWashingRoomPeople(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
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

  Future<void> _updateWashingRoomPeopleList(List<String> people) async {
    people.sort((a, b) => a.compareTo(b));

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('settings').doc('washingRoomPeople').set({
      'washingRoomPeopleList': people,
    });
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.loadSettings();
  }

  Future<void> _finalUploadFromJson(BuildContext context) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/patients(29).json',
      );
      final List<dynamic> patientsJson = json.decode(jsonString);
      await Firebase.initializeApp();
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      for (var patientData in patientsJson) {
        final patient = _convertToPatientImproved(patientData);
        await firestore
            .collection('patients')
            .doc(patient.uniqueDocName)
            .set(patient.toMap());
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('새로운 환자 데이터가 성공적으로 업로드되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  Patient _convertToPatient(Map<String, dynamic> data) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    String name = data['이름'] ?? '';
    String examDate = data['날짜'] ?? '';
    String uniqueId = data['id'] ?? '';
    String uniqueDocName = '${name}_${examDate}_${uniqueId}';
    DateTime birthday;
    try {
      birthday = DateFormat('yyyyMMdd').parse(data['생일'] ?? '');
    } catch (e) {
      birthday = DateTime.now();
    }
    DateTime parsedExamDate;
    try {
      parsedExamDate = dateFormat.parse(examDate);
    } catch (e) {
      parsedExamDate = DateTime.now();
    }
    return Patient(
      uniqueDocName: uniqueDocName,
      id: data['환자번호'] ?? '',
      name: name,
      gender: data['성별'] ?? '',
      age: int.tryParse(data['나이'] ?? '') ?? 0,
      Room: data['Room'] ?? '',
      birthday: birthday,
      doctor: data['의사'] ?? '',
      examDate: parsedExamDate,
      examTime: data['시간'] ?? '',
      GSF: _convertToEndoscopy(data, 'GSF'),
      CSF: _convertToEndoscopy(data, 'CSF'),
      sig: _convertToEndoscopy(data, 'sig'),
    );
  }

  Patient _convertToPatientImproved(Map<String, dynamic> data) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    String name = data['이름'] ?? '';
    String examDate = data['날짜'] ?? '';
    String uniqueId = data['id'] ?? '';
    String uniqueDocName = '${name}_${examDate}_${uniqueId}';
    DateTime birthday;
    try {
      birthday = DateFormat('yyyyMMdd').parse(data['생일'] ?? '');
    } catch (e) {
      birthday = DateTime.now();
    }
    DateTime parsedExamDate;
    try {
      parsedExamDate = dateFormat.parse(examDate);
    } catch (e) {
      parsedExamDate = DateTime.now();
    }
    return Patient(
      uniqueDocName: uniqueDocName,
      id: data['환자번호'] ?? '',
      name: name,
      gender: data['성별'] ?? '',
      age: int.tryParse(data['나이'] ?? '') ?? 0,
      Room: data['Room'] ?? '',
      birthday: birthday,
      doctor: data['의사'] ?? '',
      examDate: parsedExamDate,
      examTime: data['시간'] ?? '',
      GSF: _convertToEndoscopyImproved(data, 'GSF'),
      CSF: _convertToEndoscopyImproved(data, 'CSF'),
      sig: _convertToEndoscopyImproved(data, 'sig'),
    );
  }

  Endoscopy? _convertToEndoscopy(Map<String, dynamic> data, String type) {
    String gumjinOrNot = '';
    String sleepOrNot = '';
    Map<String, dynamic>? scopeData;
    switch (type) {
      case 'GSF':
        gumjinOrNot = data['위검진_외래'] ?? '';
        sleepOrNot = data['위수면_일반'] ?? '';
        scopeData = data['위내시경'];
        break;
      case 'CSF':
        gumjinOrNot = data['대장검진_외래'] ?? '';
        sleepOrNot = data['대장수면_일반'] ?? '';
        scopeData = data['대장내시경'];
        break;
      case 'sig':
        scopeData = data['sig'];
        break;
    }
    scopeData ??= {};
    return Endoscopy(
      gumjinOrNot: gumjinOrNot,
      sleepOrNot: sleepOrNot,
      scopes: _convertScopes(scopeData),
      examDetail: _convertExamDetails(data, type),
    );
  }

  Endoscopy? _convertToEndoscopyImproved(
    Map<String, dynamic> data,
    String type,
  ) {
    String gumjinOrNot = '';
    String sleepOrNot = '';
    Map<String, dynamic>? scopeData;
    switch (type) {
      case 'GSF':
        gumjinOrNot = data['위검진_외래'] ?? '';
        sleepOrNot = data['위수면_일반'] ?? '';
        scopeData = data['위내시경'];
        break;
      case 'CSF':
        gumjinOrNot = data['대장검진_외래'] ?? '';
        sleepOrNot = data['대장수면_일반'] ?? '';
        scopeData = data['대장내시경'];
        break;
      case 'sig':
        scopeData = data['sig'];
        break;
    }
    if (scopeData == null || scopeData.isEmpty) {
      return null;
    }
    return Endoscopy(
      gumjinOrNot: gumjinOrNot,
      sleepOrNot: sleepOrNot,
      scopes: _convertScopesImproved(scopeData),
      examDetail: _convertExamDetailsImproved(data, type),
    );
  }

  Map<String, Map<String, String>> _convertScopes(
    Map<String, dynamic> scopeData,
  ) {
    return scopeData.map((key, value) {
      if (value is Map) {
        return MapEntry(
          key,
          Map<String, String>.from(
            value.map((k, v) => MapEntry(k, v.toString())),
          ),
        );
      } else {
        return MapEntry(key, <String, String>{});
      }
    });
  }

  Map<String, Map<String, String>> _convertScopesImproved(
    Map<String, dynamic> scopeData,
  ) {
    return scopeData.map((key, value) {
      if (value is Map) {
        return MapEntry(
          key,
          Map<String, String>.from(
            value.map((k, v) {
              if (k == '세척시간' && v is String && v.contains(' ')) {
                return MapEntry('washingTime', v.split(' ')[1]);
              } else if (k == '세척기계') {
                return MapEntry('washingMachine', v.toString());
              } else {
                return MapEntry(k, v.toString());
              }
            }),
          ),
        );
      } else {
        return MapEntry(key, <String, String>{});
      }
    });
  }

  ExaminationDetails _convertExamDetails(
    Map<String, dynamic> data,
    String type,
  ) {
    String bx = '';
    String polypectomy = '';
    bool emergency = false;
    bool? clo;
    bool? peg;
    switch (type) {
      case 'GSF':
        bx = data['위조직'] ?? '';
        polypectomy = data['위절제술'] ?? '';
        emergency = data['위응급'] ?? false;
        clo = data['CLO'];
        peg = data['PEG'];
        break;
      case 'CSF':
        bx = data['대장조직'] ?? '';
        polypectomy = data['대장절제술'] ?? '';
        emergency = data['대장응급'] ?? false;
        break;
      case 'sig':
        bx = data['sig조직'] ?? '';
        polypectomy = data['sig절제술'] ?? '';
        emergency = data['sig응급'] ?? false;
        break;
    }
    return ExaminationDetails(
      Bx: bx,
      polypectomy: polypectomy,
      emergency: emergency,
      CLO: clo,
      PEG: peg,
    );
  }

  ExaminationDetails _convertExamDetailsImproved(
    Map<String, dynamic> data,
    String type,
  ) {
    String bx = '';
    String polypectomy = '';
    bool emergency = false;
    bool? clo;
    bool? peg;
    switch (type) {
      case 'GSF':
        bx = data['위조직'] ?? '';
        polypectomy = data['위절제술'] ?? '';
        emergency = data['위응급'] ?? false;
        clo = data['CLO'];
        peg = data['PEG'];
        break;
      case 'CSF':
        bx = data['대장조직'] ?? '';
        polypectomy = data['대장절제술'] ?? '';
        emergency = data['대장응급'] ?? false;
        break;
      case 'sig':
        bx = data['sig조직'] ?? '';
        polypectomy = data['sig절제술'] ?? '';
        emergency = data['sig응급'] ?? false;
        break;
    }
    bx = bx == '0' ? '없음' : bx;
    polypectomy = polypectomy == '0' ? '없음' : polypectomy;
    return ExaminationDetails(
      Bx: bx,
      polypectomy: polypectomy,
      emergency: emergency,
      CLO: clo,
      PEG: peg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSettingsCard(
                context,
                '의사 명단 편집',
                Icons.people,
                Colors.blue,
                () {
                  _editDoctorList(context);
                },
              ),
              _buildSettingsCard(
                context,
                '소독 실무자 편집',
                Icons.shower_outlined,
                Colors.green,
                () {
                  _editWashingRoomPeople(context);
                },
              ),
              _buildSettingsCard(
                context,
                '검사실 편집',
                Icons.meeting_room,
                Colors.orange,
                () {
                  _editRoomList(context);
                },
              ),
              _buildSettingsCard(
                context,
                '세척기 편집',
                Icons.local_laundry_service_outlined,
                Colors.purple,
                () {
                  _editWashingMachineList(context);
                },
              ),
              _buildSettingsCard(
                context,
                '위 Scopes 편집',
                Icons.gesture,
                Colors.red,
                () {
                  _editScopeList(context, 'gsf');
                },
              ),
              _buildSettingsCard(
                context,
                '대장 Scopes 편집',
                Icons.gesture,
                Colors.teal,
                () {
                  _editScopeList(context, 'csf');
                },
              ),
              _buildSettingsCard(
                context,
                'S상 Scopes 편집',
                Icons.gesture,
                Colors.indigo,
                () {
                  _editScopeList(context, 'sig');
                },
              ),
              SizedBox(height: 10),
              _buildSettingsCard(
                context,
                '소독액 편집',
                Icons.sanitizer,
                Colors.brown,
                () {
                  _editDisinfectantList(context);
                },
              ),
              SizedBox(height: 10),

              ElevatedButton(
                child: Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
              //SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () => _finalUploadFromJson(context),
              //   child: Text('JSON에서 최종 업로드'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.green,
              //     foregroundColor: Colors.white,
              //     padding: EdgeInsets.symmetric(vertical: 12),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSettingsCard(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    margin: EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}

class Patient {
  String uniqueDocName;
  String id;
  String name;
  String gender;
  int age;
  String Room;
  DateTime birthday;
  String doctor;
  DateTime examDate;
  String examTime;
  Endoscopy? GSF;
  Endoscopy? CSF;
  Endoscopy? sig;

  Patient({
    required this.uniqueDocName,
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.Room,
    required this.birthday,
    required this.doctor,
    required this.examDate,
    required this.examTime,
    this.GSF,
    this.CSF,
    this.sig,
  });

  Map<String, dynamic> toMap() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return {
      'uniqueDocName': uniqueDocName,
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'Room': Room,
      'birthday': dateFormat.format(birthday),
      'doctor': doctor,
      'examDate': dateFormat.format(examDate),
      'examTime': examTime,
      'GSF': GSF?.toMap(),
      'CSF': CSF?.toMap(),
      'sig': sig?.toMap(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      uniqueDocName: map['uniqueDocName'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      Room: map['Room'] ?? '',
      birthday:
          map['birthday'] != null
              ? DateTime.parse(map['birthday'])
              : DateTime.now(),
      doctor: map['doctor'] ?? '',
      examDate:
          map['examDate'] != null
              ? DateTime.parse(map['examDate'])
              : DateTime.now(),
      examTime: map['examTime'] ?? '',
      GSF: map['GSF'] != null ? Endoscopy.fromMap(map['GSF']) : null,
      CSF: map['CSF'] != null ? Endoscopy.fromMap(map['CSF']) : null,
      sig: map['sig'] != null ? Endoscopy.fromMap(map['sig']) : null,
    );
  }
}

class Endoscopy {
  String gumjinOrNot;
  String sleepOrNot;
  Map<String, Map<String, String>> scopes;
  ExaminationDetails examDetail;

  Endoscopy({
    required this.gumjinOrNot,
    required this.sleepOrNot,
    required this.scopes,
    required this.examDetail,
  });

  factory Endoscopy.fromMap(Map<String, dynamic> map) {
    return Endoscopy(
      gumjinOrNot: map['gumjinOrNot'] as String,
      sleepOrNot: map['sleepOrNot'] as String,
      scopes: (map['scopes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
      ),
      examDetail: ExaminationDetails.fromMap(
        map['examDetail'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gumjinOrNot': gumjinOrNot,
      'sleepOrNot': sleepOrNot,
      'scopes': scopes,
      'examDetail': examDetail.toMap(),
    };
  }
}

class ExaminationDetails {
  String Bx;
  String polypectomy;
  bool emergency;
  bool? CLO;
  bool? PEG;

  ExaminationDetails({
    required this.Bx,
    required this.polypectomy,
    required this.emergency,
    this.CLO,
    this.PEG,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'Bx': Bx,
      'polypectomy': polypectomy,
      'emergency': emergency,
    };
    if (CLO != null) {
      data['CLO'] = CLO;
    }
    if (PEG != null) {
      data['PEG'] = PEG;
    }
    return data;
  }

  factory ExaminationDetails.fromMap(Map<String, dynamic> map) {
    return ExaminationDetails(
      Bx: map['Bx'] ?? '',
      polypectomy: map['polypectomy'] ?? '',
      emergency: map['emergency'] ?? false,
      CLO: map['CLO'],
      PEG: map['PEG'],
    );
  }
}
