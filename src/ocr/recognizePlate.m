function [textoNormalizado, textoBruto] = recognizePlate(caminhoImagem)
% RECOGNIZEPLATE Reconhece caracteres de uma placa veicular.
%
% Fluxo comum aos sistemas e1 e e2:
%   1. Leitura da placa.
%   2. Extracao de ROI proporcional.
%   3. OCR com linha unica e caracteres alfanumericos.
%   4. Normalizacao do texto.
%
% Entrada:
%   caminhoImagem - Caminho da imagem (original ou com Top-hat).
%
% Saidas:
%   textoNormalizado - Letras maiusculas e digitos, sem separadores.
%   textoBruto       - Texto retornado pelo OCR sem normalizacao.
%
% Observacao: a ROI deve ser a mesma para e1 e e2. A funcao
% extractPlateROI deve estar disponivel no caminho do MATLAB.

    if ~(ischar(caminhoImagem) || ...
            (isstring(caminhoImagem) && isscalar(caminhoImagem)))
        error('recognizePlate:CaminhoInvalido', ...
            'Informe o caminho da imagem como texto.');
    end

    if ~isfile(caminhoImagem)
        error('recognizePlate:ArquivoNaoEncontrado', ...
            'Imagem nao encontrada: %s', char(caminhoImagem));
    end

    %% 1. Leitura da imagem
    imagemOriginal = imread(caminhoImagem);

    %% 2. Regiao de interesse (comum a e1 e e2)
    imagemROI = extractPlateROI(imagemOriginal);

    %% 3. Reconhecimento optico dos caracteres
    caracteresPermitidos = ...
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    resultadoOCR = ocr(imagemROI, ...
        'LayoutAnalysis', 'line', ...
        'CharacterSet', caracteresPermitidos);

    %% 4. Texto bruto e normalizacao
    textoBruto = string(resultadoOCR.Text);
    textoNormalizado = upper(regexprep( ...
        textoBruto, '[^A-Za-z0-9]', ''));
end
