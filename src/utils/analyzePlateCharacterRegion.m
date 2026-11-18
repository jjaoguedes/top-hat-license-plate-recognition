% ANALYZEPLATECHARACTERREGION Analisa as placas e visualiza a ROI dos caracteres.
%
% O script mede todas as imagens em data/selected/plates, calcula as
% dimensoes medias e aplica a regiao definida por extractPlateROI.
% Sao exibidos uma tabela com as dimensoes e duas figuras: as imagens
% originais com a delimitacao e os recortes resultantes.

clc;
close all;

%% Localizacao dos arquivos

diretorioScript = fileparts(mfilename('fullpath'));
raizProjeto = fileparts(fileparts(diretorioScript));

addpath(fullfile(raizProjeto, 'src', 'utils'));

diretorioPlacas = fullfile( ...
    raizProjeto, 'data', 'selected', 'plates');

if ~isfolder(diretorioPlacas)
    error('Diretorio de placas nao encontrado: %s', diretorioPlacas);
end

%% Localizacao e ordenacao das imagens

arquivos = [ ...
    dir(fullfile(diretorioPlacas, '*.jpg')); ...
    dir(fullfile(diretorioPlacas, '*.jpeg')); ...
    dir(fullfile(diretorioPlacas, '*.png')); ...
    dir(fullfile(diretorioPlacas, '*.tif')); ...
    dir(fullfile(diretorioPlacas, '*.tiff')); ...
    dir(fullfile(diretorioPlacas, '*.bmp'))];

if isempty(arquivos)
    error('Nenhuma imagem encontrada em: %s', diretorioPlacas);
end

[~, ordem] = sort(lower(string({arquivos.name})));
arquivos = arquivos(ordem);
quantidadeImagens = numel(arquivos);

%% Medicao e delimitacao da regiao dos caracteres

nomes = strings(quantidadeImagens, 1);
larguras = zeros(quantidadeImagens, 1);
alturas = zeros(quantidadeImagens, 1);
largurasROI = zeros(quantidadeImagens, 1);
alturasROI = zeros(quantidadeImagens, 1);
xInicial = zeros(quantidadeImagens, 1);
xFinal = zeros(quantidadeImagens, 1);
yInicial = zeros(quantidadeImagens, 1);
yFinal = zeros(quantidadeImagens, 1);
recortes = cell(quantidadeImagens, 1);

for indice = 1:quantidadeImagens
    nomes(indice) = string(arquivos(indice).name);
    caminhoImagem = fullfile( ...
        diretorioPlacas, arquivos(indice).name);

    imagem = imread(caminhoImagem);
    [alturas(indice), larguras(indice), ~] = size(imagem);

    [recortes{indice}, coordenadas] = extractPlateROI(imagem);

    [alturasROI(indice), largurasROI(indice), ~] = ...
        size(recortes{indice});

    xInicial(indice) = coordenadas.xInicial;
    xFinal(indice) = coordenadas.xFinal;
    yInicial(indice) = coordenadas.yInicial;
    yFinal(indice) = coordenadas.yFinal;
end

%% Estatisticas das imagens e das regioes

larguraMedia = mean(larguras);
alturaMedia = mean(alturas);
larguraROIMedia = mean(largurasROI);
alturaROIMedia = mean(alturasROI);

tabelaDimensoes = table( ...
    nomes, larguras, alturas, largurasROI, alturasROI, ...
    xInicial, xFinal, yInicial, yFinal, ...
    'VariableNames', { ...
        'arquivo', 'larguraImagem', 'alturaImagem', ...
        'larguraROI', 'alturaROI', ...
        'xInicial', 'xFinal', 'yInicial', 'yFinal'});

fprintf('\n========================================\n');
fprintf(' ANALISE DA REGIAO DOS CARACTERES\n');
fprintf('========================================\n');
fprintf('Imagens analisadas: %d\n', quantidadeImagens);
fprintf('Dimensao media das imagens: %.2f x %.2f pixels (L x A)\n', ...
    larguraMedia, alturaMedia);
fprintf('Dimensao media da ROI: %.2f x %.2f pixels (L x A)\n\n', ...
    larguraROIMedia, alturaROIMedia);
disp(tabelaDimensoes);

%% Visualizacao das delimitacoes e dos recortes

colunas = ceil(sqrt(quantidadeImagens));
linhas = ceil(quantidadeImagens / colunas);

figure('Name', 'Delimitacao da regiao dos caracteres', ...
    'NumberTitle', 'off');

for indice = 1:quantidadeImagens
    subplot(linhas, colunas, indice);

    caminhoImagem = fullfile( ...
        diretorioPlacas, arquivos(indice).name);
    imshow(imread(caminhoImagem));
    hold on;
    rectangle('Position', [ ...
        xInicial(indice), yInicial(indice), ...
        xFinal(indice) - xInicial(indice), ...
        yFinal(indice) - yInicial(indice)], ...
        'EdgeColor', 'g', 'LineWidth', 1.5);
    hold off;
    title(arquivos(indice).name, 'Interpreter', 'none');
end

figure('Name', 'Recortes da regiao dos caracteres', ...
    'NumberTitle', 'off');

for indice = 1:quantidadeImagens
    subplot(linhas, colunas, indice);
    imshow(recortes{indice});
    title(arquivos(indice).name, 'Interpreter', 'none');
end
