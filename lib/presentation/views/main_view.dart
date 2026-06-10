
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodels/workout_viewmodel.dart';
import '../../core/engine/workout_engine.dart';
import '../widgets/neo_coach_logo.dart';
import '../../core/pose/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// --- PALETA DE COLORES CORPORATIVOS NEOCOACH ---
class NeoColor {
  static const Color background = Color(0xFF131313); // Fondo oscuro puro
  static const Color surface = Color(0xFF1C1C1E);    // Color de tarjetas
  static const Color primary = Color(0xFFC3F400);    // Verde lima NeoCoach
  static const Color text = Color(0xFFE2E2E2);       // Off-white
  static const Color outline = Color(0xFF272729);    // Borde oscuro
}

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColor.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Consumer<WorkoutViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                spacing: 16,
                children: [
                  // 1. Barra Superior (TopAppBar)
                  const TopAppBar(),

                  // 2. Selector Horizontal de Ejercicios
                  const ExerciseSelectorBar(),

                  // 3. Visor de Cámara con Esqueleto o Placeholder
                  Expanded(
                    child: Stack(
                      children: [
                        if (viewModel.isTraining && viewModel.isInitialized)
                          const CameraViewport()
                        else
                          const PlaceholderCameraView(),

                        // Banner de feedback flotante
                        if (viewModel.isTraining)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 20,
                            child: FeedbackBanner(
                              message: viewModel.workoutEngine.feedbackMessage,
                              color: viewModel.workoutEngine.feedbackColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 4. Panel de Control HUD
                  const HUDControlPanel(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- BARRA SUPERIOR ---
class TopAppBar extends StatelessWidget {
  const TopAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 12,
            children: [
              const NeoCoachLogo(size: 32),
              const Text(
                "NeoCoach",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: NeoColor.surface,
              shape: BoxShape.circle,
              border: Border.all(color: NeoColor.primary, width: 1.5),
            ),
            child: const Icon(
              Icons.person,
              color: NeoColor.text,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// --- SELECTOR DE EJERCICIOS ---
class ExerciseSelectorBar extends StatelessWidget {
  const ExerciseSelectorBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);
    final activeExercise = viewModel.workoutEngine.selectedExercise;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ExerciseType.values.length,
        itemBuilder: (context, index) {
          final exercise = ExerciseType.values[index];
          final isSelected = activeExercise == exercise;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                viewModel.workoutEngine.selectedExercise = exercise;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? NeoColor.primary : NeoColor.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    exercise.name,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- VISOR DE LA CÁMARA (VIEWPORT DE ENTRENAMIENTO) ---
class CameraViewport extends StatelessWidget {
  const CameraViewport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);

    // Si estamos procesando video de archivo
    if (viewModel.isProcessingVideo) {
      if (viewModel.currentFrameBytes == null) {
        return Container(
          decoration: BoxDecoration(
            color: NeoColor.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                const CircularProgressIndicator(color: NeoColor.primary),
                Text(
                  viewModel.processingStatus,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      final cameraSize = viewModel.imageSize ?? const Size(480, 640);
      final double cameraAspect = cameraSize.width / cameraSize.height;

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.loose,
                children: [
                  // Imagen del frame de video
                  Center(
                    child: AspectRatio(
                      aspectRatio: cameraAspect,
                      child: Image.memory(
                        viewModel.currentFrameBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Capa superior del esqueleto
                  if (viewModel.currentPose != null && viewModel.imageSize != null && viewModel.rotation != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: cameraAspect,
                        child: CustomPaint(
                          painter: PosePainter(
                            viewModel.currentPose!,
                            viewModel.imageSize!,
                            viewModel.rotation!,
                            viewModel.workoutEngine.skeletonColor,
                            isFrontCamera: false, // Los videos de la galería no necesitan espejo
                          ),
                        ),
                      ),
                    ),

                  // Etiqueta flotante de "ANALIZANDO VIDEO"
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          const PulsingDot(),
                          Text(
                            viewModel.processingStatus.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // De lo contrario, renderizamos el flujo de la cámara en vivo
    if (viewModel.cameraController == null || !viewModel.cameraController!.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: NeoColor.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: NeoColor.primary),
        ),
      );
    }

    final cameraSize = viewModel.imageSize ?? const Size(480, 640);
    final isRotated = viewModel.rotation == InputImageRotation.rotation90deg ||
        viewModel.rotation == InputImageRotation.rotation270deg;

    final double cameraAspect = isRotated
        ? cameraSize.height / cameraSize.width
        : cameraSize.width / cameraSize.height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.loose,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: cameraAspect,
                    child: CameraPreview(viewModel.cameraController!),
                  ),
                ),
                if (viewModel.currentPose != null && viewModel.imageSize != null && viewModel.rotation != null)
                  Center(
                    child: AspectRatio(
                      aspectRatio: cameraAspect,
                      child: CustomPaint(
                        painter: PosePainter(
                          viewModel.currentPose!,
                          viewModel.imageSize!,
                          viewModel.rotation!,
                          viewModel.workoutEngine.skeletonColor,
                          isFrontCamera: viewModel.isFrontCamera,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        PulsingDot(),
                        Text(
                          "CÁMARA ACTIVA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- PUNTO ROJO DE GRABACIÓN PULSANTE ---
class PulsingDot extends StatefulWidget {
  const PulsingDot({Key? key}) : super(key: key);

  @override
  _PulsingDotState createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// --- VISTA PLACEHOLDER DE CÁMARA INACTIVA ---
class PlaceholderCameraView extends StatelessWidget {
  const PlaceholderCameraView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: NeoColor.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1.5,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [NeoColor.primary, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              Column(
                spacing: 8,
                children: [
                  const Text(
                    "CONECTA CON TU CUERPO",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Ubica el celular de forma vertical. NeoCoach evaluará tu alineación y rango de movimiento mediante inteligencia artificial en tiempo real.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.startTraining();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeoColor.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: NeoColor.primary.withOpacity(0.3),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text(
                      "ACTIVAR CÁMARA",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.pickAndProcessVideo();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeoColor.surface,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.video_library_rounded, size: 16, color: NeoColor.primary),
                    label: const Text(
                      "SUBIR VIDEO",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- BANNER DE FEEDBACK ---
class FeedbackBanner extends StatelessWidget {
  final String message;
  final Color color;

  const FeedbackBanner({
    Key? key,
    required this.message,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<String>(message),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: NeoColor.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color == Colors.green ? NeoColor.primary : color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (color == Colors.green ? NeoColor.primary : color).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Center(
          child: Text(
            message.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// --- PANEL DE CONTROL HUD ---
class HUDControlPanel extends StatelessWidget {
  const HUDControlPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);
    final engine = viewModel.workoutEngine;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: NeoColor.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  const Text(
                    "ACTIVIDAD ACTUAL",
                    style: TextStyle(
                      color: NeoColor.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    engine.selectedExercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  spacing: 4,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: viewModel.isTraining ? NeoColor.primary : Colors.grey,
                    ),
                    Text(
                      viewModel.isTraining ? "ENTRENANDO" : "EN ESPERA",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.06)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${engine.repCount}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: NeoColor.primary.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "REPETICIONES",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  if (viewModel.isTraining)
                    ElevatedButton(
                      onPressed: () {
                        _showSummaryAndStop(context, viewModel);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF272729),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "TERMINAR",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.toggleTraining();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: viewModel.isTraining ? Colors.red : NeoColor.primary,
                      foregroundColor: viewModel.isTraining ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      shadowColor: (viewModel.isTraining ? Colors.red : NeoColor.primary).withOpacity(0.25),
                      elevation: 6,
                    ),
                    icon: Icon(
                      viewModel.isTraining ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      viewModel.isTraining ? "PAUSAR" : "COMENZAR",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSummaryAndStop(BuildContext context, WorkoutViewModel viewModel) {
    final engine = viewModel.workoutEngine;
    final start = engine.sessionStartTime ?? DateTime.now();
    final duration = DateTime.now().difference(start);

    final reps = engine.repCount;
    final failed = engine.failedRepsCount;
    final exerciseName = engine.selectedExercise.name;

    viewModel.stopTraining();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkoutSummaryDialog(
        exerciseName: exerciseName,
        reps: reps,
        failed: failed,
        duration: duration,
      ),
    );
  }
}

// --- DIALOGO DE RESUMEN DE ENTRENAMIENTO ---
class WorkoutSummaryDialog extends StatelessWidget {
  final String exerciseName;
  final int reps;
  final int failed;
  final Duration duration;

  const WorkoutSummaryDialog({
    Key? key,
    required this.exerciseName,
    required this.reps,
    required this.failed,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = reps + failed;
    final accuracy = total > 0 ? ((reps / total) * 100).round() : 100;
    
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final durationStr = "$minutes:$seconds";

    final secondsTotal = duration.inSeconds;
    final repsPerMin = secondsTotal > 0 ? (reps / secondsTotal * 60).toStringAsFixed(1) : "0.0";

    return Dialog(
      backgroundColor: NeoColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
      elevation: 24,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: NeoColor.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: NeoColor.primary,
                size: 36,
              ),
            ),
            Column(
              spacing: 6,
              children: [
                const Text(
                  "ENTRENAMIENTO COMPLETADO",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NeoColor.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  exerciseName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
            Column(
              spacing: 12,
              children: [
                _buildStatRow("Repeticiones Válidas", "$reps", Icons.check_circle_rounded, NeoColor.primary),
                _buildStatRow("Intentos Fallidos", "$failed", Icons.cancel_rounded, Colors.redAccent),
                _buildStatRow("Precisión de Postura", "$accuracy%", Icons.analytics_rounded, Colors.blueAccent),
                _buildStatRow("Duración Total", durationStr, Icons.timer_rounded, Colors.amberAccent),
                _buildStatRow("Ritmo de Ejercicio", "$repsPerMin reps/min", Icons.speed_rounded, Colors.deepPurpleAccent),
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoColor.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: NeoColor.primary.withOpacity(0.2),
                ),
                child: const Text(
                  "CERRAR RESUMEN",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(icon, color: color, size: 20),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
