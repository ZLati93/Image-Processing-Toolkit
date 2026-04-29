% =========================================================
%  traitement_image_script.m
%  Script autonome – toutes les transformations du projet TI
%  À exécuter section par section (Ctrl+Entrée)
%  Pr: Y. AIT LAHCEN – Faculté des Sciences / ADIA-IISE S2
% =========================================================

clear; clc; close all;

%% ── 0. Chargement de l'image ─────────────────────────────
[fichier, dossier] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp;*.tif','Images'}, ...
    'Sélectionner une image');
if isequal(fichier,0), error('Aucune image sélectionnée.'); end

img_color = imread(fullfile(dossier, fichier));
if size(img_color,3) == 3
    img = rgb2gray(img_color);
else
    img = img_color;
end
img = im2uint8(img);
fprintf('Image chargée : %s  (%dx%d pixels)\n', fichier, size(img,1), size(img,2));

%% ── 1. ANALYSE DE L'IMAGE ORIGINALE ─────────────────────
figure('Name','1 – Analyse Image Originale','NumberTitle','off', ...
       'Color',[0.12 0.14 0.18],'Position',[50 50 1100 450]);

% Image
subplot(1,3,1);
imshow(img); title('Image Originale','Color','w'); set(gca,'Color',[.1 .1 .1]);

% Histogramme
subplot(1,3,2);
histogram(double(img(:)),256,'FaceColor',[0.2 0.5 0.9],'EdgeColor','none');
title('Histogramme','Color','w');
xlabel('Niveau de gris','Color','w'); ylabel('Fréquence','Color','w');
set(gca,'Color',[.1 .1 .1],'XColor','w','YColor','w'); grid on;

% Statistiques
subplot(1,3,3); axis off;
d = double(img(:));
stats = {
    sprintf('Moyenne      : %.2f', mean(d));
    sprintf('Écart-type   : %.2f', std(d));
    sprintf('Médiane      : %.0f', median(d));
    sprintf('Min          : %.0f', min(d));
    sprintf('Max          : %.0f', max(d));
    sprintf('Variance     : %.2f', var(d));
    sprintf('Entropie     : %.4f bits', entropy(img));
    sprintf('Taille       : %dx%d px', size(img,1), size(img,2));
};
text(0.05, 0.95, stats, 'Units','normalized', ...
     'VerticalAlignment','top', 'FontName','Courier New', ...
     'FontSize',10, 'Color',[0.4 1 0.6]);
title('Statistiques','Color','w'); set(gca,'Color',[.1 .1 .1]);

set(gcf,'Color',[0.12 0.14 0.18]);

%% ── 2. TRANSFORMATIONS NON LINÉAIRES ─────────────────────
gamma_val = 0.5;   % modifier ici (< 1 = éclaircir, > 1 = assombrir)
img_d = double(img) / 255;

% Gamma correction
img_gamma = imadjust(img, [], [], gamma_val);

% Transformation exponentielle : s = c*(exp(r*γ)-1)
c_exp = 1;
img_exp = uint8(255 * (exp(img_d * gamma_val) - 1) ./ (exp(gamma_val) - 1));

% Transformation logarithmique : s = c*log(1+r)
c_log = 255 / log(1 + 255);
img_log = uint8(c_log * log(1 + double(img)));

figure('Name','2 – Transformations Non Linéaires','NumberTitle','off', ...
       'Position',[100 100 1200 400]);

subplot(1,4,1); imshow(img);       title(sprintf('Original'));
subplot(1,4,2); imshow(img_gamma); title(sprintf('Gamma (γ=%.1f)',gamma_val));
subplot(1,4,3); imshow(img_exp);   title('Exponentielle');
subplot(1,4,4); imshow(img_log);   title('Logarithmique');
sgtitle('Transformations Non Linéaires','FontWeight','bold');

%% ── 3. AMÉLIORATION DU CONTRASTE ─────────────────────────
% Étirement linéaire (linear stretching)
img_stretch = imadjust(img);   % étire automatiquement [min,max] → [0,255]

