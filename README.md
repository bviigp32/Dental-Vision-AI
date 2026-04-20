# Dental Vision AI

> **컴퓨터 비전(Vision AI)과 대규모 언어 모델(LLM)을 결합한 지능형 치과 질환 분석 및 맞춤형 상담 플랫폼**

환자의 X-ray 이미지를 실시간으로 분석하여 질환을 탐지하고, 그 결과를 바탕으로 전문적인 AI 상담과 사후 관리 영상까지 End-to-End로 제공하는 크로스 플랫폼 애플리케이션입니다. 단순한 기능 구현을 넘어 **실시간 스트리밍(SSE), 컨텍스트 주입(Context-Aware), 사용자 심리를 고려한 UX 최적화** 등 서비스의 완성도를 높이는 데 집중했습니다.

<br>

## Tech Stack

### Backend & AI
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white) 
![YOLOv8](https://img.shields.io/badge/YOLOv8-00FFFF?style=flat-square&logo=yolo&logoColor=black) ![PyTorch](https://img.shields.io/badge/PyTorch-EE4C2C?style=flat-square&logo=pytorch&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google_Gemini-8E75B2?style=flat-square&logo=googlegemini&logoColor=white) ![LangChain](https://img.shields.io/badge/LangChain-1C3C3C?style=flat-square&logo=langchain&logoColor=white)

### Frontend & App
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white) ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) ![Dio](https://img.shields.io/badge/Dio-0175C2?style=flat-square&logo=dart&logoColor=white)

### Infrastructure & Tools
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white) ![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white)

<br>

## Core Features & Engineering

### 1. 실시간 응답 스트리밍 파이프라인 (SSE)
* **초기 응답 지연 80% 감소:** 생성형 AI의 가장 큰 문제인 '긴 응답 대기 시간'으로 인한 사용자 이탈을 방지하기 위해, **Server-Sent Events(SSE)** 프로토콜을 도입했습니다.
* 서버에서 생성되는 토큰을 클라이언트에 한 글자씩 실시간 스트리밍하여, 첫 토큰 노출 시간(TTFT)을 혁신적으로 단축하고 대화형 실시간 상담 경험을 구축했습니다.

### 2. 고정밀 X-ray 분석 및 좌표 스케일링
* **객체 탐지 모델 최적화:** 치과 데이터셋으로 파인튜닝된 **YOLOv8** 모델을 적용하여 충치, 임플란트 등의 위치를 추론합니다.
* **디바이스 독립적 정합성:** CustomPaint 기반의 좌표 변환 알고리즘을 설계하여, 원본 이미지와 디바이스 렌더링 화면의 비율을 동적으로 계산합니다. 이를 통해 다양한 모바일 해상도에서도 Bounding Box가 픽셀 단위로 정확히 일치합니다.

### 3. Context-Aware AI 상담 및 미디어 큐레이션
* **동적 프롬프트 주입:** 비전 AI의 분석 데이터(질환명, 발견 개수 등)를 **Gemini 2.5 Flash**의 시스템 프롬프트에 실시간 주입하여 환자 맞춤형 상담을 진행합니다.
* **로컬 에셋 기반 무지연 영상 재생:** 탐지된 질환에 맞는 교육 영상을 자동 큐레이션합니다. 네트워크나 Iframe 의존성을 제거하고 앱 내부 에셋으로 영상을 패키징하여, CORS 에러 없는 안정적인 멀티미디어 환경을 구축했습니다.

### 4. 사용자 심리를 고려한 UX 최적화 (Labor Illusion)
* **의도적 지연과 시각적 신뢰도 확보:** AI 서버의 응답이 지나치게 빠를 경우 사용자가 분석의 전문성을 의심할 수 있는 점을 고려하여, **Labor Illusion(노동 착각)** 개념을 도입했습니다.
* 최소 보장 로딩 시간(2.5초)과 Lottie 기반의 스캐닝 애니메이션을 결합하여, 전문 의료 시스템으로서의 시각적 신뢰도를 극대화했습니다. 탭 전환 시에는 `IndexedStack`을 통해 대화와 분석 상태를 안전하게 유지합니다.

<br>

## System Workflow

1. **[Image Upload]** 사용자가 카메라 촬영 또는 갤러리를 통해 X-ray 이미지를 업로드합니다.
2. **[Async Inference]** FastAPI 비동기 서버가 이미지를 수신하고, YOLOv8 모델을 통해 질환 위치 및 신뢰도 데이터를 반환합니다.
3. **[Context Injection]** 추출된 분석 결과를 기반으로 LangChain이 프롬프트를 재구성하여 상태 인지형(Context-Aware) 환경을 세팅합니다.
4. **[LLM Streaming]** Gemini API가 맞춤형 답변을 생성하고, SSE 통신을 통해 클라이언트에 토큰 단위로 실시간 전송합니다.

<br>

## Getting Started

프로젝트를 로컬 환경에서 실행하는 방법입니다.

### 1. Backend 서버 구동 (FastAPI)
```bash
# 가상환경 설정 및 패키지 설치
$ pip install -r requirements.txt

# 환경변수 파일(.env) 생성 및 Gemini API 키 입력
# GEMINI_API_KEY="your_api_key_here"

# Uvicorn을 이용한 서버 실행 (기본 포트 8000)
$ uvicorn main:app --reload
```

### 2. Frontend 앱 구동 (Flutter)
```bash
# 앱 디렉토리로 이동
$ cd dental_app

# 의존성 패키지 다운로드
$ flutter pub get

# 웹(Chrome) 환경으로 실행
$ flutter run -d chrome
```
