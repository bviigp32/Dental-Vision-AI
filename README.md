# Dental Vision AI

> 치과 X-ray 이미지를 분석하여 주요 질환 및 보철물을 자동으로 탐지하는 AI 모델 파이프라인 및 크로스 플랫폼 앱

## 프로젝트 개요
* **목표:** 스마트폰 캡처 및 파노라마 치과 X-ray 사진에서 충치, 임플란트, 매복치 등의 위치를 정확히 탐지하는 객체 탐지(Object Detection) AI 개발 및 서비스화
* **현재 단계:** Phase 3 - Flutter 기반 프론트엔드 구축 및 백엔드(FastAPI) API 연동 완료 (Web/App 크로스 플랫폼)

## 기술 스택
* **AI Framework:** PyTorch, Ultralytics (YOLOv8)
* **Backend API:** FastAPI, Uvicorn (CORS Middleware 적용)
* **Frontend App:** Flutter, Dart (Web/iOS/Android 지원)
* **Hardware Acceleration:** Apple Silicon MPS

## 디렉토리 구조
```text
├── Data/                # 학습/검증 데이터셋 (Git 제외)
├── runs/                # 모델 학습 결과물 및 가중치 (Git 제외)
├── preprocess.py        # 데이터 전처리 스크립트
├── train.py             # 모델 파인튜닝 스크립트
├── main.py              # FastAPI 추론 서버 (CORS 세팅 완료)
└── dental_app/          # Flutter 크로스 플랫폼 프론트엔드 프로젝트
    ├── lib/main.dart    # UI 및 HTTP 통신, JSON 파싱 로직
    └── pubspec.yaml     # 플러터 패키지 관리자 (image_picker, http)
```

## 실행 방법

### 1. API 서버 구동 (Backend)
FastAPI 서버를 실행하여 클라이언트의 요청을 대기합니다.
```bash
uvicorn main:app --reload
```

### 2. 클라이언트 앱 실행 (Frontend)
새로운 터미널에서 `dental_app` 폴더로 이동한 뒤 앱을 실행합니다.
```bash
cd dental_app
flutter run -d chrome  # 웹 브라우저 테스트용
# 또는 flutter run -d macos  # 데스크톱 앱 테스트용
```

## 향후 계획 (Next Steps)
* **Phase 4 (UI 고도화):** JSON으로 전달받은 Bounding Box 좌표를 Flutter의 CustomPaint를 활용하여 실제 업로드한 X-ray 이미지 위에 시각적으로 렌더링
* **Phase 5 (모바일 최적화):** iOS 시뮬레이터 및 실제 모바일 기기에서의 구동 테스트 및 카메라 직접 촬영 기능 추가
* **Phase 6 (배포):** AWS 또는 GCP를 활용한 백엔드 서버 클라우드 배포

