import os
import numpy as np
import matplotlib.pyplot as plt

# --- 1. GENERACIÓN DE DATASET SINTÉTICO BASADO EN ÁNGULOS DE NEOCOACH ---
# 5 Clases:
# Class 0: Sentadillas (Squats)
# Class 1: Flexiones (Pushups)
# Class 2: Curl de Bíceps (Curls)
# Class 3: Peso Muerto (Deadlift)
# Class 4: Plancha (Plank)
def generate_synthetic_data(num_samples=1500):
    np.random.seed(42)
    X = []
    y = []
    
    # 3 features: [knee_angle, elbow_angle, hip_angle]
    for _ in range(num_samples):
        exercise = np.random.randint(0, 5)
        if exercise == 0: # Squat
            knee = np.random.normal(85, 10)
            elbow = np.random.normal(170, 5)
            hip = np.random.normal(90, 10)
        elif exercise == 1: # Pushup
            knee = np.random.normal(175, 5)
            elbow = np.random.normal(90, 15)
            hip = np.random.normal(170, 5)
        elif exercise == 2: # Bicep Curl
            knee = np.random.normal(175, 5)
            elbow = np.random.normal(55, 15)
            hip = np.random.normal(175, 5)
        elif exercise == 3: # Deadlift
            knee = np.random.normal(150, 10)
            elbow = np.random.normal(175, 5)
            hip = np.random.normal(95, 10)
        else: # Plank
            knee = np.random.normal(175, 5)
            elbow = np.random.normal(90, 5)
            hip = np.random.normal(175, 5)
            
        X.append([knee, elbow, hip])
        y.append(exercise)
        
    return np.array(X, dtype=np.float32), np.array(y, dtype=np.int32)

# --- 2. IMPLEMENTACIÓN DE RED NEURONAL DESDE CERO EN NUMPY ---
# MLP de 2 capas: Input (3) -> Hidden (16, ReLU) -> Output (5, Softmax)
class NumPyMLP:
    def __init__(self, input_dim=3, hidden_dim=16, output_dim=5):
        # Inicialización He/Xavier
        self.W1 = np.random.randn(input_dim, hidden_dim) * np.sqrt(2.0 / input_dim)
        self.b1 = np.zeros((1, hidden_dim))
        self.W2 = np.random.randn(hidden_dim, output_dim) * np.sqrt(2.0 / hidden_dim)
        self.b2 = np.zeros((1, output_dim))

    def softmax(self, x):
        exp_x = np.exp(x - np.max(x, axis=1, keepdims=True))
        return exp_x / np.sum(exp_x, axis=1, keepdims=True)

    def forward(self, X):
        self.z1 = X @ self.W1 + self.b1
        self.a1 = np.maximum(0, self.z1) # ReLU
        self.z2 = self.a1 @ self.W2 + self.b2
        self.probs = self.softmax(self.z2)
        return self.probs

    def train_step(self, X, y, lr=0.001):
        num_samples = X.shape[0]
        
        # Forward
        probs = self.forward(X)
        
        # Loss (Cross-Entropy)
        loss = -np.log(probs[range(num_samples), y] + 1e-15).mean()
        
        # Backpropagation
        dz2 = probs.copy()
        dz2[range(num_samples), y] -= 1.0
        dz2 /= num_samples
        
        dW2 = self.a1.T @ dz2
        db2 = np.sum(dz2, axis=0, keepdims=True)
        
        da1 = dz2 @ self.W2.T
        dz1 = da1.copy()
        dz1[self.z1 <= 0] = 0.0 # Derivada de ReLU
        
        dW1 = X.T @ dz1
        db1 = np.sum(dz1, axis=0, keepdims=True)
        
        # Gradientes y actualización
        self.W1 -= lr * dW1
        self.b1 -= lr * db1
        self.W2 -= lr * dW2
        self.b2 -= lr * db2
        
        return loss

    def evaluate(self, X, y):
        probs = self.forward(X)
        preds = np.argmax(probs, axis=1)
        acc = (preds == y).mean()
        loss = -np.log(probs[range(X.shape[0]), y] + 1e-15).mean()
        return loss, acc

