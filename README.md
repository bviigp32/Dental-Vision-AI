# Dental Vision AI

> **컴퓨터 비전(Vision AI)과 대규모 언어 모델(LLM)을 결합한 지능형 치과 질환 분석 및 맞춤형 상담 플랫폼**

환자의 X-ray 이미지를 실시간으로 분석하여 질환을 탐지하고, 그 결과를 바탕으로 전문적인 AI 상담과 사후 관리 영상까지 End-to-End로 제공하는 크로스 플랫폼 애플리케이션입니다. 단순한 기능 구현을 넘어 **실시간 스트리밍(SSE), 컨텍스트 주입(Context-Aware), 좌표 스케일링** 등 최적화된 아키텍처를 자랑합니다.

<br>

## Tech Stack

### Languages
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white) ![Go](https://img.shields.io/badge/Go-00ADD8?style=flat-square&logo=go&logoColor=white) ![C++](https://img.shields.io/badge/C++-00599C?style=flat-square&logo=c%2B%2B&logoColor=white)

### Backend & API
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white) ![Celery](https://img.shields.io/badge/Celery-37814A?style=flat-square&logo=celery&logoColor=white) ![Kafka](https://img.shields.io/badge/Apache_Kafka-231F20?style=flat-square&logo=apachekafka&logoColor=white) ![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?style=flat-square&logo=rabbitmq&logoColor=white) ![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat-square&logo=redis&logoColor=white)

### AI & Data Engineering
![YOLOv8](https://img.shields.io/badge/YOLOv8-00FFFF?style=flat-square&logo=yolo&logoColor=black) ![PyTorch](https://img.shields.io/badge/PyTorch-EE4C2C?style=flat-square&logo=pytorch&logoColor=white) ![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=flat-square&logo=opencv&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google_Gemini-8E75B2?style=flat-square&logo=googlegemini&logoColor=white) ![LangChain](https://img.shields.io/badge/LangChain-1C3C3C?style=flat-square&logo=langchain&logoColor=white) ![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=flat-square&logo=openai&logoColor=white) ![Hugging Face](https://img.shields.io/badge/Hugging_Face-FFD21E?style=flat-square&logo=huggingface&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=flat-square&logo=pandas&logoColor=white) ![NumPy](https://img.shields.io/badge/NumPy-013243?style=flat-square&logo=numpy&logoColor=white) ![Scikit-learn](https://img.shields.io/badge/Scikit--learn-F7931E?style=flat-square&logo=scikitlearn&logoColor=white)

### Database & Vector DB
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat-square&logo=mysql&logoColor=white)
![ChromaDB](https://img.shields.io/badge/ChromaDB-FF6F00?style=flat-square) ![Milvus](https://img.shields.io/badge/Milvus-0D122B?style=flat-square) ![Qdrant](https://img.shields.io/badge/Qdrant-D33659?style=flat-square)

### Infra & Frontend
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white) ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![Elasticsearch](https://img.shields.io/badge/Elasticsearch-005571?style=flat-square&logo=elasticsearch&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)

<br>

## Core Features & Engineering

### 1. 고정밀 X-ray 분석 (Vision AI Pipeline)
* **객체 탐지 모델 최적화:** 치과 데이터셋으로 세밀하게 파인튜닝된 **YOLOv8** 모델을 적용하여 충치, 임플란트, 매복치 등의 위치와 신뢰도를 실시간으로 추론합니다.
* **멀티 디바이스 좌표 스케일링 (Coordinate Scaling):** 원본 이미지와 디바이스 렌더링 화면의 비율을 동적으로 계산하여, 어떠한 해상도에서도 Bounding Box가 픽셀 단위로 정확히 일치하도록 설계했습니다.

### 2. Context-Aware AI 상담 (LLM Integration)
* **동적 프롬프트 주입:** 비전 AI가 분석한 결과를 단순히 화면에 띄우는 것에 그치지 않고, 해당 데이터(질환명, 발견 개수 등)를 **Gemini 2.5 Flash**의 시스템 프롬프트(System Instruction)로 실시간 주입하여 환자 맞춤형 상담을 진행합니다.
* **SSE 기반 실시간 답변 스트리밍:** 생성형 AI의 가장 큰 문제인 '긴 응답 대기 시간'을 극복하기 위해, **Server-Sent Events(SSE)** 프로토콜을 도입하여 서버에서 생성되는 토큰을 한 글자씩 프론트엔드로 스트리밍합니다. 이를 통해 **초기 응답 지연을 약 80% 이상 감소**시켰습니다.

### 3. 치아 관리 가이드 (Video Education)
* **의료 경험의 확장:** 진단과 상담을 넘어 사후 관리까지 책임질 수 있도록 네이티브 비디오 플레이어를 연동하여, 올바른 치아 관리 및 예방 영상을 시청할 수 있는 멀티미디어 환경을 구축했습니다.

<br>

## System Workflow

1. **[Image Upload]** Flutter 앱에서 사용자가 카메라 촬영 또는 갤러리를 통해 X-ray 이미지를 업로드합니다.
2. **[Async Inference]** FastAPI 비동기 서버가 이미지를 수신하고, YOLOv8 모델을 통해 질환 위치 및 신뢰도(Confidence) 데이터를 반환합니다.
3. **[Context Injection]** 추출된 분석 결과를 기반으로 LangChain이 LLM 프롬프트를 재구성하여 상태 인지형(Context-Aware) 환경을 세팅합니다.
4. **[LLM Streaming]** 사용자의 질문이 들어오면, Gemini API가 답변을 생성하고 SSE 통신을 통해 클라이언트에 토큰 단위로 실시간 전송합니다.

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

<br>
