function relatorio = generateResultsReport(raizProjeto, configuracao)
% GENERATERESULTSREPORT Consolida métricas e reconhecimentos dos experimentos.
%
% Uso:
%   relatorio = generateResultsReport(raizProjeto);
%   relatorio = generateResultsReport(raizProjeto, configuracao);
%
% Lê os resultados de results/e1_baseline e results/e2_proposed. Também
% aceita o layout anterior em results/metrics. Salva tabelas e
% um relatório textual em results/reports/<pasta_exclusiva>/ e os gráficos
% correspondentes em results/figures/<pasta_exclusiva>/.

    if nargin < 1 || isempty(raizProjeto)
        raizProjeto = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end
    if nargin < 2 || isempty(configuracao)
        configuracao = struct();
    end
    assert(isfolder(raizProjeto), 'Raiz do projeto não encontrada.');
    assert(isstruct(configuracao) && isscalar(configuracao), ...
        'configuracao deve ser uma estrutura escalar.');

    %% 1. Carregamento e validação das fontes
    arquivoGT = fullfile(raizProjeto, 'data', 'ground_truth', ...
        'ground_truth.csv');
    arquivoE1 = fullfile(raizProjeto, 'results', 'e1_baseline', ...
        'ocr_baseline.csv');
    arquivoE2 = fullfile(raizProjeto, 'results', 'e2_proposed', ...
        'ocr_proposed.csv');
    if ~isfile(arquivoE1)
        arquivoE1 = fullfile(raizProjeto, 'results', 'baseline', ...
            'ocr_baseline.csv');
    end
    if ~isfile(arquivoE2)
        arquivoE2 = fullfile(raizProjeto, 'results', 'proposed', ...
            'ocr_proposed.csv');
    end
    assert(isfile(arquivoGT), 'Ground Truth não encontrado: %s', arquivoGT);
    assert(isfile(arquivoE1), 'Resultados OCR e1 não encontrados.');
    assert(isfile(arquivoE2), 'Resultados OCR e2 não encontrados.');

    gt = readtable(arquivoGT, 'TextType', 'string');
    ocrE1 = lerOCRArquivo(arquivoE1);
    ocrE2 = lerOCRArquivo(arquivoE2);
    exigirColunas(gt, {'image_id','file_name','plate_text','status'}, ...
        'Ground Truth');

    gt = sortrows(gt, 'image_id');
    ocrE1 = sortrows(ocrE1, 'image_id');
    ocrE2 = sortrows(ocrE2, 'image_id');
    assert(isequal(gt.image_id, ocrE1.image_id) && ...
        isequal(gt.image_id, ocrE2.image_id), ...
        'Os IDs do Ground Truth não correspondem aos resultados OCR.');
    assert(isequal(string(gt.file_name), string(ocrE1.file_name)) && ...
        isequal(string(gt.file_name), string(ocrE2.file_name)), ...
        'Os nomes de arquivo não correspondem aos resultados OCR.');

    verdade = normalizar(gt.plate_text);
    textoE1 = normalizar(ocrE1.raw_ocr_text);
    textoE2 = normalizar(ocrE2.raw_ocr_text);
    e1 = table(gt.image_id, gt.file_name, verdade, textoE1, ...
        textoE1 == verdade, 'VariableNames', {'image_id','file_name', ...
        'ground_truth','recognized_text','is_correct'});
    e2 = table(gt.image_id, gt.file_name, verdade, textoE2, ...
        textoE2 == verdade, 'VariableNames', {'image_id','file_name', ...
        'ground_truth','recognized_text','is_correct'});

    %% 2. Alinhamento dos resultados por imagem
    e1 = sortrows(e1, 'image_id');
    e2 = sortrows(e2, 'image_id');

    assert(height(e1) == height(e2), ...
        'Os resultados dos sistemas possuem quantidades diferentes de imagens.');
    assert(numel(unique(e1.image_id)) == height(e1) && ...
        numel(unique(e2.image_id)) == height(e2), ...
        'Existem IDs de imagens duplicados nos resultados.');
    assert(isequal(e1.image_id, e2.image_id), ...
        'Os IDs das imagens não correspondem entre os resultados.');
    assert(isequal(string(e1.file_name), string(e2.file_name)), ...
        'Os nomes das imagens não correspondem entre os resultados.');

    id = e1.image_id;
    nomes = string(e1.file_name);
    verdade = normalizar(e1.ground_truth);
    verdadeE2 = normalizar(e2.ground_truth);
    textoE1 = normalizar(e1.recognized_text);
    textoE2 = normalizar(e2.recognized_text);
    assert(isequal(verdade, verdadeE2), ...
        'O Ground Truth não corresponde entre os sistemas.');
    assert(all(strlength(verdade) > 0 & ~ismissing(verdade)), ...
        'Existem transcrições Ground Truth vazias.');

    %% 3. Comparação por imagem e métricas principais
    total = height(e1);
    distanciaE1 = zeros(total, 1);
    distanciaE2 = zeros(total, 1);
    for i = 1:total
        distanciaE1(i) = levenshtein(verdade(i), textoE1(i));
        distanciaE2(i) = levenshtein(verdade(i), textoE2(i));
    end

    comprimento = strlength(verdade);
    cerE1 = 100 * distanciaE1 ./ comprimento;
    cerE2 = 100 * distanciaE2 ./ comprimento;
    corretaE1 = textoE1 == verdade;
    corretaE2 = textoE2 == verdade;
    assert(all(logical(e1.is_correct) == corretaE1) && ...
        all(logical(e2.is_correct) == corretaE2), ...
        'Os indicadores de acerto não correspondem aos textos reconhecidos.');

    deltaCER = cerE2 - cerE1;
    situacaoCER = strings(total, 1);
    situacaoCER(deltaCER < 0) = "melhorou_CER";
    situacaoCER(deltaCER > 0) = "piorou_CER";
    situacaoCER(deltaCER == 0) = "igual_CER";

    situacaoAcerto = strings(total, 1);
    situacaoAcerto(~corretaE1 & corretaE2) = "passou_a_acertar";
    situacaoAcerto(corretaE1 & ~corretaE2) = "deixou_de_acertar";
    situacaoAcerto(corretaE1 & corretaE2) = "correta_nos_dois";
    situacaoAcerto(~corretaE1 & ~corretaE2) = "incorreta_nos_dois";

    comparacao = table(id, nomes, verdade, textoE1, textoE2, ...
        distanciaE1, distanciaE2, cerE1, cerE2, deltaCER, ...
        corretaE1, corretaE2, situacaoCER, situacaoAcerto, ...
        'VariableNames', {'image_id','file_name','ground_truth', ...
        'ocr_e1','ocr_e2','erros_e1','erros_e2', ...
        'cer_e1_percent','cer_e2_percent','diferenca_cer_percent', ...
        'correta_e1','correta_e2','situacao_cer','situacao_acerto'});

    sistemas = ["e1 - Baseline"; "e2 - Top-hat"];
    resumo = table('Size', [2 8], ...
        'VariableTypes', {'string','double','double','double', ...
        'double','double','double','double'}, ...
        'VariableNames', {'sistema','placas_avaliadas', ...
        'placas_corretas','placas_incorretas','acuracia_percent', ...
        'cer_global_percent','cer_media_por_placa_percent','ocr_vazios'});
    resumo.sistema = sistemas;

    for i = 1:2
        if i == 1
            reconhecimentosCorretos = sum(corretaE1);
            cerGlobalCalculada = 100 * sum(distanciaE1) / sum(comprimento);
            cerMediaCalculada = mean(cerE1);
            quantidadeVazios = sum(strlength(textoE1) == 0);
        else
            reconhecimentosCorretos = sum(corretaE2);
            cerGlobalCalculada = 100 * sum(distanciaE2) / sum(comprimento);
            cerMediaCalculada = mean(cerE2);
            quantidadeVazios = sum(strlength(textoE2) == 0);
        end
        resumo.placas_avaliadas(i) = total;
        resumo.placas_corretas(i) = reconhecimentosCorretos;
        resumo.placas_incorretas(i) = total - reconhecimentosCorretos;
        resumo.acuracia_percent(i) = 100 * reconhecimentosCorretos / total;
        resumo.cer_global_percent(i) = cerGlobalCalculada;
        resumo.cer_media_por_placa_percent(i) = cerMediaCalculada;
        resumo.ocr_vazios(i) = quantidadeVazios;
    end

    placasCorretas = comparacao(corretaE1 | corretaE2, :);
    placasIncorretas = comparacao(~corretaE1 & ~corretaE2, :);
    ganhosPerdas = comparacao(deltaCER ~= 0 | ...
        situacaoAcerto == "passou_a_acertar" | ...
        situacaoAcerto == "deixou_de_acertar", :);

    %% 4. Configuração registrada explicitamente
    chaves = ["operador";"elemento";"tamanho";"roi"; ...
        "layoutOCR";"semente"];
    valores = strings(numel(chaves), 1);
    for i = 1:numel(chaves)
        chave = char(chaves(i));
        if isfield(configuracao, chave)
            valores(i) = string(configuracao.(chave));
        else
            valores(i) = "nao_informado";
        end
    end
    tabelaConfig = table(chaves, valores, ...
        'VariableNames', {'parametro','valor'});

    %% 5. Criação das pastas de saída sem sobrescrita
    diretorioRelatorios = fullfile(raizProjeto, 'results', 'reports');
    diretorioFiguras = fullfile(raizProjeto, 'results', 'figures');
    if ~isfolder(diretorioRelatorios)
        mkdir(diretorioRelatorios);
    end
    if ~isfolder(diretorioFiguras)
        mkdir(diretorioFiguras);
    end

    etiqueta = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    nomePasta = ['comparacao_' etiqueta];
    pastaSaida = fullfile(diretorioRelatorios, nomePasta);
    pastaFiguras = fullfile(diretorioFiguras, nomePasta);
    contador = 1;
    while isfolder(pastaSaida) || isfolder(pastaFiguras)
        nomePasta = sprintf('comparacao_%s_%02d', etiqueta, contador);
        pastaSaida = fullfile(diretorioRelatorios, nomePasta);
        pastaFiguras = fullfile(diretorioFiguras, nomePasta);
        contador = contador + 1;
    end
    mkdir(pastaSaida);
    mkdir(pastaFiguras);

    %% 6. Salvamento das tabelas e do relatório textual
    writetable(comparacao, fullfile(pastaSaida, 'comparacao_por_placa.csv'));
    writetable(placasCorretas, fullfile(pastaSaida, 'placas_corretas.csv'));
    writetable(placasIncorretas, fullfile(pastaSaida, 'placas_incorretas.csv'));
    writetable(ganhosPerdas, fullfile(pastaSaida, 'ganhos_e_perdas_tophat.csv'));
    writetable(resumo, fullfile(pastaSaida, 'resumo_experimentos.csv'));
    writetable(tabelaConfig, fullfile(pastaSaida, 'config.csv'));
    arquivoTexto = fullfile(pastaSaida, 'relatorio.txt');
    salvarRelatorioTexto(arquivoTexto, resumo, comparacao);

    %% 7. Gráficos
    salvarGrafico(sistemas, resumo.acuracia_percent, ...
        'Acurácia exata por sistema', ...
        'Placas corretamente reconhecidas (%)', ...
        fullfile(pastaFiguras, 'comparacao_acuracia.png'));
    salvarGrafico(sistemas, resumo.cer_global_percent, ...
        'CER global por sistema', ...
        'Taxa de erro de caracteres (%)', ...
        fullfile(pastaFiguras, 'comparacao_cer.png'));

    figura = figure('Visible', 'off', 'Color', 'w');
    limpezaFigura = onCleanup(@() close(figura));
    categorias = categorical(["Melhorou CER";"Piorou CER";"CER igual"]);
    quantidades = [sum(deltaCER < 0), sum(deltaCER > 0), ...
        sum(deltaCER == 0)];
    bar(categorias, quantidades);
    ylabel('Quantidade de placas');
    title('Efeito do Top-hat por placa');
    grid on;
    exportgraphics(figura, ...
        fullfile(pastaFiguras, 'evolucao_por_placa.png'), ...
        'Resolution', 150);
    clear limpezaFigura;

    %% 8. Resultado em memória e console
    relatorio = struct('comparacao', comparacao, ...
        'placasCorretas', placasCorretas, ...
        'placasIncorretas', placasIncorretas, ...
        'ganhosPerdas', ganhosPerdas, ...
        'resumo', resumo, ...
        'configuracao', tabelaConfig, ...
        'pastaSaida', string(pastaSaida), ...
        'pastaFiguras', string(pastaFiguras), ...
        'arquivoTexto', string(arquivoTexto));

    fprintf('\n========================================\n');
    fprintf(' RELATÓRIO CONSOLIDADO e1 x e2\n');
    fprintf('========================================\n');
    disp(resumo);
    fprintf('Placas que passaram a acertar: %d\n', ...
        sum(situacaoAcerto == "passou_a_acertar"));
    fprintf('Placas que deixaram de acertar: %d\n', ...
        sum(situacaoAcerto == "deixou_de_acertar"));
    fprintf('Placas com CER menor no e2: %d\n', sum(deltaCER < 0));
    fprintf('Placas com CER maior no e2: %d\n', sum(deltaCER > 0));
    fprintf('Placas com CER igual: %d\n', sum(deltaCER == 0));
    fprintf('\nRelatório e tabelas: %s\n', pastaSaida);
    fprintf('Gráficos: %s\n\n', pastaFiguras);
