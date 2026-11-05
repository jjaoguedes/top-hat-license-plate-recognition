# Relatório do mini-projeto — sistema Top-hat para reconhecimento de placas

## Escopo e disponibilidade dos materiais

Este relatório organiza o trabalho conforme as quatro partes da especificação do mini-projeto: base de dados, objetivo, desenvolvimento MATLAB e análise dos resultados. A especificação do professor foi fornecida na solicitação. O arquivo `mini-projeto-lp.pdf` não está disponível no workspace; portanto, a descrição dos slides e das figuras abaixo se limita ao resumo fornecido, sem afirmar que o conteúdo do PDF foi verificado diretamente.

## Parte 1 — Base de dados

### 1.1 Imagens e saídas do detector

O arquivo de descrição local da base informa que o conjunto original contém 126 imagens JPEG de automóveis vistos pela traseira, com resolução de 896 × 592 pixels, obtidas em estacionamentos do Caltech. A descrição atribui a base a Markus Weber e identifica R. Fergus, com data de 4 de outubro de 2003. Essa informação descreve a base de imagens; o detector de placas usado no mini-projeto é uma etapa distinta.

Conforme a especificação fornecida pelo professor, as placas detectadas foram disponibilizadas previamente para que o trabalho se concentrasse no subbloco de processamento Top-hat, em vez de reimplementar o detector. O método de detecção indicado é o *Layout-Independent ALPR*, da UFPR, e os créditos do resultado disponibilizado são atribuídos a Anderson Souza, do PPGEE/UFAM:

