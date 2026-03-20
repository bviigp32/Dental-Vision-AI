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
        
        # 1. 핵심: CPU 대신 애플 실리콘 GPU(MPS) 사용
        device='mps', 
        
        # 2. 메모리 최적화: 한 번에 GPU로 보낼 이미지 개수 (기본값 16)
        # Mac mini Pro는 통합 메모리가 넉넉하므로 32로 올려서 속도를 높입니다.
        # (만약 Out of Memory 에러가 나면 16으로 다시 줄이세요)
        batch=32,     
        
        # 3. 데이터 로딩 병렬 처리: CPU 코어를 활용해 데이터를 빠르게 GPU로 퍼나릅니다.
        workers=8     
    )
    
    print("학습이 완료되었습니다. 결과는 runs/detect/ 폴더에 저장됩니다.")

if __name__ == '__main__':
    main()