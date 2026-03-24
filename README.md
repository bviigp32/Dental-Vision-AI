# Dental Vision AI

> 치과 X-ray 이미지를 분석하여 주요 질환 및 보철물을 자동으로 탐지하는 AI 모델 파이프라인 및 크로스 플랫폼 앱

## 프로젝트 개요
* **목표:** 스마트폰 캡처 및 파노라마 치과 X-ray 사진에서 충치, 임플란트, 매복치 등의 위치를 정확히 탐지하는 객체 탐지(Object Detection) AI 개발 및 서비스화
* **현재 단계:** Phase 4 - AI 분석 결과 시각화 (Flutter CustomPaint 기반 Bounding Box 렌더링) 완료

## 기술 스택
* **AI Framework:** PyTorch, Ultralytics (YOLOv8)
* **Backend API:** FastAPI, Uvicorn
* **Frontend App:** Flutter, Dart
* **Hardware Acceleration:** Apple Silicon MPS

## 디렉토리 구조
```text
├── Data/                # 학습/검증 데이터셋 (Git 제외)
├── runs/                # 모델 학습 결과물 및 가중치 (Git 제외)
├── preprocess.py        # 데이터 전처리 스크립트
├── train.py             # 모델 파인튜닝 스크립트
├── main.py              # FastAPI 추론 서버 (CORS 세팅 완료)
└── dental_app/          # Flutter 크로스 플랫폼 프론트엔드 프로젝트
```

## 핵심 기능 구현 현황
* **AI 모델 학습:** 커스텀 치과 데이터셋을 활용한 YOLOv8 객체 탐지 모델 파인튜닝
* **API 서버:** FastAPI를 이용한 추론 서버 구축 및 파일 업로드 처리
* **크로스 플랫폼 앱:** 이미지 갤러리 연동 및 HTTP Multipart 통신 구현
* **결과 시각화:** 원본 이미지와 디바이스 화면 비율을 계산한 정확한 네모 박스 및 신뢰도 라벨 렌더링

## 실행 방법
1. **API 서버 구동:** `uvicorn main:app --reload`
2. **앱 실행:** `cd dental_app` 이동 후 `flutter run -d chrome` (웹) 또는 `flutter run -d macos` (데스크톱)

## 향후 계획 (Next Steps)
* **Phase 5 (모바일/기기 최적화):** 실제 스마트폰 카메라 직접 촬영 기능 연동 및 네이티브 권한 설정
* **Phase 6 (배포):** AWS 또는 GCP를 활용한 백엔드 서버 클라우드 배포


