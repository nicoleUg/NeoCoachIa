import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

enum ExerciseType {
  squats,
  pushups,
  bicepCurls,
  benchPress,
  chestFlyMachine,
  deadlift,
  declineBenchPress,
  hammerCurl,
  hipThrust,
  inclineBenchPress,
  latPulldown,
  lateralRaise,
  legExtension,
  legRaises,
  plank,
  pullUp,
  romanianDeadlift,
  russianTwist,
  shoulderPress,
  tBarRow,
  tricepPushdown,
  tricepDips,
}

extension ExerciseTypeExtension on ExerciseType {
  String get name {
    switch (this) {
      case ExerciseType.squats:
        return "Sentadillas";
      case ExerciseType.pushups:
        return "Flexiones (Lagartijas)";
      case ExerciseType.bicepCurls:
        return "Curls de Bíceps";
      case ExerciseType.benchPress:
        return "Bench Press (Pecho Plano)";
      case ExerciseType.chestFlyMachine:
        return "Chest Fly (Aperturas)";
      case ExerciseType.deadlift:
        return "Peso Muerto";
      case ExerciseType.declineBenchPress:
        return "Pecho Declinado";
      case ExerciseType.hammerCurl:
        return "Curl Martillo";
      case ExerciseType.hipThrust:
        return "Hip Thrust (Empuje de Cadera)";
      case ExerciseType.inclineBenchPress:
        return "Pecho Inclinado";
      case ExerciseType.latPulldown:
        return "Jalón al Pecho";
      case ExerciseType.lateralRaise:
        return "Vuelos Laterales";
      case ExerciseType.legExtension:
        return "Extensión de Piernas";
      case ExerciseType.legRaises:
        return "Elevación de Piernas";
      case ExerciseType.plank:
        return "Plancha Abdominal";
      case ExerciseType.pullUp:
        return "Dominadas (Pull Ups)";
      case ExerciseType.romanianDeadlift:
        return "Peso Muerto Rumano";
      case ExerciseType.russianTwist:
        return "Giro Ruso";
      case ExerciseType.shoulderPress:
        return "Press de Hombros";
      case ExerciseType.tBarRow:
        return "Remo en Barra T";
      case ExerciseType.tricepPushdown:
        return "Tríceps en Polea";
      case ExerciseType.tricepDips:
        return "Fondos de Tríceps";
    }
  }

  // Clave del JSON para buscar en exercise_profiles.json
  String get jsonKey {
    switch (this) {
      case ExerciseType.squats: return "squats";
      case ExerciseType.pushups: return "pushups";
      case ExerciseType.bicepCurls: return "bicep_curls";
      case ExerciseType.benchPress: return "bench_press";
      case ExerciseType.chestFlyMachine: return "chest_fly_machine";
      case ExerciseType.deadlift: return "deadlift";
      case ExerciseType.declineBenchPress: return "decline_bench_press";
      case ExerciseType.hammerCurl: return "hammer_curl";
      case ExerciseType.hipThrust: return "hip_thrust";
      case ExerciseType.inclineBenchPress: return "incline_bench_press";
      case ExerciseType.latPulldown: return "lat_pulldown";
      case ExerciseType.lateralRaise: return "lateral_raise";
      case ExerciseType.legExtension: return "leg_extension";
      case ExerciseType.legRaises: return "leg_raises";
      case ExerciseType.plank: return "plank";
      case ExerciseType.pullUp: return "pull_up";
      case ExerciseType.romanianDeadlift: return "romanian_deadlift";
      case ExerciseType.russianTwist: return "russian_twist";
      case ExerciseType.shoulderPress: return "shoulder_press";
      case ExerciseType.tBarRow: return "t_bar_row";
      case ExerciseType.tricepPushdown: return "tricep_pushdown";
      case ExerciseType.tricepDips: return "tricep_dips";
    }
  }
}

