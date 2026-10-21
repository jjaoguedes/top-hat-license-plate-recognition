
function [textoPlaca, textoOriginal] = recognizePlate(caminhoImagem)
% RECOGNIZEPLATE Reconhece os caracteres de uma placa veicular.
%
% A função recebe o caminho de uma imagem, executa o OCR
% do MATLAB e retorna o texto reconhecido.
%
% A configuração do OCR deve ser a mesma para os sistemas
% baseline e Top-hat, garantindo uma comparação justa.
%
% Entrada:
%   caminhoImagem - Caminho da imagem da placa.
%
% Saídas:
%   textoPlaca    - Texto normalizado, contendo apenas
%                   letras maiúsculas e números.
%   textoOriginal - Texto bruto retornado pelo OCR.

    %% 1. Validação do arquivo

    % Verifica se a imagem informada existe.
    if ~isfile(caminhoImagem)
        error('Imagem da placa não encontrada: %s', ...
            char(caminhoImagem));
    end

    %% 2. Leitura da imagem

    % Carrega a imagem da placa selecionada.
    imagemPlaca = imread(caminhoImagem);

    %% 3. Configuração e execução do OCR

    % Define os caracteres permitidos no reconhecimento.
    caracteresPermitidos = ...
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    % Executa o reconhecimento óptico de caracteres.
    % LayoutAnalysis = 'line' considera uma linha de texto.
    resultadoOCR = ocr(imagemPlaca, ...
        'LayoutAnalysis', 'line', ...
        'CharacterSet', caracteresPermitidos);

    %% 4. Armazenamento do texto original

    % Preserva o resultado bruto retornado pelo OCR.
    textoOriginal = string(resultadoOCR.Text);

    %% 5. Normalização do texto

    % Remove espaços, pontuação e caracteres especiais.
    textoPlaca = regexprep(textoOriginal, ...
        '[^A-Za-z0-9]', '');

    % Converte as letras para maiúsculas.
    textoPlaca = upper(textoPlaca);

end
