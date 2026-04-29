# Image Processing Toolkit — Projet TI

> **Academic Project** | IISE S2 — Faculté des Sciences   
> **Language:** MATLAB (zero dependency on Image Processing Toolbox)

---

## 1. Description

This repository contains a complete pedagogical image‑processing environment built for master‑level engineering students. The goal is to explore fundamental digital image transformations, contrast enhancement, edge detection, and segmentation using algorithms implemented **entirely from scratch** in MATLAB.

No external toolbox is required; every routine (histogram, convolution, Otsu thresholding, etc.) is coded manually so that the underlying mathematics remain fully transparent.

**Key capabilities**
- Non‑linear intensity transforms: Gamma, Exponential, Logarithmic
- Contrast enhancement: Linear stretching & Histogram equalization (CDF)
- Edge detection: Sobel filter with manual 3×3 convolution
- Segmentation: Optimal thresholding via Otsu’s inter‑class variance method
- Standalone script + Interactive GUI (MATLAB App Designer)

---

## 2. Project Structure

| File / Folder | Role |
|---------------|------|
| `traitement_image_script.m` | **Standalone script** — run section by section (`Ctrl+Enter`) to load an image and visualize all transformations in dedicated figures. |
| `TraitementImage.m` | **GUI application** — MATLAB App Designer class (`mlapp` logic in `.m` form). Provides an interactive panel to load images, choose transforms, tune the gamma slider, view histograms/statistics, and export results. |

> Both files operate independently; use the script for rapid batch visualization and the GUI for interactive exploration.

---

## 3. Installation

### Prerequisites
- MATLAB **R2018b** or newer (App Designer support required for the GUI).
- **Image Processing Toolbox is NOT required** — every algorithm is hand‑coded.

### Steps
1. Clone or download this repository into a local folder.
2. Open MATLAB and set that folder as the **Current Folder**.
3. Ensure no shadowed function names exist on your path.

No additional package installation (`requirements.txt`, toolboxes, etc.) is necessary.

---

## 4. Usage

### 4.1 Standalone Script (`traitement_image_script.m`)

Open the file in the MATLAB Editor and execute **section by section** (`Ctrl+Enter`):

| Section | Action |
|---------|--------|
| `0. Chargement de l'image` | Interactive file picker (`uigetfile`). Accepts JPG, PNG, BMP, TIF. Converts RGB→grayscale automatically. |
| `1. Analyse de l'image originale` | Displays original image, histogram, and statistics (mean, std, median, entropy, etc.). |
| `2. Transformations non linéaires` | Gamma correction, Exponential, and Logarithmic transforms side‑by‑side. |
| `3. Amélioration du contraste` | Linear stretching and histogram equalization with before/after histograms. |
| `4. Détection des contours – Sobel` | Manual Sobel convolution (`Gx`, `Gy`, magnitude map). |
| `5. Segmentation et seuillage – OTSU` | Automatic Otsu thresholding with histogram overlay. |

> Modify `gamma_val` at the top of Section 2 to experiment with different correction intensities.

### 4.2 Interactive GUI (`TraitementImage.m`)

Launch from the MATLAB Command Window:

```matlab
TraitementImage
```

**Workflow:**
1. Click **Charger Image** to load a grayscale or color image.
2. Select a transformation from the drop‑down list:
   - Histogramme / Stats
   - Gamma Correction
   - Transformation Exponentielle
   - Transformation Logarithmique
   - Étirement Linéaire
   - Égalisation Histogramme
   - Filtre Sobel
   - Segmentation OTSU
3. Adjust the **Gamma slider** (when applicable) in the range `[0.1, 5.0]`.
4. Click **Appliquer** to render the result and update the histogram / statistics panel.
5. Use **Réinitialiser** to return to the original image.
6. Click **Sauvegarder** to export the processed image as PNG/JPG/BMP.

---

## 5. Examples

### Launch the GUI

```matlab
% In the MATLAB Command Window
cd('c:/Users/hp/OneDrive/Bureau/AIoT_Workshop/projeTI')
TraitementImage
```

### Run the script programmatically (non‑interactive batch mode)

If you prefer to bypass the file picker and process a specific image, insert the following at the top of `traitement_image_script.m` and comment out the `uigetfile` block:

```matlab
img_color = imread('sample.png');
if size(img_color,3) == 3
    img = rgb2gray(img_color);
else
    img = img_color;
end
img = im2uint8(img);
```

### Quick test of manual Sobel magnitude via Command Window

```matlab
I  = double(imread('sample.png'));
Gx = [-1 0 1; -2 0 2; -1 0 1];
Gy = [-1 -2 -1; 0 0 0; 1 2 1];
Sx = imfilter(I, Gx, 'replicate');
Sy = imfilter(I, Gy, 'replicate');
mag = sqrt(Sx.^2 + Sy.^2);
imshow(uint8(255 .* mag ./ max(mag(:))));
```

---

## 6. Academic Notes

- **Target audience:** Master’s students in Engineering (IISE S2).
- **Pedagogical focus:** Understanding the math behind each transform rather than calling black‑box toolbox functions.
- **Author & Instructor:** Pr. Y. AIT LAHCEN — Faculté des Sciences.

---

## 7. Contributors & License
 
- **Institution:** Faculté des Sciences / IISE S2

This material is provided for **academic and educational purposes**. You are free to use, modify, and distribute it within an educational context. For commercial use, please contact the author.

---

*Happy image processing! 📊🔬*

