import os
from ultralytics import YOLO

def main():
    print("학습된 치과 AI 모델을 불러옵니다.")
    
    # 학습된 최고 성능의 가중치 파일 경로
    # 만약 저장된 경로가 다르다면 아래 부분을 수정해 주십시오.
    model_path = './runs/detect/train4/weights/best.pt' 
    
    if not os.path.exists(model_path):
        print(f"경고: {model_path} 파일을 찾을 수 없습니다. runs/detect/ 폴더 구조를 확인해 주십시오.")
        return

    # 모델 로드
    model = YOLO(model_path)
    
    # 테스트할 이미지가 있는 폴더 경로 (Data 폴더 기준)
    test_source = './Data/test' 
    
    print(f"[{test_source}] 폴더의 이미지들을 분석합니다.")
    
    # 추론 실행
    # save=True: 예측 결과(네모 박스가 쳐진 이미지)를 파일로 저장합니다.
    # conf=0.25: AI가 25% 이상 확신하는 결과만 화면에 표시합니다.
    results = model.predict(source=test_source, save=True, conf=0.25)
    
    print("분석이 완료되었습니다. 결과는 runs/detect/predict 폴더에 저장되었습니다.")

if __name__ == '__main__':
    main()