function resultados = testOcrConfigurations(raizProjeto, imageID, tamanhoQuadrado)
% TESTOCRCONFIGURATIONS Compara configuracoes OCR em uma placa selecionada.
%
% Experimentos: original e Black Top-hat, com layouts diferentes,
% ROI central e binarizacao. Nao altera arquivos dos experimentos e1/e2.
%
% Uso (na pasta raiz do projeto):
%   resultados = testOcrConfigurations(pwd, 50, 43);
%
% Parametros opcionais:
%   raizProjeto    - pasta principal do projeto
%   imageID        - identificador da placa (padrao: 50)
%   tamanhoQuadrado - lado impar do elemento square (padrao: 43)
%
% Resultado:
%   tabela ordenada por CER crescente; resultados sao exploratorios.

    %% 1. Parametros e caminhos
    if nargin < 1 || isempty(raizProjeto)
        raizProjeto = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end
    if nargin < 2 || isempty(imageID)
        imageID = 50;
    end
    if nargin < 3 || isempty(tamanhoQuadrado)
        tamanhoQuadrado = 43;
    end

    validateattributes(imageID, {'numeric'}, ...
        {'scalar', 'integer', 'nonnegative'});
    validateattributes(tamanhoQuadrado, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'odd'});

    arquivoSelecao = fullfile(raizProjeto, 'data', 'selected', ...
        'selected_images.csv');
    arquivoGT = fullfile(raizProjeto, 'data', 'ground_truth', ...
        'ground_truth.csv');
    diretorioPlacas = fullfile(raizProjeto, 'data', 'selected', 'plates');

    assert(isfile(arquivoSelecao), 'Arquivo de selecao nao encontrado.');
    assert(isfile(arquivoGT), 'Ground Truth nao encontrado.');

    selecao = readtable(arquivoSelecao, 'TextType', 'string');
    gt = readtable(arquivoGT, 'TextType', 'string');

    indiceSelecao = find(selecao.image_id == imageID);
    indiceGT = find(gt.image_id == imageID);

    assert(numel(indiceSelecao) == 1, ...
        'O identificador nao corresponde a uma unica placa selecionada.');
    assert(numel(indiceGT) == 1, ...
        'Ground Truth do identificador ausente ou duplicado.');

    nomeArquivo = string(selecao.file_name(indiceSelecao));
    assert(gt.file_name(indiceGT) == nomeArquivo, ...
        'Nome da imagem diferente no Ground Truth.');
    assert(gt.status(indiceGT) == "verified", ...
        'Ground Truth ainda nao verificado.');

    textoVerdadeiro = normalizarTexto(gt.plate_text(indiceGT));
    assert(strlength(textoVerdadeiro) > 0, ...
        'Ground Truth sem caracteres validos.');

    caminhoImagem = fullfile(diretorioPlacas, char(nomeArquivo));
    assert(isfile(caminhoImagem), 'Imagem selecionada nao encontrada.');

    %% 2. Preparacao das imagens
    imagemOriginal = imread(caminhoImagem);
    if size(imagemOriginal, 3) == 3
        imagemCinza = rgb2gray(imagemOriginal);
    else
        imagemCinza = imagemOriginal;
    end

    elemento = strel('square', tamanhoQuadrado);
    imagemTopHat = imcomplement(imbothat(imagemCinza, elemento));

    [altura, largura] = size(imagemCinza);

    % ROI heuristica relativa: ajustar somente apos inspecao visual.
    % Retira parte da moldura e inscricoes superiores.
    x1 = max(1, floor(0.05 * largura) + 1);
    x2 = min(largura, ceil(0.95 * largura));
    y1 = max(1, floor(0.25 * altura) + 1);
    y2 = min(altura, ceil(0.90 * altura));

    assert(x2 >= x1 && y2 >= y1, 'ROI invalida.');

    roiOriginal = imagemCinza(y1:y2, x1:x2);
    roiTopHat = imagemTopHat(y1:y2, x1:x2);

    % O MATLAB realiza limiarizacao automatica em imagens em cinza.
    % A binarizacao explicita abaixo e um teste independente.
    imagemBinariaOriginal = imbinarize(roiOriginal);
    imagemBinariaTopHat = imbinarize(roiTopHat);

    %% 3. Visualizacao
    figure('Name', sprintf('Teste OCR - %s', char(nomeArquivo)));
    subplot(2, 3, 1); imshow(imagemCinza); title('Original');
    subplot(2, 3, 2); imshow(roiOriginal); title('Original + ROI');
    subplot(2, 3, 3); imshow(imagemBinariaOriginal); title('Original + ROI + binaria');
    subplot(2, 3, 4); imshow(imagemTopHat); title('Top-hat + complemento');
    subplot(2, 3, 5); imshow(roiTopHat); title('Top-hat + ROI');
    subplot(2, 3, 6); imshow(imagemBinariaTopHat); title('Top-hat + ROI + binaria');

    %% 4. Combinacoes experimentais
    imagens = {imagemCinza, roiOriginal, imagemBinariaOriginal, ...
              imagemTopHat, roiTopHat, imagemBinariaTopHat};
    sistemas = ["e1"; "e1"; "e1"; "e2"; "e2"; "e2"];
    tratamentos = ["Completa"; "ROI"; "ROI+Binarizacao"; ...
                   "Completa"; "ROI"; "ROI+Binarizacao"];
    layouts = ["line", "word", "block", "none"];
    caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    n = numel(imagens) * numel(layouts);
    sistema = strings(n, 1);
    tratamento = strings(n, 1);
    layout = strings(n, 1);
    reconhecido = strings(n, 1);
    CER = nan(n, 1);
    placaCorreta = false(n, 1);
    erroOCR = strings(n, 1);

    %% 5. Execucao padronizada do OCR
    linha = 0;
    for i = 1:numel(imagens)
        for j = 1:numel(layouts)
            linha = linha + 1;
            sistema(linha) = sistemas(i);
            tratamento(linha) = tratamentos(i);
            layout(linha) = layouts(j);

            try
                resposta = ocr(imagens{i}, ...
                    'LayoutAnalysis', char(layouts(j)), ...
                    'CharacterSet', caracteres);
                reconhecido(linha) = normalizarTexto(resposta.Text);
                CER(linha) = 100 * distanciaLevenshtein( ...
                    char(textoVerdadeiro), char(reconhecido(linha))) ...
                    / strlength(textoVerdadeiro);
                placaCorreta(linha) = ...
                    reconhecido(linha) == textoVerdadeiro;
            catch erro
                erroOCR(linha) = string(erro.message);
            end
        end
    end

    %% 6. Resultados
    resultados = table(sistema, tratamento, layout, reconhecido, ...
        CER, placaCorreta, erroOCR);
    resultados = sortrows(resultados, 'CER', 'ascend');

    fprintf('\n========================================\n');
    fprintf(' COMPARACAO EXPLORATORIA DO OCR\n');
    fprintf('========================================\n');
    fprintf('Imagem: %s (ID: %d)\n', char(nomeArquivo), imageID);
    fprintf('Resolucao: %d x %d pixels\n', largura, altura);
    fprintf('Ground Truth: %s\n', char(textoVerdadeiro));
    fprintf('Top-hat: square %d x %d\n', ...
        tamanhoQuadrado, tamanhoQuadrado);
    fprintf('ROI: x=%d:%d, y=%d:%d\n', x1, x2, y1, y2);
    fprintf('Total de configuracoes: %d\n\n', n);
    disp(resultados);
    fprintf(['\nCER menor e melhor. Uma boa resposta em uma placa ', ...
        'nao comprova melhoria no conjunto.\n']);
    fprintf('Nenhum arquivo de e1, e2 ou de resultados foi modificado.\n');
end

function texto = normalizarTexto(textoBruto)
    texto = upper(regexprep(string(textoBruto), '[^A-Za-z0-9]', ''));
end

function distancia = distanciaLevenshtein(a, b)
    % Distancia de edicao: insercoes, exclusoes e substituicoes.
    n = length(a);
    m = length(b);
    matriz = zeros(n + 1, m + 1);
    matriz(:, 1) = (0:n)';
    matriz(1, :) = 0:m;

    for i = 2:n + 1
        for j = 2:m + 1
            custo = double(a(i - 1) ~= b(j - 1));
            matriz(i, j) = min([ ...
                matriz(i - 1, j) + 1, ...
                matriz(i, j - 1) + 1, ...
                matriz(i - 1, j - 1) + custo]);
        end
    end
    distancia = matriz(n + 1, m + 1);
end