end

function tabela = lerOCRArquivo(arquivo)
    linhas = readlines(arquivo);
    ids = zeros(0, 1);
    nomes = strings(0, 1);
    textos = strings(0, 1);
    indiceAtual = 0;

    for i = 2:numel(linhas)
        linha = strtrim(string(linhas(i)));
        if strlength(linha) == 0
            continue;
        end

        partes = regexp(char(linha), '^([0-9]+),([^,]+),(.*)$', ...
            'tokens', 'once');
        if ~isempty(partes)
            indiceAtual = indiceAtual + 1;
            ids(indiceAtual, 1) = str2double(partes{1});
            nomes(indiceAtual, 1) = string(partes{2});
            textos(indiceAtual, 1) = string(partes{3});
        elseif indiceAtual > 0
            textos(indiceAtual) = textos(indiceAtual) + linha;
        end
    end

    tabela = table(ids, nomes, textos, 'VariableNames', ...
        {'image_id','file_name','raw_ocr_text'});
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
    d = zeros(n + 1, m + 1);
    d(:, 1) = (0:n)';
    d(1, :) = 0:m;
    for i = 2:n + 1
        for j = 2:m + 1
            custo = double(a(i - 1) ~= b(j - 1));
            d(i, j) = min([d(i - 1, j) + 1, ...
                d(i, j - 1) + 1, d(i - 1, j - 1) + custo]);
        end
    end
    distancia = d(end, end);
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

