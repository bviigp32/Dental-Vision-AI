import 'dart:convert';
import 'dart:typed_data'; // 바이트 데이터 처리를 위해 추가
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DentalApp());
}

class DentalApp extends StatelessWidget {
  const DentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dental AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  XFile? _selectedImage;
  Uint8List? _imageBytes; // 웹/앱 모두 호환되는 이미지 바이트 데이터
  String _resultText = "이미지를 선택하고 분석을 시작하세요.";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // 경로(path) 대신 바이트(bytes)를 읽어옵니다. (웹 환경 필수)
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _resultText = "이미지 준비 완료. 'AI 분석하기'를 누르세요.";
      });
    }
  }

  // FastAPI 서버로 이미지 전송
  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _resultText = "AI가 이미지를 분석 중입니다...";
    });

    try {
      var uri = Uri.parse('http://127.0.0.1:8000/api/predict');
      var request = http.MultipartRequest('POST', uri);
      
      // 웹과 앱 모두에서 안전하게 작동하는 fromBytes 방식으로 파일 첨부
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _imageBytes!,
        filename: _selectedImage!.name,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 한글 깨짐 방지를 위해 utf8 디코딩 추가
        var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _resultText = "분석 완료!\n\n발견된 질환 수: ${jsonResponse['disease_count']}개\n\n";
          for (var item in jsonResponse['results']) {
            _resultText += "- ${item['disease']} (확률: ${(item['confidence'] * 100).toInt()}%)\n";
          }
        });
      } else {
        setState(() {
          _resultText = "서버 오류 발생: 상태 코드 ${response.statusCode}\n내용: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "통신 중 오류가 발생했습니다.\n서버가 켜져 있는지 확인하세요.\n에러: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('치과 AI 비전 분석')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 바이트 데이터를 기반으로 이미지 렌더링
                if (_imageBytes != null)
                  Image.memory(_imageBytes!, height: 300)
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _pickImage,
                      child: const Text('이미지 선택'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _analyzeImage,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text('AI 분석하기'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading) const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  _resultText,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}