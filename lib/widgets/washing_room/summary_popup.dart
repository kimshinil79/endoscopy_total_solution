import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryPopup {
  static void show(
    BuildContext context,
    Map<String, dynamic> data,
    Function(
      BuildContext context,
      String uniqueDocName,
      String examType,
      String washingMachine,
      String newTime,
    )
    onUpdateSummary,
    Function(
      BuildContext context,
      String uniqueDocName,
      String examType,
      String washingMachine,
      String scopeName,
    )
    onDeleteSummary,
  ) {
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
                            onUpdateSummary(
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
                            onDeleteSummary(
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
}
