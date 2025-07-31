import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';
import 'dart:collection';

class ScopeEditor {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void showScopeList(BuildContext context, String scopeType) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String docName;
    String mapField;
    String title;
    Color buttonColor;

    switch (scopeType) {
      case 'gsf':
        docName = 'GSFName';
        mapField = 'gsfMap';
        title = 'Gastroscopy Scopes 편집';
        buttonColor = Colors.red;
        break;
      case 'csf':
        docName = 'CSFName';
        mapField = 'csfMap';
        title = 'Colonoscopy Scopes 편집';
        buttonColor = Colors.teal;
        break;
      case 'sig':
        docName = 'sigName';
        mapField = 'sigMap';
        title = 'Sigmoidoscopy Scopes 편집';
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

  static void _editScope(
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
                        icon: Icon(Icons.delete),
                        label: Text('삭제'),
                        onPressed: () async {
                          scopesMap.remove(abbreviation);
                          await _updateScopeList(context, scopesMap, scopeType);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showScopeList(context, scopeType);
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
                            scopesMap.remove(abbreviation);
                          }
                          scopesMap[abbreviationController.text] =
                              fullNameController.text;
                          await _updateScopeList(context, scopesMap, scopeType);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          showScopeList(context, scopeType);
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

  static Future<void> _updateScopeList(
    BuildContext context,
    Map<String, dynamic> scopesMap,
    String scopeType,
  ) async {
    var sortedEntries =
        scopesMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    var sortedMap = Map.fromEntries(sortedEntries);

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
}