extension ExerciseTypeMessages on ExerciseType {
  String get startFeedback {
    switch (this) {
      case ExerciseType.squats:
        return "Baja lentamente flexionando las rodillas...";
      case ExerciseType.pushups:
        return "Baja el pecho manteniendo el cuerpo firme...";
      case ExerciseType.bicepCurls:
      case ExerciseType.hammerCurl:
        return "Flexiona los codos subiendo el peso...";
      case ExerciseType.benchPress:
      case ExerciseType.inclineBenchPress:
      case ExerciseType.declineBenchPress:
        return "Baja la barra lentamente hacia el pecho...";
      case ExerciseType.chestFlyMachine:
        return "Cierra los brazos juntando las manos...";
      case ExerciseType.deadlift:
      case ExerciseType.romanianDeadlift:
        return "Inclina el torso empujando la cadera atrás...";
      case ExerciseType.hipThrust:
        return "Eleva la cadera contrayendo glúteos...";
      case ExerciseType.latPulldown:
      case ExerciseType.pullUp:
        return "Tira de la barra hacia tu pecho...";
      case ExerciseType.lateralRaise:
        return "Eleva los brazos hacia los costados...";
      case ExerciseType.legExtension:
        return "Extiende las rodillas por completo...";
      case ExerciseType.legRaises:
        return "Eleva las piernas rectas sin doblar rodillas...";
      case ExerciseType.plank:
        return "Mantén el cuerpo recto y abdomen contraído...";
      case ExerciseType.russianTwist:
        return "Gira el torso de un lado al otro...";
      case ExerciseType.shoulderPress:
        return "Empuja el peso verticalmente sobre tu cabeza...";
      case ExerciseType.tBarRow:
        return "Tira del peso hacia tu abdomen...";
      case ExerciseType.tricepPushdown:
        return "Empuja la polea hacia abajo extendiendo codos...";
      case ExerciseType.tricepDips:
        return "Baja flexionando los codos hacia atrás...";
    }
  }

  String get peakFeedback {
    switch (this) {
      case ExerciseType.squats:
        return "¡Buena profundidad! Regresa arriba despacio.";
      case ExerciseType.pushups:
        return "¡Buen fondo! Empuja hacia arriba con fuerza.";
      case ExerciseType.bicepCurls:
      case ExerciseType.hammerCurl:
        return "¡Excelente contracción! Baja controlando el peso.";
      case ExerciseType.benchPress:
      case ExerciseType.inclineBenchPress:
      case ExerciseType.declineBenchPress:
        return "¡Buen contacto! Empuja la barra hacia arriba.";
      case ExerciseType.chestFlyMachine:
        return "¡Buen cierre! Abre los brazos lentamente.";
      case ExerciseType.deadlift:
      case ExerciseType.romanianDeadlift:
        return "¡Excelente bisagra! Sube apretando glúteos.";
      case ExerciseType.hipThrust:
        return "¡Gran contracción! Baja la cadera despacio.";
      case ExerciseType.latPulldown:
      case ExerciseType.pullUp:
      case ExerciseType.tBarRow:
        return "¡Buen tirón! Regresa a la posición inicial despacio.";
      case ExerciseType.lateralRaise:
        return "¡Buena elevación! Baja los brazos lentamente.";
      case ExerciseType.legExtension:
        return "¡Excelente extensión! Regresa abajo controlando.";
      case ExerciseType.legRaises:
        return "¡Buena altura! Baja las piernas lentamente.";
      case ExerciseType.plank:
        return "¡Excelente postura sostenida!";
      case ExerciseType.russianTwist:
        return "¡Buen giro completo!";
      case ExerciseType.shoulderPress:
        return "¡Excelente extensión! Regresa a los hombros despacio.";
      case ExerciseType.tricepPushdown:
      case ExerciseType.tricepDips:
        return "¡Buena extensión de tríceps! Regresa despacio.";
    }
  }
}

enum ExerciseState {
  standing,
  activePhase,
  peakHold,
}

enum FeedbackLevel {
  info,
  success,
  warning,
  error,
}

class PoseKeypoint {
  final Point<double> position;
  final double confidence;

  PoseKeypoint({required this.position, required this.confidence});
}

class BodyPose {
  PoseKeypoint? nose;
  PoseKeypoint? neck;
  
  PoseKeypoint? leftShoulder;
  PoseKeypoint? rightShoulder;
  PoseKeypoint? leftElbow;
  PoseKeypoint? rightElbow;
  PoseKeypoint? leftWrist;
  PoseKeypoint? rightWrist;
  
  PoseKeypoint? leftHip;
  PoseKeypoint? rightHip;
  PoseKeypoint? leftKnee;
  PoseKeypoint? rightKnee;
  PoseKeypoint? leftAnkle;
  PoseKeypoint? rightAnkle;
}

// Configuración cargada dinámicamente de cada ejercicio
class ExerciseProfile {
  final double rangeMin;
  final double rangeMax;
  final double targetAngle;
  final double? maxTorsoAngle;
  final double? minHipAngle;
  final double? maxHipAngle;
  final bool isDecrease;
  final String primaryJoint;
  final bool isStatic;

