import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart'; 
import 'package:video_player/video_player.dart';

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
      VideoScreen(aiResults: _globalAiResults), // 여기에 넘겨줍니다!
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
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
          NavigationDestination(
            icon: Icon(Icons.ondemand_video_outlined),
            selectedIcon: Icon(Icons.ondemand_video),
            label: '치아 관리 영상',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 첫 번째 탭: X-ray 정밀 분석 화면
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
// 두 번째 탭: 치과 챗봇 화면 (스트리밍 구현)
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

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userMessage = _controller.text;
    
    setState(() {
      _messages.add({"sender": "user", "text": userMessage});
      _messages.add({"sender": "ai", "text": ""});
      _isTyping = true;
    });
    
    final aiMessageIndex = _messages.length - 1; 
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _dio.post(
        'http://127.0.0.1:8000/api/chat-stream',
        data: {"message": userMessage, "context": widget.aiResults},
        options: Options(responseType: ResponseType.stream), 
      );

      final stream = response.data.stream;
      String accumulatedData = ""; 

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        accumulatedData += text; 

        int sseEventIndex = accumulatedData.indexOf('\n\n');
        
        while (sseEventIndex != -1) {
          final eventString = accumulatedData.substring(0, sseEventIndex); 
          accumulatedData = accumulatedData.substring(sseEventIndex + 2); 

          if (eventString.startsWith('data: ')) {
            final jsonStr = eventString.substring(6); 
            
            try {
              final chunkData = jsonDecode(jsonStr); 
              final String contentText = chunkData['text'] ?? "";
              
              if (contentText.isNotEmpty && mounted) {
                setState(() {
                  _messages[aiMessageIndex]["text"] = _messages[aiMessageIndex]["text"]! + contentText;
                });
                _scrollToBottom(); 
              }
            } catch (e) {
              print("SSE 데이터 디코딩 에러 (정상): $e");
            }
          }
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

// ---------------------------------------------------------
// 세 번째 탭: 맞춤형 치아 관리 영상 탭 
// ---------------------------------------------------------
class VideoScreen extends StatefulWidget {
  final List<dynamic> aiResults;
  
  const VideoScreen({super.key, required this.aiResults});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final Map<String, Map<String, String>> _videoDatabase = {
    'Cavity': {
      'assetPath': 'assets/videos/cavity.mp4', 
      'title': "올바른 양치질과 충치 예방법",
      'desc': "충치 진행을 막기 위한 양치법과 관리법을 확인하세요."
    },
    'Implant': {
      'assetPath': 'assets/videos/implant.mp4', 
      'title': "임플란트 사후 관리 가이드",
      'desc': "오래 사용하는 임플란트 관리 비법을 영상으로 만나보세요."
    },
    'Impacted Tooth': {
      'assetPath': 'assets/videos/impacted.mp4',
      'title': "매복치/사랑니 발치 후 주의사항",
      'desc': "발치 후 통증과 붓기를 줄이고 빠른 회복을 돕는 주의사항입니다."
    },
    'default': {
      'assetPath': 'assets/videos/default.mp4', 
      'title': "매일매일 실천하는 치과 상식",
      'desc': "꾸준한 관리가 건강한 치아를 만듭니다."
    }
  };

  List<Map<String, String>> _getVideosToShow() {
    List<Map<String, String>> videos = [];
    if (widget.aiResults.isEmpty) {
      videos.add(_videoDatabase['default']!);
      return videos;
    }
    Set<String> uniqueDiseases = widget.aiResults.map((e) => e['disease'].toString()).toSet();
    for (var disease in uniqueDiseases) {
      if (_videoDatabase.containsKey(disease)) {
        videos.add(_videoDatabase[disease]!);
      }
    }
    if (videos.isEmpty) {
      videos.add(_videoDatabase['default']!);
    }
    return videos;
  }

  @override
  Widget build(BuildContext context) {
    final videosToShow = _getVideosToShow();
    return Scaffold(
      appBar: AppBar(title: const Text('맞춤형 예방 및 관리 가이드')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: videosToShow.length,
        itemBuilder: (context, index) {
          final videoInfo = videosToShow[index];
          return VideoItemCard(
            index: index + 1,
            title: videoInfo['title']!,
            description: videoInfo['desc']!,
            assetPath: videoInfo['assetPath']!, // 🚀 에셋 경로 전달
          );
        },
      ),
    );
  }
}

class VideoItemCard extends StatefulWidget {
  final int index;
  final String title;
  final String description;
  final String assetPath;

  const VideoItemCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.assetPath,
  });

  @override
  State<VideoItemCard> createState() => _VideoItemCardState();
}

class _VideoItemCardState extends State<VideoItemCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '${widget.index}. ${widget.title}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          _isInitialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    FloatingActionButton(
                      heroTag: 'fab_${widget.index}',
                      backgroundColor: Colors.teal.withOpacity(0.8),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                )
              : const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.description,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}