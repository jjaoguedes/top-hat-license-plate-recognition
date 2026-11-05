
%% TESTE DA FUNCAO APPLYTOPHAT
% Valida a implementacao do Black Top-hat.
%
% Objetivos:
% 1. Ler uma placa selecionada.
% 2. Executar applyTopHat.m.
% 3. Verificar a definicao matematica do Black Top-hat.
% 4. Comparar as imagens em cada etapa.
% 5. Testar o OCR antes e depois do processamento.
% 6. Comparar os resultados com o Ground Truth.
%
% Este script nao modifica os resultados oficiais
% dos sistemas e1 e e2.


%% 1. Configuracao inicial

clc;
close all;

% Identifica automaticamente a raiz do projeto.
diretorioScript = fileparts(mfilename('fullpath'));

raizProjeto = fileparts(fileparts(diretorioScript));

% Adiciona o modulo de morfologia.
addpath(fullfile(raizProjeto, 'src', 'morphology'));

% Parametros do teste.
nomeImagem = 'image_0030.jpg';

% O parametro raio define metade do lado do quadrado.
% Para um quadrado de 51 x 51, utilizar raio = 25.
raio = 25;

% O lado do quadrado sera 2*raio + 1.
tamanhoQuadrado = 2 * raio + 1;

% Localizacao da placa.
caminhoImagem = fullfile(raizProjeto, ...
    'data', 'selected', 'plates', nomeImagem);

% Localizacao do Ground Truth.
arquivoGroundTruth = fullfile(raizProjeto, ...
    'data', 'ground_truth', 'ground_truth.csv');


%% 2. Leitura da imagem

if ~isfile(caminhoImagem)
    error('Imagem nao encontrada: %s', caminhoImagem);
end

imagemOriginal = imread(caminhoImagem);

% Conversao para escala de cinza.
if size(imagemOriginal, 3) == 3
    imagemCinza = rgb2gray(imagemOriginal);
else
    imagemCinza = imagemOriginal;
end

[altura, largura] = size(imagemCinza);

fprintf('\n========================================\n');
fprintf(' TESTE DA FUNCAO APPLYTOPHAT\n');
fprintf('========================================\n');

fprintf('Imagem: %s\n', nomeImagem);
fprintf('Resolucao: %d x %d pixels\n', largura, altura);
fprintf('Operador: Black Top-hat\n');
fprintf('Elemento estruturante: square\n');
fprintf('Parametro raio: %d\n', raio);
fprintf('Tamanho: %d x %d pixels\n', ...
    tamanhoQuadrado, tamanhoQuadrado);


%% 3. Execucao da funcao principal

[imagemCorrigida, imagemTopHat] = ...
    applyTopHat(imagemOriginal, raio);


%% 4. Calculo independente da referencia

% Define o mesmo elemento estruturante.
elementoEstruturante = strel( ...
    'square', tamanhoQuadrado);

% Calcula o fechamento morfologico.
%
% O fechamento corresponde a uma dilatacao
% seguida de uma erosao.

imagemFechamento = imclose( ...
    imagemCinza, elementoEstruturante);

% Calcula a definicao matematica do Black Top-hat.
%
% T_b(f) = fechamento(f) - f

referenciaTopHat = imsubtract( ...
    imagemFechamento, imagemCinza);

% Calcula o operador nativo do MATLAB.
referenciaNativa = imbothat( ...
    imagemCinza, elementoEstruturante);

% Complemento esperado para o OCR.
referenciaOCR = imcomplement(referenciaTopHat);


%% 5. Validacao matematica

% Confirma que as dimensoes foram preservadas.
assert(isequal(size(imagemCinza), ...
    size(imagemTopHat)), ...
    'O Top-hat alterou as dimensoes da imagem.');

assert(isequal(size(imagemCinza), ...
    size(imagemCorrigida)), ...
    'A imagem corrigida possui dimensoes incorretas.');

% Compara com a definicao matematica.
assert(isequal(imagemTopHat, referenciaTopHat), ...
    'O Black Top-hat difere da definicao matematica.');

% Compara com a funcao nativa do MATLAB.
assert(isequal(imagemTopHat, referenciaNativa), ...
    'O resultado difere de imbothat().');

% Confirma a preparacao para OCR.
assert(isequal(imagemCorrigida, referenciaOCR), ...
    'A imagem preparada para OCR esta incorreta.');

% Mede a diferenca entre a imagem e a referencia.
pixelsDiferentes = nnz( ...
    imagemTopHat ~= referenciaTopHat);

% Quantifica pixels modificados no processamento.
pixelsAlterados = nnz( ...
    imagemCorrigida ~= imagemCinza);

fprintf('\n========================================\n');
fprintf(' VALIDACAO MATEMATICA\n');
fprintf('========================================\n');

