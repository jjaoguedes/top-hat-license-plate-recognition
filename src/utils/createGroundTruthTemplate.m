
function groundTruth = createGroundTruthTemplate(raizProjeto)
% CREATEGROUNDTRUTHTEMPLATE Cria a tabela inicial de Ground Truth.
%
% A função utiliza a lista de imagens selecionadas para criar
% um arquivo CSV destinado à anotação manual das placas.
%
% O arquivo é criado somente na primeira execução.
% Caso já exista, seu conteúdo é carregado sem alterações.
%
% Entrada:
%   raizProjeto - Caminho da pasta principal do projeto.
%
% Saída:
%   groundTruth - Tabela com os identificadores das imagens,
%                 nomes dos arquivos, caracteres das placas
%                 e status das anotações.

    %% 1. Definição dos caminhos

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');

    diretorioGroundTruth = fullfile(raizProjeto, ...
        'data', 'ground_truth');

    arquivoGroundTruth = fullfile(diretorioGroundTruth, ...
        'ground_truth.csv');

    %% 2. Verificação do arquivo de seleção

    % O Ground Truth depende das imagens selecionadas.
    if ~isfile(arquivoSelecao)
        error(['Arquivo de seleção não encontrado. ', ...
            'Execute selectImages.m primeiro.']);
    end

    %% 3. Leitura das imagens selecionadas

    selecao = readtable(arquivoSelecao, ...
        'TextType', 'string');

    % Verifica se a seleção possui os campos necessários.
    colunasObrigatorias = {'image_id', 'file_name'};

    if ~all(ismember(colunasObrigatorias, ...
            selecao.Properties.VariableNames))

        error('O arquivo de seleção não possui as colunas esperadas.');
    end

    %% 4. Verificação de Ground Truth existente

    % Se o arquivo já existe, preserva as anotações.
    if isfile(arquivoGroundTruth)

        groundTruth = readtable(arquivoGroundTruth, ...
            'TextType', 'string');

        fprintf('\nGround Truth existente encontrado.\n');
        fprintf('As anotações foram preservadas.\n');
        fprintf('Arquivo: %s\n\n', arquivoGroundTruth);

        disp(groundTruth);

        return;
    end

    %% 5. Criação do diretório de destino

    if ~isfolder(diretorioGroundTruth)
        mkdir(diretorioGroundTruth);
    end

    %% 6. Preparação dos dados

    % Recupera os identificadores das imagens selecionadas.
    image_id = selecao.image_id;

    % Recupera os nomes originais dos arquivos.
    file_name = selecao.file_name;

    % Obtém a quantidade de imagens selecionadas.
    quantidadeImagens = height(selecao);

    % Inicializa os caracteres das placas como texto vazio.
    plate_text = repmat("", quantidadeImagens, 1);

    % Todas as transcrições começam como pendentes.
    status = repmat("pending", quantidadeImagens, 1);

    %% 7. Criação da tabela

    groundTruth = table( ...
        image_id, ...
        file_name, ...
        plate_text, ...
        status);

    %% 8. Salvamento do arquivo CSV

    writetable(groundTruth, arquivoGroundTruth);

    %% 9. Exibição dos resultados

    fprintf('\nGround Truth criado\n');
    fprintf('Total de registros: %d\n', quantidadeImagens);
    fprintf('Arquivo: %s\n\n', arquivoGroundTruth);

    disp(groundTruth);

end
