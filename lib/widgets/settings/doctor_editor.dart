import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';

class DoctorEditor {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void showDoctorList(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doctorsDoc =
        await firestore.collection('settings').doc('doctors').get();
    List<String> doctors = List<String>.from(doctorsDoc['docList'] ?? []);

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

  static void _editDoctor(
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
                        icon: Icon(Icons.delete),
                        label: Text('삭제'),
                        onPressed: () async {
                          doctors.removeAt(index);
                          await _updateDoctorList(context, doctors);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showDoctorList(context);
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
                            doctors.add(controller.text);
                          } else {
                            doctors[index] = controller.text;
                          }
                          await _updateDoctorList(context, doctors);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showDoctorList(context);
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

  static Future<void> _updateDoctorList(
    BuildContext context,
    List<String> doctors,
  ) async {
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
}