  ExerciseProfile({
    required this.rangeMin,
    required this.rangeMax,
    required this.targetAngle,
    this.maxTorsoAngle,
    this.minHipAngle,
    this.maxHipAngle,
    required this.isDecrease,
    required this.primaryJoint,
    this.isStatic = false,
  });

  factory ExerciseProfile.fromJson(Map<String, dynamic> json) {
    final String joint = json['primary_joint'] ?? 'elbow';
    
    double minVal = (json['range_min'] as num?)?.toDouble() ??
                    (json['knee_angle_range_min'] as num?)?.toDouble() ??
                    (json['elbow_angle_range_min'] as num?)?.toDouble() ??
                    (json['hip_angle_range_min'] as num?)?.toDouble() ?? 60.0;

    double maxVal = (json['range_max'] as num?)?.toDouble() ??
                    (json['knee_angle_range_max'] as num?)?.toDouble() ??
                    (json['elbow_angle_range_max'] as num?)?.toDouble() ??
                    (json['hip_angle_range_max'] as num?)?.toDouble() ?? 180.0;

    double targetVal = (json['target_angle'] as num?)?.toDouble() ??
                       (json['recommended_target_knee_angle'] as num?)?.toDouble() ??
                       (json['recommended_target_elbow_angle'] as num?)?.toDouble() ??
                       (json['recommended_target_hip_angle'] as num?)?.toDouble() ??
                       (json['recommended_peak_elbow_angle'] as num?)?.toDouble() ?? 90.0;

    return ExerciseProfile(
      rangeMin: minVal,
      rangeMax: maxVal,
      targetAngle: targetVal,
      maxTorsoAngle: (json['max_allowed_torso_angle'] as num?)?.toDouble(),
      minHipAngle: (json['min_hip_alignment_angle'] as num?)?.toDouble(),
      maxHipAngle: (json['max_hip_alignment_angle'] as num?)?.toDouble(),
      isDecrease: json['is_decrease'] ?? true,
      primaryJoint: joint,
      isStatic: json['is_static'] ?? false,
    );
  }
}

class WorkoutEngine extends ChangeNotifier {
  ExerciseType _selectedExercise = ExerciseType.squats;
  ExerciseType get selectedExercise => _selectedExercise;
  
  set selectedExercise(ExerciseType val) {
    if (_selectedExercise != val) {
      _selectedExercise = val;
      resetSession();
    }
  }

  int repCount = 0;
  String feedbackMessage = "¡Listo para empezar! Colócate frente a la cámara.";
  Color feedbackColor = Colors.green;
  Color skeletonColor = Colors.green;

  // Variables para el estado del ejercicio y estadísticas de sesión
  ExerciseState currentState = ExerciseState.standing;
  bool isCorrectFormInCurrentRep = true;
  DateTime lastSpeakTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime plankStartTime = DateTime.now();
  int lastPlankSeconds = 0;
  
  DateTime? sessionStartTime;
  int failedRepsCount = 0;
 
  // Mapa de perfiles de ejercicios cargados
  Map<String, ExerciseProfile> profiles = {};
  bool isProfilesLoaded = false;
 
  // Callback para mandar alertas de voz (TTS)
  void Function(String message)? onFeedbackTriggered;
 
  WorkoutEngine() {
    loadExerciseProfiles();
  }
 
  Future<void> loadExerciseProfiles() async {
    try {
      final String response = await rootBundle.loadString('assets/exercise_profiles.json');
      final Map<String, dynamic> data = json.decode(response);
 
      profiles.clear();
      data.forEach((key, value) {
        profiles[key] = ExerciseProfile.fromJson(value);
      });
      isProfilesLoaded = true;
      print("Extended exercise profiles loaded successfully! Total: ${profiles.length}");
    } catch (e) {
      print("Error loading extended exercise profiles JSON: $e");
    }
    notifyListeners();
  }
 
  void resetSession() {
    repCount = 0;
    failedRepsCount = 0;
    currentState = ExerciseState.standing;
    isCorrectFormInCurrentRep = true;
    feedbackMessage = "Alineando articulaciones...";
    feedbackColor = Colors.green;
    skeletonColor = Colors.green;
    lastPlankSeconds = 0;
    plankStartTime = DateTime.now();
    sessionStartTime = DateTime.now();
    notifyListeners();
  }

