
%% VALIDAÇÃO DO OPERADOR TOP-HAT
% Objetivo:
% Analisar o comportamento do operador morfológico Top-hat
% aplicado à correção de iluminação não uniforme em
% imagens de placas de automóveis.
%
% O script realiza:
%   1. Seleção de uma placa para teste.
%   2. Aplicação do operador Top-hat.
%   3. Verificação da implementação.
%   4. Comparação visual da imagem original e processada.
%   5. Comparação visual de diferentes raios.
%   6. Comparação do OCR original com os resultados Top-hat.
%   7. Diagnóstico e resumo dos resultados.
%
% As imagens são processadas em sua resolução original.
% Nenhuma operação de ampliação é utilizada.
%
% Este script é destinado à validação exploratória.
% Não modifica as imagens originais nem os Ground Truths.


%% 1. Configuração inicial

clc;
close all;

% Obtém o caminho da pasta principal do projeto.
raizProjeto = fileparts(fileparts(mfilename('fullpath')));

% Adiciona os diretórios necessários ao MATLAB.
addpath(fullfile(raizProjeto, 'src', 'morphology'));
addpath(fullfile(raizProjeto, 'src', 'ocr'));

% Define a imagem utilizada no teste.
indiceImagem = 9;

% Define o raio utilizado na validação individual.
raio = 43;

% Define os raios utilizados na comparação.
raiosTeste = [15, 21, 27, 31, 43, 53];


%% 2. Carregamento da seleção

% Define o caminho do arquivo com as imagens selecionadas.
arquivoSelecao = fullfile(raizProjeto, ...
    'data', 'selected', 'selected_images.csv');

% Verifica se o arquivo de seleção existe.
if ~isfile(arquivoSelecao)
    error('Arquivo selected_images.csv não encontrado.');
end

% Carrega a lista de imagens selecionadas.
selecao = readtable(arquivoSelecao, ...
    'TextType', 'string');

% Organiza a seleção por identificador crescente.
selecao = sortrows(selecao, 'image_id');

% Verifica se o índice informado é válido.
if indiceImagem < 1 || indiceImagem > height(selecao)
    error('Índice da imagem fora do intervalo disponível.');
end


%% 3. Escolha e identificação da placa

% Obtém o nome do arquivo selecionado.
nomeArquivo = selecao.file_name(indiceImagem);

% Define o caminho completo da placa.
caminhoImagem = fullfile(raizProjeto, ...
    'data', 'selected', 'plates', nomeArquivo);

% Verifica se o arquivo existe.
if ~isfile(caminhoImagem)
    error('Imagem não encontrada: %s', nomeArquivo);
end

% Carrega a imagem original da placa.
imagemOriginal = imread(caminhoImagem);

% Obtém as dimensões da imagem.
[altura, largura, ~] = size(imagemOriginal);

fprintf('\n========================================\n');
fprintf(' CONFIGURAÇÃO DO TESTE TOP-HAT\n');
fprintf('========================================\n');

fprintf('Índice na seleção: %d\n', indiceImagem);
fprintf('ID da imagem: %d\n', selecao.image_id(indiceImagem));
fprintf('Arquivo: %s\n', nomeArquivo);
fprintf('Raio principal: %d\n', raio);
fprintf('Resolução: %d x %d pixels\n', largura, altura);


%% 4. Aplicação do operador Top-hat

% Aplica o Top-hat utilizando o raio principal.
[imagemCorrigida, imagemTopHat] = ...
    applyTopHat(imagemOriginal, raio);

% Converte a imagem original para escala de cinza.
if size(imagemOriginal, 3) == 3
    imagemCinza = rgb2gray(imagemOriginal);
else
    imagemCinza = imagemOriginal;
end

% Calcula a diferença absoluta entre as imagens.
imagemDiferenca = imabsdiff( ...
    imagemCinza, imagemCorrigida);


%% 5. Verificação da implementação

% Confirma que as dimensões foram preservadas.
assert(isequal(size(imagemCinza), size(imagemCorrigida)), ...
    'A imagem corrigida possui dimensões diferentes.');