fprintf('Definicao Black Top-hat: OK\n');
fprintf('Equivalencia com imbothat: OK\n');
fprintf('Preparacao da imagem OCR: OK\n');
fprintf('Pixels diferentes da referencia: %d\n', ...
    pixelsDiferentes);
fprintf('Pixels alterados na imagem OCR: %d\n', ...
    pixelsAlterados);


%% 6. Diagnostico das intensidades

fprintf('\n========================================\n');
fprintf(' DIAGNOSTICO DAS INTENSIDADES\n');
fprintf('========================================\n');

fprintf('Original   | Min: %.2f | Max: %.2f\n', ...
    double(min(imagemCinza(:))), ...
    double(max(imagemCinza(:))));

fprintf('Fechamento | Min: %.2f | Max: %.2f\n', ...
    double(min(imagemFechamento(:))), ...
    double(max(imagemFechamento(:))));

fprintf('Black TH   | Min: %.2f | Max: %.2f\n', ...
    double(min(imagemTopHat(:))), ...
    double(max(imagemTopHat(:))));

fprintf('Corrigida  | Min: %.2f | Max: %.2f\n', ...
    double(min(imagemCorrigida(:))), ...
    double(max(imagemCorrigida(:))));


%% 7. Visualizacao das etapas

figure('Name', 'Validacao do Black Top-hat', ...
    'NumberTitle', 'off');

subplot(2,2,1);
imshow(imagemCinza);
title('1. Imagem original');

subplot(2,2,2);
imshow(imagemFechamento);
title('2. Fechamento morfologico');

subplot(2,2,3);
imshow(imagemTopHat);
title('3. Black Top-hat');

subplot(2,2,4);
imshow(imagemCorrigida);
title('4. Imagem preparada para OCR');


%% 8. Comparacao direta entre as imagens

figure('Name', 'Original x Black Top-hat', ...
    'NumberTitle', 'off');

subplot(1,3,1);
imshow(imagemCinza);
title('Original');

subplot(1,3,2);
imshow(imagemTopHat);
title('Black Top-hat');

subplot(1,3,3);
imshow(imagemCorrigida);
title('Complemento para OCR');


%% 9. Recuperacao do Ground Truth

textoVerdadeiro = "";

if isfile(arquivoGroundTruth)

    tabelaGT = readtable(arquivoGroundTruth, ...
        'TextType', 'string');

    indiceGT = find( ...
        tabelaGT.file_name == string(nomeImagem), 1);

    if ~isempty(indiceGT)

        textoVerdadeiro = upper(regexprep( ...
            string(tabelaGT.plate_text(indiceGT)), ...
            '[^A-Za-z0-9]', ''));

    end

end


%% 10. Teste de reconhecimento OCR

caracteresPermitidos = ...
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

% OCR da imagem original, sem Top-hat.
resultadoOriginal = ocr(imagemCinza, ...
    'LayoutAnalysis', 'line', ...
    'CharacterSet', caracteresPermitidos);

% OCR da imagem corrigida pelo Black Top-hat.
resultadoCorrigido = ocr(imagemCorrigida, ...
    'LayoutAnalysis', 'line', ...
    'CharacterSet', caracteresPermitidos);

% Normaliza os textos reconhecidos.
textoOriginal = upper(regexprep( ...
    string(resultadoOriginal.Text), ...
    '[^A-Za-z0-9]', ''));

textoCorrigido = upper(regexprep( ...
    string(resultadoCorrigido.Text), ...
    '[^A-Za-z0-9]', ''));


%% 11. Comparacao dos resultados OCR

fprintf('\n========================================\n');
fprintf(' COMPARACAO DO OCR\n');
fprintf('========================================\n');

fprintf('Ground Truth: %s\n', textoVerdadeiro);

fprintf('OCR original: %s\n', textoOriginal);

fprintf('OCR Black Top-hat: %s\n', textoCorrigido);

if strlength(textoVerdadeiro) > 0

    originalCorreto = textoOriginal == textoVerdadeiro;

    corrigidoCorreto = textoCorrigido == textoVerdadeiro;

    fprintf('\nOriginal correto: %d\n', originalCorreto);
    fprintf('Black Top-hat correto: %d\n', corrigidoCorreto);

end


%% 12. Resultado final

fprintf('\n========================================\n');
fprintf(' TESTE CONCLUIDO\n');
fprintf('========================================\n');

fprintf('Imagem analisada: %s\n', nomeImagem);
fprintf('Operador: Black Top-hat\n');
fprintf('Elemento: square %d x %d\n', ...
    tamanhoQuadrado, tamanhoQuadrado);

fprintf('Validacao matematica: APROVADA\n');

fprintf(['As imagens foram exibidas para ', ...
    'inspecao visual.\n']);

fprintf('Nenhum resultado oficial foi alterado.\n');
