import os
import json
import math

# Intentar importar dependencias requeridas y advertir si no están instaladas
try:
    import cv2
except ImportError:
    cv2 = None
    print("⚠️ Advertencia: OpenCV (cv2) no está instalado. No se podrán procesar videos.")

try:
    import numpy as np
except ImportError:
    np = None
    print("⚠️ Advertencia: NumPy no está instalado.")

try:
    import kagglehub
except ImportError:
    kagglehub = None
    print("⚠️ Advertencia: kagglehub no está instalado. Se omitirá la descarga de datasets.")

try:
    import matplotlib.pyplot as plt
except ImportError:
    plt = None
    print("⚠️ Advertencia: matplotlib no está instalado.")

try:
    import mediapipe as mp
    import mediapipe.python.solutions.pose as mp_solutions_pose
except ImportError:
    mp = None
    mp_solutions_pose = None
    print("⚠️ Advertencia: MediaPipe no está instalado. Asegúrate de instalarlo usando el entorno virtual.")

# --- CONFIGURACIÓN Y DESCARGA ---
dataset_1_path = None
dataset_2_path = None

def calculate_angle(a, b, c):
    """Calcula el ángulo en grados en el vértice B formado por los puntos A, B y C."""
    a = np.array(a)  # [x, y]
    b = np.array(b)  # Vértice [x, y]
    c = np.array(c)  # [x, y]
    
    ba = a - b
    bc = c - b
    
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    
    return np.degrees(angle)

def calculate_torso_angle(shoulder, hip):
    """Calcula el ángulo de inclinación del torso con respecto a la vertical (eje Y)."""
    dx = shoulder[0] - hip[0]
    dy = shoulder[1] - hip[1]
    
    angle = math.degrees(math.atan2(abs(dx), abs(dy)))
    return angle

def profile_video(video_path, exercise_type, max_frames=500):
    """Procesa un video y extrae las curvas de los ángulos de articulaciones clave."""
    if mp is None:
        print("MediaPipe no está disponible para procesar el video.")
        return None
        
    mp_pose = mp_solutions_pose
    if mp_pose is None:
        print("MediaPipe pose detector no está disponible.")
        return None
    pose = mp_pose.Pose(static_image_mode=False, min_detection_confidence=0.5, min_tracking_confidence=0.5)
    
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"No se pudo abrir el video: {video_path}")
        return None
        
    angles_history = []
    frames_processed = 0
    
    while cap.isOpened() and frames_processed < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
            
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb_frame)
        
        if results.pose_landmarks:
            landmarks = results.pose_landmarks.landmark
            
            # Puntos clave normalizados
            h_right = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value].x, landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value].y]
            k_right = [landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value].x, landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value].y]
            a_right = [landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].x, landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].y]
            s_right = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].x, landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].y]
            e_right = [landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value].x, landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value].y]
            w_right = [landmarks[mp_pose.PoseLandmark.RIGHT_WRIST.value].x, landmarks[mp_pose.PoseLandmark.RIGHT_WRIST.value].y]
            
            # Calcular ángulos relevantes
            knee_angle = calculate_angle(h_right, k_right, a_right)
            hip_angle = calculate_angle(s_right, h_right, k_right)
            elbow_angle = calculate_angle(s_right, e_right, w_right)
            torso_angle = calculate_torso_angle(s_right, h_right)
            
            angles_history.append({
                "frame": frames_processed,
                "knee": knee_angle,
                "hip": hip_angle,
                "elbow": elbow_angle,
                "torso": torso_angle
            })
            
        frames_processed += 1
        
    cap.release()
    pose.close()
    return angles_history

