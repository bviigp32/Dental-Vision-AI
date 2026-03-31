import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
// 스트리밍 통신을 위해 dio 패키지 임포트
import 'package:dio/dio.dart';

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
  List<dynamic> _globalAiResults = [];

  void _updateAiResults(List<dynamic> results) {
    setState(() {
      _globalAiResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      VisionScreen(onResultsUpdated: _updateAiResults),
      ChatbotScreen(aiResults: _globalAiResults),
    ];

    return Scaffold(
      body: screens[_currentIndex],
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
// 첫 번째 탭: X-ray 정밀 분석 화면 (기존과 동일)
// ---------------------------------------------------------
class VisionScreen extends StatefulWidget {
  final Function(List<dynamic>) onResultsUpdated;
  const VisionScreen({super.key, required this.onResultsUpdated});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  ui.Image? _decodedImage; 
  String _resultText = "엑스레이 사진을 업로드하여\n질환을 분석해보세요.";
  bool _isLoading = false;
  List<dynamic> _localAiResults = []; 
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
        _localAiResults = []; 
        _resultText = "사진이 준비되었습니다.\n'분석 시작' 버튼을 눌러주세요.";
      });
      widget.onResultsUpdated([]);
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _selectedImage == null) return;
    setState(() {
      _isLoading = true;
      _resultText = "AI 전문의가 이미지를 분석 중입니다...";
      _localAiResults = [];
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
          _localAiResults = jsonResponse['results']; 
          _resultText = "분석 완료\n발견된 특이사항: ${jsonResponse['disease_count']}건";
        });
        widget.onResultsUpdated(_localAiResults);
      } else {
        setState(() => _resultText = "서버 오류: 상태 코드 ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _resultText = "통신 오류가 발생했습니다.\n서버 연결 상태를 확인해주세요.");
    } finally {
      setState(() => _isLoading = false);
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
                            if (_localAiResults.isNotEmpty)
                              Positioned(
                                left: offsetX, top: offsetY, width: renderedWidth, height: renderedHeight,
                                child: CustomPaint(
                                  painter: BoundingBoxPainter(
                                    results: _localAiResults, renderedWidth: renderedWidth, renderedHeight: renderedHeight,
                                    originalWidth: originalWidth, originalHeight: originalHeight,
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
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (_isLoading) const CircularProgressIndicator(),
                    if (_isLoading) const SizedBox(height: 12),
                    Text(_resultText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('갤러리'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('촬영'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading || _imageBytes == null ? null : _analyzeImage,
                icon: const Icon(Icons.analytics), label: const Text('분석 시작', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
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
  final double renderedWidth, renderedHeight, originalWidth, originalHeight;
  BoundingBoxPainter({required this.results, required this.renderedWidth, required this.renderedHeight, required this.originalWidth, required this.originalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / originalWidth;
    final double scaleY = size.height / originalHeight;
    for (var result in results) {
      final box = result['bounding_box'];
      final disease = result['disease'];
      final conf = (result['confidence'] * 100).toInt();
      final rect = Rect.fromLTRB(box['x_min'] * scaleX, box['y_min'] * scaleY, box['x_max'] * scaleX, box['y_max'] * scaleY);

      Color boxColor = Colors.redAccent;
      if (disease == 'Implant') boxColor = Colors.blueAccent;
      if (disease == 'Fillings') boxColor = Colors.greenAccent;
      if (disease == 'Impacted Tooth') boxColor = Colors.orangeAccent;

      final paint = Paint()..color = boxColor..style = PaintingStyle.stroke..strokeWidth = 3.5;
      canvas.drawRect(rect, paint);

      const textStyle = TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, backgroundColor: Colors.black54);
      final textPainter = TextPainter(text: TextSpan(text: ' $disease $conf% ', style: textStyle), textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------
// 두 번째 탭: 치과 챗봇 화면 (스트리밍 완벽 구현)
// ---------------------------------------------------------
class ChatbotScreen extends StatefulWidget {
  final List<dynamic> aiResults;
  const ChatbotScreen({super.key, required this.aiResults});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  
  // 스트리밍 전송을 담당할 Dio 클라이언트 초기화
  final Dio _dio = Dio();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 실시간 챗봇 전송 함수 (고난도 로직)
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userMessage = _controller.text;
    
    setState(() {
      // 1. 유저 말풍선 추가
      _messages.add({"sender": "user", "text": userMessage});
      // 2. 중요! 껍데기만 있는 빈 AI 말풍선 미리 생성
      _messages.add({"sender": "ai", "text": ""});
      _isTyping = true;
    });
    
    final aiMessageIndex = _messages.length - 1; // 빈 AI 말풍선의 위치 기억
    _controller.clear();
    _scrollToBottom();

    try {
      // 디오를 사용하여 스트리밍 데이터를 받기 위해 responseType을 stream으로 설정합니다.
      final response = await _dio.post(
        'http://127.0.0.1:8000/api/chat-stream',
        data: {"message": userMessage, "context": widget.aiResults},
        options: Options(responseType: ResponseType.stream), // 가장 핵심적인 설정
      );

      // 서버로부터 도착하는 바이트 스트림 데이터(ResponseBody)를 비동기로 읽어옵니다.
      final stream = response.data.stream;
      String accumulatedData = ""; // 네트워크 지연으로 쪼개져 들어온 SSE 데이터를 하나로 뭉치기 위한 변수

      await for (final chunk in stream) {
        // 도착한 바이트 데이터를 문자열로 디코딩
        final text = utf8.decode(chunk);
        accumulatedData += text; // 기존 데이터에 덧붙임

        // SSE 표준 형식인 '\n\n' (더블 엔터)를 기준으로 개별 data 메시지를 파싱합니다.
        int sseEventIndex = accumulatedData.indexOf('\n\n');
        
        // 네트워크에서 한 줄이 완전히 도착했을 때만 파싱을 시작
        while (sseEventIndex != -1) {
          final eventString = accumulatedData.substring(0, sseEventIndex); // 하나의 개별data 전체 ("data: {...}")
          accumulatedData = accumulatedData.substring(sseEventIndex + 2); // 처리한 부분 제거

          // "data: "로 시작하는 경우에만 안쪽의 진짜 데이터를 추출
          if (eventString.startsWith('data: ')) {
            final jsonStr = eventString.substring(6); // JSON 파싱을 위해 "data: " 뒷부분만 잘라냄
            
            try {
              final chunkData = jsonDecode(jsonStr); // JSON 파싱
              
              // AI가 보낸 진짜 텍스트 조각 {"text": "충"}
              final String contentText = chunkData['text'] ?? "";
              
              if (contentText.isNotEmpty && mounted) {
                // 플러터 UI 업데이트: 미리 만들어둔 빈 AI 말풍선에 텍스트 조각을 '실시간으로' 덧붙임!
                setState(() {
                  _messages[aiMessageIndex]["text"] = _messages[aiMessageIndex]["text"]! + contentText;
                });
                _scrollToBottom(); // 글자가 추가될 때마다 자동으로 스크롤
              }
            } catch (e) {
              // 가끔 완료 신호나 메타데이터가 올 때 JSON 파싱 에러가 날 수 있으므로 가볍게 무시
              print("SSE 데이터 디코딩 에러 (정상): $e");
            }
          }
          // 남은 accumulatedData 안에서 다음 더블 엔터('\n\n') 위치 탐색
          sseEventIndex = accumulatedData.indexOf('\n\n');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[aiMessageIndex]["text"] = "네트워크 오류가 발생했습니다.\n에러: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('치과 전문 AI 상담')),
      body: Column(
        children: [
          if (widget.aiResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.teal.withOpacity(0.1),
              width: double.infinity,
              child: Text(
                '인식된 데이터: ${widget.aiResults.length}건의 소견 기반으로 대화합니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.teal),
              ),
            ),
            
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 답변 작성 중... 말풍선 대신, 글자가 실시간으로 쳐지므로 로딩 애니메이션은 입력창 윗부분에 살짝 표시
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                ),
              ),
            ),
            
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    // 스트리밍 답변 도중에는 새로운 질문 입력 방지
                    enabled: !_isTyping,
                    decoration: const InputDecoration(
                      hintText: "궁금한 점을 물어보세요...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  // 스트리밍 답변 도중에는 전송 버튼 비활성화
                  onPressed: _isTyping ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}