function salvarRelatorioTexto(arquivo, resumo, comparacao)
    identificador = fopen(arquivo, 'w', 'n', 'UTF-8');
    if identificador < 0
        error('Não foi possível criar o relatório: %s', arquivo);
    end
    limpezaArquivo = onCleanup(@() fclose(identificador));

    fprintf(identificador, 'RELATÓRIO DE RECONHECIMENTO DE PLACAS\n\n');
    fprintf(identificador, 'MÉTRICAS PRINCIPAIS\n');
    for i = 1:height(resumo)
        fprintf(identificador, '\n%s\n', char(resumo.sistema(i)));
        fprintf(identificador, 'Placas avaliadas: %d\n', ...
            resumo.placas_avaliadas(i));
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
        fprintf(identificador, 'OCR sem caracteres: %d\n', ...
            resumo.ocr_vazios(i));
    end

    fprintf(identificador, '\nRECONHECIMENTO POR IMAGEM\n');
    fprintf(identificador, ...
        'Imagem | Ground Truth | Baseline | Top-hat | CER baseline (%%) | CER Top-hat (%%)\n');
    for i = 1:height(comparacao)
        fprintf(identificador, '%s | %s | %s | %s | %.2f | %.2f\n', ...
            char(comparacao.file_name(i)), ...
            char(comparacao.ground_truth(i)), ...
            char(comparacao.ocr_e1(i)), ...
            char(comparacao.ocr_e2(i)), ...
            comparacao.cer_e1_percent(i), ...
            comparacao.cer_e2_percent(i));
    end
    clear limpezaArquivo;
end
