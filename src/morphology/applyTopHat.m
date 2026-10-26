
function [imagemCorrigida, imagemTopHat] = applyTopHat(imagemOriginal, raio)
% APPLYTOPHAT Aplica o Black Top-hat em uma imagem.
%
% A função utiliza a transformação morfológica Black
% Top-hat para atenuar variações de iluminação e
% destacar estruturas escuras sobre fundo claro.
%
% Fundamentação:
% Seção 4.5.2 - Application to the Correction of
% Uneven Illumination, de Pierre Soille.
%
% Etapas:
%   1. Conversão da imagem para escala de cinza.
%   2. Definição do elemento estruturante.
%   3. Aplicação do Black Top-hat.
%   4. Complementação do resultado para utilização no OCR.
%
% Entradas:
%   imagemOriginal - Imagem da placa.
%   raio           - Raio do elemento estruturante.
%
% Saídas:
%   imagemCorrigida - Imagem preparada para o OCR.
%   imagemTopHat    - Resultado da transformação Black Top-hat.

    %% 1. Configuração dos parâmetros

    if nargin < 2
        raio = 9;
    end

    % Verifica se o raio é um número inteiro positivo.
    validateattributes(raio, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    %% 2. Conversão para escala de cinza

    % Converte imagens RGB para escala de cinza.
    if size(imagemOriginal, 3) == 3

        imagemCinza = rgb2gray(imagemOriginal);

    else

        imagemCinza = imagemOriginal;

    end

    %% 3. Definição do elemento estruturante

    % Utiliza um quadrado com tamanho configurável.
    % Converte o raio em um tamanho de lado ímpar.
    tamanhoQuadrado = 2 * raio + 1;

    elementoEstruturante = strel('square', tamanhoQuadrado);    

    %% 4. Aplicação do Black Top-hat

    % O Black Top-hat corresponde à diferença entre
    % o fechamento morfológico e a imagem original.
    %
    % T_b(f) = fechamento(f) - f

    imagemTopHat = imbothat( ...
        imagemCinza, elementoEstruturante);

    %% 5. Preparação da imagem para OCR

    % Inverte o resultado para apresentar os caracteres
    % escuros sobre um fundo claro.
    %
    % Essa operação não faz parte do Black Top-hat:
    % é uma preparação adicional para o OCR.

    imagemCorrigida = imcomplement(imagemTopHat);

end
