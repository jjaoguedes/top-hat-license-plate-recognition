function relatorio = generateROIResultsReport(raizProjeto, pastaResultadosROI)
% GENERATEROIRESULTSREPORT Gera um relatorio isolado dos cenarios com ROI.
%
% Uso:
%   testAllPlateROIs(raizProjeto, true, 51);
%   relatorio = generateROIResultsReport(raizProjeto);
%
% Para escolher uma execucao especifica:
%   relatorio = generateROIResultsReport(raizProjeto, ...
%       'results/analysis/roi_square_51_yyyymmdd_HHMMSS');
%
% Utiliza e1_com_roi e e2_com_roi de ocr_detalhado.csv, gerado por
% testAllPlateROIs. O fluxo aplica extractPlateROI antes do OCR. Relatorios
% e figuras ficam em pastas roi_comparacao_* separadas dos resultados de
% generateResultsReport.

    if nargin < 1 || isempty(raizProjeto)
        raizProjeto = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end
    assert(isfolder(raizProjeto), 'Raiz do projeto não encontrada.');

    if nargin < 2 || isempty(pastaResultadosROI)
        pastaResultadosROI = localizarResultadosROI(raizProjeto);
    else
        pastaResultadosROI = char(string(pastaResultadosROI));
        if ~isfolder(pastaResultadosROI)
            pastaResultadosROI = fullfile(raizProjeto, pastaResultadosROI);
        end
    end
    assert(isfolder(pastaResultadosROI), ...
        'Pasta de resultados ROI não encontrada: %s', pastaResultadosROI);

    arquivoDetalhado = fullfile(pastaResultadosROI, 'ocr_detalhado.csv');
    arquivoResumo = fullfile(pastaResultadosROI, 'resumo_4_cenarios.csv');
    assert(isfile(arquivoDetalhado) && isfile(arquivoResumo), ...
        ['A pasta selecionada não contém os resultados OCR do ', ...
        'testAllPlateROIs. Execute testAllPlateROIs(raizProjeto, true, tamanho).']);

    detalheFonte = readtable(arquivoDetalhado, 'TextType', 'string');
    resumoFonte = readtable(arquivoResumo, 'TextType', 'string');
    exigirColunas(detalheFonte, {'image_id','file_name','cenario', ...
        'ground_truth','reconhecido','cer_percent','placa_correta', ...
        'erro_ocr'}, 'OCR detalhado de testAllPlateROIs');
    exigirColunas(resumoFonte, {'cenario','placas','falhas_ocr', ...
        'placas_corretas','acuracia_percent', ...
        'cer_media_placa_percent','cer_global_percent'}, ...
        'Resumo de testAllPlateROIs');

    %% 1. Seleciona os dois sistemas com a ROI aplicada antes do OCR
    nomesCenarios = ["e1_com_roi"; "e2_com_roi"];
    resultadosSistema = cell(2, 1);
    resumo = table('Size', [2 8], ...
        'VariableTypes', {'string','double','double','double', ...
        'double','double','double','double'}, ...
        'VariableNames', {'sistema','placas_avaliadas','falhas_ocr', ...
        'placas_corretas','placas_incorretas','acuracia_percent', ...
        'cer_global_percent','cer_media_por_placa_percent'});

    for k = 1:2
        selecao = detalheFonte(string(detalheFonte.cenario) == ...
            nomesCenarios(k), :);
        assert(~isempty(selecao), ...
            'Cenário %s não encontrado nos resultados ROI.', nomesCenarios(k));
        selecao = sortrows(selecao, 'image_id');
        assert(numel(unique(selecao.image_id)) == height(selecao), ...
            'Há IDs duplicados no cenário %s.', nomesCenarios(k));

        verdade = normalizar(selecao.ground_truth);
        reconhecido = normalizar(selecao.reconhecido);
        falha = ~ismissing(selecao.erro_ocr) & ...
            strlength(string(selecao.erro_ocr)) > 0;
        acerto = ~falha & verdade == reconhecido;
        acertoFonte = logical(selecao.placa_correta);
        assert(isequal(acerto, acertoFonte), ...
            'Indicadores de acerto inconsistentes no cenário %s.', ...
            nomesCenarios(k));
        assert(all(strlength(verdade) > 0 & ~ismissing(verdade)), ...
            'Ground Truth vazio no cenário %s.', nomesCenarios(k));

        distancias = nan(height(selecao), 1);
        cerPlaca = nan(height(selecao), 1);
        for i = 1:height(selecao)
            if ~falha(i)
                distancias(i) = levenshtein(verdade(i), reconhecido(i));
                cerPlaca(i) = 100 * distancias(i) / strlength(verdade(i));
            end
        end

        if k == 1
            resultadosSistema{1} = table(selecao.image_id, ...
                string(selecao.file_name), verdade, reconhecido, ...
                distancias, cerPlaca, acerto, falha, ...
                string(selecao.erro_ocr), ...
                'VariableNames', {'image_id','file_name','ground_truth', ...
                'ocr_e1_roi','erros_e1_roi','cer_e1_roi_percent', ...
                'correta_e1_roi','falha_e1_roi','erro_e1_roi'});
        else
            resultadosSistema{2} = table(selecao.image_id, ...
                string(selecao.file_name), verdade, reconhecido, ...
                distancias, cerPlaca, acerto, falha, ...
                string(selecao.erro_ocr), ...
                'VariableNames', {'image_id','file_name','ground_truth', ...
                'ocr_e2_roi','erros_e2_roi','cer_e2_roi_percent', ...
                'correta_e2_roi','falha_e2_roi','erro_e2_roi'});
        end

        total = height(selecao);
        quantidadeFalhas = sum(falha);
        quantidadeCorretas = sum(acerto);
        cerValidas = ~falha;
        assert(any(cerValidas), ...
            'Não há resultados OCR válidos no cenário %s.', nomesCenarios(k));
        cerGlobal = 100 * sum(distancias(cerValidas)) / ...
            sum(strlength(verdade(cerValidas)));
        cerMedia = mean(cerPlaca(cerValidas));

        linhaResumo = resumoFonte(string(resumoFonte.cenario) == ...
            nomesCenarios(k), :);
        assert(height(linhaResumo) == 1, ...
            'Resumo ausente ou duplicado para %s.', nomesCenarios(k));
        validarResumo(linhaResumo, total, quantidadeFalhas, ...
            quantidadeCorretas, cerGlobal, cerMedia, nomesCenarios(k));

        resumo.sistema(k) = rotuloSistema(k);
        resumo.placas_avaliadas(k) = total;
        resumo.falhas_ocr(k) = quantidadeFalhas;
        resumo.placas_corretas(k) = quantidadeCorretas;
        resumo.placas_incorretas(k) = total - quantidadeCorretas;
        resumo.acuracia_percent(k) = 100 * quantidadeCorretas / total;
        resumo.cer_global_percent(k) = cerGlobal;
        resumo.cer_media_por_placa_percent(k) = cerMedia;
    end

    e1 = resultadosSistema{1};
    e2 = resultadosSistema{2};
    assert(isequal(e1.image_id, e2.image_id) && ...
        isequal(e1.file_name, e2.file_name) && ...
        isequal(e1.ground_truth, e2.ground_truth), ...
        'Os resultados ROI dos dois sistemas não correspondem por imagem.');

    deltaCER = e2.cer_e2_roi_percent - e1.cer_e1_roi_percent;
    situacaoCER = strings(height(e1), 1);
    ambosValidos = ~e1.falha_e1_roi & ~e2.falha_e2_roi;
    situacaoCER(ambosValidos & deltaCER < 0) = "melhorou_CER";
    situacaoCER(ambosValidos & deltaCER > 0) = "piorou_CER";
    situacaoCER(ambosValidos & deltaCER == 0) = "igual_CER";
    situacaoCER(~ambosValidos) = "falha_ocr";

    situacaoAcerto = strings(height(e1), 1);
    situacaoAcerto(~e1.correta_e1_roi & e2.correta_e2_roi) = ...
        "passou_a_acertar";
    situacaoAcerto(e1.correta_e1_roi & ~e2.correta_e2_roi) = ...
        "deixou_de_acertar";
    situacaoAcerto(e1.correta_e1_roi & e2.correta_e2_roi) = ...
        "correta_nos_dois";
    situacaoAcerto(~e1.correta_e1_roi & ~e2.correta_e2_roi) = ...
        "incorreta_nos_dois";

    comparacao = table(e1.image_id, e1.file_name, e1.ground_truth, ...
        e1.ocr_e1_roi, e2.ocr_e2_roi, e1.cer_e1_roi_percent, ...
        e2.cer_e2_roi_percent, deltaCER, e1.correta_e1_roi, ...
        e2.correta_e2_roi, e1.falha_e1_roi, e2.falha_e2_roi, ...
        e1.erro_e1_roi, e2.erro_e2_roi, situacaoCER, situacaoAcerto, ...
        'VariableNames', {'image_id','file_name','ground_truth', ...
        'ocr_e1_roi','ocr_e2_roi','cer_e1_roi_percent', ...
        'cer_e2_roi_percent','diferenca_cer_percent', ...
        'correta_e1_roi','correta_e2_roi','falha_e1_roi', ...
        'falha_e2_roi','erro_e1_roi','erro_e2_roi', ...
        'situacao_cer','situacao_acerto'});

    placasCorretas = comparacao(comparacao.correta_e1_roi | ...
        comparacao.correta_e2_roi, :);
    placasIncorretas = comparacao(~comparacao.correta_e1_roi & ...
        ~comparacao.correta_e2_roi, :);
    ganhosPerdas = comparacao( ...
        comparacao.situacao_acerto == "passou_a_acertar" | ...
        comparacao.situacao_acerto == "deixou_de_acertar" | ...
        comparacao.situacao_cer == "melhorou_CER" | ...
        comparacao.situacao_cer == "piorou_CER", :);

    %% 2. Saída exclusiva, separada do relatório sem ROI
    diretorioRelatorios = fullfile(raizProjeto, 'results', 'reports');
    diretorioFiguras = fullfile(raizProjeto, 'results', 'figures');
    if ~isfolder(diretorioRelatorios)
        mkdir(diretorioRelatorios);
    end
    if ~isfolder(diretorioFiguras)
        mkdir(diretorioFiguras);
    end

    etiqueta = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    nomePasta = ['roi_comparacao_' etiqueta];
    pastaSaida = fullfile(diretorioRelatorios, nomePasta);
    pastaFiguras = fullfile(diretorioFiguras, nomePasta);
    contador = 1;
    while isfolder(pastaSaida) || isfolder(pastaFiguras)
        nomePasta = sprintf('roi_comparacao_%s_%02d', etiqueta, contador);
        pastaSaida = fullfile(diretorioRelatorios, nomePasta);
        pastaFiguras = fullfile(diretorioFiguras, nomePasta);
        contador = contador + 1;
    end
    mkdir(pastaSaida);
    mkdir(pastaFiguras);

    writetable(comparacao, ...
        fullfile(pastaSaida, 'comparacao_por_placa_roi.csv'));
    writetable(resumo, fullfile(pastaSaida, 'resumo_roi.csv'));
    writetable(placasCorretas, ...
        fullfile(pastaSaida, 'placas_corretas_roi.csv'));
    writetable(placasIncorretas, ...
        fullfile(pastaSaida, 'placas_incorretas_roi.csv'));
    writetable(ganhosPerdas, ...
        fullfile(pastaSaida, 'ganhos_e_perdas_roi.csv'));

    arquivoTexto = fullfile(pastaSaida, 'relatorio_roi.txt');
    salvarRelatorioTexto(arquivoTexto, resumo, comparacao, ...
        pastaResultadosROI);

    sistemas = resumo.sistema;
    salvarGrafico(sistemas, resumo.acuracia_percent, ...
        'Acurácia exata com ROI por sistema', ...
        'Placas corretamente reconhecidas (%)', ...
        fullfile(pastaFiguras, 'comparacao_acuracia_roi.png'));
    salvarGrafico(sistemas, resumo.cer_global_percent, ...
        'CER global com ROI por sistema', ...
        'Taxa de erro de caracteres (%)', ...
        fullfile(pastaFiguras, 'comparacao_cer_roi.png'));
    figura = figure('Visible', 'off', 'Color', 'w');
    limpezaFigura = onCleanup(@() close(figura));
    categorias = categorical(["Melhorou CER";"Piorou CER"; ...
        "CER igual";"Falha OCR"]);
    quantidades = [sum(situacaoCER == "melhorou_CER"), ...
        sum(situacaoCER == "piorou_CER"), ...
        sum(situacaoCER == "igual_CER"), ...
        sum(situacaoCER == "falha_ocr")];
    bar(categorias, quantidades);
    ylabel('Quantidade de placas');
    title('Efeito do Top-hat com ROI por placa');
    grid on;
    exportgraphics(figura, ...
        fullfile(pastaFiguras, 'evolucao_por_placa_roi.png'), ...
        'Resolution', 150);
    clear limpezaFigura;

    relatorio = struct('comparacao', comparacao, ...
        'resumo', resumo, ...
        'placasCorretas', placasCorretas, ...
        'placasIncorretas', placasIncorretas, ...
        'ganhosPerdas', ganhosPerdas, ...
        'pastaResultadosROI', string(pastaResultadosROI), ...
        'pastaSaida', string(pastaSaida), ...
        'pastaFiguras', string(pastaFiguras), ...
        'arquivoTexto', string(arquivoTexto));

    fprintf('\n========================================\n');
    fprintf(' RELATÓRIO COM ROI - e1 x e2\n');
    fprintf('========================================\n');
    disp(resumo);
    fprintf('Placas que passaram a acertar: %d\n', ...
        sum(situacaoAcerto == "passou_a_acertar"));
    fprintf('Placas que deixaram de acertar: %d\n', ...
        sum(situacaoAcerto == "deixou_de_acertar"));
    fprintf('Resultados: %s\n', pastaSaida);
    fprintf('Gráficos: %s\n\n', pastaFiguras);