def extract_profile_stats(history, exercise_type):
    """Analiza el historial de ángulos para extraer umbrales recomendados."""
    if not history:
        return {}
        
    knees = [f["knee"] for f in history]
    hips = [f["hip"] for f in history]
    elbows = [f["elbow"] for f in history]
    torsos = [f["torso"] for f in history]
    
    stats = {}
    
    # 1. Patrón tipo "Sentadilla/Rodilla"
    if exercise_type in ["squats", "leg_extension"]:
        min_knee = min(knees)
        max_knee = max(knees)
        deepest_idx = knees.index(min_knee)
        torso_at_deepest = torsos[deepest_idx]
        
        if exercise_type == "squats":
            stats = {
                "knee_angle_range_min": float(min_knee),
                "knee_angle_range_max": float(max_knee),
                "recommended_target_knee_angle": float(min_knee + 10),
                "max_allowed_torso_angle": float(torso_at_deepest + 15),
                "is_decrease": True,
                "primary_joint": "knee"
            }
        else: # leg_extension
            stats = {
                "knee_angle_range_min": float(min_knee),
                "knee_angle_range_max": float(max_knee),
                "recommended_target_knee_angle": float(max_knee - 10),
                "is_decrease": False,
                "primary_joint": "knee"
            }
            
    # 2. Patrón tipo "Empuje/Codo"
    elif exercise_type in ["pushups", "bench_press", "decline_bench_press", "incline_bench_press", "shoulder_press", "tricep_pushdown", "tricep_dips"]:
        min_elbow = min(elbows)
        max_elbow = max(elbows)
        avg_hip = np.mean(hips)
        
        is_decrease = True
        if exercise_type in ["shoulder_press", "tricep_pushdown"]:
            is_decrease = False
            
        stats = {
            "elbow_angle_range_min": float(min_elbow),
            "elbow_angle_range_max": float(max_elbow),
            "recommended_target_elbow_angle": float(min_elbow + 15) if is_decrease else float(max_elbow - 15),
            "min_hip_alignment_angle": float(avg_hip - 20),
            "max_hip_alignment_angle": float(avg_hip + 20),
            "is_decrease": is_decrease,
            "primary_joint": "elbow"
        }
        
    # 3. Patrón tipo "Tracción/Flexión Codo"
    elif exercise_type in ["bicep_curls", "hammer_curl", "lat_pulldown", "pull_up", "t_bar_row"]:
        min_elbow = min(elbows)
        max_elbow = max(elbows)
        
        stats = {
            "elbow_angle_range_min": float(min_elbow),
            "elbow_angle_range_max": float(max_elbow),
            "recommended_peak_elbow_angle": float(min_elbow + 10),
            "recommended_extension_elbow_angle": float(max_elbow - 15),
            "is_decrease": True,
            "primary_joint": "elbow"
        }
        
    # 4. Patrón tipo "Cadera / Bisagra"
    elif exercise_type in ["deadlift", "romanian_deadlift", "hip_thrust", "leg_raises", "russian_twist", "plank"]:
        min_hip = min(hips)
        max_hip = max(hips)
        
        if exercise_type == "plank":
            stats = {
                "hip_angle_range_min": float(min_hip),
                "hip_angle_range_max": float(max_hip),
                "min_hip_alignment_angle": float(np.mean(hips) - 15),
                "max_hip_alignment_angle": float(np.mean(hips) + 15),
                "is_static": True,
                "primary_joint": "hip"
            }
        else:
            is_decrease = True
            if exercise_type in ["hip_thrust", "leg_raises"]:
                is_decrease = False
                
            stats = {
                "hip_angle_range_min": float(min_hip),
                "hip_angle_range_max": float(max_hip),
                "recommended_target_hip_angle": float(min_hip + 15) if is_decrease else float(max_hip - 15),
                "max_allowed_torso_angle": float(max(torsos) + 10),
                "is_decrease": is_decrease,
                "primary_joint": "hip"
            }
            
    # 5. Patrón "Vuelos / Abducción"
    elif exercise_type in ["lateral_raise", "chest_fly_machine"]:
        min_elbow = min(elbows)
        max_elbow = max(elbows)
        
        stats = {
            "elbow_angle_range_min": float(min_elbow),
            "elbow_angle_range_max": float(max_elbow),
            "recommended_peak_elbow_angle": float(min_elbow + 15),
            "is_decrease": False,
            "primary_joint": "abduction"
        }
        
    return stats

