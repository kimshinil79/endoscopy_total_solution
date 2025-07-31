// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:record/record.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:permission_handler/permission_handler.dart';
// import '../services/endoscopy_reading_service.dart';
// import 'dart:convert';
// import 'package:just_audio/just_audio.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:ffmpeg_kit_flutter/log.dart';
// import 'package:ffmpeg_kit_flutter/statistics.dart';

// class RecordingButton extends StatefulWidget {
//   const RecordingButton({Key? key}) : super(key: key);

//   @override
//   _RecordingButtonState createState() => _RecordingButtonState();
// }

// class _RecordingButtonState extends State<RecordingButton> {
//   bool _isAuthorizedUser = false;
//   AudioRecorder? _audioRecorder;
//   final _readingService = EndoscopyReadingService();
//   bool _isRecording = false;
//   String? _currentRecordingPath;
//   final _audioPlayer = AudioPlayer();
//   int? _playingIndex;
//   bool _isMergingAudio = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkUserAuthorization();
//     _readingService.initialize();
//   }

//   @override
//   void dispose() {
//     _disposeRecorder();
//     _audioPlayer.dispose();
//     super.dispose();
//   }

//   void _disposeRecorder() async {
//     try {
//       final recorder = _audioRecorder;
//       _audioRecorder = null;
//       if (recorder != null) {
//         await recorder.dispose();
//       }
//     } catch (e) {
//       print('Error disposing recorder: $e');
//     }
//   }

//   void _checkUserAuthorization() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null && user.email == 'alienpro@naver.com') {
//       setState(() {
//         _isAuthorizedUser = true;
//       });
//     }
//   }

//   Future<void> _playRecording(int index, Function setState) async {
//     try {
//       if (_playingIndex != null) {
//         await _audioPlayer.stop();
//       }

//       final path = _readingService.recordings[index];
//       await _audioPlayer.setFilePath(path);
//       await _audioPlayer.play();

//       setState(() {
//         _playingIndex = index;
//       });

//       _audioPlayer.playerStateStream.listen((state) {
//         if (state.processingState == ProcessingState.completed) {
//           setState(() {
//             _playingIndex = null;
//           });
//         }
//       });
//     } catch (e) {
//       print('Error playing recording: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('녹음을 재생할 수 없습니다')));
//     }
//   }

//   Future<void> _mergeRecordings(Function setState) async {
//     print('========== AUDIO MERGING START ==========');
//     print('Trying to merge recordings at ${DateTime.now()}');

//     if (_readingService.recordings.isEmpty ||
//         _readingService.recordings.length < 2) {
//       print('Error: Not enough recordings to merge');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('합칠 녹음 파일이 충분하지 않습니다')));
//       return;
//     }

//     setState(() {
//       _isMergingAudio = true;
//     });

//     try {
//       print(
//         'Number of recordings to merge: ${_readingService.recordings.length}',
//       );

//       // Get app directory
//       final directory = await getApplicationDocumentsDirectory();
//       print('App document directory: ${directory.path}');

//       // Create output file path
//       final now = DateTime.now();
//       final timeString = '${now.hour}-${now.minute}-${now.second}';
//       final mergedFilePath = '${directory.path}/merged_$timeString.m4a';
//       print('Target merged file path: $mergedFilePath');

//       // Print details of all files being merged
//       print('Details of files to be merged:');
//       for (int i = 0; i < _readingService.recordings.length; i++) {
//         final file = File(_readingService.recordings[i]);
//         final exists = await file.exists();
//         final size = exists ? await file.length() : 0;
//         print('File ${i + 1}: ${_readingService.recordings[i]}');
//         print('  - Exists: $exists');
//         print('  - Size: $size bytes');
//       }

//       // Create temp directory for file list
//       final tempDir = await getTemporaryDirectory();
//       print('Temp directory: ${tempDir.path}');

//       final listFilePath = '${tempDir.path}/filelist_$timeString.txt';
//       final listFile = File(listFilePath);

//       // Create list file with detailed paths
//       final buffer = StringBuffer();
//       for (final path in _readingService.recordings) {
//         // Properly escape single quotes in file paths
//         final escapedPath = path.replaceAll("'", "'\\''");
//         buffer.writeln("file '$escapedPath'");
//       }

//       // Write list file
//       await listFile.writeAsString(buffer.toString());
//       print('List file created at: $listFilePath');
//       print('List file content:');
//       print(await listFile.readAsString());

//       // Check if list file exists and has content
//       if (await listFile.exists()) {
//         print('List file exists with size: ${await listFile.length()} bytes');
//       } else {
//         print('ERROR: List file does not exist after creation!');
//       }

