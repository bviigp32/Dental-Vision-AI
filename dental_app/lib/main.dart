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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const VisionScreen(),
    const ChatbotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.image_search_outlined),
            selectedIcon: Icon(Icons.image_search),
            label: 'X-ray 분석',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '치과 AI 상담',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 첫 번째 탭: X-ray 정밀 분석 화면 (좌표 보정 완료)
// ---------------------------------------------------------
class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  ui.Image? _decodedImage; 
  
  String _resultText = "엑스레이 사진을 업로드하여\n질환을 분석해보세요.";
  bool _isLoading = false;
  List<dynamic> _aiResults = []; 
  
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _decodedImage = frameInfo.image;
        _aiResults = []; 
        _resultText = "사진이 준비되었습니다.\n'분석 시작' 버튼을 눌러주세요.";
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _resultText = "AI 전문의가 이미지를 분석 중입니다...";
      _aiResults = [];
    });

    try {
      var uri = Uri.parse('http://127.0.0.1:8000/api/predict');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', _imageBytes!, filename: _selectedImage!.name,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _aiResults = jsonResponse['results']; 
          _resultText = "분석 완료\n발견된 특이사항: ${jsonResponse['disease_count']}건";
        });
      } else {
        setState(() {
          _resultText = "서버 오류: 상태 코드 ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "통신 오류가 발생했습니다.\n서버 연결 상태를 확인해주세요.";
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
      appBar: AppBar(title: const Text('X-ray 정밀 분석')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  height: 350,
                  color: Colors.grey[100],
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (_imageBytes != null && _decodedImage != null) {
                        final double containerWidth = constraints.maxWidth;
                        final double containerHeight = constraints.maxHeight;

                        final double originalWidth = _decodedImage!.width.toDouble();
                        final double originalHeight = _decodedImage!.height.toDouble();
                        final double imgRatio = originalWidth / originalHeight;
                        final double containerRatio = containerWidth / containerHeight;

                        double renderedWidth, renderedHeight, offsetX, offsetY;

                        if (imgRatio > containerRatio) {
                          renderedWidth = containerWidth;
                          renderedHeight = containerWidth / imgRatio;
                          offsetX = 0;
                          offsetY = (containerHeight - renderedHeight) / 2;
                        } else {
                          renderedHeight = containerHeight;
                          renderedWidth = containerHeight * imgRatio;
                          offsetY = 0;
                          offsetX = (containerWidth - renderedWidth) / 2;
                        }

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_imageBytes!, fit: BoxFit.contain),
                            if (_aiResults.isNotEmpty)
                              Positioned(
                                left: offsetX,
                                top: offsetY,
                                width: renderedWidth,
                                height: renderedHeight,
                                child: CustomPaint(
                                  painter: BoundingBoxPainter(
                                    results: _aiResults,
                                    renderedWidth: renderedWidth,
                                    renderedHeight: renderedHeight,
                                    originalWidth: originalWidth,
                                    originalHeight: originalHeight,
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('사진을 추가해주세요', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_isLoading) const CircularProgressIndicator(),
                    if (_isLoading) const SizedBox(height: 12),
                    Text(
                      _resultText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('갤러리'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('촬영'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading || _imageBytes == null ? null : _analyzeImage,
                icon: const Icon(Icons.analytics),
                label: const Text('분석 시작', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> results;
  final double renderedWidth;
  final double renderedHeight;
  final double originalWidth;
  final double originalHeight;

  BoundingBoxPainter({
    required this.results,
    required this.renderedWidth,
    required this.renderedHeight,
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
        box['x_min'] * scaleX, box['y_min'] * scaleY, box['x_max'] * scaleX, box['y_max'] * scaleY,
      );

      Color boxColor = Colors.redAccent;
      if (disease == 'Implant') boxColor = Colors.blueAccent;
      if (disease == 'Fillings') boxColor = Colors.greenAccent;
      if (disease == 'Impacted Tooth') boxColor = Colors.orangeAccent;

      final paint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      canvas.drawRect(rect, paint);

      const textStyle = TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, backgroundColor: Colors.black54);
      final textSpan = TextSpan(text: ' $disease $conf% ', style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('치과 전문 AI 상담')), body: const Center(child: Text('챗봇 UI 구현 예정')));
  }
}