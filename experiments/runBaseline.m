
function resultados = runBaseline(raizProjeto)
% RUNBASELINE Executa o OCR do sistema de referência.
%
% A função percorre as placas previamente selecionadas,
% executa o reconhecimento óptico de caracteres (OCR)
% e armazena os resultados em um arquivo CSV.
%
% O sistema baseline utiliza diretamente as placas
% recortadas, sem aplicar o operador Top-hat.
%
% Os resultados são gerados apenas uma vez.
% Caso o arquivo CSV já exista, ele será preservado.
%
% Entrada:
%   raizProjeto - Caminho da pasta principal do projeto.
%
% Saída:
%   resultados  - Tabela com os caracteres reconhecidos
%                 e os textos originais retornados pelo OCR.

    %% 1. Definição dos caminhos

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');

    diretorioPlacas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');

    diretorioResultados = fullfile(raizProjeto, ...
        'results', 'baseline');

    arquivoResultados = fullfile(diretorioResultados, ...
        'ocr_baseline.csv');

    %% 2. Verificação de resultados existentes

    % Impede que uma nova execução substitua os resultados.
    if isfile(arquivoResultados)
        error(['O resultado do baseline já existe: %s\n', ...
            'O arquivo foi preservado.'], arquivoResultados);
    end

    %% 3. Validação dos arquivos necessários

    % Verifica se a seleção das imagens foi realizada.
    if ~isfile(arquivoSelecao)
        error(['Arquivo de seleção não encontrado. ', ...
            'Execute selectImages.m primeiro.']);
    end

    % Verifica se o diretório das placas está disponível.
    if ~isfolder(diretorioPlacas)
        error('Diretório de placas selecionadas não encontrado.');
    end

    %% 4. Carregamento da seleção

    selecao = readtable(arquivoSelecao, ...
        'TextType', 'string');

    % Verifica se as colunas necessárias estão presentes.
    colunasObrigatorias = {'image_id', 'file_name'};

    if ~all(ismember(colunasObrigatorias, ...
            selecao.Properties.VariableNames))

        error('O arquivo de seleção possui colunas ausentes.');
    end

    % Organiza as imagens por identificador crescente.
    selecao = sortrows(selecao, 'image_id');

    % Obtém a quantidade de placas selecionadas.
    quantidadePlacas = height(selecao);

    if quantidadePlacas ~= 40
        error(['A seleção deve conter 40 placas. ', ...
            'Foram encontrados %d registros.'], quantidadePlacas);
    end

    %% 5. Verificação das placas selecionadas

    % Confere a existência dos arquivos antes do OCR.
    for indice = 1:quantidadePlacas

        nomeArquivo = char(selecao.file_name(indice));

        caminhoPlaca = fullfile(diretorioPlacas, ...
            nomeArquivo);

        if ~isfile(caminhoPlaca)
            error('Placa não encontrada: %s', nomeArquivo);
        end

    end

    %% 6. Preparação das variáveis

    % Armazena os caracteres reconhecidos e normalizados.
    textosReconhecidos = strings(quantidadePlacas, 1);

    % Armazena os textos brutos retornados pelo OCR.
    textosOriginaisOCR = strings(quantidadePlacas, 1);

    %% 7. Execução do sistema baseline

    fprintf('\n========================================\n');
    fprintf(' EXECUÇÃO DO SISTEMA BASELINE\n');
    fprintf('========================================\n');

    fprintf('Total de placas: %d\n\n', quantidadePlacas);

    for indice = 1:quantidadePlacas

        % Identifica o arquivo da placa.
        nomeArquivo = char(selecao.file_name(indice));

        % Define o caminho completo da imagem.
        caminhoPlaca = fullfile(diretorioPlacas, ...
            nomeArquivo);

        % Executa o reconhecimento OCR.
        [textoNormalizado, textoBruto] = ...
            recognizePlate(caminhoPlaca);

        % Armazena os resultados do reconhecimento.
        textosReconhecidos(indice) = textoNormalizado;
        textosOriginaisOCR(indice) = textoBruto;

        % Apresenta o resultado no Command Window.
        fprintf('%2d/%2d | ID: %4d | %s | OCR: %s\n', ...
            indice, ...
            quantidadePlacas, ...
            selecao.image_id(indice), ...
            nomeArquivo, ...
            textoNormalizado);

    end

    %% 8. Organização dos resultados

    % Mantém os nomes das colunas padronizados para
    % facilitar a comparação com o sistema Top-hat.
    resultados = table( ...
        selecao.image_id, ...
        selecao.file_name, ...
        textosReconhecidos, ...
        textosOriginaisOCR, ...
        'VariableNames', { ...
        'image_id', ...
        'file_name', ...
        'recognized_text', ...
        'raw_ocr_text'});

    %% 9. Criação do diretório de resultados

    if ~isfolder(diretorioResultados)
        mkdir(diretorioResultados);
    end

    %% 10. Salvamento dos resultados

    writetable(resultados, arquivoResultados);

    %% 11. Exibição do resumo

    fprintf('\n========================================\n');
    fprintf(' BASELINE CONCLUÍDO\n');
    fprintf('========================================\n');

    fprintf('Total de placas processadas: %d\n', ...
        quantidadePlacas);

    fprintf('Resultados salvos em:\n%s\n\n', ...
        arquivoResultados);

    disp(resultados);

end
