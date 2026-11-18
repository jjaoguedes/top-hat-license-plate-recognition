% TESTE 04 - Layout do texto reconhecido com Black Top-hat
%
% Objetivo:
% Avaliar o comportamento padrão da função ocr()
% na identificação dos caracteres de uma placa.

clc;
clear;
close all;

diretorioScript = fileparts(mfilename('fullpath'));
raizProjeto = fileparts(fileparts(fileparts(diretorioScript)));
addpath(fullfile(raizProjeto, 'src', 'utils'));
addpath(fullfile(raizProjeto, 'src', 'morphology'));

% Carregamento da imagem
caminhoImagem = fullfile( ...
    raizProjeto, 'data', 'selected', 'plates', 'image_0008.jpg');
I = imread(caminhoImagem);
I = im2gray(I);

figure
imshow(I)

results = ocr(I, LayoutAnalysis="Block", characterSet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

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

BW = imbinarize(I);

figure
imshowpair(I,BW,"montage")

% Aplica o Black Top-hat.
raio = 25;
SE = 'disk';
Icorrected = applyTopHat(I, SE,raio);

BW1 = imbinarize(Icorrected);

figure 
imshowpair(I,BW1,"montage")

results1 = ocr(Icorrected, LayoutAnalysis="Block", characterSet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

% Exibição dos resultados
disp("Texto reconhecido com Black TopHat:");
disp(results1.Text);

disp("Palavras identificadas com Black TopHat::");
disp(results1.Words);

% Visualização das regiões
imshow(Icorrected);
hold on;

% Coordenadas das regiões reconhecidas
wordBBox = results1.WordBoundingBoxes;

% Desenha retângulo ao redor do que foi reconhecido pelo OCR
for i = 1:size(wordBBox, 1)
    rectangle('Position', wordBBox(i,:), ...
        'EdgeColor', 'r', 'LineWidth', 2);
end

% Diretório para salvar os resultados
outputDir = "src/ocr/results/test04";

% Cria o diretório caso não exista
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Salva o resultado do Layout Analysis
outputFile = fullfile(outputDir, ...
    "image_0008_black_TopHat.png");

exportgraphics(gcf, outputFile);

% Binarização da imagem
BW = imbinarize(I);

% Exibe imagem original e binarizada
figure;
imshowpair(I, BW, "montage");

% Salva a comparação
outputFileBW = fullfile(outputDir, ...
    "image_0008_binarized_montage.png");

exportgraphics(gcf, outputFileBW);

% Salva somente a imagem binarizada
imwrite(BW, fullfile(outputDir, ...
    "image_0008_binarized.png"));

disp("Resultados salvos em: " + outputDir);