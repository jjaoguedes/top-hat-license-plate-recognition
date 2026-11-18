function [text, imagemProcessada] = recognizePlate( ...
        caminhoImagem, system, SE, raio)
% RECOGNIZEPLATE Reconhece os caracteres de uma imagem de placa.
%
% O sistema e1 executa OCR na imagem original. O sistema e2 aplica
% Black Top-hat antes do OCR.
%
% Entradas:
%   caminhoImagem - Caminho completo da imagem da placa.
%   system        - Sistema: 'e1' ou 'e2' (padrão: 'e1').
%   SE            - Forma do elemento estruturante (padrão: 'disk').
%   raio          - Raio do elemento estruturante (padrão: 51).
%
% Saídas:
%   text             - Texto bruto retornado pelo OCR.
%   imagemProcessada - Imagem efetivamente enviada ao OCR.

if nargin < 2 || isempty(system)
    system = 'e1';
end

if nargin < 3 || isempty(SE)
    SE = 'disk';
end

if nargin < 4 || isempty(raio)
    raio = 51;
end

if ~isfile(caminhoImagem)
    error('recognizePlate:ImagemNaoEncontrada', ...
        'Imagem não encontrada: %s', caminhoImagem);
end

imagemOriginal = im2gray(imread(caminhoImagem));

switch lower(char(string(system)))
    case 'e1'
        imagemProcessada = imagemOriginal;

    case 'e2'
        imagemProcessada = applyTopHat(imagemOriginal, SE, raio);

    otherwise
        error('recognizePlate:SistemaInvalido', ...
            'Sistema deve ser ''e1'' ou ''e2''.');
end

resultado = ocr(imagemProcessada, ...
    'LayoutAnalysis', 'Block', ...
    'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
text = string(resultado.Text);
end
