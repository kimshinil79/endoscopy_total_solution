import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';

class DisinfectantEditor {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void showDisinfectantList(BuildContext context) async {
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

  static void _editDisinfectant(
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
                          await _updateDisinfectantList(context, disinfectants);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showDisinfectantList(context);
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
                          await _updateDisinfectantList(context, disinfectants);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showDisinfectantList(context);
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

  static Future<void> _updateDisinfectantList(
    BuildContext context,
    List<String> disinfectants,
  ) async {
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
}
