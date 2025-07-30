// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';

// class EndoscopyReadingService {
//   static final EndoscopyReadingService _instance =
//       EndoscopyReadingService._internal();
//   factory EndoscopyReadingService() => _instance;
//   EndoscopyReadingService._internal();

//   String? _readingSamples;
//   final List<String> _recordings = [];

//   List<String> get recordings => _recordings;

//   void addRecording(String path) {
//     _recordings.add(path);
//   }

//   void removeRecording(int index) {
//     if (index >= 0 && index < _recordings.length) {
//       _recordings.removeAt(index);
//     }
//   }

//   void clearRecordings() {
//     _recordings.clear();
//   }

//   Future<String?> mergeAudioFiles(
//     List<String> filePaths,
//     String outputPath,
//   ) async {
//     if (filePaths.isEmpty) return null;

//     // If there's only one file, just copy it
//     if (filePaths.length == 1) {
//       try {
//         final file = File(filePaths.first);
//         if (await file.exists()) {
//           await file.copy(outputPath);
//           return outputPath;
//         }
//       } catch (e) {
//         print('Error copying single file: $e');
//       }
//       return null;
//     }

//     try {
//       print(
//         'Attempting to merge ${filePaths.length} audio files using ffmpeg_kit_flutter',
//       );

//       // Create a temporary file list for FFmpeg
//       final tempDir = await getTemporaryDirectory();
//       final fileListPath = '${tempDir.path}/filelist.txt';
//       final fileListFile = File(fileListPath);

//       // Create file list content for FFmpeg concat
//       final buffer = StringBuffer();
//       for (final path in filePaths) {
//         // Make sure to escape single quotes in file paths
//         final escapedPath = path.replaceAll("'", "'\\''");
//         buffer.writeln("file '$escapedPath'");
//       }

//       // Write the file list
//       await fileListFile.writeAsString(buffer.toString());
//       print('Created file list at: $fileListPath');
//       print('File list content:\n${await fileListFile.readAsString()}');

//       // Construct FFmpeg command to concatenate audio files
//       final command =
//           '-f concat -safe 0 -i "$fileListPath" -c copy "$outputPath"';
//       print('Executing FFmpeg command: $command');

//       // Execute the FFmpeg command
//       final session = await FFmpegKit.execute(command);
//       final returnCode = await session.getReturnCode();

//       // Clean up the temporary file
//       if (await fileListFile.exists()) {
//         await fileListFile.delete();
//       }

//       if (ReturnCode.isSuccess(returnCode)) {
//         print('Successfully merged audio files to: $outputPath');
//         final outputFile = File(outputPath);
//         if (await outputFile.exists()) {
//           final fileSize = await outputFile.length();
//           print('Output file size: $fileSize bytes');
//           return outputPath;
//         } else {
//           print('Output file does not exist despite successful execution');
//         }
//       } else {
//         print('FFmpeg failed with return code: ${returnCode?.getValue()}');
//         print('Trying alternative approach...');

//         // Alternative approach using filter_complex
//         final filterCommand = _buildFilterComplexCommand(filePaths, outputPath);
//         print('Executing alternative FFmpeg command: $filterCommand');

//         final altSession = await FFmpegKit.execute(filterCommand);
//         final altReturnCode = await altSession.getReturnCode();

//         if (ReturnCode.isSuccess(altReturnCode)) {
//           print('Successfully merged audio files using alternative method');
//           return outputPath;
//         } else {
//           print(
//             'Alternative method also failed with code: ${altReturnCode?.getValue()}',
//           );

//           // Fall back to copying the first file
//           final firstFile = File(filePaths.first);
//           if (await firstFile.exists()) {
//             await firstFile.copy(outputPath);
//             print('Fallback: Copied first file to output path');
//             return outputPath;
//           }
//         }
//       }

//       return null;
//     } catch (e) {
//       print('Error merging audio files: $e');

//       // Fallback on error
//       try {
//         final firstFile = File(filePaths.first);
//         if (await firstFile.exists()) {
//           await firstFile.copy(outputPath);
//           print('Error fallback: Copied first file after exception');
//           return outputPath;
//         }
//       } catch (e) {
//         print('Fallback also failed: $e');
//       }

//       return null;
//     }
//   }

//   // Helper method to build an alternative FFmpeg command using filter_complex
//   String _buildFilterComplexCommand(List<String> filePaths, String outputPath) {
//     StringBuffer command = StringBuffer();

//     // Add input files
//     for (String path in filePaths) {
//       command.write('-i "$path" ');
//     }

//     // Add filter_complex for audio concatenation
//     command.write('-filter_complex "');
//     for (int i = 0; i < filePaths.length; i++) {
//       command.write('[$i:0]');
//     }
//     command.write('concat=n=${filePaths.length}:v=0:a=1[out]" ');

//     // Add output mapping and file
//     command.write('-map "[out]" "$outputPath"');

//     return command.toString();
//   }

//   Future<void> initialize() async {
//     try {
//       _readingSamples = await rootBundle.loadString('assets/readingSample.txt');
//     } catch (e) {
//       print('Error loading reading samples: $e');
//     }
//   }

//   Future<String> analyzeTranscription(String transcription) async {
//     try {
//       final systemPrompt = '''

// ${_readingSamples ?? 'No reading samples available.'}

// Please analyze the following endoscopy reading by strictly following the exact format and structure of the examples above.
// "If there is no mention of cecum insertion, write 'Up to cecum base.'
// Your response must maintain the same sections, terminology, and formatting style as shown in the examples.
// Do not add any additional sections or deviate from the example format.
// ''';

//       final response = await http.post(
//         Uri.parse('https://api.openai.com/v1/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer YOUR_OPENAI_API_KEY_HERE',
//         },
//         body: utf8.encode(
//           jsonEncode({
//             'model': 'gpt-3.5-turbo',
//             'messages': [
//               {'role': 'system', 'content': systemPrompt},
//               {
//                 'role': 'user',
//                 'content':
//                     'Please analyze this endoscopy reading:\n\n$transcription',
//               },
//             ],
//             'temperature': 0.7,
//             'max_tokens': 1000,
//           }),
//         ),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(utf8.decode(response.bodyBytes));
//         final analysis = data['choices'][0]['message']['content'];

//         final result = StringBuffer();
//         result.writeln('=== Transcription Result ===');
//         result.writeln(transcription);
//         result.writeln('\n=== Specialist Analysis ===');
//         result.writeln(analysis);

//         return result.toString();
//       } else {
//         throw Exception('Failed to analyze transcription');
//       }
//     } catch (e) {
//       print('Error analyzing transcription: $e');
//       return 'Error occurred during analysis. Please try again.';
//     }
//   }
// }
