# Dental Vision AI

> 치과 X-ray 이미지를 분석하여 주요 질환을 탐지하고, 그 결과를 바탕으로 전문적인 상담을 제공하는 AI 앱

## 프로젝트 개요
* **목표:** X-ray 객체 탐지(Object Detection) AI와 대규모 언어 모델(LLM)을 결합한 종합 의료 AI 서비스 구축
* **현재 단계:** Phase 6 - 로컬 프로토타입 완성 (UI 개편 및 Gemini 2.5 Flash 챗봇 연동 완료)

## 기술 스택
* **Vision AI:** PyTorch, Ultralytics (YOLOv8)
* **LLM:** Google Gemini 2.5 Flash, LangChain
* **Backend:** FastAPI, Uvicorn
* **Frontend:** Flutter (Web/iOS/Android 호환)

## 핵심 기능 구현 현황
* **AI 비전 분석:** 커스텀 치과 데이터셋으로 학습된 YOLOv8 모델이 질환(충치, 임플란트 등)의 Bounding Box 좌표 반환
* **크로스 플랫폼 앱:** 카메라 직접 촬영 및 갤러리 연동, 시각화(CustomPaint) 처리 및 모던 UI(Bottom Navigation) 적용
* **Context-Aware 챗봇:** 비전 AI의 분석 결과를 LLM의 System Prompt로 주입하여, 환자의 현재 상태를 인지하고 대화하는 맞춤형 AI 상담사 구현

## 실행 방법 (Local)
1. **API 서버 구동:** `uvicorn main:app --reload` (루트 디렉토리)
2. **앱 실행:** `cd dental_app` 이동 후 `flutter run -d chrome`

## 향후 계획 (Next Steps)
* **Phase 6 (클라우드 배포):** 외부 환경에서도 앱이 작동할 수 있도록 AI 백엔드 서버를 클라우드 환경에 배포

