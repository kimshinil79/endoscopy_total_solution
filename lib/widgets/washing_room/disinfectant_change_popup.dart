import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../provider/settings_provider.dart';

class DisinfectantChangePopup {
  static void show(
    BuildContext context,
    String machineName,
    VoidCallback onDataChanged,
  ) async {
    Map<String, String> changeDates = {};
    final Color oceanBlue = Color(0xFF1A5F7A);
    final Color seafoamGreen = Color(0xFF57C5B6);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

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

                          final String? selectedDisinfectant =
                              await _showDisinfectantSelectionDialog(
                                context,
                                disinfectants,
                                oceanBlue,
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

                                // Use SettingsProvider to update the date
                                await settingsProvider
                                    .updateDisinfectantChangeDate(
                                      machineName,
                                      selectedDate.toIso8601String(),
                                      selectedDisinfectant,
                                    );

                                // Refresh data
                                onDataChanged();
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
                                        await _showDeleteConfirmationDialog(
                                          context,
                                        ) ??
                                        false;

                                    if (confirmDelete) {
                                      setState(() {
                                        changeDates.remove(dateKey);
                                      });

                                      // Use SettingsProvider to delete the date
                                      await settingsProvider
                                          .deleteDisinfectantChangeDate(
                                            machineName,
                                            dateKey,
                                          );

                                      // Refresh data
                                      onDataChanged();

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

  static Future<String?> _showDisinfectantSelectionDialog(
    BuildContext context,
    List<String> disinfectants,
    Color oceanBlue,
  ) {
    return showDialog<String>(
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
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          disinfectants.map((disinfectant) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: InkWell(
                                onTap:
                                    () =>
                                        Navigator.of(context).pop(disinfectant),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    disinfectant,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '취소',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('이 소독액 교환 기록을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('삭제'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}
