function analise = analyzePlateDimensions(raizProjeto)
% ANALYZEPLATEDIMENSIONS Analisa as dimensões das placas.
%
% A função examina as imagens recortadas selecionadas,
% calcula estatísticas de largura e altura e recomenda
% parâmetros iniciais para o elemento estruturante.
%
% A recomendação considera a altura média das placas
% e utiliza um elemento estruturante quadrado, seguindo
% a abordagem ilustrada na Figura 4.18 de Pierre Soille.
%
% A recomendação é geométrica e deve ser validada
% posteriormente por meio dos resultados do OCR.
%
% Entrada:
%   raizProjeto - Caminho da pasta principal do projeto.
%
% Saída:
%   analise - Estrutura contendo as dimensões,
%             estatísticas e parâmetros recomendados.


    %% 1. Definição dos caminhos

    diretorioPlacas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');

    diretorioResultados = fullfile(raizProjeto, ...
        'results', 'analysis');


    %% 2. Verificação dos arquivos necessários

    if ~isfolder(diretorioPlacas)
        error('Diretório de placas selecionadas não encontrado.');
    end

    if ~isfile(arquivoSelecao)
        error('Arquivo selected_images.csv não encontrado.');
    end


    %% 3. Carregamento da seleção

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

    quantidadeImagens = height(selecao);

    if quantidadeImagens ~= 40
        error('Esperadas 40 imagens. Encontradas: %d.', ...
            quantidadeImagens);
    end


    %% 4. Preparação das variáveis

    % Reserva espaço para armazenar as dimensões.
    larguras = zeros(quantidadeImagens, 1);

    alturas = zeros(quantidadeImagens, 1);


    %% 5. Leitura das dimensões das imagens

    for indice = 1:quantidadeImagens

        nomeArquivo = char(selecao.file_name(indice));

        caminhoImagem = fullfile( ...
            diretorioPlacas, nomeArquivo);

        % Confirma a existência da imagem.
        if ~isfile(caminhoImagem)
            error('Imagem não encontrada: %s', nomeArquivo);
        end

        % Obtém as propriedades da imagem.
        informacoes = imfinfo(caminhoImagem);

        % Armazena largura e altura em pixels.
        larguras(indice) = informacoes.Width;

        alturas(indice) = informacoes.Height;

    end


    %% 6. Organização das dimensões

    tabelaDimensoes = table( ...
        selecao.image_id, ...
        selecao.file_name, ...
        larguras, ...
        alturas, ...
        'VariableNames', { ...
        'image_id', ...
        'file_name', ...
        'width_pixels', ...
        'height_pixels'});


    %% 7. Cálculo das estatísticas

    % Calcula as dimensões médias.
    larguraMedia = mean(larguras);
    alturaMedia = mean(alturas);

    % Calcula as medianas.
    larguraMediana = median(larguras);
    alturaMediana = median(alturas);

    % Identifica os valores mínimos e máximos.
    larguraMinima = min(larguras);
    larguraMaxima = max(larguras);

    alturaMinima = min(alturas);
    alturaMaxima = max(alturas);

    % Calcula os desvios-padrão.
    desvioLargura = std(larguras);
    desvioAltura = std(alturas);


    %% 8. Recomendação do elemento estruturante

    % A Figura 4.18 utiliza um elemento quadrado grande.
    %
    % Como ponto inicial, considera-se um quadrado com
    % lado equivalente a aproximadamente 80% da
    % altura média das placas.
    %
    % Esse percentual é uma heurística experimental
    % e não representa um parâmetro ótimo comprovado.

    proporcaoRecomendada = 0.80;

    % Calcula o tamanho aproximado do quadrado.
    tamanhoEstimado = ...
        alturaMedia * proporcaoRecomendada;

    % Arredonda para um tamanho ímpar.
    tamanhoQuadrado = ...
        2 * round((tamanhoEstimado - 1) / 2) + 1;

    % Garante tamanho mínimo válido.
    tamanhoQuadrado = max(3, tamanhoQuadrado);

    % Raio de um disco com diâmetro nominal semelhante.
    raioEquivalente = (tamanhoQuadrado - 1) / 2;


    %% 9. Configurações alternativas

    % Define proporções exploratórias da altura média.
    proporcoes = [0.60; 0.80; 1.00];

    tamanhosAlternativos = ...
        2 * round((alturaMedia * proporcoes - 1) / 2) + 1;

    tamanhosAlternativos = max(3, tamanhosAlternativos);

    raiosEquivalentes = ...
        (tamanhosAlternativos - 1) / 2;

    tabelaRecomendacoes = table( ...
        proporcoes * 100, ...
        tamanhosAlternativos, ...
        raiosEquivalentes, ...
        'VariableNames', { ...
        'height_percentage', ...
        'square_size', ...
        'equivalent_disk_radius'});


    %% 10. Organização dos resultados

    analise = struct();

    % Dados individuais.
    analise.dimensoes = tabelaDimensoes;

    % Estatísticas.
    analise.larguraMedia = larguraMedia;
    analise.alturaMedia = alturaMedia;

    analise.larguraMediana = larguraMediana;
    analise.alturaMediana = alturaMediana;

    analise.larguraMinima = larguraMinima;
    analise.larguraMaxima = larguraMaxima;

    analise.alturaMinima = alturaMinima;
    analise.alturaMaxima = alturaMaxima;

    analise.desvioLargura = desvioLargura;
    analise.desvioAltura = desvioAltura;

    % Recomendações.
    analise.elementoRecomendado = "square";
    analise.tamanhoQuadrado = tamanhoQuadrado;
    analise.raioEquivalente = raioEquivalente;

    analise.recomendacoes = tabelaRecomendacoes;


    %% 11. Exibição das dimensões

    fprintf('\n========================================\n');
    fprintf(' ANÁLISE DAS DIMENSÕES DAS PLACAS\n');
    fprintf('========================================\n');

    fprintf('Total de imagens: %d\n\n', quantidadeImagens);

    disp(tabelaDimensoes);


    %% 12. Exibição das estatísticas

    fprintf('\n========================================\n');
    fprintf(' ESTATÍSTICAS DAS IMAGENS\n');
    fprintf('========================================\n');

    fprintf('Largura média: %.2f pixels\n', larguraMedia);
    fprintf('Altura média: %.2f pixels\n', alturaMedia);

    fprintf('\nLargura mediana: %.2f pixels\n', ...
        larguraMediana);

    fprintf('Altura mediana: %.2f pixels\n', ...
        alturaMediana);

    fprintf('\nLargura mínima: %d pixels\n', ...
        larguraMinima);

    fprintf('Largura máxima: %d pixels\n', ...
        larguraMaxima);

    fprintf('Altura mínima: %d pixels\n', ...
        alturaMinima);

    fprintf('Altura máxima: %d pixels\n', ...
        alturaMaxima);

    fprintf('\nDesvio-padrão da largura: %.2f pixels\n', ...
        desvioLargura);

    fprintf('Desvio-padrão da altura: %.2f pixels\n', ...
        desvioAltura);


    %% 13. Exibição das recomendações

    fprintf('\n========================================\n');
    fprintf(' RECOMENDAÇÃO DO ELEMENTO ESTRUTURANTE\n');
    fprintf('========================================\n');

    fprintf('Formato inicial recomendado: square\n');

    fprintf('Lado do quadrado: %d pixels\n', ...
        tamanhoQuadrado);

    fprintf('Disco equivalente: raio %d pixels\n', ...
        raioEquivalente);

    fprintf('\nParâmetros alternativos para investigação:\n');

    disp(tabelaRecomendacoes);

    fprintf(['\nATENÇÃO: a recomendação considera apenas ', ...
        'as dimensões das imagens.\n']);

    fprintf(['O melhor parâmetro para OCR deve ser ', ...
        'determinado por validação experimental.\n']);


    %% 14. Salvamento da análise

    % Cria o diretório caso não exista.
    if ~isfolder(diretorioResultados)
        mkdir(diretorioResultados);
    end

    arquivoDimensoes = fullfile(diretorioResultados, ...
        'plate_dimensions.csv');

    arquivoRecomendacoes = fullfile(diretorioResultados, ...
        'structuring_element_recommendations.csv');

    % Impede sobrescrever resultados já existentes.
    if isfile(arquivoDimensoes) || isfile(arquivoRecomendacoes)
        error(['Os arquivos de análise já existem. ', ...
            'Preserve-os antes de realizar outra análise.']);
    end

    % Salva as dimensões individuais.
    writetable(tabelaDimensoes, arquivoDimensoes);

    % Salva os parâmetros recomendados.
    writetable(tabelaRecomendacoes, arquivoRecomendacoes);

    fprintf('\nArquivos gerados com sucesso:\n');
    fprintf('%s\n', arquivoDimensoes);
    fprintf('%s\n', arquivoRecomendacoes);

end