# main.py
from fastapi import FastAPI, UploadFile, File
from ultralytics import YOLO
from PIL import Image
import io

# FastAPI 앱 초기화
app = FastAPI(
    title="Dental AI Vision API",
    description="치과 X-ray 이미지를 분석하여 질환을 탐지하는 API",
    version="1.0.0"
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