  void processPose(BodyPose pose) {
    if (!isProfilesLoaded) return;
    
    final profile = profiles[_selectedExercise.jsonKey];
    if (profile == null) {
      _setFeedback("Perfil de ejercicio no disponible en el JSON.", Colors.grey);
      return;
    }

    // Usar el lado derecho del cuerpo como referencia nativa
    final hip = pose.rightHip?.position;
    final knee = pose.rightKnee?.position;
    final ankle = pose.rightAnkle?.position;
    final shoulder = pose.rightShoulder?.position;
    final elbow = pose.rightElbow?.position;
    final wrist = pose.rightWrist?.position;

    // Dependiendo de la articulación principal, validamos los puntos requeridos
    if (profile.primaryJoint == 'knee' && (hip == null || knee == null || ankle == null)) {
      _setFeedback("Coloca tu pierna derecha visible ante la cámara.", Colors.grey);
      return;
    }
    if (profile.primaryJoint == 'elbow' && (shoulder == null || elbow == null || wrist == null)) {
      _setFeedback("Coloca tu brazo derecho visible ante la cámara.", Colors.grey);
      return;
    }
    if (profile.primaryJoint == 'hip' && (shoulder == null || hip == null || knee == null)) {
      _setFeedback("Asegúrate de que tu torso y cadera sean visibles.", Colors.grey);
      return;
    }
    if (profile.primaryJoint == 'abduction' && (hip == null || shoulder == null || elbow == null)) {
      _setFeedback("Coloca tu brazo y torso visibles de frente.", Colors.grey);
      return;
    }

    // Calcular ángulos
    final double kneeAngle = (hip != null && knee != null && ankle != null) ? _calculateAngle(hip, knee, ankle) : 180.0;
    final double elbowAngle = (shoulder != null && elbow != null && wrist != null) ? _calculateAngle(shoulder, elbow, wrist) : 180.0;
    final double hipAngle = (shoulder != null && hip != null && knee != null) ? _calculateAngle(shoulder, hip, knee) : 180.0;
    final double torsoAngle = (shoulder != null && hip != null) ? _calculateTorsoAngle(shoulder, hip) : 0.0;
    // La abducción del brazo es el ángulo entre el torso (Hombro-Cadera) y el brazo (Hombro-Codo)
    final double abductionAngle = (hip != null && shoulder != null && elbow != null) ? _calculateAngle(hip, shoulder, elbow) : 0.0;

    // Asignar el ángulo activo principal
    double activeAngle = 0.0;
    switch (profile.primaryJoint) {
      case 'knee': activeAngle = kneeAngle; break;
      case 'elbow': activeAngle = elbowAngle; break;
      case 'hip': activeAngle = hipAngle; break;
      case 'abduction': activeAngle = abductionAngle; break;
      default: activeAngle = elbowAngle;
    }

    // --- VALIDACIÓN DE POSTURA EN TIEMPO REAL ---
    // 1. Inclinación del Torso
    if (profile.maxTorsoAngle != null && torsoAngle > profile.maxTorsoAngle!) {
      isCorrectFormInCurrentRep = false;
      _triggerFeedback("Mantén la espalda más recta", FeedbackLevel.warning);
    }
    // 2. Alineación de Cadera
    if (profile.minHipAngle != null && profile.maxHipAngle != null) {
      if (hipAngle < profile.minHipAngle! || hipAngle > profile.maxHipAngle!) {
        isCorrectFormInCurrentRep = false;
        _triggerFeedback("Alinea tu cadera con el cuerpo", FeedbackLevel.warning);
      }
    }

    // --- MÁQUINA DE ESTADOS UNIFICADA ---
    // Plancha estática (Plank)
    if (profile.isStatic) {
      if (currentState == ExerciseState.standing) {
        plankStartTime = DateTime.now();
        currentState = ExerciseState.activePhase;
        _triggerFeedback("Mantén la posición estática", FeedbackLevel.success);
      }
      
      if (isCorrectFormInCurrentRep) {
        skeletonColor = const Color(0xFFC3F400); // Verde NeoCoach
        final duration = DateTime.now().difference(plankStartTime).inSeconds;
        if (duration > lastPlankSeconds) {
          lastPlankSeconds = duration;
          // Cada 5 segundos cuenta como una "repetición" para dar feedback dinámico
          if (duration % 5 == 0 && duration > 0) {
            repCount = duration ~/ 5;
            _triggerFeedback("¡Sigue así! $duration segundos", FeedbackLevel.success);
          } else {
            _setFeedback("Sosteniendo... $duration s", const Color(0xFFC3F400));
          }
        }
      } else {
        // Postura incorrecta detectada
        plankStartTime = DateTime.now(); // reset timer
        isCorrectFormInCurrentRep = true;
      }
      return;
    }

    // Ejercicios dinámicos con repeticiones
    final double standingBoundary = profile.isDecrease 
        ? (profile.rangeMax - 15.0).clamp(0.0, 180.0) 
        : (profile.rangeMin + 15.0).clamp(0.0, 180.0);
        
    final double peakBoundary = profile.targetAngle;

    switch (currentState) {
      case ExerciseState.standing:
        skeletonColor = const Color(0xFFC3F400);
        
        bool isAtStart = profile.isDecrease 
            ? activeAngle > standingBoundary 
            : activeAngle < standingBoundary;

        if (isAtStart) {
          _setFeedback(
            _selectedExercise.startFeedback, 
            const Color(0xFFC3F400)
          );
          if (!isCorrectFormInCurrentRep) {
            isCorrectFormInCurrentRep = true;
          }
        } else {
          // Ha salido de la posición inicial
          currentState = ExerciseState.activePhase;
          notifyListeners();
        }
        break;

      case ExerciseState.activePhase:
        bool isAtPeak = profile.isDecrease 
            ? activeAngle <= peakBoundary 
            : activeAngle >= peakBoundary;

        if (isAtPeak) {
          currentState = ExerciseState.peakHold;
          _triggerFeedback(
            _selectedExercise.peakFeedback, 
            FeedbackLevel.success
          );
        } else {
          _setFeedback("Continúa el movimiento...", Colors.blue);
        }
        break;

      case ExerciseState.peakHold:
        bool isReturned = profile.isDecrease 
            ? activeAngle > standingBoundary 
            : activeAngle < standingBoundary;

        if (isReturned) {
          if (isCorrectFormInCurrentRep) {
            repCount += 1;
            _triggerFeedback("¡Buen trabajo! Rep $repCount", FeedbackLevel.success);
          } else {
            failedRepsCount += 1;
            _triggerFeedback("Postura incorrecta. Corrige y repite.", FeedbackLevel.error);
          }
          currentState = ExerciseState.standing;
          isCorrectFormInCurrentRep = true;
          notifyListeners();
        }
        break;
    }
  }

