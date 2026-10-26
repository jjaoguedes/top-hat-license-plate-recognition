
function [resultados, resumo, comparacao] = testAllPlateROIs(raizProjeto, executarOCR, tamanhoQuadrado)
% TESTALLPLATEROIS Inspeciona as 40 placas e compara OCR com/sem ROI.
%
% Quatro cenarios com a MESMA configuracao de OCR:
%   e1_sem_roi: original -> OCR
%   e1_com_roi: original -> ROI -> OCR
%   e2_sem_roi: Top-hat -> OCR
%   e2_com_roi: Top-hat -> ROI -> OCR
%
% Uso:
%   raizProjeto = fileparts(which('main.m'));
%   [resultados, resumo, comparacao] = testAllPlateROIs(raizProjeto, true, 51);
%   [resultados, resumo, comparacao] = testAllPlateROIs(raizProjeto, false, 51);
%
% Observacoes:
%   - O Top-hat e Black Top-hat com SE square, seguido de complemento.
%   - A ROI e calculada por extractPlateROI.m (mesma regra em e1/e2).
%   - Nao modifica imagens ou CSVs oficiais de e1/e2.
%   - Salva tabelas e figuras apenas em results/analysis/roi_... .
%   - Resultados exploratorios: CER media por placa e CER global sao
%     grandezas diferentes.

    if nargin < 1 || isempty(raizProjeto)
        raizProjeto = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end

    if nargin < 2 || isempty(executarOCR)
        executarOCR = true;
    end

    if nargin < 3 || isempty(tamanhoQuadrado)
        tamanhoQuadrado = 51;
    end

    validateattributes(executarOCR, {'numeric','logical'}, {'scalar'});
    executarOCR = logical(executarOCR);

    validateattributes(tamanhoQuadrado, {'numeric'}, ...
        {'scalar','integer','positive','odd'});

    addpath(fullfile(raizProjeto, 'src', 'utils'));

    pastaPlacas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');

    arquivoGT = fullfile(raizProjeto, ...
        'data', 'ground_truth', 'ground_truth.csv');

    assert(isfolder(pastaPlacas), ...
        'Pasta das placas nao encontrada.');

    assert(isfile(arquivoSelecao), ...
        'selected_images.csv nao encontrado.');

    selecao = sortrows( ...
        readtable(arquivoSelecao, 'TextType','string'), ...
        'image_id');

    total = height(selecao);

    assert(total > 0, 'Nao ha placas selecionadas.');

    %% 1. Carregamento do Ground Truth

    if executarOCR

        assert(isfile(arquivoGT), ...
            'ground_truth.csv nao encontrado.');

        gt = readtable(arquivoGT, 'TextType','string');

        [encontrado, posicaoGT] = ismember( ...
            selecao.image_id, gt.image_id);

        assert(all(encontrado) && ...
            numel(unique(gt.image_id)) == height(gt), ...
            'Ground Truth ausente ou com IDs duplicados.');

        assert(all(string(gt.file_name(posicaoGT)) == ...
            string(selecao.file_name)), ...
            'Arquivos selecionados nao correspondem ao Ground Truth.');

        assert(all(string(gt.status(posicaoGT)) == "verified"), ...
            'O Ground Truth contem anotacoes nao verificadas.');

        verdadeiro = normalizarTexto( ...
            gt.plate_text(posicaoGT));

        assert(all(strlength(verdadeiro) > 0 & ...
            ~ismissing(verdadeiro)), ...
            'O Ground Truth contem placas vazias.');

    else

        verdadeiro = strings(total, 1);

    end

    %% 2. Preparacao das variaveis

    cenarios = [ ...
        "e1_sem_roi";
        "e1_com_roi";
        "e2_sem_roi";
        "e2_com_roi"];

    textos = strings(total, 4);
    erros = strings(total, 4);

    distancia = nan(total, 4);
    cer = nan(total, 4);
    correta = false(total, 4);

    largura = zeros(total,1);
    altura = zeros(total,1);

    larguraROI = zeros(total,1);
    alturaROI = zeros(total,1);

    xInicial = zeros(total,1);
    xFinal = zeros(total,1);
    yInicial = zeros(total,1);
    yFinal = zeros(total,1);

    imagensE1 = cell(total,1);
    imagensE2 = cell(total,1);

    imagensROIe1 = cell(total,1);
    imagensROIe2 = cell(total,1);

    %% 3. Configuracao dos experimentos

    elemento = strel('square', tamanhoQuadrado);

    caracteres = ...
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    fprintf('\n========================================\n');
    fprintf(' INSPECAO COMPLETA COM E SEM ROI\n');
    fprintf('========================================\n');

    fprintf('Placas: %d | OCR: %d | Top-hat: square %d x %d\n', ...
        total, executarOCR, tamanhoQuadrado, tamanhoQuadrado);

    %% 4. Processamento de todas as placas

    for i = 1:total

        arquivo = fullfile( ...
            pastaPlacas, char(selecao.file_name(i)));

        assert(isfile(arquivo), ...
            'Placa nao encontrada: %s', arquivo);

        original = imread(arquivo);

        % Conversao para escala de cinza.
        if size(original,3) == 3
            cinza = rgb2gray(original);
        else
            cinza = original;
        end

        % Sistema e2: Black Top-hat + complemento.
        processada = imcomplement( ...
            imbothat(cinza, elemento));

        % Extracao da ROI em ambos os sistemas.
        [roiOriginal, c] = extractPlateROI(cinza);

        [roiProcessada, c2] = extractPlateROI(processada);

        % Confirma que a mesma regra de ROI foi aplicada.
        assert(isequal(c, c2), ...
            'ROI diferente entre sistemas no ID %d.', ...
            selecao.image_id(i));

        % Dimensoes da placa original.
        [altura(i), largura(i)] = size(cinza);

        % Dimensoes da ROI.
        [alturaROI(i), larguraROI(i)] = size(roiOriginal);

        % Coordenadas.
        xInicial(i) = c.xInicial;
        xFinal(i) = c.xFinal;
        yInicial(i) = c.yInicial;
        yFinal(i) = c.yFinal;

        % Imagens para a inspecao visual.
        imagensE1{i} = cinza;
        imagensE2{i} = processada;

        imagensROIe1{i} = roiOriginal;
        imagensROIe2{i} = roiProcessada;

        %% 4.1. Execucao do OCR

        if executarOCR

            entradas = { ...
                cinza, ...
                roiOriginal, ...
                processada, ...
                roiProcessada};

            for k = 1:4

                try

                    resposta = ocr(entradas{k}, ...
                        'LayoutAnalysis','line', ...
                        'CharacterSet', caracteres);

                    textos(i,k) = normalizarTexto( ...
                        resposta.Text);

                    distancia(i,k) = distanciaEdicao( ...
                        verdadeiro(i), textos(i,k));

                    cer(i,k) = 100 * distancia(i,k) / ...
                        strlength(verdadeiro(i));

                    correta(i,k) = ...
                        textos(i,k) == verdadeiro(i);

                catch excecao

                    erros(i,k) = string(excecao.message);

                    % Falhas tecnicas nao sao tratadas como
                    % texto vazio. A CER permanece NaN.

                end

            end

            fprintf(['%2d/%2d | ID %3d | GT %-10s | ', ...
                'e1: %-9s -> %-9s | e2: %-9s -> %-9s\n'], ...
                i, total, selecao.image_id(i), ...
                char(verdadeiro(i)), ...
                char(textos(i,1)), char(textos(i,2)), ...
                char(textos(i,3)), char(textos(i,4)));

        else

            fprintf('%2d/%2d | ID %3d | %d x %d | ROI %d x %d\n', ...
                i, total, selecao.image_id(i), ...
                largura(i), altura(i), ...
                larguraROI(i), alturaROI(i));

        end

    end

    %% 5. Tabela de dimensoes e coordenadas

    resultados = table( ...
        selecao.image_id, ...
        selecao.file_name, ...
        largura, ...
        altura, ...
        xInicial, ...
        xFinal, ...
        yInicial, ...
        yFinal, ...
        larguraROI, ...
        alturaROI, ...
        'VariableNames', { ...
        'image_id', ...
        'file_name', ...
        'largura', ...
        'altura', ...
        'roi_x_inicial', ...
        'roi_x_final', ...
        'roi_y_inicial', ...
        'roi_y_final', ...
        'roi_largura', ...
        'roi_altura'});

    resumo = table();
    comparacao = table();
    detalhe = table();

    %% 6. Avaliacao individual dos resultados OCR

    if executarOCR

        resultados.ground_truth = verdadeiro;

        % Armazena o OCR, CER e acerto de cada cenario.
        for k = 1:4

            prefixo = char(cenarios(k));

            resultados.(['ocr_' prefixo]) = textos(:,k);

            resultados.(['cer_' prefixo]) = cer(:,k);

            resultados.(['correta_' prefixo]) = correta(:,k);

            resultados.(['erro_' prefixo]) = erros(:,k);

        end

        %% 6.1. Efeito da ROI e do Top-hat por placa

        resultados.roi_ajudou_e1 = ...
            ~correta(:,1) & correta(:,2);

        resultados.roi_prejudicou_e1 = ...
            correta(:,1) & ~correta(:,2);

        resultados.roi_ajudou_e2 = ...
            ~correta(:,3) & correta(:,4);

        resultados.roi_prejudicou_e2 = ...
            correta(:,3) & ~correta(:,4);

        resultados.top_hat_ajudou_sem_roi = ...
            ~correta(:,1) & correta(:,3);

        resultados.top_hat_prejudicou_sem_roi = ...
            correta(:,1) & ~correta(:,3);

        resultados.top_hat_ajudou_com_roi = ...
            ~correta(:,2) & correta(:,4);

        resultados.top_hat_prejudicou_com_roi = ...
            correta(:,2) & ~correta(:,4);

        %% 6.2. Metricas por cenario

        acertos = zeros(4,1);
        acuracias = zeros(4,1);

        mediaCER = nan(4,1);
        cerGlobal = nan(4,1);

        falhasOCR = zeros(4,1);

        for k = 1:4

            acertos(k) = sum(correta(:,k));

            acuracias(k) = ...
                100 * acertos(k) / total;

            falhasOCR(k) = ...
                sum(strlength(erros(:,k)) > 0);

            validos = ~isnan(cer(:,k));

            if any(validos)

                % Media das CERs individuais.
                mediaCER(k) = mean(cer(validos,k));

                % CER global: total de erros dividido
                % pelo total de caracteres de referencia.
                cerGlobal(k) = ...
                    100 * sum(distancia(validos,k)) / ...
                    sum(strlength(verdadeiro(validos)));

            end

        end

        resumo = table( ...
            cenarios, ...
            repmat(total,4,1), ...
            falhasOCR, ...
            acertos, ...
            acuracias, ...
            mediaCER, ...
            cerGlobal, ...
            'VariableNames', { ...
            'cenario', ...
            'placas', ...
            'falhas_ocr', ...
            'placas_corretas', ...
            'acuracia_percent', ...
            'cer_media_placa_percent', ...
            'cer_global_percent'});

        %% 6.3. Comparacoes de ganhos e perdas

        pares = [ ...
            1 2;
            3 4;
            1 3;
            2 4];

        descricoes = [ ...
            "Efeito ROI no e1";
            "Efeito ROI no e2";
            "Efeito Top-hat sem ROI";
            "Efeito Top-hat com ROI"];

        ganhos = zeros(4,1);
        perdas = zeros(4,1);

        mantidas = zeros(4,1);
        sempreErradas = zeros(4,1);

        for k = 1:4

            antes = correta(:,pares(k,1));
            depois = correta(:,pares(k,2));

            ganhos(k) = sum(~antes & depois);

            perdas(k) = sum(antes & ~depois);

            mantidas(k) = sum(antes & depois);

            sempreErradas(k) = sum(~antes & ~depois);

        end

        comparacao = table( ...
            descricoes, ...
            cenarios(pares(:,1)), ...
            cenarios(pares(:,2)), ...
            ganhos, ...
            perdas, ...
            mantidas, ...
            sempreErradas, ...
            'VariableNames', { ...
            'comparacao', ...
            'antes', ...
            'depois', ...
            'passaram_a_acertar', ...
            'deixaram_de_acertar', ...
            'corretas_em_ambos', ...
            'incorretas_em_ambos'});

        %% 6.4. Tabela detalhada por placa e cenario

        % Formato longo: quatro linhas por placa.
        id = repelem(selecao.image_id,4);

        arquivo = repelem( ...
            string(selecao.file_name),4);

        g = repelem(verdadeiro,4);

        cen = repmat(cenarios,total,1);

        detalhe = table( ...
            id, ...
            arquivo, ...
            cen, ...
            g, ...
            reshape(textos.',[],1), ...
            reshape(cer.',[],1), ...
            reshape(correta.',[],1), ...
            reshape(erros.',[],1), ...
            'VariableNames', { ...
            'image_id', ...
            'file_name', ...
            'cenario', ...
            'ground_truth', ...
            'reconhecido', ...
            'cer_percent', ...
            'placa_correta', ...
            'erro_ocr'});

        %% 6.5. Exibicao do resumo

        fprintf('\n========================================\n');
        fprintf(' RESUMO DOS QUATRO CENARIOS\n');
        fprintf('========================================\n');

        disp(resumo);

        fprintf('\n========================================\n');
        fprintf(' GANHOS E PERDAS INDIVIDUAIS\n');
        fprintf('========================================\n');

        disp(comparacao);

        %% 6.6. Identificacao das placas corretas

        fprintf('\nPLACAS CORRETAS POR CENARIO (IDs):\n');

        for k = 1:4

            fprintf('%s: %s\n', ...
                char(cenarios(k)), ...
                mat2str(selecao.image_id(correta(:,k))'));

        end

        %% 6.7. Placas beneficiadas ou prejudicadas

        fprintf('\nTop-hat com ROI: ganhos (IDs): %s\n', ...
            mat2str(selecao.image_id( ...
            resultados.top_hat_ajudou_com_roi)'));

        fprintf('Top-hat com ROI: perdas (IDs): %s\n', ...
            mat2str(selecao.image_id( ...
            resultados.top_hat_prejudicou_com_roi)'));

        fprintf(['\nObservacao: CER e acuracia ignoram ', ...
            'falhas tecnicas de OCR na CER;\n']);

        fprintf(['confira a coluna falhas_ocr ', ...
            'antes de comparar metricas.\n']);

    end

    %% 7. Criacao do diretorio de resultados

    raizSaida = fullfile(raizProjeto, ...
        'results', 'analysis');

    if ~isfolder(raizSaida)
        mkdir(raizSaida);
    end

    % Cada execucao gera uma pasta exclusiva.
    instante = datestr(now,'yyyymmdd_HHMMSS');

    prefixo = sprintf( ...
        'roi_square_%d_%s', tamanhoQuadrado, instante);

    pastaSaida = fullfile(raizSaida, prefixo);

    contador = 1;

    while isfolder(pastaSaida)

        pastaSaida = fullfile(raizSaida, ...
            sprintf('%s_%d', prefixo, contador));

        contador = contador + 1;

    end

    mkdir(pastaSaida);

    %% 8. Salvamento das tabelas

    writetable(resultados, ...
        fullfile(pastaSaida, 'inspecao_por_placa.csv'));

    if executarOCR

        writetable(resumo, ...
            fullfile(pastaSaida, 'resumo_4_cenarios.csv'));

        writetable(comparacao, ...
            fullfile(pastaSaida, 'ganhos_e_perdas.csv'));

        writetable(detalhe, ...
            fullfile(pastaSaida, 'ocr_detalhado.csv'));

    end

    %% 9. Inspecao visual de todas as placas

    % Cada figura apresenta quatro placas.
    % Cada placa possui quatro representacoes:
    %
    % 1. e1 sem ROI
    % 2. e1 com ROI
    % 3. e2 sem ROI
    % 4. e2 com ROI

    placasPorPagina = 4;

    paginas = ceil(total/placasPorPagina);

    for p = 1:paginas

        figura = figure( ...
            'Name', sprintf('Inspecao ROI - pagina %d/%d', ...
            p, paginas), ...
            'NumberTitle', 'off', ...
            'Visible', 'off');

        inicio = (p-1)*placasPorPagina+1;

        fim = min(p*placasPorPagina,total);

        for i = inicio:fim

            linha = i-inicio;

            entradas = { ...
                imagensE1{i}, ...
                imagensROIe1{i}, ...
                imagensE2{i}, ...
                imagensROIe2{i}};

            titulos = { ...
                'e1 sem ROI', ...
                'e1 com ROI', ...
                'e2 sem ROI', ...
                'e2 com ROI'};

            for k = 1:4

                subplot(placasPorPagina,4,linha*4+k);

                imshow(entradas{k});

                % Exibe o contorno da ROI sobre
                % as imagens completas.
                if k == 1 || k == 3

                    hold on;

                    rectangle('Position', [ ...
                        xInicial(i), ...
                        yInicial(i), ...
                        xFinal(i)-xInicial(i)+1, ...
                        yFinal(i)-yInicial(i)+1], ...
                        'EdgeColor','g', ...
                        'LineWidth',1);

                    hold off;

                end

                if executarOCR

                    marca = 'ERRO';

                    if correta(i,k)
                        marca = 'OK';
                    end

                    title(sprintf('ID %d %s | %s | %s', ...
                        selecao.image_id(i), ...
                        titulos{k}, ...
                        char(textos(i,k)), ...
                        marca), ...
                        'FontSize',8, ...
                        'Interpreter','none');

                else

                    title(sprintf('ID %d - %s', ...
                        selecao.image_id(i), ...
                        titulos{k}), ...
                        'FontSize',8, ...
                        'Interpreter','none');

                end

            end

        end

        set(figura, 'Position', [50 50 1250 850]);

        % Salva a figura de inspecao.
        exportgraphics(figura, ...
            fullfile(pastaSaida, ...
            sprintf('inspecao_pagina_%02d.png',p)), ...
            'Resolution',150);

        % Exibe a figura ao usuario.
        set(figura,'Visible','on');

    end

    %% 10. Finalizacao

    fprintf('\nRelatorios exploratorios e figuras salvos em:\n%s\n', ...
        pastaSaida);

    fprintf('Nenhum CSV oficial de e1/e2 foi alterado.\n');

end


%% Funcao auxiliar - Normalizacao do texto

function texto = normalizarTexto(valor)

    texto = upper(regexprep( ...
        string(valor), '[^A-Za-z0-9]', ''));

end


%% Funcao auxiliar - Distancia de Levenshtein

function distancia = distanciaEdicao(a,b)

    a = char(a);
    b = char(b);

    n = numel(a);
    m = numel(b);

    matriz = zeros(n+1,m+1);

    matriz(:,1) = (0:n)';
    matriz(1,:) = 0:m;

    for i = 2:n+1

        for j = 2:m+1

            custo = double(a(i-1) ~= b(j-1));

            matriz(i,j) = min([ ...
                matriz(i-1,j)+1, ...
                matriz(i,j-1)+1, ...
                matriz(i-1,j-1)+custo]);

        end

    end

    distancia = matriz(end,end);

end
