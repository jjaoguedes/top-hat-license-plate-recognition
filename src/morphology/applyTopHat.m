
function [imagemCorrigida, imagemTopHat] = applyTopHat(imagemOriginal, raio)
% APPLYTOPHAT Aplica o Black Top-hat em uma imagem para correção de iluminação.
%
% A função utiliza a transformação morfológica Black Top-hat para atenuar
% variações de iluminação (gradientes de fundo) e destacar estruturas
% escuras sobre fundos claros, como os caracteres de placas veiculares.
%
% Fundamentação:
% Seção 4.5.2 - Application to the Correction of Uneven Illumination,
% de Pierre Soille.
%
% Etapas:
% 1. Configuração dos parâmetros.
% 2. Conversão da imagem para escala de cinza.
% 3. Definição do elemento estruturante.
% 4. Aplicação manual do Black Top-hat (fechamento - imagem).
% 5. Preparação da imagem para OCR.
%
% Entradas:
% imagemOriginal - Imagem de entrada.
% raio - Parâmetro utilizado para calcular o tamanho do elemento estruturante.
%
% Saídas:
% imagemCorrigida - Imagem preparada para o OCR.
% imagemTopHat - Resultado da transformação Black Top-hat.


%% 1. Configuração dos parâmetros

if nargin < 2
    raio = 9;
end

% Verifica se o parâmetro é um número inteiro positivo.
validateattributes(raio, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});


%% 2. Conversão da imagem para escala de cinza

% Converte imagens RGB para escala de cinza.
if size(imagemOriginal, 3) == 3
    imagemCinza = rgb2gray(imagemOriginal);
else
    imagemCinza = imagemOriginal;
end


%% 3. Definição do elemento estruturante

% Utiliza um elemento estruturante quadrado.
% O lado do quadrado é calculado por 2*raio + 1.
tamanhoQuadrado = 2 * raio + 1;

elementoEstruturante = strel('square', tamanhoQuadrado);


%% 4. Aplicação manual do Black Top-hat

% O Black Top-hat é dado pela diferença entre o fechamento
% morfológico da imagem e a imagem original:
%
% T_b(f) = phi_B(f) - f
%
% Em que:
% f        - Imagem original em escala de cinza.
% phi_B(f) - Fechamento morfológico da imagem.
% B        - Elemento estruturante.
%
% 4.1 Fechamento morfológico:
% Atenua estruturas escuras menores que o elemento
% estruturante, produzindo uma estimativa do fundo.

imagemFechamento = imclose( ...
    imagemCinza, elementoEstruturante);

% O fechamento morfológico corresponde à dilatação
% seguida de erosão pelo mesmo elemento estruturante.
%
% Implementação equivalente:
% imagemFechamento = imerode( ...
%     imdilate(imagemCinza, elementoEstruturante), ...
%     elementoEstruturante);


% 4.2 Subtração da imagem original do fechamento:
% Destaca as estruturas escuras eliminadas ou atenuadas
% pela operação de fechamento morfológico.

imagemTopHat = imsubtract( ...
    imagemFechamento, imagemCinza);


%% 5. Preparação da imagem para OCR

% O Black Top-hat apresenta as estruturas escuras
% destacadas como regiões claras sobre fundo escuro.
%
% Para apresentar os caracteres escuros sobre fundo
% claro, aplica-se o complemento da transformação.
%
% A complementação é uma etapa adicional de
% preparação para OCR, não parte do Black Top-hat.

imagemCorrigida = imcomplement(imagemTopHat);

end
