import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';

class RoomEditor {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void showRoomList(BuildContext context) async {
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

  static void _editRoom(
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
                        icon: Icon(Icons.delete),
                        label: Text('삭제'),
                        onPressed: () async {
                          rooms.removeAt(index);
                          await _updateRoomList(context, rooms);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showRoomList(context);
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
                            rooms.add(controller.text);
                          } else {
                            rooms[index] = controller.text;
                          }
                          await _updateRoomList(context, rooms);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showRoomList(context);
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

  static Future<void> _updateRoomList(
    BuildContext context,
    List<String> rooms,
  ) async {
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
}
