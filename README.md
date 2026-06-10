# NeoCoach

Aplicacion movil multiplataforma de asistencia deportiva para el analisis de pose en tiempo real y el conteo de repeticiones de ejercicios fisicos.

## Descripcion General

NeoCoach es un sistema de asistencia inteligente para entrenamientos de fuerza y acondicionamiento. A traves de la camara en vivo del dispositivo movil o mediante la carga de archivos de video desde la galeria local, la aplicacion utiliza redes neuronales de deteccion de pose para rastrear las articulaciones del cuerpo humano, validar la postura articular en tiempo real (evitando lesiones) y contar automaticamente las repeticiones ejecutadas. Cuenta adicionalmente con un entrenador virtual por voz en español que provee sugerencias instantaneas.

## Caracteristicas Principales

1. Soporte para 22 Ejercicios de Gimnasio: Rango completo de entrenamiento incluyendo sentadillas, flexiones, peso muerto, peso muerto rumano, curls de biceps, extensiones de piernas, plancha abdominal, aperturas de pecho, jalon al pecho, press de hombros, fondos de triceps y otros.
2. Analisis Biomecanico en Tiempo Real: Calculo automatico de angulos de flexion en codos, rodillas y caderas mediante vectores trigonometricos de proyeccion 2D.
3. Alertas de Voz Adaptativas: Entrenador por sintesis de voz (TTS) configurado para español que dicta correcciones especificas de postura (por ejemplo, inclinacion excesiva del torso o mala alineacion de cadera) e indica aciertos.
4. Carga y Procesamiento de Archivos de Video: Permite seleccionar un archivo de video desde la galeria del dispositivo, extrayendo y analizando fotograma por fotograma a una tasa uniforme para reproducir el analisis con el esqueleto sobrepuesto.
5. Panel HUD de Estadisticas de Entrenamiento: Boton de finalizacion del entrenamiento que abre un reporte detallado con las repeticiones validas completadas, intentos fallidos por mala postura, porcentaje de precision, duracion de la sesion y ritmo medio (repeticiones por minuto).
6. Diseño Estetico Premium: Interfaz oscura pura con detalles en verde neon de alta visibilidad para entornos de entrenamiento.

## Arquitectura del Proyecto

El sistema se compone de dos modulos principales:

### 1. Script de Calibracion y Modelado (Python)
Ubicado en la carpeta de scripts, descarga colecciones de video deportivas desde Kaggle y procesa fotogramas de referencia a traves de MediaPipe Pose para modelar el comportamiento promedio de los angulos articulares humanos. Genera una base de datos de configuracion para los 22 ejercicios.

### 2. Aplicacion Movil (Flutter / Dart)
Cliente movil construido con principios de arquitectura limpia y gestion de estado a traves de Provider:
* core/audio: Modulo de sintesis de voz en español para entrenamiento virtual.
* core/engine: Motor de estados finitos que valida el paso de la articulacion de la posicion inicial a la posicion maxima y el retorno a la extension.
* core/pose: Sistema de renderizado personalizado (CustomPainter) para dibujar el esqueleto sobre la imagen.
* presentation/viewmodels: Modelo de vista que intermedia la inicializacion de la camara, la conversion de formatos de imagen YUV a ML Kit y el procesamiento asincrono de videos locales.
* presentation/views: Interfaz de usuario adaptada a telefonos inteligentes Android.

## Estructura de Directorios

* assets/ : Archivos de configuracion de la aplicacion, incluyendo la definicion de perfiles de ejercicio.
* lib/ : Codigo fuente de la aplicacion Flutter escrita en Dart.
  * lib/core/ : Motores logicos, calculos trigonometricos y utilidades de audio.
  * lib/presentation/ : Controladores, componentes graficos y vistas de pantalla.
* scripts/ : Scripts en Python para calibracion offline y extraccion automatica de rangos.
* test/ : Pruebas unitarias y de humo para verificacion de interfaz.

## Instalacion y Configuracion

### Requisitos Previos

* Flutter SDK (version 3.11.5 o superior)
* Dart SDK (compatible con el entorno Flutter activo)
* Android SDK y un dispositivo Android compatible (con depuracion USB activa)
* Python 3.10+ (requerido unicamente si se desea regenerar o volver a calibrar los limites articulares)

### Instalacion de la Aplicacion Movil

1. Clone el repositorio del proyecto en su equipo local.
2. Ingrese a la carpeta del proyecto y descargue las dependencias ejecutando:
   ```bash
   flutter pub get
   ```
3. Conecte su dispositivo Android y verifique su reconocimiento:
   ```bash
   flutter devices
   ```
4. Compile e instale la aplicacion en modo debug con el siguiente comando:
   ```bash
   flutter run
   ```

### Ejecucion de la Calibracion Articular (Opcional)

Si desea ejecutar el script de extraccion de limites en Python utilizando los datasets originales de Kaggle:

1. Ingrese a la carpeta scripts e instale las dependencias de Python listadas en requirements.txt:
   ```bash
   pip install -r requirements.txt
   ```
2. Ejecute el script de calibracion:
   ```bash
   python scripts/profile_exercises.py
   ```
El script descargara los videos correspondientes de Kaggle y actualizara los limites de movimiento recomendados en assets/exercise_profiles.json.
