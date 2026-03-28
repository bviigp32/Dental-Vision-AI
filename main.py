# main.py
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware 
from ultralytics import YOLO
from PIL import Image
import io

# FastAPI 앱 초기화
app = FastAPI(
    title="Dental AI Vision API",
    description="치과 X-ray 이미지를 분석하여 질환을 탐지하는 API",
    version="1.0.0"
)

# --- CORS 설정 부분 ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # 모든 출처(포트)에서의 요청을 허용 (로컬 테스트용)
    allow_credentials=True,
    allow_methods=["*"], # POST, GET 등 모든 방식 허용
    allow_headers=["*"],
)

# 1. 서버 시작 시 AI 모델을 메모리에 로드 (Global)
print("AI 모델을 로딩 중입니다...")

MODEL_PATH = "./runs/detect/train4/weights/best.pt" 
model = YOLO(MODEL_PATH)
print("AI 모델 로딩 완료!")

@app.post("/api/predict")
async def predict_xray(file: UploadFile = File(...)):
    """
    클라이언트로부터 X-ray 이미지를 받아 AI 분석 결과를 반환합니다.
    """
    # 1. 업로드된 파일을 메모리에서 읽어 이미지(PIL) 객체로 변환
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    
    # 2. AI 모델 추론 진행 (conf=0.25: 25% 이상 확신하는 것만)
    results = model.predict(image, conf=0.25)
    
    # 3. 결과 파싱 (JSON으로 응답하기 좋게 가공)
    detections = []
    
    # results는 배열 형태로 반환되므로 첫 번째 결과[0]를 사용
    for box in results[0].boxes:
        # 좌표값 추출 (xmin, ymin, xmax, ymax)
        x1, y1, x2, y2 = box.xyxy[0].tolist()
        
        # 신뢰도(확률) 추출
        conf = round(box.conf[0].item(), 2)
        
        # 질환명(클래스) 추출
        class_id = int(box.cls[0].item())
        class_name = model.names[class_id]
        
        detections.append({
            "disease": class_name,
            "confidence": conf,
            "bounding_box": {
                "x_min": round(x1, 2),
                "y_min": round(y1, 2),
                "x_max": round(x2, 2),
                "y_max": round(y2, 2)
            }
        })
        
    return {
        "filename": file.filename,
        "disease_count": len(detections),
        "results": detections
    }

from pydantic import BaseModel
from typing import List, Optional

# ... (기존 모델 로딩 및 /api/predict 코드는 그대로 유지) ...

# 챗봇 요청 데이터 모델 정의
class ChatRequest(BaseModel):
    message: str
    context: Optional[List[dict]] = None

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    user_message = request.message
    ai_context = request.context
    
    # 향후 여기에 OpenAI나 Gemini API 호출 로직이 들어갑니다.
    # 현재는 프론트엔드에서 데이터가 잘 넘어오는지 확인하기 위한 모의 로직입니다.
    
    response_text = ""
    
    if ai_context and len(ai_context) > 0:
        disease_names = [item['disease'] for item in ai_context]
        response_text = f"현재 엑스레이 분석 결과 {', '.join(disease_names)} 소견이 있습니다. "
    else:
        response_text = "현재 분석된 엑스레이 데이터가 없습니다. 일반적인 치과 상담을 진행합니다. "
        
    response_text += f"\n환자님의 질문 '{user_message}'에 대한 치과 전문의 수준의 답변을 여기에 생성할 예정입니다."
    
    return {"reply": response_text}