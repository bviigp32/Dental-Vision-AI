# train.py
from ultralytics import YOLO

def main():
    print("Mac Mini Pro GPU(MPS) 가속을 활용하여 학습을 시작합니다...")
    
    model = YOLO('yolov8n.pt')
    
    # 모델 학습 시작 (Apple Silicon 최적화 설정)
    results = model.train(
        data='./data.yaml',
        epochs=20,
        imgsz=640,
        
        device='mps', 
        
        batch=32,     
        
        workers=8     
    )
    
    print("학습이 완료되었습니다. 결과는 runs/detect/ 폴더에 저장됩니다.")

if __name__ == '__main__':
    main()