- UFPR, [Layout-Independent ALPR](https://web.inf.ufpr.br/vri/publications/layout-independent-alpr/).

No workspace estão disponíveis 126 arquivos em cada uma das pastas `data/raw/cars_markus/image/`, `data/raw/cars_markus/image_car/` e `data/raw/cars_markus/image_plate/`. A pasta `images_plate_mark`, mencionada na especificação, não foi encontrada localmente. O arquivo compactado `cars.rar` também não está presente.

De acordo com a descrição do professor, `image` contém as imagens fornecidas, `image_car` contém imagens após a etapa de detecção, `images_plate_mark` contém imagens anotadas visualmente com retângulos verdes e `images_plate` contém os recortes das placas. A existência de cada conjunto descrito pelo professor não implica que todos estejam disponíveis nesta cópia local.

### 1.2 Seleção experimental e Ground Truth

O projeto registra 40 pares selecionados em `data/selected/selected_images.csv`, com semente 42. Os nomes de arquivo mantêm o pareamento entre as imagens de origem e os recortes de placa. O Ground Truth local contém 40 registros marcados como verificados. A função de seleção reutiliza a seleção registrada, em vez de sorteá-la novamente quando o CSV já existe.

A comparação dos sistemas usa os mesmos recortes e o mesmo Ground Truth. Como as imagens de placas e as transcrições podem ser privadas, este relatório não reproduz imagens, nomes associados às transcrições ou textos de placas. Antes de publicar o repositório, confirme que imagens de placas e Ground Truth privado não estão incluídos no conjunto público.

## Parte 2 — Objetivo e problema

O problema proposto é a degradação do OCR em imagens de placas com baixo contraste ou iluminação não uniforme. Segundo a descrição fornecida do slide 1, o sistema de referência pode falhar e produzir a condição “not recognized”. Como o PDF não está no workspace, essa condição é tratada aqui como a motivação da especificação, e não como uma citação verificada do slide.

O objetivo do sistema proposto é aplicar processamento morfológico à saída do detector antes do OCR, buscando atenuar o efeito da iluminação e tornar os caracteres mais reconhecíveis. O detector é tratado como uma etapa já executada; o projeto avalia o processamento e o OCR sobre imagens de placas previamente recortadas.

## Parte 3 — Pesquisa e desenvolvimento em MATLAB

### 3.1 Escolha e implementação do operador

O código do projeto declara como referência a Seção 4.5.2 de Soille, dedicada à correção de iluminação não uniforme. Assim, a implementação corresponde à escolha de uma das alternativas pedidas, e não à combinação das Seções 4.5.2 e 4.5.3. Como o PDF do mini-projeto não está disponível, não foi possível verificar diretamente a correspondência com a Figura 4.18 nem cotejar a alternativa da Figura 4.21.

Para a imagem em tons de cinza \(f\) e o elemento estruturante \(B\), o código calcula o Black Top-hat:

\[
T_b(f) = (f \bullet B) - f
\]

em que \(f \bullet B\) é o fechamento morfológico. O resultado é complementado para criar a imagem encaminhada ao OCR. A função `src/morphology/applyTopHat.m` usa um elemento estruturante quadrado definido por `strel('square', 2*raio+1)`.

No `main.m`, o valor atual do parâmetro é `raio=51`, que corresponde a um quadrado de 103 × 103 pixels. Já os testes com ROI passam o lado 51 diretamente a `strel`, usando um elemento de 51 × 51 pixels. Os dois parâmetros não são equivalentes. Além disso, os arquivos de configuração dos relatórios históricos indicam `nao_informado` para o elemento e o tamanho; portanto, a configuração atual do código não comprova qual parâmetro gerou cada CSV antigo. Não há evidência de uma execução dos sistemas com elemento estruturante disco.

### 3.2 Sistemas e execução

O fluxo do experimento principal é:

```text
e1 — Baseline: placa recortada selecionada → OCR → comparação com Ground Truth
e2 — Proposto: placa recortada selecionada → escala de cinza, se necessária
                  → Black Top-hat → complemento → OCR
                  → comparação com Ground Truth
```

`experiments/runBaseline.m` e `experiments/runProposed.m` processam as mesmas 40 placas. Ambos chamam `src/ocr/recognizePlate.m`, que usa OCR com `LayoutAnalysis='line'` e caracteres permitidos `A-Z` e `0-9`. O fluxo principal não aplica ROI. A função de recorte `extractPlateROI` aparece nos testes complementares, especialmente em `testAllPlateROIs`, e não nos runners principais.

As imagens de sistema estão disponíveis localmente em `data/e1/` e `data/e2/`, com 40 arquivos em cada pasta. O código do `main.m` cria e valida essas saídas, preservando arquivos já existentes; os resultados OCR e as métricas ficam em `results/`.

### 3.3 Ground Truth e avaliação

O Ground Truth é carregado de `data/ground_truth/ground_truth.csv`. `evaluateRecognition` normaliza os textos para letras maiúsculas e caracteres alfanuméricos, conta como acerto somente a correspondência exata da placa completa e calcula a taxa de erro de caracteres pela distância de Levenshtein.

O código armazena CSVs de OCR dos sistemas em `results/baseline/ocr_baseline.csv` e `results/proposed/ocr_proposed.csv`. As imagens processadas são separadas em `data/e1/` e `data/e2/`, atendendo à organização por sistema solicitada. A presença local desses arquivos não significa que devam ser enviados ou publicados caso contenham dados privados.

## Parte 4 — Análise dos resultados

### 4.1 Execução principal, sem ROI

Os CSVs locais de métricas e OCR registram o seguinte resultado para as 40 placas:

| Sistema | Placas corretas | Placas incorretas | Acurácia exata | CER global | OCR vazio |
|---|---:|---:|---:|---:|---:|
| e1 — Baseline, sem ROI | 0/40 | 40/40 | 0,00% | 83,87% | 20 |
| e2 — Black Top-hat, sem ROI | 1/40 | 39/40 | 2,50% | 87,46% | 27 |

O baseline tem resultados OCR vazios em 20 das 40 imagens. Isso é compatível com a motivação de falhas de reconhecimento, mas não permite afirmar que todas as saídas vazias correspondam exatamente à mensagem “not recognized” mencionada na especificação.

### 4.2 Os resultados foram satisfatórios? O sistema proposto foi superior?

Para o conjunto principal, os resultados não são satisfatórios em termos de reconhecimento completo: quase todas as placas foram avaliadas como incorretas em ambos os sistemas. O e2 obteve um acerto exato a mais que o baseline, mas a acurácia exata continua baixa, em 2,50%.

Com a métrica simples de acurácia exata, o e2 supera o baseline por 2,50 pontos percentuais (2,50% contra 0,00%). Porém, essa melhora isolada não basta para concluir superioridade geral. A CER global do e2 é 87,46%, maior que os 83,87% do e1, e o e2 tem mais saídas vazias (27 contra 20). Assim, pelos resultados principais sem ROI, não há evidência consistente de superioridade do sistema proposto: melhora ligeiramente a contagem de placas exatas, mas piora o erro global de caracteres.

Uma confirmação mais robusta deve comparar, nas mesmas imagens e sob a mesma configuração, tanto a acurácia exata quanto a CER. A CER menor indica menos edições necessárias para transformar o texto reconhecido no Ground Truth; a acurácia exata, por sua vez, mede a proporção de placas integralmente corretas. As duas métricas respondem a aspectos diferentes do problema.

### 4.3 Resultados complementares com ROI — não combinar com o experimento principal

Os relatórios de 28/10 para o teste com ROI registram 40 placas em cada sistema e elemento quadrado 51 × 51:

| Sistema com ROI | Placas corretas | Acurácia exata | CER global |
|---|---:|---:|---:|
| e1 — Baseline com ROI | 6/40 | 15,00% | 42,29% |
| e2 — Black Top-hat com ROI | 8/40 | 20,00% | 37,63% |

Nesta configuração específica, o e2 obteve mais acertos e CER inferior. Esse resultado é complementar e não deve ser agregado ao principal: aplica ROI, usa lado de elemento estruturante distinto do implícito no `raio=51` do `main.m` e representa outra configuração experimental.

Há ainda uma divergência entre arquivos históricos: o resumo exploratório de quatro cenários de 23/10 registra CER global de 85,66% para e2 sem ROI, enquanto os CSVs principais e relatórios comparativos de 28/10 registram 87,46%. A causa não está documentada. Os valores foram mantidos separados, sem substituir um pelo outro.

## Conclusão

O projeto atende ao objetivo de implementar e comparar um baseline e um sistema com Black Top-hat sobre 40 recortes de placas. O processamento principal utiliza Black Top-hat com elemento quadrado, seguido de complemento, e não aplica ROI. No resultado principal sem ROI, a acurácia do e2 aumenta de 0,00% para 2,50%, mas sua CER global também aumenta; portanto, os resultados não demonstram uma melhoria geral consistente. O teste com ROI é mais favorável ao e2, porém responde a uma configuração distinta.

Para fortalecer a conclusão, as próximas execuções devem registrar junto aos resultados o lado efetivo e a forma do elemento estruturante, a aplicação de ROI, os parâmetros OCR e a identificação da execução. Também devem manter e1/e2 pareados e variar um fator por vez. Antes de compartilhar os artefatos, deve-se verificar a política de privacidade do Ground Truth e das imagens de placas.

## Como executar

Na raiz do projeto, no MATLAB:

```matlab
raizProjeto = pwd;
addpath(genpath(raizProjeto));
run(fullfile(raizProjeto, 'main.m'));
```

O fluxo principal exige os dados locais, o Ground Truth verificado e as funções MATLAB de processamento morfológico e OCR. Ele preserva resultados existentes e interrompe operações que tentariam sobrescrever determinados arquivos. Para os testes complementares de ROI, use a função específica, sem confundir a saída com a execução principal:

```matlab
[resultados, resumo, comparacao] = testAllPlateROIs(raizProjeto, true, 51);
relatorioROI = generateROIResultsReport(raizProjeto);
```

O segundo comando avalia ROI e elemento `square` de lado 51. Não reproduz a configuração `raio=51` do fluxo principal, que resulta em lado 103.

## Referências

- SOILLE, Pierre. *Morphological Image Analysis: Principles and Applications*. O código do projeto declara como base a Seção 4.5.2; edição, ano e páginas não estão registrados nos arquivos locais.
- MathWorks. [Recognize Text Using Optical Character Recognition (OCR)](https://www.mathworks.com/help/vision/examples/recognize-text-using-optical-character-recognition-ocr.html).
- UFPR. [Layout-Independent ALPR](https://web.inf.ufpr.br/vri/publications/layout-independent-alpr/).
- FERGUS, R. Descrição local da base Caltech de imagens de automóveis, 4 out. 2003. Os metadados bibliográficos completos não estão disponíveis no workspace.
