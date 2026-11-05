
function [textoNormalizado, textoBruto] = recognizePlate(caminhoImagem)
% RECOGNIZEPLATE Reconhece caracteres de placas veiculares.
%
% A funcao executa OCR diretamente na imagem recebida,
% sem aplicar ROI ou transformacoes morfologicas.
%
% Esta funcao e compartilhada pelos sistemas:
% e1 - Placa original -> OCR.
% e2 - Placa com Top-hat -> OCR.
%
% Entradas:
% caminhoImagem - Caminho completo da imagem da placa.
%
% Saidas:
% textoNormalizado - Texto contendo apenas letras e numeros.
% textoBruto - Texto original retornado pelo OCR.


%% 1. Leitura da imagem

if ~isfile(caminhoImagem)
    error('Imagem nao encontrada: %s', caminhoImagem);
end

imagemOriginal = imread(caminhoImagem);


%% 2. Configuracao do OCR

caracteresPermitidos = ...
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';


%% 3. Reconhecimento dos caracteres

% Executa OCR diretamente sobre a imagem completa.
% Nenhuma ROI e aplicada nesta funcao.

resultadoOCR = ocr(imagemOriginal, ...
    'LayoutAnalysis', 'line', ...
    'CharacterSet', caracteresPermitidos);


%% 4. Recuperacao do texto

textoBruto = string(resultadoOCR.Text);


%% 5. Normalizacao do reconhecimento

% Remove espacos, quebras de linha e caracteres especiais.
textoNormalizado = upper(regexprep( ...
    textoBruto, '[^A-Za-z0-9]', ''));

end