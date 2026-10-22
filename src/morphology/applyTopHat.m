
function imagemCorrigida = applyTopHat(imagemOriginal, raio)
% APPLYTOPHAT Corrige a iluminação não uniforme de uma imagem.
%
% A função utiliza a transformação morfológica Top-hat
% para destacar os caracteres escuros das placas.
%
% Etapas:
%   1. Conversão para escala de cinza.
%   2. Inversão das intensidades.
%   3. Aplicação do Top-hat branco.
%   4. Restauração da polaridade dos caracteres.
%
% Entradas:
%   imagemOriginal - Imagem da placa.
%   raio           - Raio do elemento estruturante.
%
% Saída:
%   imagemCorrigida - Imagem após a correção de iluminação.

    %% 1. Configuração dos parâmetros

    if nargin < 2
        raio = 9;
    end

    validateattributes(raio, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    %% 2. Conversão para escala de cinza

    % Se a imagem for RGB, converte para escala de cinza.
    if size(imagemOriginal, 3) == 3
        imagemCinza = rgb2gray(imagemOriginal);
    else
        imagemCinza = imagemOriginal;
    end

    %% 3. Inversão da imagem

    % Transforma caracteres escuros em estruturas claras.
    imagemInvertida = imcomplement(imagemCinza);

    %% 4. Definição do elemento estruturante

    % Utiliza um disco de raio configurável.
    elementoEstruturante = strel('disk', raio);

    %% 5. Aplicação do Top-hat

    % Remove a componente de fundo estimada pela abertura.
    imagemTopHat = imtophat( ...
        imagemInvertida, elementoEstruturante);

    %% 6. Restauração da polaridade

    % Retorna caracteres escuros sobre fundo claro,
    % mantendo uma apresentação adequada ao OCR.
    imagemCorrigida = imcomplement(imagemTopHat);

end