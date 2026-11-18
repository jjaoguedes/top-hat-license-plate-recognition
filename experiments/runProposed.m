function resultados = runProposed(raizProjeto, SE, raio)
% RUNPROPOSED Executa o sistema proposto com Black Top-hat.
%
% Aplica a correção de iluminação nas placas selecionadas, executa o OCR,
% salva as imagens processadas e registra a saída exibida em um CSV.
%
% Entradas:
%   raizProjeto - Caminho da pasta principal do projeto.
%   SE          - Formato do elemento estruturante (padrão: 'disk').
%   raio        - Raio do elemento estruturante (padrão: 25).
%
% Saída:
%   resultados  - Tabela com os textos brutos retornados pelo OCR.

    if nargin < 2 || isempty(SE)
        SE = 'disk';
    end

    if nargin < 3 || isempty(raio)
        raio = 51;
    end

    arquivoSelecao = fullfile(raizProjeto, ...
        'data', 'selected', 'selected_images.csv');
    diretorioPlacas = fullfile(raizProjeto, ...
        'data', 'selected', 'plates');
    diretorioE2 = fullfile(raizProjeto, 'data', 'e2');
    diretorioResultados = fullfile(raizProjeto, ...
        'results', 'e2_proposed');
    arquivoResultados = fullfile(diretorioResultados, ...
        'ocr_proposed.csv');
    arquivoRelatorio = fullfile(diretorioResultados, ...
        'execution_report.csv');

    if ~isfile(arquivoSelecao)
        error('Arquivo de seleção não encontrado: %s', arquivoSelecao);
    end

    if ~isfolder(diretorioPlacas)
        error('Diretório de placas não encontrado: %s', diretorioPlacas);
    end

    if isfile(arquivoResultados)
        error('Os resultados do sistema proposto já existem: %s', ...
            arquivoResultados);
    end

    if isfile(arquivoRelatorio)
        error('O relatório da execução já existe: %s', arquivoRelatorio);
    end

    selecao = readtable(arquivoSelecao, 'TextType', 'string');
    colunasObrigatorias = {'image_id', 'file_name'};

    if ~all(ismember(colunasObrigatorias, ...
            selecao.Properties.VariableNames))
        error('O arquivo de seleção possui colunas ausentes.');
    end

    selecao = sortrows(selecao, 'image_id');
    quantidadePlacas = height(selecao);

    if quantidadePlacas ~= 40
        error('O experimento deve conter exatamente 40 placas.');
    end

    for indice = 1:quantidadePlacas
        nomeArquivo = char(selecao.file_name(indice));
        caminhoEntrada = fullfile(diretorioPlacas, nomeArquivo);
        caminhoSaida = fullfile(diretorioE2, nomeArquivo);

        if ~isfile(caminhoEntrada)
            error('Placa não encontrada: %s', nomeArquivo);
        end

        if isfile(caminhoSaida)
            error('Imagem processada já existe: %s', caminhoSaida);
        end
    end

    if ~isfolder(diretorioE2)
        mkdir(diretorioE2);
    end

    if ~isfolder(diretorioResultados)
        mkdir(diretorioResultados);
    end

    textosOriginaisOCR = strings(quantidadePlacas, 1);
    relatorio = table( ...
        zeros(0, 1), strings(0, 1), nan(0, 1), ...
        strings(0, 1), strings(0, 1), strings(0, 1), ...
        'VariableNames', { ...
            'sequence', 'event_type', 'image_id', ...
            'file_name', 'raw_ocr_text', 'console_output'});

    relatorio = registrarSaida(relatorio, "cabecalho", NaN, "", "", ...
        "========================================");
    relatorio = registrarSaida(relatorio, "cabecalho", NaN, "", "", ...
        " SISTEMA E2 PROPOSTO - BLACK TOP-HAT");
    relatorio = registrarSaida(relatorio, "cabecalho", NaN, "", "", ...
        "========================================");
    relatorio = registrarSaida(relatorio, "parametro", NaN, "", "", ...
        sprintf('Total de placas: %d', quantidadePlacas));
    relatorio = registrarSaida(relatorio, "parametro", NaN, "", "", ...
        sprintf('Elemento estruturante: %s', char(string(SE))));
    relatorio = registrarSaida(relatorio, "parametro", NaN, "", "", ...
        sprintf('Raio do elemento estruturante: %d', raio));
    relatorio = registrarSaida(relatorio, "formatacao", NaN, "", "", "");

    for indice = 1:quantidadePlacas
        nomeArquivo = char(selecao.file_name(indice));
        caminhoPlaca = fullfile(diretorioPlacas, nomeArquivo);
        caminhoProcessado = fullfile(diretorioE2, nomeArquivo);

        % Executa o OCR na placa original e obtém a imagem processada para
        % salvá-la em data/e2 sem aplicar o Top-hat novamente.
        [textoBruto, imagemProcessada] = recognizePlate( ...
            caminhoPlaca, 'e2', SE, raio);
        imwrite(imagemProcessada, caminhoProcessado);

        % Armazena os resultados do reconhecimento.
        textosOriginaisOCR(indice) = textoBruto;

        linhaConsole = sprintf( ...
            '%2d/%2d | ID: %4d | %s | OCR: %s', ...
            indice, quantidadePlacas, ...
            selecao.image_id(indice), nomeArquivo, textoBruto);

        relatorio = registrarSaida(relatorio, "placa", ...
            selecao.image_id(indice), nomeArquivo, textoBruto, ...
            linhaConsole);
    end

    resultados = table( ...
        selecao.image_id, ...
        selecao.file_name, ...
        textosOriginaisOCR, ...
        'VariableNames', { ...
            'image_id', 'file_name', 'raw_ocr_text'});

    writetable(resultados, arquivoResultados);

    relatorio = registrarSaida(relatorio, "formatacao", NaN, "", "", "");
    relatorio = registrarSaida(relatorio, "resumo", NaN, "", "", ...
        "========================================");
    relatorio = registrarSaida(relatorio, "resumo", NaN, "", "", ...
        " SISTEMA E2 PROPOSTO CONCLUÍDO");
    relatorio = registrarSaida(relatorio, "resumo", NaN, "", "", ...
        "========================================");
    relatorio = registrarSaida(relatorio, "resumo", NaN, "", "", ...
        sprintf('Placas processadas: %d', quantidadePlacas));
    relatorio = registrarSaida(relatorio, "caminho", NaN, "", "", ...
        sprintf('Imagens salvas em: %s', diretorioE2));
    relatorio = registrarSaida(relatorio, "caminho", NaN, "", "", ...
        sprintf('Resultados OCR: %s', arquivoResultados));
    relatorio = registrarSaida(relatorio, "caminho", NaN, "", "", ...
        sprintf('Relatório da execução: %s', arquivoRelatorio));

    textoTabela = evalc('disp(resultados);');
    relatorio = registrarSaida(relatorio, "formatacao", NaN, "", "", "");
    fprintf('%s', textoTabela);
    linhasTabela = splitlines(string(textoTabela));

    for indice = 1:numel(linhasTabela)
        if strlength(linhasTabela(indice)) > 0
            relatorio = adicionarLinhaRelatorio(relatorio, ...
                "tabela_resultados", NaN, "", "", ...
                linhasTabela(indice));
        end
    end

    writetable(relatorio, arquivoRelatorio);
end

function relatorio = registrarSaida( ...
        relatorio, tipoEvento, imageId, fileName, textoOCR, mensagem)

    mensagem = string(mensagem);
    fprintf('%s\n', char(mensagem));
    relatorio = adicionarLinhaRelatorio( ...
        relatorio, tipoEvento, imageId, fileName, textoOCR, mensagem);
end

function relatorio = adicionarLinhaRelatorio( ...
        relatorio, tipoEvento, imageId, fileName, textoOCR, mensagem)

    linha = table( ...
        height(relatorio) + 1, string(tipoEvento), imageId, ...
        campoCSV(fileName), campoCSV(textoOCR), campoCSV(mensagem), ...
        'VariableNames', relatorio.Properties.VariableNames);
    relatorio = [relatorio; linha];
end

function valor = campoCSV(valor)

    valor = string(valor);
    valor = replace(valor, string(char(13)), "");
    valor = replace(valor, newline, "\n");
end
