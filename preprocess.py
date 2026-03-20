import os
import pandas as pd

def convert_csv_to_yolo(base_dir):
    folders = ['train', 'valid', 'test']
    classes_map = {}
    class_id_counter = 0

    for folder in folders:
        folder_path = os.path.join(base_dir, folder)
        csv_path = os.path.join(folder_path, '_annotations.csv')
        
        if not os.path.exists(csv_path):
            print(f"경고: {csv_path} 파일을 찾을 수 없습니다.")
            continue
            
        print(f"[{folder}] 폴더 변환 시작...")
        df = pd.read_csv(csv_path)
        
        # 고유한 클래스(질환명)를 찾아 숫자로 매핑
        for cls in df['class'].unique():
            if cls not in classes_map:
                classes_map[cls] = class_id_counter
                class_id_counter += 1
        
        # 이미지 파일명 단위로 그룹화하여 txt 파일 생성
        for filename, group in df.groupby('filename'):
            txt_filename = os.path.splitext(filename)[0] + '.txt'
            txt_path = os.path.join(folder_path, txt_filename)
            
            with open(txt_path, 'w') as f:
                for _, row in group.iterrows():
                    img_w = row['width']
                    img_h = row['height']
                    
                    # YOLO 포맷으로 좌표 정규화 (0 ~ 1 사이 값)
                    center_x = (row['xmin'] + row['xmax']) / 2.0 / img_w
                    center_y = (row['ymin'] + row['ymax']) / 2.0 / img_h
                    bbox_width = (row['xmax'] - row['xmin']) / img_w
                    bbox_height = (row['ymax'] - row['ymin']) / img_h
                    
                    class_id = classes_map[row['class']]
                    
                    # class_id center_x center_y width height 형식으로 기록
                    f.write(f"{class_id} {center_x:.6f} {center_y:.6f} {bbox_width:.6f} {bbox_height:.6f}\n")
                    
        print(f"[{folder}] 폴더 내 {len(df['filename'].unique())}개 이미지에 대한 라벨링 파일 생성 완료.")
        
    return classes_map

# archive 폴더가 있는 실제 경로로 지정하여 실행
base_directory = './Data'
result_map = convert_csv_to_yolo(base_directory)

print("\n최종 클래스 매핑 결과:")
print(result_map)