% Conta os pixels alterados pelo processamento.
quantidadePixelsAlterados = nnz(imagemDiferenca);

tamanhoQuadrado = 2 * raio + 1;

elementoEstruturante = strel('square', tamanhoQuadrado);

% Calcula o fechamento morfológico.
imagemFechamento = imclose( ...
    imagemCinza, elementoEstruturante);

% Calcula o Black Top-hat pela definição matemática.
referenciaTopHat = imsubtract( ...
    imagemFechamento, imagemCinza);

% Verifica a equivalência com imbothat().
assert(isequal(imagemTopHat, referenciaTopHat), ...
    'Black Top-hat diferente da definição matemática.');

% Verifica a imagem utilizada pelo OCR.
referenciaOCR = imcomplement(referenciaTopHat);

assert(isequal(imagemCorrigida, referenciaOCR), ...
    'Imagem corrigida diferente da referência.');

fprintf('\n========================================\n');
fprintf(' VERIFICAÇÃO DO BLACK TOP-HAT\n');
fprintf('========================================\n');

fprintf('Pixels alterados: %d\n', ...
    quantidadePixelsAlterados);

fprintf('Black Top-hat: OK\n');
fprintf('Preparação para OCR: OK\n');


%% 6. Comparação visual das imagens

figure('Name', 'Validação visual do Black Top-hat');

subplot(2, 2, 1);
imshow(imagemCinza);
title('Imagem original');

subplot(2, 2, 2);
imshow(imagemFechamento);
title('Fechamento morfológico');

subplot(2, 2, 3);
imshow(imagemTopHat);
title('Black Top-hat');

subplot(2, 2, 4);
imshow(imagemCorrigida);
title('Imagem preparada para OCR');


%% 7. Comparação visual dos raios

% Aplica o Top-hat utilizando diferentes raios.
% As imagens são apresentadas sem ampliação.

quantidadeRaios = numel(raiosTeste);

% Define automaticamente a organização dos gráficos.
quantidadeColunas = 3;
quantidadeLinhas = ceil(quantidadeRaios / quantidadeColunas);

figure('Name', 'Comparação dos raios Top-hat');

for indice = 1:quantidadeRaios

    raioAtual = raiosTeste(indice);

    % Aplica o Top-hat com o raio atual.
    imagemTeste = applyTopHat( ...
        imagemOriginal, raioAtual);

    subplot(quantidadeLinhas, quantidadeColunas, indice);

    imshow(imagemTeste);

    title(sprintf('Raio = %d', raioAtual));

end


%% 8. Reconhecimento OCR da imagem original

% Executa o mesmo OCR utilizado no sistema baseline.
[textoOriginal, ~] = recognizePlate(caminhoImagem);

% Prepara a apresentação do resultado.
if ismissing(textoOriginal) || strlength(textoOriginal) == 0
    textoOriginalExibido = "[SEM RECONHECIMENTO]";
else
    textoOriginalExibido = textoOriginal;
end

fprintf('\n========================================\n');
fprintf(' OCR DA IMAGEM ORIGINAL\n');
fprintf('========================================\n');

fprintf('Arquivo: %s\n', nomeArquivo);
fprintf('OCR original: %s\n', textoOriginalExibido);


%% 9. Reconhecimento OCR com diferentes raios

% Executa o Top-hat e o OCR para cada raio.
%
% O OCR utiliza a mesma configuração definida
% na função recognizePlate.m.
%
% Nenhuma ampliação é aplicada às imagens.

fprintf('\n========================================\n');
fprintf(' OCR COM DIFERENTES RAIOS TOP-HAT\n');
fprintf('========================================\n');

fprintf('Imagem: %s\n\n', nomeArquivo);

% Prepara as variáveis para armazenar os resultados.
textosReconhecidos = strings(quantidadeRaios, 1);

