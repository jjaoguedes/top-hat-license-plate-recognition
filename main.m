
%% MINI PROJETO - OPERADOR TOP-HAT
% Correção de iluminação não uniforme em placas veiculares.
%
% Objetivo:
% Executar e comparar dois sistemas de reconhecimento:
%
% e1 - Sistema de referência, sem Top-hat.
% e2 - Sistema proposto, com Top-hat.
%
% Ambos utilizam:
%   - As mesmas 40 placas selecionadas.
%   - O mesmo Ground Truth.
%   - A mesma configuração de OCR.
%   - As mesmas métricas de avaliação.
%
% Os arquivos existentes são preservados.


%% 1. Configuração inicial

clc;

% Obtém o caminho principal do projeto.
raizProjeto = fileparts(mfilename('fullpath'));

% Adiciona os diretórios dos módulos.
addpath(fullfile(raizProjeto, 'src', 'utils'));
addpath(fullfile(raizProjeto, 'src', 'ocr'));
addpath(fullfile(raizProjeto, 'src', 'evaluation'));
addpath(fullfile(raizProjeto, 'src', 'morphology'));
addpath(fullfile(raizProjeto, 'experiments'));

% Parâmetros da seleção.
quantidadeImagens = 40;
sementeAleatoria = 42;

% Parâmetro do sistema Top-hat.
% Definir após concluir a validação do operador.
raioElementoEstruturante = 21;
fprintf('Raio do elemento estruturante: %d\n', ...
    raioElementoEstruturante);

fprintf('\n========================================\n');
fprintf(' MINI PROJETO - TOP-HAT\n');
fprintf('========================================\n');


%% 2. Seleção das imagens

% Seleciona ou reutiliza os 40 pares já registrados.
% A seleção existente não será modificada.

selecao = selectImages( ...
    raizProjeto, quantidadeImagens, sementeAleatoria);

% Organiza os registros por identificador crescente.
selecao = sortrows(selecao, 'image_id');

fprintf('\nSeleção disponível: %d imagens.\n', ...
    height(selecao));


%% 3. Verificação do Ground Truth

% Cria ou recupera o arquivo das transcrições.
groundTruth = createGroundTruthTemplate(raizProjeto);

% Organiza os registros pela mesma ordem da seleção.
groundTruth = sortrows(groundTruth, 'image_id');

% Confirma a correspondência entre os arquivos.
if ~isequal(selecao.image_id, groundTruth.image_id) || ...
        ~isequal(selecao.file_name, groundTruth.file_name)

    error('Ground Truth não corresponde à seleção.');
end

% Conta as transcrições verificadas.
verificadas = groundTruth.status == "verified" & ...
    ~ismissing(groundTruth.plate_text) & ...
    strlength(groundTruth.plate_text) > 0;

quantidadeVerificadas = sum(verificadas);

fprintf('\nGround Truth verificado: %d/%d\n', ...
    quantidadeVerificadas, quantidadeImagens);

% Interrompe a avaliação caso existam anotações pendentes.
if quantidadeVerificadas ~= quantidadeImagens

    error(['Conclua as 40 transcrições do Ground Truth ', ...
        'antes de executar a avaliação.']);
end


%% 4. Preparação das imagens do sistema e1

% e1 utiliza diretamente as placas selecionadas.
% Nenhuma transformação de imagem é aplicada.
%
% As placas são copiadas para data/e1/ apenas
% para organizar a entrega do experimento.

diretorioPlacas = fullfile(raizProjeto, ...
    'data', 'selected', 'plates');

diretorioE1 = fullfile(raizProjeto, 'data', 'e1');

if ~isfolder(diretorioE1)
    mkdir(diretorioE1);
end

fprintf('\nPreparando imagens do sistema e1...\n');

for indice = 1:height(selecao)

    nomeArquivo = char(selecao.file_name(indice));

    arquivoOrigem = fullfile(diretorioPlacas, ...
        nomeArquivo);

    arquivoDestino = fullfile(diretorioE1, ...
        nomeArquivo);

    % Confirma que a placa original existe.
    if ~isfile(arquivoOrigem)
        error('Placa não encontrada: %s', nomeArquivo);
    end

    % Copia somente quando o destino não existe.
    if ~isfile(arquivoDestino)

        [sucesso, mensagem] = copyfile( ...
            arquivoOrigem, arquivoDestino);

        if ~sucesso
            error('Falha na cópia: %s', mensagem);
        end

    else

        % Confirma que a cópia existente é idêntica.
        imagemOrigem = imread(arquivoOrigem);
        imagemDestino = imread(arquivoDestino);

        if ~isequal(imagemOrigem, imagemDestino)
            error('Imagem e1 diferente da origem: %s', ...
                nomeArquivo);
        end

    end
end

% Confere a quantidade de imagens.
arquivosE1 = dir(fullfile(diretorioE1, '*.jpg'));

if numel(arquivosE1) ~= quantidadeImagens
    error('O diretório e1 não contém exatamente 40 imagens.');
end

fprintf('Imagens e1 preparadas: %d\n', numel(arquivosE1));


%% 5. Execução do sistema e1 - Baseline

% O baseline executa o OCR diretamente nas placas
% selecionadas, sem aplicar Top-hat.

arquivoOCRBaseline = fullfile(raizProjeto, ...
    'results', 'baseline', 'ocr_baseline.csv');

if ~isfile(arquivoOCRBaseline)

    fprintf('\nExecutando OCR do sistema e1...\n');

    resultadosBaseline = runBaseline(raizProjeto);

else

    fprintf('\nResultados e1 existentes preservados.\n');

    resultadosBaseline = readtable( ...
        arquivoOCRBaseline, 'TextType', 'string');
