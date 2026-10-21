
function metricas = evaluateRecognition(raizProjeto)
% EVALUATERECOGNITION Avalia o reconhecimento OCR do baseline.
%
% A função compara os caracteres reconhecidos pelo OCR
% com as transcrições manuais registradas no Ground Truth.
%
% São consideradas apenas as placas com status "verified".
% Uma placa é considerada correta somente quando todos
% os caracteres reconhecidos correspondem ao Ground Truth.
%
% Entrada:
%   raizProjeto - Caminho da pasta principal do projeto.
%
% Saída:
%   metricas - Tabela com o número de placas avaliadas,
%              reconhecimentos corretos, acurácia (%)
%              e taxa de erro de caracteres (CER).

    %% 1. Definição dos caminhos

    arquivoGroundTruth = fullfile(raizProjeto, ...
        'data', 'ground_truth', 'ground_truth.csv');

    arquivoBaseline = fullfile(raizProjeto, ...
        'results', 'baseline', 'ocr_baseline.csv');

    diretorioMetricas = fullfile(raizProjeto, ...
        'results', 'metrics');

    arquivoMetricas = fullfile(diretorioMetricas, ...
        'baseline_metrics.csv');

    arquivoDetalhamento = fullfile(diretorioMetricas, ...
        'baseline_comparison.csv');

    %% 2. Verificação dos arquivos de entrada

    if ~isfile(arquivoGroundTruth)
        error('Arquivo Ground Truth não encontrado.');
    end

    if ~isfile(arquivoBaseline)
        error(['Resultados do baseline não encontrados. ', ...
            'Execute runBaseline.m primeiro.']);
    end

    %% 3. Proteção dos resultados existentes

    % Impede a substituição de avaliações anteriores.
    if isfile(arquivoMetricas) || isfile(arquivoDetalhamento)

        error(['Já existem arquivos de avaliação. ', ...
            'Preserve ou arquive os resultados antes ', ...
            'de realizar uma nova avaliação.']);
    end

    %% 4. Carregamento dos dados

    groundTruth = readtable(arquivoGroundTruth, ...
        'TextType', 'string');

    baseline = readtable(arquivoBaseline, ...
        'TextType', 'string');

    %% 5. Validação da estrutura dos arquivos

    colunasGroundTruth = { ...
        'image_id', 'file_name', 'plate_text', 'status'};

    colunasBaseline = { ...
        'image_id', 'file_name', 'recognized_text'};

    if ~all(ismember(colunasGroundTruth, ...
            groundTruth.Properties.VariableNames))

        error('O arquivo Ground Truth possui colunas ausentes.');
    end

    if ~all(ismember(colunasBaseline, ...
            baseline.Properties.VariableNames))

        error('O arquivo baseline possui colunas ausentes.');
    end

    %% 6. Organização dos registros

    % Ordena ambas as tabelas por identificador crescente.
    groundTruth = sortrows(groundTruth, 'image_id');

    baseline = sortrows(baseline, 'image_id');

    % Verifica se a quantidade de registros é igual.
    if height(groundTruth) ~= height(baseline)

        error(['Ground Truth e baseline possuem ', ...
            'quantidades diferentes de registros.']);
    end

    % Confirma que os registros correspondem às mesmas imagens.
    mesmosIDs = isequal( ...
        groundTruth.image_id, baseline.image_id);

    mesmosArquivos = isequal( ...
        groundTruth.file_name, baseline.file_name);

    if ~mesmosIDs || ~mesmosArquivos
        error('As tabelas possuem imagens diferentes.');
    end

    % Garante que não existam identificadores duplicados.
    if numel(unique(groundTruth.image_id)) ~= height(groundTruth)
        error('Existem identificadores de imagens duplicados.');
    end

    %% 7. Identificação dos Ground Truths verificados

    % Considera apenas as placas confirmadas manualmente
    % e que possuem caracteres verdadeiros preenchidos.
    registrosValidos = ...
        groundTruth.status == "verified" & ...
        ~ismissing(groundTruth.plate_text) & ...
        strlength(groundTruth.plate_text) > 0;

    if ~any(registrosValidos)
        error('Nenhuma placa possui Ground Truth verificado.');
    end

    %% 8. Seleção dos registros para avaliação

    groundTruthValido = groundTruth(registrosValidos, :);

    baselineValido = baseline(registrosValidos, :);

    quantidadeAvaliadas = height(groundTruthValido);

    %% 9. Preparação dos textos para comparação

    % Os caracteres verdadeiros são padronizados.
    textosVerdadeiros = upper(regexprep( ...
        groundTruthValido.plate_text, '[^A-Za-z0-9]', ''));

    % Os textos reconhecidos também são padronizados.
    textosReconhecidos = upper(regexprep( ...
        baselineValido.recognized_text, '[^A-Za-z0-9]', ''));

    % Reconhecimentos vazios são considerados incorretos.
    textosReconhecidos(ismissing(textosReconhecidos)) = "";

    %% 10. Comparação dos caracteres

    % Retorna true quando todos os caracteres coincidem.
    reconhecimentosCorretos = ...
        textosVerdadeiros == textosReconhecidos;

    %% 11. Cálculo das métricas

    quantidadeCorretas = sum(reconhecimentosCorretos);

    quantidadeIncorretas = ...
        quantidadeAvaliadas - quantidadeCorretas;

    acuracia = ...
        (quantidadeCorretas / quantidadeAvaliadas) * 100;

    % Calcula a taxa de erro de caracteres (CER).
    %
    % A distância de Levenshtein representa o número
    % mínimo de substituições, inserções e exclusões
    % necessárias para transformar um texto em outro.

    totalErrosCaracteres = 0;
    totalCaracteres = 0;

    for indice = 1:quantidadeAvaliadas

        textoVerdadeiro = char(textosVerdadeiros(indice));
        textoReconhecido = char(textosReconhecidos(indice));

        % Calcula os erros de reconhecimento desta placa.
        erros = calcularDistanciaLevenshtein( ...
            textoVerdadeiro, textoReconhecido);

        % Acumula os erros e os caracteres verdadeiros.
        totalErrosCaracteres = totalErrosCaracteres + erros;

        totalCaracteres = totalCaracteres + ...
            length(textoVerdadeiro);

    end

    % Taxa de erro considerando todas as placas avaliadas.
    cer = (totalErrosCaracteres / totalCaracteres) * 100;

    %% 12. Organização das métricas

    metricas = table( ...
        quantidadeAvaliadas, ...
        quantidadeCorretas, ...
        quantidadeIncorretas, ...
        acuracia, ...
        cer, ...
        'VariableNames', { ...
        'verified_plates', ...
        'exact_matches', ...
        'incorrect_matches', ...
        'accuracy_percent', ...
        'cer_percent'});

    %% 13. Detalhamento dos resultados

    % Cria uma tabela contendo a comparação por imagem.
    comparacao = table( ...
        groundTruthValido.image_id, ...
        groundTruthValido.file_name, ...
        textosVerdadeiros, ...
        textosReconhecidos, ...
        reconhecimentosCorretos, ...
        'VariableNames', { ...
        'image_id', ...
        'file_name', ...
        'ground_truth', ...
        'recognized_text', ...
        'is_correct'});

    %% 14. Criação do diretório de resultados

    if ~isfolder(diretorioMetricas)
        mkdir(diretorioMetricas);
    end

    %% 15. Salvamento dos resultados

    writetable(metricas, arquivoMetricas);

    writetable(comparacao, arquivoDetalhamento);

    %% 16. Exibição dos resultados

    fprintf('\n========================================\n');
    fprintf(' AVALIAÇÃO DO SISTEMA BASELINE\n');
    fprintf('========================================\n');

    fprintf('Placas avaliadas: %d\n', quantidadeAvaliadas);
    fprintf('Reconhecimentos corretos: %d\n', quantidadeCorretas);
    fprintf('Reconhecimentos incorretos: %d\n', quantidadeIncorretas);
    fprintf('Acurácia: %.2f%%\n', acuracia);
    fprintf('Taxa de erro de caracteres (CER): %.2f%%\n\n', cer);

    fprintf('Resultados salvos em:\n');
    fprintf('%s\n', arquivoMetricas);
    fprintf('%s\n\n', arquivoDetalhamento);

    disp(metricas);

