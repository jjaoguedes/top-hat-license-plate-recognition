
function annotateGroundTruth(raizProjeto)
% ANNOTATEGROUNDTRUTH Realiza a anotação manual das placas.
%
% A função apresenta as placas selecionadas e solicita ao
% usuário a transcrição manual dos caracteres identificados.
%
% Cada anotação confirmada é salva no arquivo Ground Truth.
%
% Comandos disponíveis:
%   Enter - Pula a placa atual.
%   ?     - Marca a placa como incerta.
%   q     - Encerra o processo de anotação.
%
% As placas já verificadas são ignoradas automaticamente.
%
% Entrada:
%   raizProjeto - Caminho da pasta principal do projeto.

    %% 1. Definição dos diretórios

    arquivoGroundTruth = fullfile(raizProjeto, ...
        'data', 'ground_truth', 'ground_truth.csv');

    diretorioPlacas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');

    diretorioOriginais = fullfile(raizProjeto, ...
        'data', 'selected', 'images');

    %% 2. Verificação dos arquivos necessários

    if ~isfile(arquivoGroundTruth)
        error(['Arquivo Ground Truth não encontrado. ', ...
            'Execute createGroundTruthTemplate.m primeiro.']);
    end

    if ~isfolder(diretorioPlacas)
        error('Diretório de placas selecionadas não encontrado.');
    end

    if ~isfolder(diretorioOriginais)
        error('Diretório de imagens originais não encontrado.');
    end

    %% 3. Carregamento do Ground Truth

    groundTruth = readtable(arquivoGroundTruth, ...
        'TextType', 'string');

    % Verifica se as colunas necessárias estão disponíveis.
    colunasObrigatorias = { ...
        'image_id', 'file_name', 'plate_text', 'status'};

    if ~all(ismember(colunasObrigatorias, ...
            groundTruth.Properties.VariableNames))

        error('O arquivo Ground Truth possui colunas ausentes.');
    end

    % Garante que as colunas textuais sejam do tipo string.
    groundTruth.file_name = string(groundTruth.file_name);
    groundTruth.plate_text = string(groundTruth.plate_text);
    groundTruth.status = string(groundTruth.status);

    % Ordena as imagens por identificador numérico.
    groundTruth = sortrows(groundTruth, 'image_id');

    quantidadeImagens = height(groundTruth);

    %% 4. Início da anotação

    fprintf('\n========================================\n');
    fprintf(' ANOTAÇÃO MANUAL DAS PLACAS\n');
    fprintf('========================================\n');

    fprintf('Total de imagens: %d\n', quantidadeImagens);

    fprintf('\nComandos disponíveis:\n');
    fprintf(' Enter - Pular placa\n');
    fprintf(' ?     - Marcar como incerta\n');
    fprintf(' q     - Encerrar anotação\n');

    %% 5. Percorrer as placas selecionadas

    for indice = 1:quantidadeImagens

        % Ignora as placas que já foram verificadas.
        if groundTruth.status(indice) == "verified"
            continue;
        end

        nomeArquivo = char(groundTruth.file_name(indice));

        % Define os caminhos das imagens.
        caminhoPlaca = fullfile(diretorioPlacas, nomeArquivo);

        caminhoOriginal = fullfile(diretorioOriginais, nomeArquivo);

        % Verifica se os arquivos existem.
        if ~isfile(caminhoPlaca)
            error('Placa não encontrada: %s', nomeArquivo);
        end

        if ~isfile(caminhoOriginal)
            error('Imagem original não encontrada: %s', ...
                nomeArquivo);
        end

        %% 6. Leitura das imagens

        imagemPlaca = imread(caminhoPlaca);
        imagemOriginal = imread(caminhoOriginal);

        %% 7. Exibição das imagens

        figura = figure(1);
        clf(figura);

        % Exibe a placa recortada.
        subplot(2, 1, 1);

        imshow(imagemPlaca, ...
            'InitialMagnification', 'fit');

        title(sprintf('Placa %d/%d - %s', ...
            indice, quantidadeImagens, nomeArquivo), ...
            'Interpreter', 'none');

        % Exibe a imagem original do automóvel.
        subplot(2, 1, 2);

        imshow(imagemOriginal, ...
            'InitialMagnification', 'fit');

        title('Imagem original do automóvel');

        drawnow;

        %% 8. Solicitação da transcrição

        fprintf('\n----------------------------------------\n');
        fprintf('Imagem %d de %d\n', ...
            indice, quantidadeImagens);

        fprintf('Arquivo: %s\n', nomeArquivo);

        resposta = strtrim(input( ...
            'Caracteres (Enter=pular, ?=incerta, q=sair): ', ...
            's'));

        %% 9. Tratamento dos comandos

        % Encerra o processo.
        if strcmpi(resposta, 'q')
            fprintf('\nAnotação interrompida.\n');
            break;
        end

        % Pula a imagem sem modificar seu registro.
        if isempty(resposta)
            fprintf('Placa ignorada temporariamente.\n');
            continue;
        end

        % Marca a placa como incerta.
        if strcmp(resposta, '?')

            groundTruth.plate_text(indice) = "";
            groundTruth.status(indice) = "uncertain";

        else

            %% 10. Normalização da transcrição

            % Converte os caracteres para maiúsculas.
            resposta = upper(resposta);

            % Remove espaços e hífens.
            resposta = regexprep(resposta, '[\s-]', '');

            %% 11. Validação dos caracteres

            % Aceita somente letras de A a Z e números de 0 a 9.
            padraoValido = '^[A-Z0-9]+$';

            if isempty(regexp(resposta, padraoValido, 'once'))

                fprintf('Transcrição inválida.\n');
                fprintf('Utilize apenas letras e números.\n');

                continue;
            end

            %% 12. Confirmação da transcrição

            fprintf('\nTranscrição informada: %s\n', resposta);

            confirmacao = strtrim(input( ...
                'Confirmar transcrição? [s/N]: ', 's'));

            if ~strcmpi(confirmacao, 's')

                fprintf('Transcrição não confirmada.\n');
                continue;
            end

            % Atualiza os caracteres e o status da placa.
            groundTruth.plate_text(indice) = string(resposta);
            groundTruth.status(indice) = "verified";

        end

        %% 13. Salvamento da anotação

        % Atualiza o arquivo CSV após cada anotação.
        writetable(groundTruth, arquivoGroundTruth);

        fprintf('Anotação salva com sucesso!\n');

    end

    %% 14. Resumo das anotações

    quantidadeVerificadas = sum( ...
        groundTruth.status == "verified");

    quantidadePendentes = sum( ...
        groundTruth.status == "pending");

    quantidadeIncertas = sum( ...
        groundTruth.status == "uncertain");

    fprintf('\n========================================\n');
    fprintf(' RESUMO DAS ANOTAÇÕES\n');
    fprintf('========================================\n');

    fprintf('Verificadas: %d\n', quantidadeVerificadas);
    fprintf('Pendentes:   %d\n', quantidadePendentes);
    fprintf('Incertas:   %d\n', quantidadeIncertas);

    fprintf('Total:      %d\n', quantidadeImagens);

end