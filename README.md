# Dental Vision AI (가칭)

> 치과 X-ray 이미지를 분석하여 주요 질환 및 보철물을 자동으로 탐지하는 AI 모델 파이프라인

## 프로젝트 개요
* **목표:** 스마트폰 캡처 및 파노라마 치과 X-ray 사진에서 충치, 임플란트, 매복치 등의 위치를 정확히 탐지하는 객체 탐지(Object Detection) AI 개발
* **현재 단계:** Phase 1 - 컴퓨터 비전 모델(YOLOv8) 커스텀 학습 및 추론 검증 완료

## 탐지 클래스 (Classes)
AI 모델은 다음 4가지의 치아 상태를 식별하고 Bounding Box로 위치를 표시합니다.
0. **Implant** (임플란트)
1. **Fillings** (레진/충전물)
2. **Impacted Tooth** (매복치)
3. **Cavity** (충치)

## 기술 스택
* **AI Framework:** PyTorch, Ultralytics (YOLOv8)
* **Data Processing:** Pandas, Python
* **Hardware Acceleration:** Apple Silicon MPS (Metal Performance Shaders)

## 디렉토리 구조
```text
├── Data/                # 학습/검증/테스트 이미지 및 정답지(CSV) 폴더
├── runs/                # 모델 학습 결과물 및 추론(Predict) 결과 이미지 저장소
├── preprocess.py        # CSV 정답지 데이터를 YOLO 포맷(.txt)으로 변환하는 스크립트
├── data.yaml            # YOLO 모델 학습을 위한 데이터셋 경로 및 클래스 설정 파일
├── train.py             # Mac MPS 가속을 활용한 YOLOv8 모델 파인튜닝 스크립트
└── predict.py           # 학습된 가중치(best.pt)를 활용한 새로운 X-ray 이미지 추론 스크립트
```

## 실행 방법

**1. 데이터 전처리**
CSV 형태의 라벨 데이터를 YOLO 모델이 읽을 수 있는 형식으로 변환합니다.
```bash
python preprocess.py
```

**2. AI 모델 학습**
M시리즈 Mac의 GPU(MPS)를 활용하여 모델 학습을 시작합니다.
```bash
python train.py
```

**3. 모델 추론 (테스트)**
학습된 최고 성능의 가중치(`runs/detect/train/weights/best.pt`)를 바탕으로 새로운 X-ray 사진을 분석합니다.
```bash
python predict.py
```

## 향후 계획 (Next Steps)
* **Phase 2 (Backend):** 학습된 AI 모델을 FastAPI 서버에 올려 REST API 형태로 서빙 (AI Inference Server 구축)
* **Phase 3 (Frontend):** 치과 위생사 및 사용자가 직접 사진을 업로드하고 결과를 확인할 수 있는 모바일 앱(Flutter 등) 연동 및 UI 개발
* **Phase 4 (고도화):** 실제 치과 전문의의 피드백을 반영한 데이터셋 확충 및 모델 재학습 파이프라인 구축
```
