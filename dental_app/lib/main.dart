import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
  Uint8List? _imageBytes;
  ui.Image? _decodedImage; 
  
  String _resultText = "이미지를 선택하거나 촬영하여 분석을 시작하세요.";
  bool _isLoading = false;
  List<dynamic> _aiResults = []; 
  
  final ImagePicker _picker = ImagePicker();

  // 1. 갤러리에서 이미지 선택 함수
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _decodedImage = frameInfo.image;
        _aiResults = []; 
        _resultText = "이미지 준비 완료. 'AI 분석하기'를 누르세요.";
      });
    }
  }

  // 2. 카메라로 직접 촬영하는 함수
  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _decodedImage = frameInfo.image;
        _aiResults = []; 
        _resultText = "사진 촬영 완료. 'AI 분석하기'를 누르세요.";
      });
    }
  }

  // 3. FastAPI 서버로 이미지 전송 및 분석 함수
  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _resultText = "AI가 이미지를 분석 중입니다...";
      _aiResults = [];
    });

    try {
      var uri = Uri.parse('http://127.0.0.1:8000/api/predict');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _imageBytes!,
        filename: _selectedImage!.name,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _aiResults = jsonResponse['results']; 
          _resultText = "분석 완료!\n발견된 질환 수: ${jsonResponse['disease_count']}개";
        });
      } else {
        setState(() {
          _resultText = "서버 오류 발생: 상태 코드 ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "통신 오류 발생. 서버가 켜져 있는지 확인하세요.\n에러: $e";
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
                if (_imageBytes != null && _decodedImage != null)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: AspectRatio(
                      aspectRatio: _decodedImage!.width / _decodedImage!.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.contain),
                          if (_aiResults.isNotEmpty)
                            CustomPaint(
                              painter: BoundingBoxPainter(
                                results: _aiResults,
                                originalWidth: _decodedImage!.width.toDouble(),
                                originalHeight: _decodedImage!.height.toDouble(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                const SizedBox(height: 20),
                
                // 3개의 버튼이 나란히 배치되는 부분
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('갤러리'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('사진 촬영'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading || _imageBytes == null ? null : _analyzeImage,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      icon: const Icon(Icons.analytics, color: Colors.white),
                      label: const Text('AI 분석', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading) const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  _resultText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> results;
  final double originalWidth;
  final double originalHeight;

  BoundingBoxPainter({
    required this.results,
    required this.originalWidth,
    required this.originalHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / originalWidth;
    final double scaleY = size.height / originalHeight;

    for (var result in results) {
      final box = result['bounding_box'];
      final disease = result['disease'];
      final conf = (result['confidence'] * 100).toInt();

      final rect = Rect.fromLTRB(
        box['x_min'] * scaleX,
        box['y_min'] * scaleY,
        box['x_max'] * scaleX,
        box['y_max'] * scaleY,
      );

      Color boxColor = Colors.red;
      if (disease == 'Implant') boxColor = Colors.blue;
      if (disease == 'Fillings') boxColor = Colors.green;
      if (disease == 'Impacted Tooth') boxColor = Colors.orange;

      final paint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRect(rect, paint);

      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      );
      
      final textSpan = TextSpan(
        text: ' $disease $conf% ',
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}