% TESTE 03 - Conjunto de caracteres
%
% Objetivo:
% Avaliar o comportamento padrão da função ocr()
% na identificação dos caracteres de uma placa.

clc;
clear;
close all;

% Carregamento da imagem
I = imread("data/selected/plates/image_0002.jpg");
I = im2gray(I);

figure
imshow(I)

results = ocr(I, LayoutAnalysis="Block", characterSet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

% Exibição dos resultados
disp("Texto reconhecido:");
disp(results.Text);

disp("Palavras identificadas:");
disp(results.Words);