# Dental Vision AI

> 치과 X-ray 이미지를 분석하여 주요 질환 및 보철물을 자동으로 탐지하는 AI 모델 파이프라인 및 API 서버

## 프로젝트 개요
* **목표:** 스마트폰 캡처 및 파노라마 치과 X-ray 사진에서 충치, 임플란트, 매복치 등의 위치를 정확히 탐지하는 객체 탐지(Object Detection) AI 개발 및 API 서비스화
* **현재 단계:** Phase 2 - FastAPI 기반 AI 추론(Inference) API 서버 구축 완료

## 탐지 클래스 (Classes)
AI 모델은 다음 4가지의 치아 상태를 식별하고 Bounding Box로 위치를 표시합니다.
0. **Implant** (임플란트)
1. **Fillings** (레진/충전물)
2. **Impacted Tooth** (매복치)
3. **Cavity** (충치)

## 기술 스택
* **AI Framework:** PyTorch, Ultralytics (YOLOv8)
* **Backend API:** FastAPI, Uvicorn, Python-multipart
* **Data Processing:** Pandas, Pillow
* **Hardware Acceleration:** Apple Silicon MPS (Metal Performance Shaders)

## 디렉토리 구조
```text
├── Data/                # 학습/검증/테스트 이미지 및 정답지(CSV) 폴더 (Git 제외)
├── runs/                # 모델 학습 결과물 및 모델 가중치(best.pt) 저장소 (Git 제외)
├── preprocess.py        # CSV 정답지 데이터를 YOLO 포맷(.txt)으로 변환하는 스크립트
├── data.yaml            # YOLO 모델 학습을 위한 데이터셋 경로 및 클래스 설정 파일
├── train.py             # Mac MPS 가속을 활용한 YOLOv8 모델 파인튜닝 스크립트
├── predict.py           # 학습된 가중치를 활용한 로컬 테스트용 추론 스크립트
└── main.py              # 외부에서 이미지를 받아 AI 분석 결과를 JSON으로 반환하는 FastAPI 서버
```

## 실행 방법

### AI 모델 학습 (선택)
데이터셋을 새로 구성하여 AI를 다시 학습시킬 경우 실행합니다.
```bash
python preprocess.py
python train.py
```

### API 서버 구동
학습된 모델을 기반으로 추론 API 서버를 실행합니다.
```bash
uvicorn main:app --reload
```
서버가 구동되면 `http://127.0.0.1:8000/docs` 에 접속하여 Swagger UI를 통해 이미지 업로드 및 AI 분석 API를 테스트할 수 있습니다.

## 향후 계획 (Next Steps)
* **Phase 3 (Frontend):** 치과 위생사 및 일반 사용자가 직접 사진을 업로드하고 시각화된 결과를 확인할 수 있는 클라이언트 앱(모바일/웹) 연동 및 UI 개발
* **Phase 4 (고도화):** 클라우드 환경(AWS/GCP) GPU 서버 배포 및 실제 사용자 데이터 피드백을 통한 모델 재학습 파이프라인 구축
```
