import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider extends ChangeNotifier {
  List<String> _doctors = ['의사'];
  List<String> _rooms = ['검사실'];
  Map<String, String> _gsfScopes = {};
  Map<String, String> _csfScopes = {};
  Map<String, String> _sigScopes = {};
  List<String> _washingRoomPeople = [];
  String _selectedWashingCharger = '소독실무자';
  String get selectedWashingCharger => _selectedWashingCharger;
  List<String> _washerNames = [];
  Map<String, String> _doctorMap = {};
  List<String> _encouragingComments = [];
  List<String> get encouragingComments => _encouragingComments;

  // Washing machine related fields
  List<String> _washingMachineNames = [];
  Map<String, String> _recentDisinfectantChangeDates = {};
  Map<String, int> _washingMachineCounts = {};
  Map<String, int> _machineAfterChangeCounts = {};

  // Getters for washing machine data
  List<String> get washingMachineNames => _washingMachineNames;
  Map<String, String> get recentDisinfectantChangeDates =>
      _recentDisinfectantChangeDates;
  Map<String, int> get washingMachineCounts => _washingMachineCounts;
  Map<String, int> get machineAfterChangeCounts => _machineAfterChangeCounts;

  Future<void> setSelectedWashingCharger(String charger) async {
    _selectedWashingCharger = charger;

    try {
      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('washingRoomPeople')
          .update({'selectedWashingCharger': charger});
    } catch (e) {
      print('Error saving selected washing charger: $e');
    }

    notifyListeners();
  }

  List<String> get doctors => _doctors;
  Map<String, String> get doctorMap => _doctorMap;
  List<String> get rooms => _rooms;
  Map<String, String> get gsfScopes => _gsfScopes;
  Map<String, String> get csfScopes => _csfScopes;
  Map<String, String> get sigScopes => _sigScopes;
  List<String> get washingRoomPeople => _washingRoomPeople;
  List<String> get washerNames => _washerNames;

  Future<void> loadSettings() async {
    await _loadDoctors();
    await _loadRooms();
    await _loadScopes('GSFName', 'gsfMap');
    await _loadScopes('CSFName', 'csfMap');
    await _loadScopes('sigName', 'sigMap');
    await _loadWashingRoomPeople();
    await _loadSelectedWashingCharger();
    await _loadWasherName();
    await _loadEncouragingComments();
    await _loadWashingMachineNames();
    notifyListeners();
  }

  // Load washing machine names from Firebase
  Future<void> _loadWashingMachineNames() async {
    try {
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('washingMachines')
          .get(GetOptions(source: Source.server));

      if (settingsDoc.exists) {
        Map<String, dynamic>? data =
            settingsDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('washingMachineMap')) {
          List<String> machineNames = List<String>.from(
            data['washingMachineMap'].keys,
          );

          // Sort machine names by machine number (e.g., "1호기", "2호기", ...)
          machineNames.sort((a, b) {
            // Extract number from machine name (assuming format "n호기" where n is a number)
            int aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            int bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return aNum.compareTo(bNum);
          });

          _washingMachineNames = machineNames;

          // Initialize maps with fetched machine names
          _recentDisinfectantChangeDates = Map.fromEntries(
            machineNames.map((name) => MapEntry(name, '00/00')),
          );

          _washingMachineCounts = Map.fromEntries(
            machineNames.map((name) => MapEntry(name, 0)),
          );

          _machineAfterChangeCounts = Map.fromEntries(
            machineNames.map((name) => MapEntry(name, 0)),
          );

          // Load recent disinfectant change dates
          await _loadRecentDisinfectantChangeDates();
        }
      }
    } catch (e) {
      print('Error fetching washing machine names: $e');
      // If we can't fetch machine names, initialize with default values
      _washingMachineNames = ['1호기', '2호기', '3호기', '4호기', '5호기'];

      // Initialize with default machine names
      _recentDisinfectantChangeDates = Map.fromEntries(
        _washingMachineNames.map((name) => MapEntry(name, '00/00')),
      );

      _washingMachineCounts = Map.fromEntries(
        _washingMachineNames.map((name) => MapEntry(name, 0)),
      );

      _machineAfterChangeCounts = Map.fromEntries(
        _washingMachineNames.map((name) => MapEntry(name, 0)),
      );
    }
  }

  // Load recent disinfectant change dates for each machine
  Future<void> _loadRecentDisinfectantChangeDates() async {
    for (String machineName in _washingMachineNames) {
      try {
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('washingMachines')
            .doc(machineName)
            .get(GetOptions(source: Source.server));

        if (docSnapshot.exists) {
          Map<String, dynamic> data =
              docSnapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> dates = data['disinfectantChangeDate'] ?? {};

          if (dates.isNotEmpty) {
            // 날짜 키값을 DateTime으로 변환하여 정렬
            List<String> dateKeys = dates.keys.toList();
            dateKeys.sort(
              (a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)),
            );

            if (dateKeys.isNotEmpty) {
              _recentDisinfectantChangeDates[machineName] = dateKeys.first;
            }
          }
        }
      } catch (e) {
        print('Error loading disinfectant change date for $machineName: $e');
      }
    }
    notifyListeners();
  }

  // Update washing machine counts
  void updateWashingMachineCounts(Map<String, int> counts) {
    _washingMachineCounts = Map<String, int>.from(counts);
    notifyListeners();
  }

  // Update machine after change counts
  void updateMachineAfterChangeCounts(Map<String, int> counts) {
    _machineAfterChangeCounts = Map<String, int>.from(counts);
    notifyListeners();
  }

  // Update a recent disinfectant change date for a specific machine
  Future<void> updateDisinfectantChangeDate(
    String machineName,
    String dateKey,
    String disinfectantName,
  ) async {
    try {
      // Get current change dates
      DocumentSnapshot docSnapshot =
          await FirebaseFirestore.instance
              .collection('washingMachines')
              .doc(machineName)
              .get();

      Map<String, dynamic> changeDates = {};
      if (docSnapshot.exists) {
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data['disinfectantChangeDate'] != null) {
          changeDates = Map<String, dynamic>.from(
            data['disinfectantChangeDate'],
          );
        }
      }

      // Add or update the new date
      changeDates[dateKey] = disinfectantName;

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('washingMachines')
          .doc(machineName)
          .set({'disinfectantChangeDate': changeDates});

      // Update local state
      _recentDisinfectantChangeDates[machineName] = dateKey;
      notifyListeners();

      // Reload data to ensure everything is up to date
      await _loadRecentDisinfectantChangeDates();
    } catch (e) {
      print('Error updating disinfectant change date: $e');
      throw e;
    }
  }

  // Delete a disinfectant change date for a specific machine
  Future<void> deleteDisinfectantChangeDate(
    String machineName,
    String dateKey,
  ) async {
    try {
      // Get current change dates
      DocumentSnapshot docSnapshot =
          await FirebaseFirestore.instance
              .collection('washingMachines')
              .doc(machineName)
              .get();

      Map<String, dynamic> changeDates = {};
      if (docSnapshot.exists) {
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data['disinfectantChangeDate'] != null) {
          changeDates = Map<String, dynamic>.from(
            data['disinfectantChangeDate'],
          );
        }
      }

      // Remove the date
      changeDates.remove(dateKey);

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('washingMachines')
          .doc(machineName)
          .set({'disinfectantChangeDate': changeDates});

      // Update local state - if we deleted the most recent date, we need to find the new most recent
      await _loadRecentDisinfectantChangeDates();
    } catch (e) {
      print('Error deleting disinfectant change date: $e');
      throw e;
    }
  }

  Future<void> _loadWasherName() async {
    final washerDoc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('washerNames')
            .get();
    List<String> loadedWasherNames = List<String>.from(
      washerDoc['washerNameList'] ?? [],
    );
    _washerNames = loadedWasherNames;
  }

  Future<void> _loadDoctors() async {
    try {
      final doctorsDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('doctors')
              .get();

      if (doctorsDoc.exists) {
        final data = doctorsDoc.data() as Map<String, dynamic>;

        // doctorMap이 있으면 그것을 사용, 없으면 docList 사용
        if (data.containsKey('doctorMap')) {
          _doctorMap = Map<String, String>.from(data['doctorMap'] ?? {});
          List<String> doctorNames = _doctorMap.keys.toList();
          _doctors = ['의사', ...doctorNames];
        } else if (data.containsKey('docList')) {
          List<String> loadedDoctors = List<String>.from(data['docList'] ?? []);
          _doctors = ['의사', ...loadedDoctors];
          _doctorMap = {};
        } else {
          _doctors = ['의사'];
          _doctorMap = {};
        }
      } else {
        _doctors = ['의사'];
        _doctorMap = {};
      }
    } catch (e) {
      print('Error loading doctors: $e');
      _doctors = ['의사'];
      _doctorMap = {};
    }
  }

  Future<void> _loadRooms() async {
    final roomsDoc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('Rooms')
            .get();
    List<String> loadedRooms = List<String>.from(roomsDoc['roomList'] ?? []);
    _rooms = ['검사실', ...loadedRooms];
  }

  Future<void> _loadScopes(String docName, String mapField) async {
    final scopesDoc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc(docName)
            .get();
    final scopesMap = scopesDoc[mapField] as Map<String, dynamic>? ?? {};

    switch (docName) {
      case 'GSFName':
        _gsfScopes = Map<String, String>.from(scopesMap);
        break;
      case 'CSFName':
        _csfScopes = Map<String, String>.from(scopesMap);
        break;
      case 'sigName':
        _sigScopes = Map<String, String>.from(scopesMap);
        break;
    }
  }

  Future<void> _loadWashingRoomPeople() async {
    final peopleDoc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('washingRoomPeople')
            .get();
    List<String> loadedPeople = List<String>.from(
      peopleDoc['washingRoomPeopleList'] ?? [],
    );
    _washingRoomPeople = loadedPeople;
  }

  Future<void> _loadSelectedWashingCharger() async {
    try {
      DocumentSnapshot docSnapshot =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('washingRoomPeople')
              .get();
      if (docSnapshot.exists) {
        _selectedWashingCharger =
            docSnapshot['selectedWashingCharger'] ?? '소독실무자';
      }
    } catch (e) {
      print('Error loading selected washing charger: $e');
      _selectedWashingCharger = '소독실무자';
    }
  }

  Future<void> _loadEncouragingComments() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('encouragingComments')
              .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _encouragingComments = List<String>.from(data['comments'] ?? []);
      }
    } catch (e) {
      print('Error loading encouraging comments: $e');
      _encouragingComments = [];
    }
  }

  Future<void> addEncouragingComment(String comment) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('settings')
          .doc('encouragingComments');

      await docRef.update({
        'comments': FieldValue.arrayUnion([comment]),
      });

      _encouragingComments.add(comment);
      notifyListeners();
    } catch (e) {
      print('Error adding encouraging comment: $e');
      rethrow;
    }
  }

  Future<void> updateEncouragingComment(int index, String newComment) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('settings')
          .doc('encouragingComments');

      List<String> updatedComments = List<String>.from(_encouragingComments);
      updatedComments[index] = newComment;

      await docRef.update({'comments': updatedComments});

      _encouragingComments = updatedComments;
      notifyListeners();
    } catch (e) {
      print('Error updating encouraging comment: $e');
      rethrow;
    }
  }

  Future<void> deleteEncouragingComment(int index) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('settings')
          .doc('encouragingComments');

      List<String> updatedComments = List<String>.from(_encouragingComments);
      updatedComments.removeAt(index);

      await docRef.update({'comments': updatedComments});

      _encouragingComments = updatedComments;
      notifyListeners();
    } catch (e) {
      print('Error deleting encouraging comment: $e');
      rethrow;
    }
  }
}
