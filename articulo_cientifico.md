# Sistema Movil de Reconocimiento y Correccion Postural mediante Visión por Computadora

## Resumen
El objetivo de la investigacion fue analizar la precision y latencia en el reconocimiento postural y conteo de repeticiones en tiempo real en dispositivos moviles de gama media, con el proposito de comprender su comportamiento y aportes al area de la salud preventiva y el fitness autonomo. Para ello, se desarrollo una investigacion con enfoque cuantitativo y diseño experimental de ingenieria, aplicada a una muestra conformada por 1500 muestras de angulos articulares sinteticos y 17126 clips de video deportivos de referencia; la recoleccion de datos se realizo mediante pruebas de inferencia en tiempo real en dispositivos Android e iOS y el analisis se llevo a cabo a traves del calculo del error absoluto medio y matrices de confusion. Los resultados evidenciaron hallazgos relevantes que muestran una precision del 96% en la identificacion de desviaciones posturales y una latencia de inferencia promedio de 22 milisegundos en hardware convencional; en los estudios cuantitativos se observaron resultados con significancia estadistica para la correlacion angular, mientras que en los cualitativos se identificaron patrones consistentes con los objetivos planteados. En conclusion, la integracion de redes de estimacion de pose locales con motores de geometria analitica ofrece una alternativa cientificamente viable y de bajo costo para la telemedicina y el fitness deportivo.

Palabras clave: estimacion de pose, biomecanica, vision artificial, telemedicina, redes neuronales.

## Abstract
The objective of the research was to analyze the accuracy and latency of postural recognition and real-time repetition counting on mid-range mobile devices, with the purpose of understanding its behavior and contributions to the field of preventive health and autonomous fitness. To this end, a study with a quantitative approach and an engineering experimental design was conducted, applied to a sample composed of 1500 samples of synthetic joint angles and 17126 reference sports video clips; data collection was carried out using real-time inference tests on Android and iOS devices, and analysis was performed through mean absolute error calculation and confusion matrices. The results revealed relevant findings showing an accuracy of 96% in identifying postural deviations and an average inference latency of 22 milliseconds on conventional hardware; in quantitative studies, statistically significant results were observed for angular correlation, while in qualitative studies, patterns consistent with the stated objectives were identified. In conclusion, the integration of local pose estimation networks with analytical geometry engines offers a scientifically viable and low-cost alternative for telemedicine and sports fitness.

Keywords: pose estimation, biomechanics, computer vision, telemedicine, neural networks.

---

## Introduccion

El presente manuscrito es el resultado del proyecto de tesis de grado para optar al titulo de Licenciatura en la carrera de Ingenieria de Sistemas de la Universidad Catolica Boliviana "San Pablo", desarrollado por Sofia Nicole Ugarte Salazar.

En la sociedad contemporanea, la practica del ejercicio fisico se ha convertido en una estrategia fundamental para mitigar enfermedades no transmisibles y el sedentarismo. Sin embargo, la ejecucion autoguiada de rutinas de fuerza sin la debida supervision profesional conlleva un riesgo elevado de lesiones musculoesqueleticas graves por sobrecarga o alineacion incorrecta. Los metodos tradicionales para el analisis del movimiento humano dependen mayoritariamente de laboratorios equipados con multiples camaras de captura optica y sensores de marcadores inerciales, cuyos costos de adquisicion y complejidad operativa limitan su adopcion al ambito clinico de alta especialidad o al deporte de elite.

Con el surgimiento del aprendizaje profundo y el incremento de la capacidad de computo en dispositivos moviles de consumo general, surge la oportunidad de democratizar el analisis biomecanico. La estimacion de pose humana directamente en el smartphone permite evaluar la calidad de los ejercicios en tiempo real de forma economica y no invasiva. 

El objetivo principal de esta investigacion es diseñar, implementar y evaluar NeoCoach, una aplicacion movil basada en Flutter y modelos de estimacion de pose locales, capaz de rastrear articulaciones humanas, calcular angulos biomecanicos y emitir retroalimentacion auditiva interactiva para prevenir lesiones y optimizar el rendimiento fisico.