def main():
    global dataset_1_path, dataset_2_path
    
    if kagglehub is not None:
        print("Intentando verificar/descargar datasets de Kaggle...")
        try:
            dataset_1_path = kagglehub.dataset_download("hasyimabdillah/workoutfitness-video")
            dataset_2_path = kagglehub.dataset_download("philosopher0808/gym-workoutexercises-video")
            print(f"Dataset 1 verificado en: {dataset_1_path}")
            print(f"Dataset 2 verificado en: {dataset_2_path}")
        except Exception as e:
            print(f"\n⚠️ No se pudieron verificar los datasets en Kaggle: {e}")
            print("Se continuará usando los perfiles por defecto.\n")
    else:
        print("kagglehub no está disponible. Saltando descarga de datasets...")
        
    exercises_to_profile = [
        "squats", "pushups", "bicep_curls", "bench_press", "chest_fly_machine",
        "deadlift", "decline_bench_press", "hammer_curl", "hip_thrust", "incline_bench_press",
        "lat_pulldown", "lateral_raise", "leg_extension", "leg_raises", "plank",
        "pull_up", "romanian_deadlift", "russian_twist", "shoulder_press", "t_bar_row",
        "tricep_pushdown", "tricep_dips"
    ]
    
    dataset_paths = [path for path in [dataset_1_path, dataset_2_path] if path is not None]
    
    profiles = {}
    
    # Mapeo de nombres de carpetas según el dataset
    folder_keywords = {
        "squats": ["squat", "sentadilla"],
        "pushups": ["pushup", "push-up", "flexion"],
        "bicep_curls": ["barbell biceps curl", "biceps curl", "curl", "bicep"],
        "bench_press": ["bench press", "pecho plano"],
        "chest_fly_machine": ["chest fly", "pecho aperturas", "fly"],
        "deadlift": ["deadlift", "peso muerto"],
        "decline_bench_press": ["decline bench", "declinado"],
        "hammer_curl": ["hammer curl", "martillo"],
        "hip_thrust": ["hip thrust", "cadera empuje"],
        "incline_bench_press": ["incline bench", "inclinado"],
        "lat_pulldown": ["lat pulldown", "jalon al pecho"],
        "lateral_raise": ["lateral raise", "vuelos laterales"],
        "leg_extension": ["leg extension", "extension pierna"],
        "leg_raises": ["leg raises", "elevacion piernas"],
        "plank": ["plank", "plancha"],
        "pull_up": ["pull up", "dominada"],
        "romanian_deadlift": ["romanian deadlift", "muerto rumano"],
        "russian_twist": ["russian twist", "giro ruso"],
        "shoulder_press": ["shoulder press", "press hombro"],
        "t_bar_row": ["t bar row", "remo en t"],
        "tricep_pushdown": ["tricep pushdown", "triceps polea"],
        "tricep_dips": ["tricep dips", "fondos triceps"]
    }
    
    for exercise in exercises_to_profile:
        found_video = None
        keywords = folder_keywords[exercise]
        
        for base_path in dataset_paths:
            if not base_path or not os.path.exists(base_path):
                continue
            for root, dirs, files in os.walk(base_path):
                if any(kw in root.lower() for kw in keywords):
                    for file in files:
                        if file.lower().endswith(('.mp4', '.avi', '.mov')):
                            found_video = os.path.join(root, file)
                            break
                if found_video:
                    break
            if found_video:
                break
                
        if found_video and cv2 is not None and mp is not None:
            print(f"Perfilando {exercise} usando el video: {found_video}")
            history = profile_video(found_video, exercise)
            if history:
                stats = extract_profile_stats(history, exercise)
                profiles[exercise] = stats
                print(f"Perfil de {exercise} completado: {stats}")
            else:
                print(f"Error procesando video para {exercise}")
                found_video = None
        else:
            if found_video:
                print(f"No se pudo procesar el video encontrado porque falta OpenCV o MediaPipe.")
                found_video = None
                
        if not found_video:
            print(f"Usando valores predeterminados para {exercise}...")
            if exercise == "squats":
                profiles[exercise] = {
                    "knee_angle_range_min": 75.0,
                    "knee_angle_range_max": 170.0,
                    "recommended_target_knee_angle": 90.0,
                    "max_allowed_torso_angle": 35.0,
                    "is_decrease": True,
                    "primary_joint": "knee"
                }
            elif exercise in ["pushups", "bench_press", "decline_bench_press", "incline_bench_press"]:
                profiles[exercise] = {
                    "elbow_angle_range_min": 70.0,
                    "elbow_angle_range_max": 165.0,
                    "recommended_target_elbow_angle": 85.0,
                    "min_hip_alignment_angle": 160.0,
                    "max_hip_alignment_angle": 185.0,
                    "is_decrease": True,
                    "primary_joint": "elbow"
                }
            elif exercise in ["bicep_curls", "hammer_curl", "t_bar_row"]:
                profiles[exercise] = {
                    "elbow_angle_range_min": 40.0,
                    "elbow_angle_range_max": 170.0,
                    "recommended_peak_elbow_angle": 55.0,
                    "recommended_extension_elbow_angle": 150.0,
                    "is_decrease": True,
                    "primary_joint": "elbow"
                }
            elif exercise in ["lat_pulldown", "pull_up"]:
                profiles[exercise] = {
                    "elbow_angle_range_min": 50.0,
                    "elbow_angle_range_max": 175.0,
                    "recommended_peak_elbow_angle": 70.0,
                    "recommended_extension_elbow_angle": 160.0,
                    "is_decrease": True,
                    "primary_joint": "elbow"
                }
            elif exercise in ["deadlift", "romanian_deadlift"]:
                profiles[exercise] = {
                    "hip_angle_range_min": 80.0,
                    "hip_angle_range_max": 175.0,
                    "recommended_target_hip_angle": 95.0,
                    "max_allowed_torso_angle": 45.0,
                    "is_decrease": True,
                    "primary_joint": "hip"
                }
            elif exercise == "hip_thrust":
                profiles[exercise] = {
                    "hip_angle_range_min": 110.0,
                    "hip_angle_range_max": 175.0,
                    "recommended_target_hip_angle": 165.0,
                    "is_decrease": False,
                    "primary_joint": "hip"
                }
            elif exercise == "leg_extension":
                profiles[exercise] = {
                    "knee_angle_range_min": 80.0,
                    "knee_angle_range_max": 170.0,
                    "recommended_target_knee_angle": 155.0,
                    "is_decrease": False,
                    "primary_joint": "knee"
                }
            elif exercise == "leg_raises":
                profiles[exercise] = {
                    "hip_angle_range_min": 85.0,
                    "hip_angle_range_max": 175.0,
                    "recommended_target_hip_angle": 95.0,
                    "is_decrease": True,
                    "primary_joint": "hip"
                }
            elif exercise == "plank":
                profiles[exercise] = {
                    "hip_angle_range_min": 165.0,
                    "hip_angle_range_max": 185.0,
                    "min_hip_alignment_angle": 160.0,
                    "max_hip_alignment_angle": 190.0,
                    "is_static": True,
                    "primary_joint": "hip"
                }
            elif exercise in ["shoulder_press", "tricep_pushdown"]:
                profiles[exercise] = {
                    "elbow_angle_range_min": 60.0,
                    "elbow_angle_range_max": 175.0,
                    "recommended_target_elbow_angle": 160.0,
                    "is_decrease": False,
                    "primary_joint": "elbow"
                }
            elif exercise == "tricep_dips":
                profiles[exercise] = {
                    "elbow_angle_range_min": 80.0,
                    "elbow_angle_range_max": 170.0,
                    "recommended_target_elbow_angle": 90.0,
                    "is_decrease": True,
                    "primary_joint": "elbow"
                }
            elif exercise in ["lateral_raise", "chest_fly_machine"]:
                profiles[exercise] = {
                    "elbow_angle_range_min": 140.0,
                    "elbow_angle_range_max": 175.0,
                    "recommended_peak_elbow_angle": 150.0,
                    "is_decrease": False,
                    "primary_joint": "abduction"
                }
            elif exercise == "russian_twist":
                profiles[exercise] = {
                    "hip_angle_range_min": 90.0,
                    "hip_angle_range_max": 130.0,
                    "recommended_target_hip_angle": 100.0,
                    "is_decrease": True,
                    "primary_joint": "hip"
                }

    output_path = "assets/exercise_profiles.json"
    with open(output_path, "w") as f:
        json.dump(profiles, f, indent=4)
        
    print(f"Perfiles de ejercicios guardados exitosamente en {output_path}")

if __name__ == "__main__":
    main()
