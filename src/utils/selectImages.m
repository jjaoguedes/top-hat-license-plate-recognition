
function selecao = selectImages(raizProjeto, quantidade, semente)
% SELECTIMAGES Seleciona pares de imagens para os experimentos.
%
% A função identifica imagens originais que possuem uma placa
% recortada correspondente, seleciona uma quantidade aleatória
% de pares e organiza os arquivos nos diretórios de destino.
%
% A seleção é realizada apenas uma vez. Caso o arquivo CSV
% já exista, a seleção anterior será reutilizada.
%
% Entradas:
%   raizProjeto - Caminho da pasta principal do projeto.
%   quantidade  - Número de pares a selecionar (padrão: 40).
%   semente     - Semente aleatória utilizada (padrão: 42).
%
% Saída:
%   selecao     - Tabela com os identificadores, nomes dos
%                 arquivos e semente utilizada.

    %% 1. Configuração dos parâmetros

    if nargin < 2
        quantidade = 40;
    end

    if nargin < 3
        semente = 42;
    end

    % Valida os parâmetros informados.
    validateattributes(quantidade, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(semente, {'numeric'}, ...
        {'scalar', 'integer', 'nonnegative'});

    %% 2. Definição dos diretórios

    diretorioOriginais = fullfile(raizProjeto, ...
        'data', 'raw', 'cars_markus', 'image');

    diretorioPlacas = fullfile(raizProjeto, ...
        'data', 'raw', 'cars_markus', 'image_plate');

    diretorioSelecionadas = fullfile(raizProjeto, ...
        'data', 'selected', 'images');

    diretorioPlacasSelecionadas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');

    %% 3. Verificação dos diretórios de origem

    if ~isfolder(diretorioOriginais)
        error('Diretório de imagens originais não encontrado.');
    end

    if ~isfolder(diretorioPlacas)
        error('Diretório de placas recortadas não encontrado.');
    end

    %% 4. Identificação dos arquivos

    % Lista os arquivos JPG das imagens e das placas.
    arquivosOriginais = dir(fullfile( ...
        diretorioOriginais, '*.jpg'));

    arquivosPlacas = dir(fullfile( ...
        diretorioPlacas, '*.jpg'));

    % Obtém os nomes dos arquivos.
    nomesOriginais = string({arquivosOriginais.name})';
    nomesPlacas = string({arquivosPlacas.name})';

    % Define o padrão esperado: image_0001.jpg
    padraoNome = '^image_\d{4,}\.jpg$';

    % Mantém somente os arquivos com nomes válidos.
    nomesOriginais = nomesOriginais( ...
        ~cellfun('isempty', regexp( ...
        cellstr(nomesOriginais), padraoNome, 'once')));

    nomesPlacas = nomesPlacas( ...
        ~cellfun('isempty', regexp( ...
        cellstr(nomesPlacas), padraoNome, 'once')));

    %% 5. Identificação dos pares válidos

    % Encontra os nomes presentes nos dois diretórios.
    paresValidos = intersect(nomesOriginais, nomesPlacas);

    % Verifica se existem imagens suficientes.
    if numel(paresValidos) < quantidade
        error('Existem apenas %d pares válidos. Necessários: %d.', ...
            numel(paresValidos), quantidade);
    end

    % Extrai os identificadores numéricos dos arquivos.
    ids = str2double(erase(erase( ...
        paresValidos, 'image_'), '.jpg'));

    % Organiza os pares por identificador crescente.
    [~, ordem] = sort(ids);
    paresValidos = paresValidos(ordem);

    %% 6. Verificação de seleção anterior

    if isfile(arquivoSelecao)

        % Carrega a seleção já registrada.
        selecao = readtable(arquivoSelecao, ...
            'TextType', 'string');

        % Verifica a quantidade de registros.
        if height(selecao) ~= quantidade
            error('A seleção existente possui %d registros.', ...
                height(selecao));
        end

        % Confirma que os arquivos continuam na base original.
        if ~all(ismember(selecao.file_name, paresValidos))
            error('A seleção contém arquivos sem pares válidos.');
        end

        % Verifica se os arquivos selecionados estão disponíveis.
        for indice = 1:height(selecao)

            nomeArquivo = char(selecao.file_name(indice));

            caminhoImagem = fullfile( ...
                diretorioSelecionadas, nomeArquivo);

            caminhoPlaca = fullfile( ...
                diretorioPlacasSelecionadas, nomeArquivo);

            if ~isfile(caminhoImagem) || ~isfile(caminhoPlaca)
                error('Arquivo selecionado ausente: %s', ...
                    nomeArquivo);
            end
        end

        fprintf('\nSeleção anterior reutilizada.\n');
        disp(selecao);

        return;
    end

    %% 7. Proteção contra seleção parcial

    % Impede uma nova seleção quando já existem imagens
    % copiadas, mas o arquivo CSV não está disponível.

    if isfolder(diretorioSelecionadas)

        arquivosExistentes = dir(fullfile( ...
            diretorioSelecionadas, '*.jpg'));

        if ~isempty(arquivosExistentes)
            error(['Existem imagens selecionadas sem CSV. ', ...
                'Verifique os arquivos antes de continuar.']);
        end
    end

    if isfolder(diretorioPlacasSelecionadas)

        arquivosExistentes = dir(fullfile( ...
            diretorioPlacasSelecionadas, '*.jpg'));

        if ~isempty(arquivosExistentes)
            error(['Existem placas selecionadas sem CSV. ', ...
                'Verifique os arquivos antes de continuar.']);
        end
    end

    %% 8. Seleção aleatória

    % Preserva o estado atual do gerador aleatório.
    estadoAnterior = rng;

    % Define a semente para reproduzir a seleção.
    rng(semente, 'twister');

    % Sorteia os índices sem repetição.
    indicesSorteados = randperm( ...
        numel(paresValidos), quantidade);

    % Recupera o estado anterior do gerador.
    rng(estadoAnterior);

    % Obtém os nomes dos arquivos sorteados.
    nomesSelecionados = paresValidos(indicesSorteados);

    %% 9. Ordenação dos arquivos selecionados

    idsSelecionados = str2double(erase(erase( ...
        nomesSelecionados, 'image_'), '.jpg'));

    [idsSelecionados, ordem] = sort(idsSelecionados);

    nomesSelecionados = nomesSelecionados(ordem);

    %% 10. Criação dos diretórios de destino

    if ~isfolder(diretorioSelecionadas)
        mkdir(diretorioSelecionadas);
    end

    if ~isfolder(diretorioPlacasSelecionadas)
        mkdir(diretorioPlacasSelecionadas);
    end

    %% 11. Cópia dos pares selecionados

    for indice = 1:quantidade

        nomeArquivo = char(nomesSelecionados(indice));

        % Define os caminhos dos arquivos originais.
        origemImagem = fullfile( ...
            diretorioOriginais, nomeArquivo);

        origemPlaca = fullfile( ...
            diretorioPlacas, nomeArquivo);

        % Define os caminhos de destino.
        destinoImagem = fullfile( ...
            diretorioSelecionadas, nomeArquivo);

        destinoPlaca = fullfile( ...
            diretorioPlacasSelecionadas, nomeArquivo);

        % Copia a imagem original.
        [sucesso, mensagem] = copyfile( ...
            origemImagem, destinoImagem);

        if ~sucesso
            error('Erro ao copiar imagem: %s', mensagem);
        end

        % Copia a placa correspondente.
        [sucesso, mensagem] = copyfile( ...
            origemPlaca, destinoPlaca);

        if ~sucesso
            error('Erro ao copiar placa: %s', mensagem);
        end
    end

    %% 12. Registro da seleção

    selecao = table( ...
        idsSelecionados(:), ...
        nomesSelecionados(:), ...
        repmat(semente, quantidade, 1), ...
        'VariableNames', { ...
        'image_id', 'file_name', 'selection_seed'});

    % Salva os dados para utilização nos experimentos.
    writetable(selecao, arquivoSelecao);

    %% 13. Exibição dos resultados

    fprintf('\nSeleção concluída com sucesso!\n');
    fprintf('Total de pares: %d\n', quantidade);
    fprintf('Semente utilizada: %d\n\n', semente);

    disp(selecao);

end
