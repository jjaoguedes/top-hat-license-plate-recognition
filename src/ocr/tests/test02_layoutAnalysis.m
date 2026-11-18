% TESTE 02 - Layout do texto reconhecido
%
% Objetivo:
% Avaliar o comportamento padrão da função ocr()
% na identificação dos caracteres de uma placa.

clc;
clear;
close all;

% Carregamento da imagem
I = imread("data/selected/plates/image_0097.jpg");
I = im2gray(I);

figure
imshow(I)

results = ocr(I, LayoutAnalysis="Block");

% Exibição dos resultados
disp("Texto reconhecido:");
disp(results.Text);

disp("Palavras identificadas:");
disp(results.Words);

% Visualização das regiões
imshow(I);
hold on;

% Coordenadas das regiões reconhecidas
wordBBox = results.WordBoundingBoxes;

% Desenha retângulo ao redor do que foi reconhecido pelo OCR
for i = 1:size(wordBBox, 1)
    rectangle('Position', wordBBox(i,:), ...
        'EdgeColor', 'r', 'LineWidth', 2);
end

hold off;

% Diretório para salvar os resultados
outputDir = "src/ocr/results/test02";

% Cria o diretório caso não exista
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Salva o resultado do Layout Analysis
outputFile = fullfile(outputDir, ...
    "image_0097_layout_Analysis.png");

exportgraphics(gcf, outputFile);

% Binarização da imagem
BW = imbinarize(I);

% Exibe imagem original e binarizada
figure;
imshowpair(I, BW, "montage");

% Salva a comparação
outputFileBW = fullfile(outputDir, ...
    "image_0097_binarized_montage.png");

exportgraphics(gcf, outputFileBW);

% Salva somente a imagem binarizada
imwrite(BW, fullfile(outputDir, ...
    "image_0097_binarized.png"));

disp("Resultados salvos em: " + outputDir);