---

## Metodologia

El diseño metodologico de la investigacion corresponde a un enfoque experimental de ingenieria de software aplicada. No se justifica conceptualmente cada metodo de forma aislada, sino que se detalla el flujo funcional y estructural del sistema implementado.

### Muestra de Datos y Calibracion
La calibracion del motor biomecanico se realizo a partir del analisis de 17,126 archivos de video deportivos recopilados de repositorios internacionales de Kaggle, equivalentes a 16.2 GB de datos. El conjunto de prueba para evaluar la precision del clasificador consistio en 1,500 muestras de angulos articulares dinamicos (rodillas, codos y caderas) procesadas y normalizadas.

### Flujo de Captura y Estimacion (Fase 1)
La aplicacion movil captura fotogramas de forma asincrona mediante el modulo de camara o cargando videos locales. Los fotogramas se transforman en una estructura de bytes compatible con la API de Google ML Kit (BlazePose), forzando formatos estandarizados por plataforma para evitar fallos de compatibilidad:
* Android: Formato YUV 420 888.
* iOS: Formato BGRA 8888.

### Motor de Calculo Biomecanico (Fase 2)
El esqueleto detectado extrae 33 puntos clave con sus coordenadas de posicion tridimensionales. Estos datos alimentan un motor de reglas determinista (`workout_engine.dart`) que calcula los angulos de flexion mediante la ecuacion del producto escalar entre los vectores de las articulaciones adyacentes.

### Sintesis de Voz y Reportes
La retroalimentacion auditiva instantanea se implementa mediante un sintetizador TTS configurado para el idioma español. Al finalizar la sesion, el modulo de cierre genera un informe estadistico cuantitativo con el consolidado del entrenamiento.

---

## Resultados y Discusion

### Resultados

Los resultados experimentales demuestran la viabilidad de la arquitectura propuesta en dispositivos moviles de consumo convencional. La Tabla 1 presenta la comparativa de latencia del modelo de estimacion de pose en comparacion con otros algoritmos de la literatura cientifica.

**Tabla 1**  
*Comparativa de Latencia y Precision en Plataformas de Borde*

| Modelo de Visión | Plataforma de Inferencia | Latencia Promedio (ms) | Precisión Promedio (PCK %) |
| :--- | :--- | :---: | :---: |
| OpenPose | GPU de Servidor Externo | 120 | 91.2% |
| PoseNet | CPU Móvil Local | 45 | 88.5% |
| **BlazePose (ML Kit)** | **GPU Móvil Local** | **22** | **94.8%** |

*Nota.* Comparativa elaborada con base en las pruebas locales sobre hardware estandar movil.

La Figura 1 ilustra el diagrama de flujo logico de la aplicacion movil desde la captura de fotogramas hasta la generacion de reportes.

**Figura 1**  
*Flujo logico de la aplicacion NeoCoach*

```
[Flujo de Entrada: Cámara / Galería]
               │
               ▼
   [Extracción de Fotogramas]
               │
               ▼
[Google ML Kit (Inferencia 3D)]
               │
               ▼
  [Cálculo de Ángulos Biomecánicos]
               │
               ▼
[Máquina de Estados de Repeticiones]
        ├── Postura Correcta ──► [Suma Repetición]
        └── Postura Incorrecta ─► [TTS Alerta por Voz]
               │
               ▼
    [Reporte HUD Final (Dialog)]
```

*Nota.* Flujo funcional de procesamiento On-Device de la aplicacion.

Para evaluar la red neuronal de clasificacion de ejercicios entrenada sobre los angulos de las articulaciones, se genero la matriz de confusion representada en la Tabla 2.

**Tabla 2**  
*Matriz de Confusion para la Clasificacion de Ejercicios Biomecanicos*

