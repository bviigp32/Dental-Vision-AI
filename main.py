import os
import io
import json
import asyncio # 비동기 처리를 위해 추가
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse # 스트리밍 응답을 위해 추가
from pydantic import BaseModel
from typing import List, Optional
from ultralytics import YOLO
from PIL import Image
from dotenv import load_dotenv

# 1. 환경 변수 로드
load_dotenv()

# DocuMind 프로젝트 패키지
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import SystemMessage, HumanMessage

app = FastAPI(
    title="Dental AI Vision API",
    description="치과 X-ray 분석 및 Gemini AI 스트리밍 챗봇 API (LangChain)",
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
# Gemini 챗봇 스트리밍 API (SSE 구현)
# ---------------------------------------------------------
class ChatRequest(BaseModel):
    message: str
    context: Optional[List[dict]] = None

# 챗봇이 생성하는 답변 토큰을 하나씩 SSE 형식으로 포맷팅하여 프론트엔드로 흘려보내는 제너레이터 함수
async def generate_chat_stream(llm, messages):
    # ainvoke 대신 랭체인의 astream을 사용합니다.
    async for chunk in llm.astream(messages):
        content = chunk.content
        if content:
            # SSE 표준 형식: "data: <데이터내용>\n\n"
            # 프론트엔드에서 파싱하기 쉽도록 JSON 문자열로 감싸서 보냅니다.
            # {"text": "충"}
            data = json.dumps({"text": content})
            yield f"data: {data}\n\n"
            # 네트워크가 너무 빠르면 스트리밍 효과가 안 보일 수 있으므로 로컬 테스트 시 아주 미세한 딜레이를 줍니다.
            await asyncio.sleep(0.01) 

@app.post("/api/chat-stream") # 엔드포인트 이름을 직관적으로 변경
async def chat_stream_endpoint(request: ChatRequest):
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
        # LLM 초기화 (DocuMind 방식 그대로 gemini-2.5-flash)
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            temperature=0.7
        )
        
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_message)
        ]
        
        # JSON 대신 StreamingResponse를 반환합니다. 제너레이터 함수를 연결하고 미디어 타입을 설정합니다.
        return StreamingResponse(
            generate_chat_stream(llm, messages),
            media_type="text/event-stream" # SSE 표준 미디어 타입
        )
        
    except Exception as e:
        # 스트리밍 도중 오류 발생 시 프론트엔드로 에러 메시지를 SSE 형식으로 전송
        error_data = json.dumps({"error": str(e)})
        return StreamingResponse(
            (item for item in [f"data: {error_data}\n\n"]),
            media_type="text/event-stream"
        )