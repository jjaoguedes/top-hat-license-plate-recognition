# Top-hat for License Plate Recognition

Mini projeto acadêmico desenvolvido em MATLAB, com foco na aplicação de operações morfológicas Top-hat para o processamento de imagens de placas de automóveis e avaliação do desempenho de reconhecimento óptico de caracteres (OCR).

## 1. Contextualização

O reconhecimento automático de placas de veículos (*Automatic License Plate Recognition* — ALPR) envolve etapas de detecção, processamento e reconhecimento dos caracteres presentes nas placas.

Entretanto, fatores como iluminação não uniforme e baixo contraste podem comprometer o desempenho do reconhecimento óptico de caracteres.

Neste projeto, investiga-se a aplicação do operador morfológico Top-hat como técnica de processamento de imagens para reduzir essas limitações.

## 2. Objetivo

Desenvolver e avaliar um sistema de processamento de imagens baseado no operador Top-hat, comparando seu desempenho com um sistema de referência (*baseline*) no reconhecimento de caracteres de placas de automóveis.

### Objetivos específicos

- Selecionar aleatoriamente 40 imagens da base disponibilizada.
- Construir os *ground truths* das placas selecionadas.
- Implementar o sistema de referência utilizando OCR.
- Implementar o sistema proposto utilizando Top-hat e OCR.
- Avaliar o desempenho de ambos os sistemas.
- Comparar quantitativamente e discutir os resultados obtidos.

## 3. Fundamentação teórica

O projeto fundamenta-se nos conceitos de Morfologia Matemática, com ênfase no operador morfológico Top-hat, utilizado no processamento de imagens para destacar estruturas e corrigir variações de iluminação.

A abordagem adotada corresponde à Seção 4.5.2 — Application to the Correction of Uneven Illumination (Aplicação à Correção de Iluminação Não Uniforme), apresentada por Pierre Soille em Morphological Image Analysis: Principles and Applications.

O objetivo dessa abordagem é reduzir os efeitos da iluminação não uniforme nas imagens das placas de automóveis, buscando melhorar a visibilidade dos caracteres e, consequentemente, o desempenho do reconhecimento óptico de caracteres (OCR).

A implementação será realizada em MATLAB, utilizando operações morfológicas e avaliando seus resultados em comparação com o sistema de referência (baseline).

## 4. Tecnologias

- MATLAB
- Image Processing Toolbox
- Computer Vision Toolbox
- Git e GitHub

## 5. Organização do projeto

| Diretório | Descrição |
|---|---|
| `data/` | Base de imagens e ground truths |
| `src/` | Funções MATLAB |
| `experiments/` | Scripts dos experimentos |
| `results/` | Imagens processadas, métricas e gráficos |
| `docs/` | Metodologia e relatório |
| `main.m` | Ponto de entrada do projeto |

## 6. Metodologia experimental

O projeto será dividido nas seguintes etapas:

1. Preparação e inspeção da base de dados.
2. Seleção reprodutível de 40 imagens.
3. Construção manual dos ground truths.
4. Implementação e execução do baseline.
5. Implementação e execução do sistema Top-hat.
6. Avaliação quantitativa dos resultados.
7. Elaboração do relatório final.

Os dois sistemas utilizarão o mesmo conjunto de imagens e o mesmo procedimento de reconhecimento OCR.

## 7. Avaliação

A avaliação considerará a correspondência entre os caracteres reconhecidos pelo OCR e os respectivos ground truths.

Serão investigadas métricas como:

- Acurácia de reconhecimento completo das placas.
- Taxa de erro de caracteres (CER).
- Quantidade de placas reconhecidas corretamente.

## 8. Referências

- SOILLE, Pierre. *Morphological Image Analysis: Principles and Applications*.
- MathWorks. [Recognize Text Using Optical Character Recognition (OCR)](https://www.mathworks.com/help/vision/ug/recognize-text-using-optical-character-recognition-ocr.html).
- UFPR — [Layout-Independent ALPR](https://web.inf.ufpr.br/vri/publications/layout-independent-alpr/).

## 9. Créditos

As imagens e as placas previamente detectadas foram disponibilizadas para fins acadêmicos.

A etapa de detecção de placas foi realizada por Anderson Souza, do PPGEE/UFAM, conforme os créditos fornecidos pelo professor.