% Égalisation d'histogramme
img_heq = histeq(img);

figure('Name','3 – Amélioration du Contraste','NumberTitle','off', ...
       'Position',[150 150 1200 500]);

subplot(2,3,1); imshow(img);        title('Original');
subplot(2,3,2); imshow(img_stretch);title('Étirement Linéaire');
subplot(2,3,3); imshow(img_heq);    title('Égalisation Histogramme');

subplot(2,3,4);
histogram(double(img(:)),256,'FaceColor',[0.5 0.5 0.5],'EdgeColor','none');
title('Histogramme Original'); xlabel('Niveau gris');

subplot(2,3,5);
histogram(double(img_stretch(:)),256,'FaceColor',[0.2 0.7 0.3],'EdgeColor','none');
title('Après Étirement'); xlabel('Niveau gris');

subplot(2,3,6);
histogram(double(img_heq(:)),256,'FaceColor',[0.2 0.4 0.9],'EdgeColor','none');
title('Après Égalisation'); xlabel('Niveau gris');

sgtitle('Amélioration du Contraste','FontWeight','bold');

%% ── 4. DÉTECTION DES CONTOURS – FILTRE SOBEL ─────────────
img_sobel = edge(img, 'Sobel');

% Noyaux Sobel manuels (pour visualisation)
Gx = [-1 0 1; -2 0 2; -1 0 1];
Gy = [-1 -2 -1; 0 0 0; 1 2 1];
Sx = imfilter(double(img), Gx, 'replicate');
Sy = imfilter(double(img), Gy, 'replicate');
magnitude = sqrt(Sx.^2 + Sy.^2);
magnitude = uint8(255 * magnitude / max(magnitude(:)));

figure('Name','4 – Détection de Contours Sobel','NumberTitle','off', ...
       'Position',[200 200 1100 400]);

subplot(1,4,1); imshow(img);              title('Original');
subplot(1,4,2); imshow(uint8(abs(Sx).*255/max(abs(Sx(:))))); title('Gradient Gx');
subplot(1,4,3); imshow(uint8(abs(Sy).*255/max(abs(Sy(:))))); title('Gradient Gy');
subplot(1,4,4); imshow(magnitude);        title('Magnitude |∇I|');
sgtitle('Détection de Contours – Filtre Sobel','FontWeight','bold');

%% ── 5. SEGMENTATION ET SEUILLAGE – MÉTHODE OTSU ──────────
niveau_otsu = graythresh(img);           % seuil normalisé [0,1]
seuil_val   = round(niveau_otsu * 255);  % en niveaux de gris

img_otsu = imbinarize(img, niveau_otsu);

fprintf('\n── Méthode OTSU ──────────────────────────\n');
fprintf('Seuil optimal (normalisé) : %.4f\n', niveau_otsu);
fprintf('Seuil optimal (0-255)     : %d\n', seuil_val);

figure('Name','5 – Segmentation OTSU','NumberTitle','off', ...
       'Position',[250 250 1100 450]);

subplot(1,3,1);
imshow(img); title('Image Originale');

subplot(1,3,2);
histogram(double(img(:)),256,'FaceColor',[0.4 0.5 0.8],'EdgeColor','none');
hold on;
xline(seuil_val,'r-','LineWidth',2);
text(seuil_val+5, max(ylim)*0.8, sprintf('Seuil OTSU = %d', seuil_val), ...
     'Color','r','FontWeight','bold');
title('Histogramme + Seuil OTSU');
xlabel('Niveau de gris'); ylabel('Fréquence');

subplot(1,3,3);
imshow(img_otsu); title(sprintf('Segmentation OTSU (seuil=%d)', seuil_val));

sgtitle('Segmentation par la Méthode OTSU','FontWeight','bold');

%% ── Résumé final ─────────────────────────────────────────
fprintf('\n══════════════════════════════════════════════\n');
fprintf('  Toutes les transformations ont été appliquées\n');
fprintf('  Lancez TraitementImage pour l''interface GUI\n');
fprintf('══════════════════════════════════════════════\n');