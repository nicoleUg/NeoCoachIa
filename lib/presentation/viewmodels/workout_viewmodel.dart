import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart' hide ImageFormat;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/audio/speech_synthesizer.dart';
import '../../core/engine/workout_engine.dart';

class WorkoutViewModel extends ChangeNotifier {
  CameraController? cameraController;
  bool isInitialized = false;
  bool isFrontCamera = true;
  
  Pose? currentPose;
  Size? imageSize;
  InputImageRotation? rotation;
  Uint8List? currentFrameBytes;
  
  final WorkoutEngine _workoutEngine = WorkoutEngine();
  WorkoutEngine get workoutEngine => _workoutEngine;

  final SpeechSynthesizer _speechSynthesizer = SpeechSynthesizer();
  
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );

  bool _isTraining = false;
  bool get isTraining => _isTraining;

  bool _isProcessingVideo = false;
  bool get isProcessingVideo => _isProcessingVideo;

  String _processingStatus = "";
  String get processingStatus => _processingStatus;

  bool _isProcessingFrame = false;
  List<CameraDescription> _cameras = [];
  CameraDescription? _cameraDescription;

  WorkoutViewModel() {
    _workoutEngine.onFeedbackTriggered = (message) {
      _speechSynthesizer.speak(message);
    };
    _workoutEngine.addListener(notifyListeners);
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print("No cameras available.");
        return;
      }
      
      _cameraDescription = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      
      isFrontCamera = _cameraDescription!.lensDirection == CameraLensDirection.front;

      cameraController = CameraController(
        _cameraDescription!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      isInitialized = true;
      
      cameraController!.startImageStream((CameraImage image) {
        _processCameraImage(image);
      });
      
      notifyListeners();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void startTraining() {
    _isTraining = true;
    _workoutEngine.resetSession();
    notifyListeners();
  }

  void stopTraining() {
    _isTraining = false;
    currentPose = null;
    _isProcessingVideo = false;
    currentFrameBytes = null;
    notifyListeners();
  }

  void toggleTraining() {
    if (_isTraining) {
      stopTraining();
    } else {
      startTraining();
    }
  }

  // --- SELECCIONAR Y PROCESAR VIDEO DE LA GALERÍA ---
  Future<void> pickAndProcessVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    _isProcessingVideo = true;
    _isTraining = true;
    _workoutEngine.resetSession();
    notifyListeners();

    try {
      final videoPath = video.path;
      final tempDir = Directory.systemTemp.createTempSync();
      
      int ms = 0;
      int consecutiveNulls = 0;

      while (_isTraining) {
        _processingStatus = "Procesando segundo ${(ms / 1000).toStringAsFixed(1)}...";
        notifyListeners();

        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          maxHeight: 480, // Altura reducida para que ML Kit procese ultra rápido
          quality: 50,
        );

        if (thumbnailPath == null) {
          consecutiveNulls++;
          // Si falla más de dos veces consecutivas, asumimos final del video
          if (consecutiveNulls >= 2) break;
          ms += 200;
          continue;
        }
        consecutiveNulls = 0;

        final file = File(thumbnailPath);
        if (file.existsSync()) {
          final inputImage = InputImage.fromFilePath(thumbnailPath);
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty && _isTraining) {
            final pose = poses.first;
            currentPose = pose;

            // Leer dimensiones de la imagen para dibujar esqueleto
            final fileBytes = await file.readAsBytes();
            currentFrameBytes = fileBytes;
            final decodedImage = await decodeImageFromList(fileBytes);
            imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
            rotation = InputImageRotation.rotation0deg; // Las imágenes de archivo están orientadas por defecto

            final bodyPose = _convertToBodyPose(pose);
            _workoutEngine.processPose(bodyPose);
          }

          // Limpiar archivo temporal
          file.deleteSync();
        }

        ms += 200; // Avanzar 200 ms (5 FPS)
        
        // Esperar 150 ms para simular playback fluido en la UI
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      print("Error processing video file: $e");
    } finally {
      _isProcessingVideo = false;
      _processingStatus = "";
      notifyListeners();
    }
  }

  void _processCameraImage(CameraImage image) async {
    // Si estamos procesando video de archivo, ignoramos la cámara en vivo
    if (!_isTraining || _isProcessingFrame || _isProcessingVideo || cameraController == null) return;
    _isProcessingFrame = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        
        if (poses.isNotEmpty && _isTraining && !_isProcessingVideo) {
          final pose = poses.first;
          currentPose = pose;
          imageSize = Size(image.width.toDouble(), image.height.toDouble());
          rotation = inputImage.metadata?.rotation;
          
          final bodyPose = _convertToBodyPose(pose);
          _workoutEngine.processPose(bodyPose);
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error in pose estimation: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameraController == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final sensorOrientation = _cameraDescription!.sensorOrientation;
    
    InputImageRotation? imgRotation;
    if (Platform.isAndroid || Platform.isIOS) {
      imgRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    imgRotation ??= InputImageRotation.rotation0deg;

    InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    // Fallback robusto para evitar que retorne null por diferencias de fabricante en raw format
    if (format == null) {
      if (Platform.isAndroid) {
        format = InputImageFormat.yuv_420_888;
      } else if (Platform.isIOS) {
        format = InputImageFormat.bgra8888;
      }
    }
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imgRotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  BodyPose _convertToBodyPose(Pose pose) {
    final bodyPose = BodyPose();
    
    PoseKeypoint? getKp(PoseLandmarkType type) {
      final lm = pose.landmarks[type];
      if (lm == null) return null;
      return PoseKeypoint(
        position: Point<double>(lm.x, lm.y),
        confidence: lm.likelihood,
      );
    }

    bodyPose.nose = getKp(PoseLandmarkType.nose);
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (leftShoulder != null && rightShoulder != null) {
      bodyPose.neck = PoseKeypoint(
        position: Point<double>(
          (leftShoulder.x + rightShoulder.x) / 2,
          (leftShoulder.y + rightShoulder.y) / 2,
        ),
        confidence: min(leftShoulder.likelihood, rightShoulder.likelihood),
      );
    }

    bodyPose.leftShoulder = getKp(PoseLandmarkType.leftShoulder);
    bodyPose.rightShoulder = getKp(PoseLandmarkType.rightShoulder);
    bodyPose.leftElbow = getKp(PoseLandmarkType.leftElbow);
    bodyPose.rightElbow = getKp(PoseLandmarkType.rightElbow);
    bodyPose.leftWrist = getKp(PoseLandmarkType.leftWrist);
    bodyPose.rightWrist = getKp(PoseLandmarkType.rightWrist);
    bodyPose.leftHip = getKp(PoseLandmarkType.leftHip);
    bodyPose.rightHip = getKp(PoseLandmarkType.rightHip);
    bodyPose.leftKnee = getKp(PoseLandmarkType.leftKnee);
    bodyPose.rightKnee = getKp(PoseLandmarkType.rightKnee);
    bodyPose.leftAnkle = getKp(PoseLandmarkType.leftAnkle);
    bodyPose.rightAnkle = getKp(PoseLandmarkType.rightAnkle);
    
    return bodyPose;
  }

  @override
  void dispose() {
    _workoutEngine.removeListener(notifyListeners);
    _workoutEngine.dispose();
    _poseDetector.close();
    cameraController?.dispose();
    _speechSynthesizer.dispose();
    super.dispose();
  }
}
