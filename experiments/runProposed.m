
function resultados = runProposed(raizProjeto, raio)
% RUNPROPOSED Executa o sistema proposto com Top-hat.
%
% A função aplica a correção de iluminação nas placas
% selecionadas e executa o reconhecimento OCR.
%
% As imagens processadas são armazenadas em data/e2/,
% preservando os nomes originais dos arquivos.
%
% Entrada:
%   raizProjeto - Caminho da pasta principal do projeto.
%   raio        - Raio do elemento estruturante.
%
% Saída:
%   resultados  - Tabela com os resultados do OCR.

    %% 1. Configuração dos parâmetros

    if nargin < 2
        raio = 9;
    end

    %% 2. Definição dos caminhos

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');

    diretorioPlacas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');

    diretorioE2 = fullfile(raizProjeto, 'data', 'e2');

    diretorioResultados = fullfile(raizProjeto, ...
        'results', 'proposed');

    arquivoResultados = fullfile(diretorioResultados, ...
        'ocr_proposed.csv');

    %% 3. Verificação dos arquivos necessários

    if ~isfile(arquivoSelecao)
        error('Arquivo de seleção não encontrado.');
    end

    if ~isfolder(diretorioPlacas)
        error('Diretório de placas não encontrado.');
    end

    % Impede a substituição de resultados existentes.
    if isfile(arquivoResultados)
        error('Os resultados do sistema proposto já existem.');
    end

    %% 4. Carregamento da seleção

    selecao = readtable(arquivoSelecao, ...
        'TextType', 'string');

    selecao = sortrows(selecao, 'image_id');

    quantidadePlacas = height(selecao);

    if quantidadePlacas ~= 40
        error('O experimento deve conter exatamente 40 placas.');
    end

    %% 5. Verificação dos arquivos

    for indice = 1:quantidadePlacas

        nomeArquivo = char(selecao.file_name(indice));

        caminhoEntrada = fullfile(diretorioPlacas, ...
            nomeArquivo);

        caminhoSaida = fullfile(diretorioE2, ...
            nomeArquivo);

        if ~isfile(caminhoEntrada)
            error('Placa não encontrada: %s', nomeArquivo);
        end

        % Não sobrescreve imagens processadas anteriormente.
        if isfile(caminhoSaida)
            error('Imagem processada já existe: %s', nomeArquivo);
        end

    end

    %% 6. Preparação dos diretórios

    if ~isfolder(diretorioE2)
        mkdir(diretorioE2);
    end

    if ~isfolder(diretorioResultados)
        mkdir(diretorioResultados);
    end

    %% 7. Preparação das variáveis

    textosReconhecidos = strings(quantidadePlacas, 1);

    textosOriginaisOCR = strings(quantidadePlacas, 1);

    %% 8. Execução do sistema proposto

    fprintf('\n========================================\n');
    fprintf(' SISTEMA PROPOSTO - TOP-HAT\n');
    fprintf('========================================\n');

    fprintf('Total de placas: %d\n', quantidadePlacas);
    fprintf('Raio do elemento estruturante: %d\n\n', raio);

    for indice = 1:quantidadePlacas

        nomeArquivo = char(selecao.file_name(indice));

        caminhoEntrada = fullfile(diretorioPlacas, ...
            nomeArquivo);

        caminhoSaida = fullfile(diretorioE2, ...
            nomeArquivo);

        % Lê a placa recortada.
        imagemOriginal = imread(caminhoEntrada);

        % Aplica a correção de iluminação.
        imagemCorrigida = applyTopHat( ...
            imagemOriginal, raio);

        % Salva a imagem mantendo o nome original.
        imwrite(imagemCorrigida, caminhoSaida);

        % Executa o mesmo OCR utilizado pelo baseline.
        [textoNormalizado, textoBruto] = ...
            recognizePlate(caminhoSaida);

        % Armazena os resultados.
        textosReconhecidos(indice) = textoNormalizado;
        textosOriginaisOCR(indice) = textoBruto;

        fprintf('%2d/%2d | ID: %4d | %s | OCR: %s\n', ...
            indice, ...
            quantidadePlacas, ...
            selecao.image_id(indice), ...
            nomeArquivo, ...
            textoNormalizado);

    end

    %% 9. Organização dos resultados

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

    %% 10. Salvamento dos resultados

    writetable(resultados, arquivoResultados);

    %% 11. Exibição do resumo

    fprintf('\n========================================\n');
    fprintf(' SISTEMA PROPOSTO CONCLUÍDO\n');
    fprintf('========================================\n');

    fprintf('Placas processadas: %d\n', quantidadePlacas);
    fprintf('Imagens salvas em: %s\n', diretorioE2);
    fprintf('Resultados OCR: %s\n\n', arquivoResultados);

    disp(resultados);

end