end


%% Função auxiliar - Distância de Levenshtein

function distancia = calcularDistanciaLevenshtein(texto1, texto2)
% CALCULARDISTANCIALEVENSHTEIN Calcula a distância entre textos.
%
% A distância corresponde ao número mínimo de operações
% necessárias para transformar o primeiro texto no segundo.
%
% Operações consideradas:
%   - Substituição de caractere.
%   - Inserção de caractere.
%   - Exclusão de caractere.
%
% Entradas:
%   texto1 - Texto verdadeiro (Ground Truth).
%   texto2 - Texto reconhecido pelo OCR.
%
% Saída:
%   distancia - Número mínimo de operações necessárias.

    tamanho1 = length(texto1);
    tamanho2 = length(texto2);

    % Cria a matriz utilizada na programação dinâmica.
    matriz = zeros(tamanho1 + 1, tamanho2 + 1);

    % Inicializa os custos de exclusão.
    matriz(:, 1) = 0:tamanho1;

    % Inicializa os custos de inserção.
    matriz(1, :) = 0:tamanho2;

    % Percorre os caracteres dos dois textos.
    for i = 2:tamanho1 + 1

        for j = 2:tamanho2 + 1

            % Custo zero para caracteres iguais.
            % Custo um para caracteres diferentes.
            custo = double(texto1(i-1) ~= texto2(j-1));

            % Calcula os custos das três operações.
            exclusao = matriz(i-1, j) + 1;
            insercao = matriz(i, j-1) + 1;
            substituicao = matriz(i-1, j-1) + custo;

            % Seleciona a operação de menor custo.
            matriz(i, j) = min([ ...
                exclusao, insercao, substituicao]);

        end
    end

    % O último elemento contém a distância mínima.
    distancia = matriz(tamanho1 + 1, tamanho2 + 1);

end