//       // Construct FFmpeg command - use simpler approach
//       final command =
//           '-f concat -safe 0 -i "$listFilePath" -c copy "$mergedFilePath"';
//       print('FFmpeg command: $command');

//       try {
//         print('Executing FFmpeg command...');
//         final session = await FFmpegKit.execute(command);

//         // Get return code
//         final returnCode = await session.getReturnCode();
//         print('FFmpeg return code: ${returnCode?.getValue() ?? "null"}');
//         print('Is success: ${ReturnCode.isSuccess(returnCode)}');

//         // Get session ID for logs
//         final sessionId = await session.getSessionId();
//         print('FFmpeg session ID: $sessionId');

//         // Get logs from the session
//         print('FFmpeg execution logs:');
//         final logs = await session.getLogs();
//         if (logs.isEmpty) {
//           print('No logs available from FFmpeg');
//         }

//         for (final log in logs) {
//           print('[${log.getLevel()}] ${log.getMessage()}');
//         }

//         // Check for output file
//         final outputFile = File(mergedFilePath);
//         final outputExists = await outputFile.exists();
//         print('Output file exists: $outputExists');

//         if (outputExists) {
//           final outputSize = await outputFile.length();
//           print('Output file size: $outputSize bytes');

//           // Check if output file has reasonable size
//           if (outputSize > 100) {
//             // Assume at least 100 bytes for a valid audio file
//             print('Output file has valid size, adding to recordings list');
//             _readingService.addRecording(mergedFilePath);

//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text('녹음 파일이 성공적으로 합쳐졌습니다')));
//           } else {
//             print(
//               'Output file exists but has suspicious size: $outputSize bytes',
//             );
//             throw Exception(
//               'Output file too small, likely corruption: $outputSize bytes',
//             );
//           }
//         } else {
//           print('ERROR: Output file was not created by FFmpeg');
//           throw Exception('FFmpeg did not create output file');
//         }
//       } catch (ffmpegError) {
//         print('FFmpeg execution error: $ffmpegError');

//         // Fallback: copy first file
//         print('Trying fallback: copying first file');
//         final firstFile = File(_readingService.recordings.first);
//         if (await firstFile.exists()) {
//           await firstFile.copy(mergedFilePath);
//           final fallbackFile = File(mergedFilePath);

//           if (await fallbackFile.exists()) {
//             print('Fallback successful: ${await fallbackFile.length()} bytes');
//             _readingService.addRecording(mergedFilePath);

//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text('오류로 인해 첫 번째 파일만 저장되었습니다')));
//           } else {
//             print('Fallback failed: Could not copy first file');
//             throw Exception('Failed to merge and fallback also failed');
//           }
//         } else {
//           print('Fallback failed: First file does not exist');
//           throw Exception('First file does not exist for fallback');
//         }
//       }

//       // Clean up list file
//       try {
//         if (await listFile.exists()) {
//           await listFile.delete();
//           print('Temporary list file deleted');
//         }
//       } catch (e) {
//         print('Warning: Could not delete list file: $e');
//       }
//     } catch (e) {
//       print('ERROR during merging process: $e');
//       print('Stack trace: ${StackTrace.current}');

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('녹음 파일을 합치는데 실패했습니다: $e')));
//     } finally {
//       setState(() {
//         _isMergingAudio = false;
//       });
//       print('========== AUDIO MERGING END ==========');
//     }
//   }

//   Future<void> _startRecording() async {
//     try {
//       // Dispose any existing recorder first
//       _disposeRecorder();

//       // Create a new recorder
//       _audioRecorder = AudioRecorder();

//       if (await Permission.microphone.request().isGranted) {
//         final directory = await getApplicationDocumentsDirectory();
//         final now = DateTime.now();
//         final timeString = '${now.hour}-${now.minute}-${now.second}';
//         final filePath = '${directory.path}/audio_$timeString.m4a';
//         print('filePath: $filePath');

//         await _audioRecorder?.start(
//           RecordConfig(
//             encoder: AudioEncoder.aacLc,
//             bitRate: 128000,
//             sampleRate: 44100,
//           ),
//           path: filePath,
//         );

//         setState(() {
//           _isRecording = true;
//           _currentRecordingPath = filePath;
//         });
//       } else {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('마이크 권한이 필요합니다')));
//       }
//     } catch (e) {
//       print('Error starting recording: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('녹음을 시작할 수 없습니다')));
//     }
//   }

//   Future<void> _stopRecording() async {
//     if (!_isRecording || _audioRecorder == null) return;

//     String? path;
//     try {
//       // Stop recording
//       path = await _audioRecorder?.stop();

//       // Update UI state immediately
//       setState(() {
//         _isRecording = false;
//         _currentRecordingPath = null;
//       });