def main():
    X, y = generate_synthetic_data(1500)
    
    # Normalizar datos (Media 0, Desviación 1)
    mean = X.mean(axis=0)
    std = X.std(axis=0) + 1e-6
    X_scaled = (X - mean) / std
    
    # Separar en Train, Val, Test (80% / 10% / 10%)
    indices = np.arange(len(X))
    np.random.seed(42)
    np.random.shuffle(indices)
    
    train_idx = indices[:1200]
    val_idx = indices[1200:1350]
    test_idx = indices[1350:]
    
    X_train, y_train = X_scaled[train_idx], y[train_idx]
    X_val, y_val = X_scaled[val_idx], y[val_idx]
    X_test, y_test = X_scaled[test_idx], y[test_idx]
    
    # Instanciar Red Neuronal
    model = NumPyMLP(input_dim=3, hidden_dim=16, output_dim=5)
    
    epochs = 100
    lr = 0.1
    
    train_losses, train_accs = [], []
    val_losses, val_accs = [], []
    
    print("Entrenando Red Neuronal Artificial en Numpy...")
    for epoch in range(epochs):
        loss = model.train_step(X_train, y_train, lr=lr)
        
        # Evaluar
        t_loss, t_acc = model.evaluate(X_train, y_train)
        v_loss, v_acc = model.evaluate(X_val, y_val)
        
        train_losses.append(t_loss)
        train_accs.append(t_acc)
        val_losses.append(v_loss)
        val_accs.append(v_acc)
        
        if (epoch + 1) % 10 == 0:
            print(f"Epoca {epoch+1}/{epochs} | Perdida: {t_loss:.4f} | Precision Val: {v_acc * 100:.2f}%")
            
    # --- 3. EXTRACCIÓN DE GRÁFICOS ---
    output_dir = "scripts/outputs"
    os.makedirs(output_dir, exist_ok=True)
    epoch_range = range(1, epochs + 1)
    
    # 1. Gráfico de Pérdida (Loss)
    plt.figure(figsize=(8, 5))
    plt.plot(epoch_range, train_losses, 'b-', label='Perdida Entrenamiento')
    plt.plot(epoch_range, val_losses, 'r-', label='Perdida Validacion')
    plt.title('Historial de Perdida (Loss) por Epoca')
    plt.xlabel('Epocas')
    plt.ylabel('Loss')
    plt.legend()
    plt.grid(True)
    loss_path = os.path.join(output_dir, "loss_plot.png")
    plt.savefig(loss_path, dpi=300)
    plt.close()
    print(f"Grafico de Perdida guardado en: {loss_path}")
    
    # 2. Gráfico de Precisión (Accuracy)
    plt.figure(figsize=(8, 5))
    plt.plot(epoch_range, train_accs, 'b-', label='Precision Entrenamiento')
    plt.plot(epoch_range, val_accs, 'r-', label='Precision Validacion')
    plt.title('Historial de Precision (Accuracy) por Epoca')
    plt.xlabel('Epocas')
    plt.ylabel('Accuracy')
    plt.legend()
    plt.grid(True)
    acc_path = os.path.join(output_dir, "accuracy_plot.png")
    plt.savefig(acc_path, dpi=300)
    plt.close()
    print(f"Grafico de Precision guardado en: {acc_path}")
    
    # 3. Predicciones y Matriz de Confusión
    probs_test = model.forward(X_test)
    y_pred = np.argmax(probs_test, axis=1)
    
    # Calcular Matriz de Confusión
    cm = np.zeros((5, 5), dtype=np.int32)
    for true_l, pred_l in zip(y_test, y_pred):
        cm[true_l, pred_l] += 1
        
    classes = ['Sentadillas', 'Flexiones', 'Curls', 'Peso Muerto', 'Plancha']
    
    # Dibujar Matriz
    plt.figure(figsize=(8, 6))
    plt.imshow(cm, interpolation='nearest', cmap=plt.cm.Blues)
    plt.title('Matriz de Confusion')
    plt.colorbar()
    tick_marks = np.arange(len(classes))
    plt.xticks(tick_marks, classes, rotation=45)
    plt.yticks(tick_marks, classes)
    
    thresh = cm.max() / 2.
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            plt.text(j, i, format(cm[i, j], 'd'),
                     horizontalalignment="center",
                     color="white" if cm[i, j] > thresh else "black")
            
    plt.ylabel('Clase Real')
    plt.xlabel('Clase Predicha')
    plt.tight_layout()
    cm_path = os.path.join(output_dir, "confusion_matrix.png")
    plt.savefig(cm_path, dpi=300)
    plt.close()
    print(f"Grafico de Matriz de Confusion guardado en: {cm_path}")

if __name__ == '__main__':
    main()
