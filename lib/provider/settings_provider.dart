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

  Future<void> setSelectedWashingCharger(String charger) async {
    if (charger != '소독실무자') {
      _selectedWashingCharger = charger;
      notifyListeners();
    }
  }

  List<String> get doctors => _doctors;
  List<String> get rooms => _rooms;
  Map<String, String> get gsfScopes => _gsfScopes;
  Map<String, String> get csfScopes => _csfScopes;
  Map<String, String> get sigScopes => _sigScopes;
  List<String> get washingRoomPeople => _washingRoomPeople;
  List<String> get washerNames => _washerNames;
  Map<String, String> get doctorMap => _doctorMap;

  Future<void> loadSettings() async {
    await _loadDoctors();
    await _loadRooms();
    await _loadScopes('GSFName', 'gsfMap');
    await _loadScopes('CSFName', 'csfMap');
    await _loadScopes('sigName', 'sigMap');
    await _loadWashingRoomPeople();
    await _loadSelectedWashingCharger();
    await _loadWasherName();
    notifyListeners();
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
    final doctorsDoc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('doctors')
            .get();

    Map<String, dynamic> loadedDoctorMap = doctorsDoc['doctorMap'] ?? {};
    _doctorMap = Map<String, String>.from(loadedDoctorMap);

    List<String> loadedDoctors = loadedDoctorMap.keys.toList();
    _doctors = ['의사', ...loadedDoctors];
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
    DocumentSnapshot docSnapshot =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('washingCharger')
            .get();
    if (docSnapshot.exists) {
      _selectedWashingCharger = docSnapshot['selectedCharger'] ?? '소독실무자';
    }
  }
}
