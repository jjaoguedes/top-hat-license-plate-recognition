
%% MINI PROJETO - RECONHECIMENTO DE PLACAS
% Sistema de referência (Baseline)
%
% Objetivo:
% Preparar a base de imagens, construir o Ground Truth,
% executar o reconhecimento OCR e avaliar os resultados.
%
% Nesta etapa, o operador Top-hat não será utilizado.

%% 1. Configuração inicial

clc;

% Obtém o caminho da pasta principal do projeto.
raizProjeto = fileparts(mfilename('fullpath'));

% Adiciona os diretórios das funções ao MATLAB.
addpath(fullfile(raizProjeto, 'src', 'utils'));
addpath(fullfile(raizProjeto, 'src', 'ocr'));
addpath(fullfile(raizProjeto, 'src', 'evaluation'));
addpath(fullfile(raizProjeto, 'experiments'));

fprintf('\n========================================\n');
fprintf(' MINI PROJETO - SISTEMA BASELINE\n');
fprintf('========================================\n');

fprintf('Diretório do projeto:\n%s\n', raizProjeto);

%% 2. Seleção das imagens

% Seleciona 40 pares de imagens utilizando semente fixa.
%
% Caso a seleção já exista, os mesmos arquivos serão
% reutilizados, evitando alterações no experimento.

quantidadeImagens = 40;
sementeAleatoria = 42;

selecao = selectImages( ...
    raizProjeto, quantidadeImagens, sementeAleatoria);

%% 3. Preparação do Ground Truth

% Cria o arquivo CSV inicial para as transcrições.
%
% Caso o arquivo já exista, suas informações são
% carregadas sem substituir as anotações anteriores.

groundTruth = createGroundTruthTemplate(raizProjeto);

%% 4. Anotação manual das placas

% Apresenta as placas ainda não verificadas.
%
% A execução depende da identificação manual dos
% caracteres e da confirmação pelo usuário.
%
% Para iniciar ou continuar a anotação,
% execute esta seção individualmente.

% annotateGroundTruth(raizProjeto);

%% 5. Execução do sistema baseline

% Executa o OCR nas 40 placas selecionadas.
%
% Os resultados são armazenados em:
% results/baseline/ocr_baseline.csv
%
% Execute esta seção quando desejar gerar os resultados.
% O arquivo existente não será sobrescrito.

% resultadosBaseline = runBaseline(raizProjeto);

%% 6. Avaliação do reconhecimento

% Compara os resultados do OCR com o Ground Truth.
%
% Recomenda-se executar apenas após verificar
% manualmente as 40 placas selecionadas.
%
% Os resultados serão armazenados em:
% results/metrics/baseline_metrics.csv
% results/metrics/baseline_comparison.csv

% metricasBaseline = evaluateRecognition(raizProjeto);

%% 7. Finalização

fprintf('\n========================================\n');
fprintf(' CONFIGURAÇÃO INICIAL CONCLUÍDA\n');
fprintf('========================================\n');

fprintf('Seleção de imagens e Ground Truth disponíveis.\n');
fprintf('Execute as demais etapas conforme necessário.\n');
