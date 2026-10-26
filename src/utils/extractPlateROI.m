function [imagemROI, coordenadas] = extractPlateROI(imagem)
% EXTRACTPLATEROI Extrai a região principal de caracteres da placa.
%
% Entrada:
%   imagem - Imagem da placa (RGB ou escala de cinza).
%
% Saidas:
%   imagemROI   - Regiao da imagem destinada ao OCR.
%   coordenadas - Limites inclusivos do recorte em pixels.
%
% Os percentuais abaixo sao exploratorios. Verificar
% visualmente nas 40 placas se nenhum caractere e cortado.

    validateattributes(imagem, {'numeric', 'logical'}, ...
        {'nonempty'}, mfilename, 'imagem', 1);

    [altura, largura, ~] = size(imagem);

    % Percentuais definidos para a etapa exploratoria.
    proporcaoEsquerda = 0.06;
    proporcaoDireita = 0.95;
    proporcaoSuperior = 0.32;
    proporcaoInferior = 0.90;

    % Limites, adaptados a cada resolucao.
    xInicial = max(1, min(largura, round(proporcaoEsquerda * largura)));
    xFinal = max(1, min(largura, round(proporcaoDireita * largura)));
    yInicial = max(1, min(altura, round(proporcaoSuperior * altura)));
    yFinal = max(1, min(altura, round(proporcaoInferior * altura)));

    if xInicial >= xFinal || yInicial >= yFinal
        error('extractPlateROI:RegiaoInvalida', ...
            'A imagem e pequena demais para a ROI configurada.');
    end

    imagemROI = imagem(yInicial:yFinal, xInicial:xFinal, :);

    coordenadas = struct( ...
        'xInicial', xInicial, 'xFinal', xFinal, ...
        'yInicial', yInicial, 'yFinal', yFinal);
end
