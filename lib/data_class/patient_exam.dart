import 'package:intl/intl.dart';

class Patient {
  String uniqueDocName;
  String id;
  String name;
  String gender;
  int age;
  String Room;
  DateTime birthday;
  String doctor;
  DateTime examDate;
  String examTime;
  Endoscopy? GSF;
  Endoscopy? CSF;
  Endoscopy? sig;

  Patient({
    required this.uniqueDocName,
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.Room,
    required this.birthday,
    required this.doctor,
    required this.examDate,
    required this.examTime,
    this.GSF,
    this.CSF,
    this.sig,
  });

  Map<String, dynamic> toMap() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return {
      'uniqueDocName': uniqueDocName,
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'Room': Room,
      'birthday': dateFormat.format(birthday),
      'doctor': doctor,
      'examDate': dateFormat.format(examDate),
      'examTime': examTime,
      'GSF': GSF?.toMap(),
      'CSF': CSF?.toMap(),
      'sig': sig?.toMap(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      uniqueDocName: map['uniqueDocName'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      Room: map['Room'] ?? '',
      birthday:
          map['birthday'] != null
              ? DateFormat('yyyy-MM-dd').parse(map['birthday'])
              : DateTime.now(),
      doctor: map['doctor'] ?? '',
      examDate:
          map['examDate'] != null
              ? DateFormat('yyyy-MM-dd').parse(map['examDate'])
              : DateTime.now(),
      examTime: map['examTime'] ?? '',
      GSF: map['GSF'] != null ? Endoscopy.fromMap(map['GSF']) : null,
      CSF: map['CSF'] != null ? Endoscopy.fromMap(map['CSF']) : null,
      sig: map['sig'] != null ? Endoscopy.fromMap(map['sig']) : null,
    );
  }
}

class Endoscopy {
  String gumjinOrNot;
  String sleepOrNot;
  Map<String, Map<String, String>> scopes;
  ExaminationDetails examDetail;
  bool cancel;

  Endoscopy({
    required this.gumjinOrNot,
    required this.sleepOrNot,
    required this.scopes,
    required this.examDetail,
    this.cancel = false,
  });

  factory Endoscopy.fromMap(Map<String, dynamic> map) {
    final scopesData = map['scopes'] as Map<String, dynamic>?;
    final Map<String, Map<String, String>> convertedScopes = {};

    if (scopesData != null) {
      scopesData.forEach((key, value) {
        if (value is Map) {
          convertedScopes[key] = Map<String, String>.from(
            value.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
      });
    }

    return Endoscopy(
      gumjinOrNot: map['gumjinOrNot'] as String? ?? '',
      sleepOrNot: map['sleepOrNot'] as String? ?? '',
      scopes: convertedScopes,
      examDetail: ExaminationDetails.fromMap(
        (map['examDetail'] as Map<String, dynamic>?) ?? {},
      ),
      cancel: map['cancel'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gumjinOrNot': gumjinOrNot,
      'sleepOrNot': sleepOrNot,
      'scopes': scopes,
      'examDetail': examDetail.toMap(),
      'cancel': cancel,
    };
  }
}

class ExaminationDetails {
  String Bx;
  String polypectomy;
  bool emergency;
  bool? CLO;
  String? CLOResult;
  bool? PEG;
  bool? stoolOB;

  ExaminationDetails({
    required this.Bx,
    required this.polypectomy,
    required this.emergency,
    this.CLO,
    this.CLOResult,
    this.PEG,
    this.stoolOB,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'Bx': Bx,
      'polypectomy': polypectomy,
      'emergency': emergency,
    };

    if (CLO != null) {
      data['CLO'] = CLO;
    }
    if (CLOResult != null) {
      data['CLOResult'] = CLOResult;
    }
    if (PEG != null) {
      data['PEG'] = PEG;
    }
    if (stoolOB != null) {
      data['stoolOB'] = stoolOB;
    }

    return data;
  }

  factory ExaminationDetails.fromMap(Map<String, dynamic> map) {
    return ExaminationDetails(
      Bx: map['Bx'] ?? '',
      polypectomy: map['polypectomy'] ?? '',
      emergency: map['emergency'] ?? false,
      CLO: map['CLO'],
      CLOResult: map['CLOResult'],
      PEG: map['PEG'],
      stoolOB: map['stoolOB'],
    );
  }

  factory ExaminationDetails.empty() {
    return ExaminationDetails(
      Bx: '',
      polypectomy: '',
      emergency: false,
      CLO: null,
      CLOResult: '',
      PEG: null,
      stoolOB: null,
    );
  }
}