end

function pasta = localizarResultadosROI(raizProjeto)
    diretorioAnalise = fullfile(raizProjeto, 'results', 'analysis');
    assert(isfolder(diretorioAnalise), ...
        'Diretório results/analysis não encontrado.');
    candidatos = dir(fullfile(diretorioAnalise, 'roi_square_*'));
    candidatos = candidatos([candidatos.isdir]);
    [~, ordem] = sort([candidatos.datenum], 'descend');
    candidatos = candidatos(ordem);

    for i = 1:numel(candidatos)
        pastaCandidata = fullfile(candidatos(i).folder, candidatos(i).name);
        if isfile(fullfile(pastaCandidata, 'ocr_detalhado.csv')) && ...
                isfile(fullfile(pastaCandidata, 'resumo_4_cenarios.csv'))
            pasta = pastaCandidata;
            return;
        end
    end

    error(['Nenhum resultado OCR de testAllPlateROIs foi encontrado. ', ...
        'Execute testAllPlateROIs(raizProjeto, true, tamanho).']);
end

function exigirColunas(tabela, colunas, origem)
    assert(all(ismember(colunas, tabela.Properties.VariableNames)), ...
        'Colunas obrigatórias ausentes em %s.', origem);
end

function texto = normalizar(valor)
    texto = string(valor);
    texto(ismissing(texto)) = "";
    texto = upper(regexprep(texto, '[^A-Za-z0-9]', ''));
