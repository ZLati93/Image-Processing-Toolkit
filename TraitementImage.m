% % =========================================================
%  TraitementImage.m  –  Application MATLAB (App Designer)
%  Projet TI – Faculté des Sciences / ADIA-IISE S2
%  Prof : Y. AIT LAHCEN
%  *** VERSION SANS Image Processing Toolbox ***
%  Tous les algorithmes sont implémentés manuellement.
% =========================================================

classdef TraitementImage < matlab.apps.AppBase

    % ── Composants UI ─────────────────────────────────────
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        PanelControls       matlab.ui.container.Panel
        AxesOriginal        matlab.ui.control.UIAxes
        AxesResult          matlab.ui.control.UIAxes
        AxesHistogram       matlab.ui.control.UIAxes
        BtnCharger          matlab.ui.control.Button
        BtnAppliquer        matlab.ui.control.Button
        BtnReset            matlab.ui.control.Button
        BtnSauvegarder      matlab.ui.control.Button
        DropdownTransfo     matlab.ui.control.DropDown
        LabelTransfo        matlab.ui.control.Label
        SliderGamma         matlab.ui.control.Slider
        LabelGamma          matlab.ui.control.Label
        LabelGammaVal       matlab.ui.control.Label
        LabelStats          matlab.ui.control.Label
        TextAreaStats       matlab.ui.control.TextArea
        TitleLabel          matlab.ui.control.Label
        LabelOrig           matlab.ui.control.Label
        LabelRes            matlab.ui.control.Label
        LabelHist           matlab.ui.control.Label
    end

    properties (Access = private)
        ImageOriginale
        ImageResultat
    end

    % ══════════════════════════════════════════════════════
    %  ALGORITHMES (sans Image Processing Toolbox)
    % ══════════════════════════════════════════════════════
    methods (Access = private)

        % ── RGB → Niveaux de gris (ITU BT.601) ───────────
        function gris = rgb2gris_manuel(~, img)
            if size(img,3) == 3
                gris = uint8(0.299*double(img(:,:,1)) + ...
                             0.587*double(img(:,:,2)) + ...
                             0.114*double(img(:,:,3)));
            else
                gris = img;
            end
        end

        % ── Histogramme 256 bins ──────────────────────────
        function h = calcHistogramme(~, img)
            h = zeros(1, 256);
            vals = double(img(:));
            for k = 0:255
                h(k+1) = sum(vals == k);
            end
        end

        % ── Gamma Correction : s = (r/255)^γ * 255 ───────
        function out = gammaCorrection(~, img, gamma)
            out = uint8(255 .* (double(img)./255).^gamma);
        end

        % ── Exponentielle : s = 255*(e^(r/255*γ)-1)/(e^γ-1)
        function out = transfoExponentielle(~, img, gamma)
            r = double(img) ./ 255;
            if abs(gamma) < 1e-6, gamma = 0.01; end
            out = uint8(255 .* (exp(r .* gamma) - 1) ./ (exp(gamma) - 1));
        end

        % ── Logarithmique : s = c*log(1+r) ───────────────
        function out = transfoLogarithmique(~, img)
            c = 255 / log(256);
            out = uint8(c .* log(1 + double(img)));
        end

        % ── Étirement linéaire ────────────────────────────
        function out = etirementLineaire(~, img)
            mn = double(min(img(:)));
            mx = double(max(img(:)));
            if mx == mn
                out = img;
            else
                out = uint8((double(img) - mn) ./ (mx - mn) .* 255);
            end
        end

        % ── Égalisation d'histogramme (CDF) ──────────────
        function out = egalisationHistogramme(app, img)
            N   = numel(img);
            h   = app.calcHistogramme(img);
            cdf = cumsum(h) ./ N;
            lut = uint8(round(cdf .* 255));
            out = lut(double(img(:)) + 1);
            out = reshape(out, size(img));
        end

        % ── Filtre Sobel (convolution manuelle) ───────────
        function out = filtreSobel(~, img)
            Gx = [-1 0 1; -2 0 2; -1 0 1];
            Gy = [-1 -2 -1; 0 0 0; 1 2 1];
            I  = double(img);
            [nr, nc] = size(I);
            % Padding par réplication des bords
            Ip = [I(1,1),   I(1,:),   I(1,nc);
                  I(:,1),   I,        I(:,nc);
                  I(nr,1), I(nr,:),  I(nr,nc)];
            Sx = zeros(nr, nc);
            Sy = zeros(nr, nc);
            for i = 1:nr
                for j = 1:nc
                    bloc = Ip(i:i+2, j:j+2);
                    Sx(i,j) = sum(sum(Gx .* bloc));
                    Sy(i,j) = sum(sum(Gy .* bloc));
                end
            end
            mag = sqrt(Sx.^2 + Sy.^2);
            out = uint8(255 .* mag ./ (max(mag(:)) + eps));
        end

        % ── Segmentation OTSU (variance inter-classe) ─────
        function [out, seuil] = segmentationOTSU(app, img)
            N  = numel(img);
            h  = app.calcHistogramme(img) ./ N;
            best = -1;
            seuil = 0;
            for t = 1:254
                w0 = sum(h(1:t));
                w1 = sum(h(t+1:256));
                if w0 < 1e-10 || w1 < 1e-10, continue; end
                mu0 = sum((0:t-1)  .* h(1:t))   ./ w0;
                mu1 = sum((t:255)  .* h(t+1:end)) ./ w1;
                sb  = w0 .* w1 .* (mu0 - mu1).^2;
                if sb > best
                    best  = sb;
                    seuil = t;
                end
            end
            out = uint8((double(img) >= seuil) .* 255);
        end

        % ── Afficher statistiques ─────────────────────────
        function AfficherStatistiques(app, img)
            d   = double(img(:));
            mn  = mean(d);
            sd  = sqrt(mean((d - mn).^2));
            med = median(d);
            h   = app.calcHistogramme(img) ./ numel(img);
            hp  = h(h > 0);
            ent = -sum(hp .* log2(hp));
            txt = sprintf([ ...
                'Moyenne      : %.2f\n' ...
                'Ecart-type   : %.2f\n' ...
                'Mediane      : %.0f\n'  ...
                'Min          : %.0f\n'  ...
                'Max          : %.0f\n'  ...
                'Variance     : %.2f\n'  ...
                'Entropie     : %.4f bits\n' ...
                'Taille       : %dx%d px'], ...
                mn, sd, med, min(d), max(d), sd^2, ent, ...
                size(img,1), size(img,2));
            app.TextAreaStats.Value = txt;
        end

        % ── Afficher histogramme ──────────────────────────
        function AfficherHistogramme(app, img)
            h = app.calcHistogramme(img);
            cla(app.AxesHistogram);
            bar(app.AxesHistogram, 0:255, h, 1, ...
                'FaceColor',[0.25 0.55 0.90],'EdgeColor','none');
            app.AxesHistogram.XLim = [0 255];
            app.AxesHistogram.XLabel.String = 'Niveau de gris';
            app.AxesHistogram.XLabel.Color  = [0.8 0.8 0.8];
            app.AxesHistogram.YLabel.String = 'Frequence';
            app.AxesHistogram.YLabel.Color  = [0.8 0.8 0.8];
            title(app.AxesHistogram,'Histogramme','Color','w');
        end

    end  % algorithmes

    % ══════════════════════════════════════════════════════
    %  CALLBACKS
    % ══════════════════════════════════════════════════════
    methods (Access = private)

        function ChargerImage(app, ~, ~)
            [f, d] = uigetfile( ...
                {'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff','Images'}, ...
                'Selectionner une image');
            if isequal(f,0), return; end
            raw = imread(fullfile(d,f));
            img = app.rgb2gris_manuel(raw);
            app.ImageOriginale = img;
            app.ImageResultat  = img;
            imshow(img,'Parent',app.AxesOriginal);
            title(app.AxesOriginal,'Image Originale','Color','w');
            imshow(img,'Parent',app.AxesResult);
            title(app.AxesResult,'Resultat','Color','w');
            app.AfficherHistogramme(img);
            app.AfficherStatistiques(img);
        end

        function AppliquerTransformation(app, ~, ~)
            if isempty(app.ImageOriginale)
                uialert(app.UIFigure,'Chargez une image d''abord.','Attention');
                return;
            end
            gamma   = app.SliderGamma.Value;
            transfo = app.DropdownTransfo.Value;

            switch transfo
                case 'Histogramme / Stats'
                    imgRes = app.ImageOriginale;

                case 'Gamma Correction'
                    imgRes = app.gammaCorrection(app.ImageOriginale, gamma);

                case 'Transformation Exponentielle'
                    imgRes = app.transfoExponentielle(app.ImageOriginale, gamma);

                case 'Transformation Logarithmique'
                    imgRes = app.transfoLogarithmique(app.ImageOriginale);

                case 'Etirement Lineaire'
                    imgRes = app.etirementLineaire(app.ImageOriginale);

                case 'Egalisation Histogramme'
                    imgRes = app.egalisationHistogramme(app.ImageOriginale);

                case 'Filtre Sobel'
                    imgRes = app.filtreSobel(app.ImageOriginale);

                case 'Segmentation OTSU'
                    [imgRes, seuil] = app.segmentationOTSU(app.ImageOriginale);
                    app.TextAreaStats.Value = sprintf( ...
                        'Methode : OTSU\nSeuil optimal : %d / 255\n(normalise : %.4f)', ...
                        seuil, seuil/255);

                otherwise
                    imgRes = app.ImageOriginale;
            end

            app.ImageResultat = imgRes;
            imshow(imgRes,'Parent',app.AxesResult);
            title(app.AxesResult,['Resultat : ' transfo],'Color','w');

            if ~strcmp(transfo,'Segmentation OTSU')
                app.AfficherHistogramme(imgRes);
                app.AfficherStatistiques(imgRes);
            end
        end

        function ResetApp(app, ~, ~)
            if isempty(app.ImageOriginale), return; end
            app.ImageResultat = app.ImageOriginale;
            imshow(app.ImageOriginale,'Parent',app.AxesResult);
            title(app.AxesResult,'Resultat (reinitialise)','Color','w');
            app.AfficherHistogramme(app.ImageOriginale);
            app.AfficherStatistiques(app.ImageOriginale);
        end

        function SauvegarderResultat(app, ~, ~)
            if isempty(app.ImageResultat)
                uialert(app.UIFigure,'Aucun resultat.','Attention');
                return;
            end
            [f,d] = uiputfile({'*.png','PNG';'*.jpg','JPEG';'*.bmp','BMP'}, ...
                               'Enregistrer');
            if ~isequal(f,0)
                imwrite(app.ImageResultat, fullfile(d,f));
                uialert(app.UIFigure,'Sauvegarde reussie !','Succes','Icon','success');
            end
        end

        function SliderGammaValueChanged(app, ~, ~)
            app.LabelGammaVal.Text = sprintf('g = %.2f', app.SliderGamma.Value);
        end

    end  % callbacks

    % ══════════════════════════════════════════════════════
    %  CONSTRUCTION DE L'INTERFACE
    % ══════════════════════════════════════════════════════
    methods (Access = private)

        function createComponents(app)

            app.UIFigure = uifigure('Visible','off');
            app.UIFigure.Position = [80 50 1220 720];
            app.UIFigure.Name = 'Traitement Image - Pr. Y. AIT LAHCEN';
            app.UIFigure.Color = [0.12 0.14 0.18];

            % Barre titre
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.Position = [0 678 1220 40];
            app.TitleLabel.Text = ...
                '  Application Traitement d''Image  |  ADIA/IISE S2  |  Pr. Y. AIT LAHCEN';
            app.TitleLabel.FontSize = 15;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor  = [1 1 1];
            app.TitleLabel.BackgroundColor = [0.15 0.35 0.65];

            % Panneau controles
            app.PanelControls = uipanel(app.UIFigure);
            app.PanelControls.Position = [8 8 225 665];
            app.PanelControls.Title = 'Controles';
            app.PanelControls.BackgroundColor = [0.15 0.17 0.22];
            app.PanelControls.ForegroundColor = [1 1 1];
            app.PanelControls.FontWeight = 'bold';

            % Btn Charger
            app.BtnCharger = uibutton(app.PanelControls,'push');
            app.BtnCharger.Position = [12 600 198 36];
            app.BtnCharger.Text = 'Charger Image';
            app.BtnCharger.FontSize = 13;
            app.BtnCharger.BackgroundColor = [0.15 0.52 0.32];
            app.BtnCharger.FontColor = [1 1 1];
            app.BtnCharger.ButtonPushedFcn = createCallbackFcn(app,@ChargerImage,true);

            % Dropdown
            app.LabelTransfo = uilabel(app.PanelControls);
            app.LabelTransfo.Position  = [12 558 198 22];
            app.LabelTransfo.Text      = 'Transformation :';
            app.LabelTransfo.FontColor = [0.85 0.85 0.85];
            app.LabelTransfo.FontWeight = 'bold';

            app.DropdownTransfo = uidropdown(app.PanelControls);
            app.DropdownTransfo.Position = [12 528 198 28];
            app.DropdownTransfo.Items = {
                'Histogramme / Stats', ...
                'Gamma Correction', ...
                'Transformation Exponentielle', ...
                'Transformation Logarithmique', ...
                'Etirement Lineaire', ...
                'Egalisation Histogramme', ...
                'Filtre Sobel', ...
                'Segmentation OTSU'};
            app.DropdownTransfo.Value = 'Histogramme / Stats';
            app.DropdownTransfo.BackgroundColor = [0.22 0.25 0.32];
            app.DropdownTransfo.FontColor = [1 1 1];

            % Slider Gamma
            app.LabelGamma = uilabel(app.PanelControls);
            app.LabelGamma.Position  = [12 488 130 22];
            app.LabelGamma.Text      = 'Parametre Gamma :';
            app.LabelGamma.FontColor = [0.85 0.85 0.85];
            app.LabelGamma.FontWeight = 'bold';

            app.LabelGammaVal = uilabel(app.PanelControls);
            app.LabelGammaVal.Position  = [145 488 65 22];
            app.LabelGammaVal.Text      = 'g = 1.00';
            app.LabelGammaVal.FontColor = [0.35 0.80 1.0];
            app.LabelGammaVal.FontWeight = 'bold';

            app.SliderGamma = uislider(app.PanelControls);
            app.SliderGamma.Position   = [12 468 198 3];
            app.SliderGamma.Limits     = [0.1 5.0];
            app.SliderGamma.Value      = 1.0;
            app.SliderGamma.MajorTicks = [0.1 1 2 3 4 5];
            app.SliderGamma.FontColor  = [1 1 1];
            app.SliderGamma.ValueChangedFcn = ...
                createCallbackFcn(app,@SliderGammaValueChanged,true);

            % Btn Appliquer
            app.BtnAppliquer = uibutton(app.PanelControls,'push');
            app.BtnAppliquer.Position = [12 410 198 42];
            app.BtnAppliquer.Text = 'Appliquer';
            app.BtnAppliquer.FontSize = 14;
            app.BtnAppliquer.FontWeight = 'bold';
            app.BtnAppliquer.BackgroundColor = [0.15 0.35 0.75];
            app.BtnAppliquer.FontColor = [1 1 1];
            app.BtnAppliquer.ButtonPushedFcn = ...
                createCallbackFcn(app,@AppliquerTransformation,true);

            % Btn Reset
            app.BtnReset = uibutton(app.PanelControls,'push');
            app.BtnReset.Position = [12 358 198 36];
            app.BtnReset.Text = 'Reinitialiser';
            app.BtnReset.FontSize = 12;
            app.BtnReset.BackgroundColor = [0.52 0.32 0.08];
            app.BtnReset.FontColor = [1 1 1];
            app.BtnReset.ButtonPushedFcn = createCallbackFcn(app,@ResetApp,true);

            % Btn Sauvegarder
            app.BtnSauvegarder = uibutton(app.PanelControls,'push');
            app.BtnSauvegarder.Position = [12 308 198 36];
            app.BtnSauvegarder.Text = 'Sauvegarder';
            app.BtnSauvegarder.FontSize = 12;
            app.BtnSauvegarder.BackgroundColor = [0.38 0.15 0.52];
            app.BtnSauvegarder.FontColor = [1 1 1];
            app.BtnSauvegarder.ButtonPushedFcn = ...
                createCallbackFcn(app,@SauvegarderResultat,true);

            % Stats
            app.LabelStats = uilabel(app.PanelControls);
            app.LabelStats.Position  = [12 272 198 22];
            app.LabelStats.Text      = 'Statistiques :';
            app.LabelStats.FontColor = [0.85 0.85 0.85];
            app.LabelStats.FontWeight = 'bold';

            app.TextAreaStats = uitextarea(app.PanelControls);
            app.TextAreaStats.Position   = [12 20 198 248];
            app.TextAreaStats.Value      = 'Chargez une image...';
            app.TextAreaStats.Editable   = false;
            app.TextAreaStats.BackgroundColor = [0.09 0.11 0.15];
            app.TextAreaStats.FontColor  = [0.4 0.95 0.5];
            app.TextAreaStats.FontName   = 'Courier New';
            app.TextAreaStats.FontSize   = 11;

            % Axes Original
            app.LabelOrig = uilabel(app.UIFigure);
            app.LabelOrig.Position  = [242 656 360 20];
            app.LabelOrig.Text      = 'IMAGE ORIGINALE';
            app.LabelOrig.FontColor = [0.65 0.65 0.65];
            app.LabelOrig.FontWeight = 'bold';

            app.AxesOriginal = uiaxes(app.UIFigure);
            app.AxesOriginal.Position = [242 355 380 298];
            app.AxesOriginal.BackgroundColor = [0.07 0.09 0.13];
            app.AxesOriginal.XColor = 'none';
            app.AxesOriginal.YColor = 'none';
            app.AxesOriginal.Color  = [0.07 0.09 0.13];

            % Axes Resultat
            app.LabelRes = uilabel(app.UIFigure);
            app.LabelRes.Position  = [638 656 500 20];
            app.LabelRes.Text      = 'IMAGE RESULTANTE';
            app.LabelRes.FontColor = [0.65 0.65 0.65];
            app.LabelRes.FontWeight = 'bold';

            app.AxesResult = uiaxes(app.UIFigure);
            app.AxesResult.Position = [638 355 572 298];
            app.AxesResult.BackgroundColor = [0.07 0.09 0.13];
            app.AxesResult.XColor = 'none';
            app.AxesResult.YColor = 'none';
            app.AxesResult.Color  = [0.07 0.09 0.13];

            % Axes Histogramme
            app.LabelHist = uilabel(app.UIFigure);
            app.LabelHist.Position  = [242 332 300 20];
            app.LabelHist.Text      = 'HISTOGRAMME';
            app.LabelHist.FontColor = [0.65 0.65 0.65];
            app.LabelHist.FontWeight = 'bold';

            app.AxesHistogram = uiaxes(app.UIFigure);
            app.AxesHistogram.Position = [242 20 968 308];
            app.AxesHistogram.BackgroundColor = [0.07 0.09 0.13];
            app.AxesHistogram.Color   = [0.07 0.09 0.13];
            app.AxesHistogram.XColor  = [0.65 0.65 0.65];
            app.AxesHistogram.YColor  = [0.65 0.65 0.65];
            app.AxesHistogram.GridColor = [0.28 0.28 0.28];
            grid(app.AxesHistogram,'on');

            app.UIFigure.Visible = 'on';
        end

    end

    methods (Access = public)
        function app = TraitementImage
            createComponents(app);
            registerApp(app, app.UIFigure);
            if nargout == 0, clear app; end
        end
        function delete(app)
            delete(app.UIFigure);
        end
    end

end