for indice = 1:quantidadeRaios

    raioAtual = raiosTeste(indice);

    % Aplica o operador Top-hat.
    imagemTopHat = applyTopHat( ...
        imagemOriginal, raioAtual);

    % Cria um arquivo temporário em formato PNG.
    arquivoTemporario = [tempname, '.png'];

    % Salva temporariamente a imagem processada.
    imwrite(imagemTopHat, arquivoTemporario);

    % Executa o OCR utilizando a função do projeto.
    [textoReconhecido, ~] = ...
        recognizePlate(arquivoTemporario);

    % Remove o arquivo temporário.
    delete(arquivoTemporario);

    % Armazena o resultado do reconhecimento.
    textosReconhecidos(indice) = textoReconhecido;

    % Identifica resultados vazios.
    if ismissing(textoReconhecido) || ...
            strlength(textoReconhecido) == 0

        textoExibido = "[SEM RECONHECIMENTO]";

    else

        textoExibido = textoReconhecido;

    end

    % Apresenta o resultado do raio atual.
    fprintf('Raio: %2d | OCR: %s\n', ...
        raioAtual, textoExibido);

end


%% 10. Diagnóstico da imagem corrigida

% Realiza o diagnóstico da imagem processada
% com o raio principal definido na Seção 1.

totalPixels = numel(imagemCinza);

% Calcula os valores mínimo e máximo de intensidade.
intensidadeMinima = double(min(imagemCorrigida(:)));

intensidadeMaxima = double(max(imagemCorrigida(:)));

% Define os caracteres permitidos no OCR.
caracteresPermitidos = ...
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

% Executa OCR diretamente na imagem corrigida.
resultadoOCR = ocr(imagemCorrigida, ...
    'LayoutAnalysis', 'line', ...
    'CharacterSet', caracteresPermitidos);

% Obtém a quantidade de caixas de caracteres detectadas.
caracteresDetectados = size( ...
    resultadoOCR.CharacterBoundingBoxes, 1);

fprintf('\n========================================\n');
fprintf(' DIAGNÓSTICO DA IMAGEM CORRIGIDA\n');
fprintf('========================================\n');

fprintf('Arquivo: %s\n', nomeArquivo);
fprintf('Raio utilizado: %d\n', raio);
fprintf('Largura: %d pixels\n', largura);
fprintf('Altura: %d pixels\n', altura);
fprintf('Total de pixels: %d\n', totalPixels);

fprintf('Intensidade mínima: %.2f\n', intensidadeMinima);
fprintf('Intensidade máxima: %.2f\n', intensidadeMaxima);

fprintf('Texto bruto do OCR:\n');
disp(resultadoOCR.Text);

fprintf('Caixas de caracteres detectadas: %d\n', ...
    caracteresDetectados);

% Exibe a imagem corrigida e sua binarização.
figure('Name', 'Diagnóstico da imagem corrigida');

subplot(1, 2, 1);
imshow(imagemCorrigida);
title(sprintf('Top-hat - Raio %d', raio));

subplot(1, 2, 2);
imshow(imbinarize(imagemCorrigida));
title('Binarização automática');


%% 11. Resumo dos resultados

fprintf('\n========================================\n');
fprintf(' RESUMO DA VALIDAÇÃO TOP-HAT\n');
fprintf('========================================\n');

fprintf('Imagem analisada: %s\n', nomeArquivo);
fprintf('Raio principal: %d\n', raio);

fprintf('Resolução original: %d x %d pixels\n', ...
    largura, altura);

fprintf('Pixels alterados: %d\n', ...
    quantidadePixelsAlterados);

fprintf('Pixels diferentes da referência: %d\n', ...
    pixelsDiferentes);

fprintf('\nResultado OCR original: %s\n', ...
    textoOriginalExibido);

fprintf('\nResultados por raio:\n');

for indice = 1:quantidadeRaios

    texto = textosReconhecidos(indice);

    if ismissing(texto) || strlength(texto) == 0
        texto = "[SEM RECONHECIMENTO]";
    end

    fprintf('Raio: %2d | OCR: %s\n', ...
        raiosTeste(indice), texto);

end

fprintf('\nVerificação concluída.\n');
fprintf('Analise visualmente as imagens e os resultados OCR.\n');
