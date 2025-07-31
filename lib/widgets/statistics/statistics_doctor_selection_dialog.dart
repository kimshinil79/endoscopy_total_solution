import 'package:flutter/material.dart';

class StatisticsDoctorSelectionDialog {
  static final Color oceanBlue = Color(0xFF1A5F7A);

  static void show(
    BuildContext context,
    List<String> doctors,
    DateTime? startDate,
    DateTime? endDate,
    Function(String) onDoctorSelected,
    VoidCallback onQueryPatients,
    Function(bool) setLoadingState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '의사 선택',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: oceanBlue,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      // Skip the placeholder "의사" option
                      if (doctors[index] == '의사') return SizedBox.shrink();

                      return ListTile(
                        title: Text(
                          doctors[index],
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: oceanBlue,
                          size: 16,
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();

                          // Set the selected doctor
                          onDoctorSelected(doctors[index]);

                          // Query patients if date range is selected
                          if (startDate != null && endDate != null) {
                            setLoadingState(true);
                            onQueryPatients();
                            setLoadingState(false);
                          }
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oceanBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