end

function distancia = levenshtein(a, b)
    a = char(a);
    b = char(b);
    n = numel(a);
    m = numel(b);
    matriz = zeros(n + 1, m + 1);
    matriz(:, 1) = (0:n)';
    matriz(1, :) = 0:m;
    for i = 2:n + 1
        for j = 2:m + 1
            custo = double(a(i - 1) ~= b(j - 1));
            matriz(i, j) = min([matriz(i - 1, j) + 1, ...
                matriz(i, j - 1) + 1, matriz(i - 1, j - 1) + custo]);
        end
    end
    distancia = matriz(end, end);
end

function validarResumo(linha, total, falhas, corretas, cerGlobal, cerMedia, cenario)
    assert(linha.placas(1) == total && ...
        linha.falhas_ocr(1) == falhas && ...
        linha.placas_corretas(1) == corretas && ...
        abs(linha.acuracia_percent(1) - 100 * corretas / total) < 1e-8 && ...
        abs(linha.cer_global_percent(1) - cerGlobal) < 1e-8 && ...
        abs(linha.cer_media_placa_percent(1) - cerMedia) < 1e-8, ...
        'O resumo de métricas não corresponde ao cenário %s.', cenario);
end

function rotulo = rotuloSistema(indice)
    if indice == 1
        rotulo = "e1 - Baseline com ROI";
    else
        rotulo = "e2 - Top-hat com ROI";
    end
