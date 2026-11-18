clc;
clear;
close all;

diretorioScript = fileparts(mfilename('fullpath'));
raizProjeto = fileparts(fileparts(fileparts(diretorioScript)));
addpath(fullfile(raizProjeto, 'src', 'utils'));

% Carregamento da imagem
caminhoImagem = fullfile( ...
    raizProjeto, 'data', 'selected', 'plates', 'image_0002.jpg');
I = imread(caminhoImagem);
I = im2gray(I);

% Recorte da regiao dos caracteres e OCR da imagem corrigida
imagemROI = extractPlateROI(I);
results2 = ocr(imagemROI, LayoutAnalysis="Block", characterSet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

disp("Texto reconhecido na ROI:");
disp(results2.Text);

disp("Palavras identificadas na ROI:");
disp(results2.Words);

% Visualizacao das regioes reconhecidas na imagem recortada
figure;
imshow(imagemROI);