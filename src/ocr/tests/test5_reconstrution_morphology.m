% TESTE 02 - Layout do texto reconhecido
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

% Aplica o Black Top-hat.
raio = 25;
SE = 'disk';
Icorrected = applyTopHat(I, SE,raio);

BW1 = imbinarize(Icorrected);

figure 
imshowpair(I,BW1,"montage")

% Perform morphological reconstruction and show binarized image.
marker = imerode(Icorrected,strel("line",10,0));
Iclean = imreconstruct(marker,Icorrected);

Ibinary = imbinarize(Iclean);

figure
imshowpair(Iclean,Ibinary,"montage")



results = ocr(Ibinary,LayoutAnalysis="block");

results.Text

% Use the "CharacterSet" parameter to constrain OCR
results = ocr(Ibinary,LayoutAnalysis="Block", characterSet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

results.Text

% Use regionprops to find bounding boxes around text regions and measure their area.
cc = bwconncomp(Ibinary);
stats = regionprops(cc, ["BoundingBox","Area"]);

% Extract bounding boxes and area from the output statistics.
roi = vertcat(stats(:).BoundingBox);
area = vertcat(stats(:).Area);

% Show all the connected regions.
img = insertObjectAnnotation(I,"rectangle",roi,area,"LineWidth",3);
figure;
imshow(img);

% Define area constraint based on the area of smallest character of interest.
areaConstraint = area > 347;

% Keep regions that meet the area constraint.
roi = double(roi(areaConstraint,:));

% Show remaining bounding boxes after applying the area constraint.
img = insertShape(I,"rectangle",roi);
figure;
imshow(img);

% Compute the aspect ratio.
width  = roi(:,3);
height = roi(:,4);
aspectRatio = width ./ height;

% An aspect ratio between 0.25 and 1.25 is typical for individual characters
% as they are usually not very short and wide or very tall and skinny.
roi = roi( aspectRatio > 0.25 & aspectRatio < 1.25 ,:);

% Show regions after applying the area and aspect ratio constraints.
img = insertShape(I,"rectangle",roi);
figure;
imshow(img);

numAdditionalPixels = 5;
roi(:,1:2) = roi(:,1:2) - numAdditionalPixels;
roi(:,3:4) = roi(:,3:4) + 2*numAdditionalPixels;

results = ocr(Ibinary,roi,LayoutAnalysis="Block", characterSet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");