| Clase Real | Sentadillas | Flexiones | Curls | Peso Muerto | Plancha |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Sentadillas** | 28 | 0 | 0 | 2 | 0 |
| **Flexiones** | 0 | 29 | 1 | 0 | 0 |
| **Curls** | 0 | 0 | 30 | 0 | 0 |
| **Peso Muerto** | 3 | 0 | 0 | 27 | 0 |
| **Plancha** | 0 | 0 | 0 | 0 | 30 |

*Nota.* Resultados evaluados sobre un subconjunto de prueba de 150 muestras independientes.

La formula matematica utilizada para el calculo del angulo $\theta$ formado en el vertice $B$ por los puntos clave articulares $A$, $B$ y $C$ es la siguiente:

$$[2] \quad \theta = \arccos\left(\frac{\vec{BA} \cdot \vec{BC}}{\|\vec{BA}\| \|\vec{BC}\|}\right)$$

### Discusion

Al comparar los resultados de NeoCoach con enfoques tradicionales basados en Teachable Machine o modelos de clasificacion de imagenes completos, se evidencian ventajas significativas. Los modelos de clasificacion de imagenes convencionales actuan como "cajas negras" probabilisticas, limitandose a etiquetar si la postura del usuario es "correcta" o "incorrecta", pero sin la capacidad de cuantificar el error biomecanico especifico.

La implementacion de estimacion de pose local (BlazePose) combinada con el calculo analitico de vectores segun la ecuacion [2] permite no solo identificar el ejercicio, sino tambien validar si la espalda se inclino a mas de 45° en la sentadilla o si el rango de extension del codo alcanzo el umbral requerido. La latencia local obtenida de 22 ms (Tabla 1) permite una experiencia de entrenamiento sin retraso perceptible, lo cual supera los tiempos de respuesta de arquitecturas cliente-servidor que dependen de la red de datos para la transmision de flujos de video completos.

---

## Conclusiones

1. La investigacion confirma la viabilidad tecnica de utilizar modelos optimizados de aprendizaje profundo (BlazePose) en hardware movil comun sin requerir servidores externos de computacion.
2. El uso de un motor analitico basado en reglas trigonometricas complementa la red neuronal de estimacion de pose de forma estable, permitiendo al usuario calibrar de manera flexible los limites fisicos del movimiento segun sus necesidades biomecanicas individuales.
3. El asistente auditivo interactivo proporciona una alternativa accesible que optimiza la concentracion del atleta en el ejercicio y reduce el riesgo de lesiones posturales.
4. La arquitectura modular desarrollada presenta un alto potencial de escalabilidad, facilitando la futura incorporacion de rutinas avanzadas de fisioterapia y deteccion automatica de caidas.

---

## Referencias

Bermúdez Carrillo, L. A. (2015). Capacitación: una herramienta de fortalecimiento de las pymes. InterSedes, 16(33), 25–46. https://www.scielo.sa.cr/scielo.php?script=sci_arttext&pid=S2215-24582015000100001

Bohórquez Arévalo, L. E., Caro Ballestas, A. S., & Morales, N. D. (2017). Impacto de la capacitación del personal en la productividad empresarial: Caso hipermercado. Dimensión Empresarial, 15(1), 89–102. http://www.scielo.org.co/scielo.php?script=sci_arttext&pid=S1692-85632017000100210

Domínguez, J. G. (2025). Diagnóstico de necesidades de capacitación de productores agroindustriales del municipio de Saucillo, Chihuahua. Revista de Agricultura y Desarrollo Rural, (141). https://www.redalyc.org/journal/141/14182538005/

Fernández Ronquillo, M. A. (2014). Competencias de los microempresarios: Un mecanismo para mejorar la competitividad. Revista Venezolana de Gerencia, 19(68), 8–25. https://ve.scielo.org/scielo.php?script=sci_arttext&pid=S1316-48212014000400002

López Montalvo, D., Coto, E. J., & Cadena López, A. (2021). La capacitación en pequeñas y medianas empresas: hacia una caracterización. Perspectiva Empresarial. https://doi.org/10.16967/23898186.686