end


%% 6. Avaliação do sistema e1

arquivoMetricasBaseline = fullfile(raizProjeto, ...
    'results', 'metrics', 'baseline_metrics.csv');

if ~isfile(arquivoMetricasBaseline)

    fprintf('\nAvaliando sistema e1...\n');

    metricasBaseline = evaluateRecognition( ...
        raizProjeto, 'baseline');

else

    fprintf('\nMétricas e1 existentes preservadas.\n');

    metricasBaseline = readtable( ...
        arquivoMetricasBaseline, 'TextType', 'string');
end


%% 7. Execução do sistema e2 - Top-hat

% O sistema proposto aplica o Top-hat nas mesmas
% 40 placas utilizadas pelo baseline.
%
% As imagens processadas são salvas em data/e2/.

arquivoOCRProposto = fullfile(raizProjeto, ...
    'results', 'proposed', 'ocr_proposed.csv');

diretorioE2 = fullfile(raizProjeto, 'data', 'e2');

if ~isfile(arquivoOCRProposto)

    % Evita executar sobre imagens processadas
    % anteriormente em uma execução interrompida.
    if isfolder(diretorioE2)

        arquivosExistentes = dir(fullfile( ...
            diretorioE2, '*.jpg'));

        if ~isempty(arquivosExistentes)
            error(['Existem imagens em data/e2/ sem ', ...
                'resultados OCR completos. ', ...
                'Verifique os arquivos antes de continuar.']);
        end
    end

    fprintf('\nExecutando sistema e2 - Top-hat...\n');

    resultadosPropostos = runProposed( ...
        raizProjeto, raioElementoEstruturante);

else

    fprintf('\nResultados e2 existentes preservados.\n');

    resultadosPropostos = readtable( ...
        arquivoOCRProposto, 'TextType', 'string');

end


%% 8. Verificação das imagens processadas em e2

% Confirma que todas as placas foram processadas
% e que os nomes originais foram preservados.

if ~isfolder(diretorioE2)
    error('Diretório data/e2/ não encontrado.');
end

arquivosE2 = dir(fullfile(diretorioE2, '*.jpg'));

if numel(arquivosE2) ~= quantidadeImagens
    error('O diretório e2 não contém exatamente 40 imagens.');
end

nomesE2 = sort(string({arquivosE2.name})');
nomesSelecionados = sort(selecao.file_name);

if ~isequal(nomesE2, nomesSelecionados)
    error('Os arquivos e2 não correspondem à seleção.');
end

fprintf('\nImagens e2 verificadas: %d\n', ...
    numel(arquivosE2));


%% 9. Avaliação do sistema e2

arquivoMetricasPropostas = fullfile(raizProjeto, ...
    'results', 'metrics', 'proposed_metrics.csv');

if ~isfile(arquivoMetricasPropostas)

    fprintf('\nAvaliando sistema e2...\n');

    metricasPropostas = evaluateRecognition( ...
        raizProjeto, 'proposed');

else

    fprintf('\nMétricas e2 existentes preservadas.\n');

    metricasPropostas = readtable( ...
        arquivoMetricasPropostas, 'TextType', 'string');
end


%% 10. Comparação dos resultados

% Organiza as principais métricas dos dois sistemas.

sistemas = ["e1 - Baseline"; "e2 - Top-hat"];

placasAvaliadas = [ ...
    metricasBaseline.verified_plates;
    metricasPropostas.verified_plates];

placasCorretas = [ ...
    metricasBaseline.exact_matches;
    metricasPropostas.exact_matches];

acuracia = [ ...
    metricasBaseline.accuracy_percent;
    metricasPropostas.accuracy_percent];

cer = [ ...
    metricasBaseline.cer_percent;
    metricasPropostas.cer_percent];

% Cria a tabela comparativa.
comparacaoFinal = table( ...
    sistemas, ...
    placasAvaliadas, ...
    placasCorretas, ...
    acuracia, ...
    cer, ...
    'VariableNames', { ...
    'sistema', ...
    'placas_avaliadas', ...
    'placas_corretas', ...
    'acuracia_percent', ...
    'cer_percent'});

fprintf('\n========================================\n');
fprintf(' COMPARAÇÃO FINAL - e1 x e2\n');
fprintf('========================================\n');

disp(comparacaoFinal);

% Exibe as diferenças entre os sistemas.
diferencaAcuracia = ...
    acuracia(2) - acuracia(1);

diferencaCER = ...
    cer(2) - cer(1);

fprintf('Diferença de acurácia: %+.2f p.p.\n', ...
    diferencaAcuracia);

fprintf('Diferença de CER: %+.2f p.p.\n', ...
    diferencaCER);


%% 11. Salvamento da comparação

diretorioMetricas = fullfile(raizProjeto, ...
    'results', 'metrics');

arquivoComparacao = fullfile(diretorioMetricas, ...
    'comparison_e1_e2.csv');

% Preserva o resultado comparativo existente.
if ~isfile(arquivoComparacao)

    writetable(comparacaoFinal, arquivoComparacao);

    fprintf('\nComparação salva em:\n%s\n', ...
        arquivoComparacao);

else

    fprintf('\nComparação existente preservada:\n%s\n', ...
        arquivoComparacao);
end


%% 12. Finalização

fprintf('\n========================================\n');
fprintf(' EXPERIMENTOS CONCLUÍDOS\n');
fprintf('========================================\n');

fprintf('Sistema e1: data/e1/\n');
fprintf('Sistema e2: data/e2/\n');

fprintf('Resultados: results/\n');

fprintf('\nTotal de imagens por sistema: %d\n', ...
    quantidadeImagens);