  // --- AYUDANTES MATEMÁTICOS ---
  double _calculateAngle(Point<double> a, Point<double> b, Point<double> c) {
    final ba = Point<double>(a.x - b.x, a.y - b.y);
    final bc = Point<double>(c.x - b.x, c.y - b.y);

    final dotProduct = ba.x * bc.x + ba.y * bc.y;
    final magnitudeA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magnitudeC = sqrt(bc.x * bc.x + bc.y * bc.y);

    if (magnitudeA <= 0 || magnitudeC <= 0) return 0.0;

    final cosAngle = dotProduct / (magnitudeA * magnitudeC);
    final clampedCos = cosAngle.clamp(-1.0, 1.0);
    final angleRad = acos(clampedCos);

    return angleRad * 180.0 / pi;
  }

  double _calculateTorsoAngle(Point<double> shoulder, Point<double> hip) {
    final dx = shoulder.x - hip.x;
    final dy = shoulder.y - hip.y;

    final angleRad = atan2(dx.abs(), dy.abs());
    return angleRad * 180.0 / pi;
  }

  // --- CONTROL DE FEEDBACK Y ALERTAS DE VOZ ---
  void _setFeedback(String message, Color color) {
    if (feedbackMessage != message || feedbackColor != color) {
      feedbackMessage = message;
      feedbackColor = color;
      notifyListeners();
    }
  }

  void _triggerFeedback(String message, FeedbackLevel level) {
    feedbackMessage = message;

    switch (level) {
      case FeedbackLevel.info:
        feedbackColor = Colors.blue;
        skeletonColor = Colors.blue;
        break;
      case FeedbackLevel.success:
        feedbackColor = const Color(0xFFC3F400);
        skeletonColor = const Color(0xFFC3F400);
        break;
      case FeedbackLevel.warning:
        feedbackColor = Colors.amber;
        skeletonColor = Colors.amber;
        break;
      case FeedbackLevel.error:
        feedbackColor = Colors.redAccent;
        skeletonColor = Colors.redAccent;
        break;
    }

    final now = DateTime.now();
    if (now.difference(lastSpeakTime).inMilliseconds > 1500) {
      onFeedbackTriggered?.call(message);
      lastSpeakTime = now;
    }
    notifyListeners();
  }
}