//       // Add recording to service
//       if (path != null) {
//         _readingService.addRecording(path);
//         print('path: $path');
//       }
//     } catch (e) {
//       print('Error stopping recording: $e');
//       setState(() {
//         _isRecording = false;
//         _currentRecordingPath = null;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('녹음을 중지할 수 없습니다')));
//     } finally {
//       // Always dispose the recorder after stopping
//       _disposeRecorder();
//     }
//   }

//   Future<void> _showRecordingDialog() async {
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: Text('녹음 관리'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ElevatedButton(
//                         onPressed: () async {
//                           if (_isRecording) {
//                             await _stopRecording();
//                           } else {
//                             await _startRecording();
//                           }
//                           // Update dialog state
//                           if (mounted) {
//                             setDialogState(() {});
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor:
//                               _isRecording ? Colors.red[50] : Colors.white,
//                           foregroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                             side: BorderSide(
//                               color: _isRecording ? Colors.red : Colors.green,
//                               width: 0.5,
//                             ),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               _isRecording ? Icons.stop : Icons.mic,
//                               color: _isRecording ? Colors.red : Colors.green,
//                             ),
//                             SizedBox(width: 4),
//                             Text(
//                               _isRecording ? '녹음 중지' : '녹음',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: _isRecording ? Colors.red : Colors.green,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 16),
//                   if (_readingService.recordings.isNotEmpty)
//                     Container(
//                       height: 200,
//                       width: 300,
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: _readingService.recordings.length,
//                         itemBuilder: (context, index) {
//                           final fileName =
//                               _readingService.recordings[index].split('/').last;
//                           final isFinalFile = fileName.startsWith('final_');

//                           return ListTile(
//                             title: Text(
//                               isFinalFile ? '합친 녹음' : fileName,
//                               style:
//                                   isFinalFile
//                                       ? TextStyle(fontWeight: FontWeight.bold)
//                                       : null,
//                             ),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                   icon: Icon(
//                                     _playingIndex == index
//                                         ? Icons.stop
//                                         : Icons.play_arrow,
//                                     color:
//                                         _playingIndex == index
//                                             ? Colors.red
//                                             : Colors.blue,
//                                   ),
//                                   onPressed: () {
//                                     if (_playingIndex == index) {
//                                       _audioPlayer.stop();
//                                       setDialogState(() {
//                                         _playingIndex = null;
//                                       });
//                                     } else {
//                                       _playRecording(index, setDialogState);
//                                     }
//                                   },
//                                 ),
//                                 IconButton(
//                                   icon: Icon(Icons.delete),
//                                   onPressed: () {
//                                     _readingService.removeRecording(index);
//                                     setDialogState(() {});
//                                   },
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('닫기'),
//                 ),
//                 if (_readingService.recordings.length > 1)
//                   ElevatedButton(
//                     onPressed:
//                         _isMergingAudio
//                             ? null
//                             : () => _mergeRecordings(setDialogState),
//                     child:
//                         _isMergingAudio
//                             ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                             : Text('합치기'),
//                   ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _transcribeAudio(String audioPath) async {
//     try {
//       final file = File(audioPath);
//       final bytes = await file.readAsBytes();

//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
//       );

//       request.headers['Authorization'] = 'Bearer YOUR_OPENAI_API_KEY_HERE';
//       request.files.add(
//         http.MultipartFile.fromBytes('file', bytes, filename: 'audio.m4a'),
//       );
//       request.fields['model'] = 'whisper-1';
//       request.fields['language'] = 'en';
//       request.fields['response_format'] = 'json';

//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();

//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(responseBody);
//         final transcription = jsonResponse['text'];
//         final analysisResult = await _readingService.analyzeTranscription(
//           transcription,
//         );
//         _showTranscriptionDialog(analysisResult);
//       } else {
//         throw Exception('Failed to transcribe audio');
//       }
//     } catch (e) {
//       print('Error transcribing audio: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('음성을 텍스트로 변환할 수 없습니다')));
//     }
//   }

//   void _showTranscriptionDialog(String result) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('내시경 판독 결과'),
//           content: SingleChildScrollView(child: Text(result)),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('닫기'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isAuthorizedUser) {
//       return SizedBox.shrink();
//     }

//     return Padding(
//       padding: const EdgeInsets.only(left: 8.0),
//       child: ElevatedButton(
//         onPressed: _showRecordingDialog,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.white,
//           foregroundColor: Colors.black,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(30),
//             side: BorderSide(color: Colors.green, width: 0.5),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.mic, color: Colors.green),
//             SizedBox(width: 4),
//             Text(
//               '녹음',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
