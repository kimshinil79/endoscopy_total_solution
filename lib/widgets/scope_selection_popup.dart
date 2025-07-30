import 'package:flutter/material.dart';

class ScopeSelectionPopup {
  static void show(
    BuildContext context,
    Map<String, String> gsfMachine,
    Map<String, String> csfMachine,
    String selectedScope,
    Function(String) onScopeSelected,
  ) {
    final List<String> allScopes = [...gsfMachine.keys, ...csfMachine.keys];
    // 숫자 기준으로 정렬
    allScopes.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      allScopes.map((scope) {
                        final bool isSelected = scope == selectedScope;
                        return GestureDetector(
                          onTap: () {
                            onScopeSelected(scope);
                            Navigator.of(context).pop();
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
                                      isSelected ? Colors.blue : Colors.black87,
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
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('닫기', style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