end

function salvarGrafico(sistemas, valores, titulo, eixoY, arquivo)
    figura = figure('Visible', 'off', 'Color', 'w');
    limpezaFigura = onCleanup(@() close(figura));
    bar(categorical(sistemas), valores);
    ylabel(eixoY);
    title(titulo);
    grid on;
    exportgraphics(figura, arquivo, 'Resolution', 150);
    clear limpezaFigura;
end

function salvarRelatorioTexto(arquivo, resumo, comparacao, pastaFonte)
    identificador = fopen(arquivo, 'w', 'n', 'UTF-8');
    if identificador < 0
        error('Não foi possível criar o relatório: %s', arquivo);
    end
    limpezaArquivo = onCleanup(@() fclose(identificador));
    fprintf(identificador, 'RELATÓRIO DE RECONHECIMENTO DE PLACAS COM ROI\n');
    fprintf(identificador, 'Resultados de origem: %s\n\n', pastaFonte);
    fprintf(identificador, 'MÉTRICAS PRINCIPAIS\n');
    for i = 1:height(resumo)
        fprintf(identificador, '\n%s\n', char(resumo.sistema(i)));
        fprintf(identificador, 'Placas avaliadas: %d\n', ...
            resumo.placas_avaliadas(i));
        fprintf(identificador, 'Falhas OCR: %d\n', resumo.falhas_ocr(i));
        fprintf(identificador, 'Reconhecimentos corretos: %d\n', ...
            resumo.placas_corretas(i));
        fprintf(identificador, 'Reconhecimentos incorretos: %d\n', ...
            resumo.placas_incorretas(i));
        fprintf(identificador, 'Acurácia exata: %.2f%%\n', ...
            resumo.acuracia_percent(i));
        fprintf(identificador, 'CER global: %.2f%%\n', ...
            resumo.cer_global_percent(i));
        fprintf(identificador, 'CER média por placa: %.2f%%\n', ...
            resumo.cer_media_por_placa_percent(i));
    end

    fprintf(identificador, '\nRECONHECIMENTO POR IMAGEM\n');
    fprintf(identificador, ...
        'Imagem | Ground Truth | Baseline com ROI | Top-hat com ROI | CER e1 (%%) | CER e2 (%%)\n');
    for i = 1:height(comparacao)
        fprintf(identificador, '%s | %s | %s | %s | %.2f | %.2f\n', ...
            char(comparacao.file_name(i)), ...
            char(comparacao.ground_truth(i)), ...
            char(comparacao.ocr_e1_roi(i)), ...
            char(comparacao.ocr_e2_roi(i)), ...
            comparacao.cer_e1_roi_percent(i), ...
            comparacao.cer_e2_roi_percent(i));
    end
    clear limpezaArquivo;
end
