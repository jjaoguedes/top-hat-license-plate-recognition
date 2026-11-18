% TESTE 01 - Reconhecimento básico de placa
%
% Objetivo:
% Avaliar o comportamento padrão da função ocr()
% na identificação dos caracteres de uma placa.

clc;
clear;
close all;

% Carregamento da imagem
I = imread("data/selected/plates/image_0097.jpg");

% Reconhecimento OCR
results = ocr(I);

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
outputDir = "src/ocr/results/test01";

% Cria o diretório caso não exista
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Caminho do arquivo
outputFile = fullfile(outputDir, ...
    "image_0097_basic_ocr.png");

% Salva a imagem
exportgraphics(gcf, outputFile);

disp("Imagem salva em: " + outputFile);