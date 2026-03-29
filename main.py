import os
import io
import json
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from ultralytics import YOLO
from PIL import Image
from dotenv import load_dotenv

# 1. 환경 변수 로드
load_dotenv()

# 2. DocuMind에서 사용했던 LangChain 패키지 임포트
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import SystemMessage, HumanMessage

app = FastAPI(
    title="Dental AI Vision API",
    description="치과 X-ray 분석 및 Gemini AI 챗봇 API (LangChain)",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("AI 비전 모델을 로딩 중입니다...")
# 본인의 best.pt 경로에 맞게 수정되어 있는지 확인
MODEL_PATH = "./runs/detect/train4/weights/best.pt"
model = YOLO(MODEL_PATH)
print("AI 비전 모델 로딩 완료.")

@app.post("/api/predict")
async def predict_xray(file: UploadFile = File(...)):
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    
    results = model.predict(image, conf=0.25)
    detections = []
    
    for box in results[0].boxes:
        x1, y1, x2, y2 = box.xyxy[0].tolist()
        conf = round(box.conf[0].item(), 2)
        class_id = int(box.cls[0].item())
        class_name = model.names[class_id]
        
        detections.append({
            "disease": class_name,
            "confidence": conf,
            "bounding_box": {
                "x_min": round(x1, 2), "y_min": round(y1, 2),
                "x_max": round(x2, 2), "y_max": round(y2, 2)
            }
        })
        
    return {
        "filename": file.filename,
        "disease_count": len(detections),
        "results": detections
    }

# ---------------------------------------------------------
# Gemini 챗봇 연동 API (LangChain 방식)
# ---------------------------------------------------------
class ChatRequest(BaseModel):
    message: str
    context: Optional[List[dict]] = None

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    user_message = request.message
    ai_context = request.context
    
    context_str = "현재 분석된 엑스레이 데이터가 없습니다. 일반적인 치과 상담을 진행합니다."
    
    if ai_context and len(ai_context) > 0:
        disease_counts = {}
        for item in ai_context:
            disease = item['disease']
            disease_counts[disease] = disease_counts.get(disease, 0) + 1
        
        context_parts = []
        for disease, count in disease_counts.items():
            context_parts.append(f"{disease} {count}개")
            
        context_str = f"환자의 엑스레이 분석 결과, 현재 {', '.join(context_parts)}가 발견되었습니다."

    system_prompt = f"""당신은 10년 차 경력의 친절하고 전문적인 AI 치과 의사입니다. 
당신의 임무는 환자의 질문에 답하고 치과 질환에 대한 조언을 제공하는 것입니다.

[환자 현재 상태 정보]
{context_str}

[지시사항]
1. 환자의 현재 상태 정보를 바탕으로 맞춤형 상담을 제공하십시오.
2. 환자가 엑스레이 결과와 관련된 질문을 하면, 상태 정보를 참고하여 알기 쉽게 설명해주십시오.
3. 충치(Cavity), 임플란트(Implant), 매복치(Impacted Tooth), 레진/충전물(Fillings) 등 전문 용어는 환자가 이해하기 쉬운 일상적인 언어로 풀어서 설명하십시오.
4. 모든 의학적 조언의 끝에는 '정확한 진단은 실제 치과 전문의의 대면 진료를 통해 받아야 한다'는 점을 부드럽게 명시하십시오.
"""

    try:
        # 3. DocuMind에서 성공했던 gemini-2.5-flash 모델 호출
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            temperature=0.7
        )
        
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_message)
        ]
        
        # 비동기(ainvoke)로 답변 생성
        response = await llm.ainvoke(messages)
        
        return {"reply": response.content}
        
    except Exception as e:
        return {"reply": f"Gemini API 통신 중 문제가 발생했습니다: {str(e)}"}