# Relatório técnico — reconhecimento de placas com Black Top-hat

## 1. Introdução

Este relatório descreve o projeto de processamento das placas veículos com morfologia matemática e reconhecimento óptico de caracteres (OCR), implementado em MATLAB. A análise compara um sistema de referência, sem processamento morfológico (e1), com um sistema que aplica Black Top-hat antes do OCR (e2).

O objetivo experimental é verificar se a transformação melhora a leitura de caracteres em imagens com variações de iluminação. As imagens usadas pelos sistemas são recortes de placas previamente selecionados.

## 2. Materiais e métodos

### 2.1 Materiais

- Implementação MATLAB em `main.m`, `experiments/`, `src/`.
- Seleção registrada em `data/selected/selected_images.csv`: 40 imagens, com semente de seleção 42.
- Ground Truth local com 40 registros verificados.
- Resultados OCR e métricas nos diretórios `results/baseline/`, `results/proposed/` e `results/metrics/`.
- Relatórios e análises exploratórias em `results/reports/` e `results/analysis/`.

### 2.2 Sistemas comparados

**e1 — referência:** imagem recortada selecionada → OCR.

**e2 — proposto:** imagem recortada selecionada → Black Top-hat → complemento da imagem transformada → OCR.

### 2.3 Operador morfológico

Para a imagem em tons de cinza \(f\) e elemento estruturante \(B\), a implementação calcula:

\[
T_b(f) = (f \bullet B) - f
\]

em que \(f \bullet B\) representa o fechamento morfológico. O resultado Black Top-hat é complementado para produzir a imagem encaminhada ao OCR. O complemento é uma etapa de preparação da imagem, não parte da definição do Black Top-hat.

A implementação em `src/morphology/applyTopHat.m` usa `strel('square', 2*raio+1)`. Portanto, o parâmetro chamado `raio` representa metade do lado do quadrado, e não o lado diretamente. Os testes de validação comparam a operação com a definição matemática e com `imbothat`.

### 2.4 Métricas

- **Acurácia exata:** proporção de placas em que o texto reconhecido completo é igual ao Ground Truth normalizado.
- **CER global:** soma das distâncias de Levenshtein dividida pela soma dos caracteres do Ground Truth, em porcentagem.
- **CER média por placa:** média aritmética da CER individual de cada placa. Não é equivalente à CER global, pois esta última pondera placas pelo número de caracteres.

Textos OCR vazios contam como reconhecimento incorreto e contribuem para a CER. Os resultados principais incluem 40 placas verificadas.

## 3. Arquitetura e fluxo de execução

```text
main.m
 ├─ selectImages                 reutiliza/valida a seleção existente
 ├─ createGroundTruthTemplate    carrega/verifica o Ground Truth
 ├─ runBaseline                  imagem selecionada → recognizePlate
 ├─ runProposed                  imagem selecionada → applyTopHat → OCR
 ├─ evaluateRecognition         comparação com Ground Truth e métricas
 └─ comparação e1/e2             preserva os resultados já existentes
```

O fluxo e1/e2 principal **não aplica ROI**. `recognizePlate` executa OCR sobre a imagem recebida sem recorte adicional. A extração ROI está em `src/utils/extractPlateROI.m` e é usada por `testAllPlateROIs` e experimentos complementares, não pelos runners do fluxo principal.

O `main.m` atualmente configura `raioElementoEstruturante = 51`, que resulta em `square` de 103×103 pixels quando executado por `applyTopHat`. Entretanto, os arquivos `config.csv` dos relatórios comparativos registram operador, elemento, tamanho, ROI, layout OCR e semente como `nao_informado`. Assim, o código atual documenta a configuração presente no script, mas os CSVs existentes não permitem certificar que esse foi o parâmetro efetivamente usado para gerar cada resultado histórico.

Funções e scripts:

- `experiments/runBaseline.m` e `experiments/runProposed.m`: execução dos dois sistemas.
- `experiments/validateTopHat.m` e `src/utils/testApplyTopHat.m`: validação matemática e testes exploratórios do operador.
- `src/utils/testAllPlateROIs.m`: avaliação exploratória de quatro cenários com e sem ROI.
- `src/utils/testOcrConfigurations.m`: comparação exploratória de layouts e tratamentos OCR em uma placa.
- `src/utils/analyzePlateDimensions.m`: análise dimensional e recomendações geométricas.
- `src/utils/generateResultsReport.m` e `src/utils/generateROIResultsReport.m`: consolidação separada dos relatórios com e sem ROI.

## 4. Resultados

### 4.1 Execução principal — placas completas, sem ROI

Os resultados abaixo são os registrados em `results/metrics/baseline_metrics.csv` e `results/metrics/proposed_metrics.csv`, conferidos com os CSVs de OCR e com as comparações por imagem. A CER foi recalculada a partir dos textos locais sem exibir ou copiar as transcrições.

| Sistema | Placas | Acertos exatos | Erros exatos | Acurácia | CER global | CER média por placa | OCR vazio |
|---|---:|---:|---:|---:|---:|---:|---:|
| e1 — Baseline, sem ROI | 40 | 0 | 40 | 0,00% | 83,87% | 83,98% | 20 |
| e2 — Black Top-hat, sem ROI | 40 | 1 | 39 | 2,50% | 87,46% | 87,49% | 27 |

Na comparação por placa do conjunto principal, a CER diminuiu em 8 placas, aumentou em 7 e permaneceu igual em 25. Uma placa passou a ter correspondência exata no e2; nenhuma deixou de ser exata. Esses dados não demonstram uma redução global do erro no experimento sem ROI.



### 4.2 Experimento com ROI — elemento `square` 51×51

Os relatórios `results/reports/roi_comparacao_20261028_102857/` e `results/reports/roi_comparacao_20261028_102949/` registram os mesmos resultados. Nesse teste, `testAllPlateROIs` recebe `tamanhoQuadrado=51` e usa diretamente `strel('square', 51)`. A ROI é aplicada tanto a e1 como a e2 antes do OCR.

| Sistema | Placas | Acertos exatos | Erros exatos | Acurácia | CER global | CER média por placa | Falhas técnicas de OCR |
|---|---:|---:|---:|---:|---:|---:|---:|
| e1 — Baseline com ROI | 40 | 6 | 34 | 15,00% | 42,29% | 42,80% | 0 |
| e2 — Black Top-hat com ROI | 40 | 8 | 32 | 20,00% | 37,63% | 37,98% | 0 |

Estes valores pertencem à configuração com ROI e quadrado 51×51. Não são uma reexecução do fluxo principal e não devem ser combinados com as métricas sem ROI.

### 4.3 Registro exploratório de quatro cenários

O arquivo `results/analysis/roi_square_51_20261023_212510/resumo_4_cenarios.csv` mantém uma execução exploratória que inclui, separadamente, os cenários sem ROI e com ROI. A tabela abaixo registra os resultados do próprio arquivo; não os agrega aos resultados principais nem aos relatórios ROI de 28/10.

| Cenário exploratório (square 51×51) | Acertos exatos | Acurácia | CER global | CER média por placa |
|---|---:|---:|---:|---:|
| e1 sem ROI | 0/40 | 0,00% | 83,87% | 83,98% |
| e2 sem ROI | 1/40 | 2,50% | 85,66% | 85,54% |
| e1 com ROI | 6/40 | 15,00% | 42,29% | 42,80% |
| e2 com ROI | 8/40 | 20,00% | 37,63% | 37,98% |

Há uma divergência que deve ser preservada: o e2 **sem ROI** desta execução exploratória tem CER global de 85,66%, enquanto os CSVs do experimento principal e os quatro relatórios comparativos de 28/10 registram 87,46%. O resumo exploratório não fornece informação suficiente para determinar a causa. Não se deve escolher um valor em substituição ao outro nem tratá-los como a mesma execução.

### 4.4 Elemento disco e demais configurações

Não foram encontrados resultados identificados como execução com elemento estruturante disco, nem uso de `strel('disk', ...)` nos sistemas principais ou nos testes consultados. `analyzePlateDimensions.m` calcula um raio de disco equivalente como recomendação geométrica, mas isso não comprova que o disco tenha sido aplicado. Portanto, não há métricas de disco a relatar.

As recomendações exploratórias em `results/analysis/structuring_element_recommendations.csv` indicam lados quadrados 31, 43 e 53 para 60%, 80% e 100% da altura média, respectivamente. São recomendações, não resultados de OCR comparáveis. Outros testes variam o parâmetro ou o layout OCR e devem continuar sendo identificados pela configuração própria.

## 5. Discussão

No resultado principal sem ROI, o Top-hat produziu uma placa corretamente reconhecida, mas a acurácia exata foi baixa (2,50%) e a CER global foi maior que a do baseline. O número de saídas OCR vazias também foi superior no e2. Portanto, os resultados disponíveis não sustentam a afirmação de que o processamento, na configuração principal registrada, melhorou o reconhecimento sem ROI.

No teste específico com ROI e quadrado 51×51, e2 apresentou mais acertos exatos e CER inferior a e1. Esse achado é restrito a essa configuração e não isola uma comparação direta com o sistema principal sem ROI: a ROI altera a entrada do OCR e o lado do elemento usado nesse teste difere do lado implícito no `raio=51` do `main.m`.

A divergência entre arquivos exploratórios e principais, bem como a ausência dos parâmetros nos CSVs de configuração, limita a reprodutibilidade histórica. Também não há evidência registrada de execução com disco. Recomenda-se que futuras execuções salvem junto às métricas os parâmetros efetivos (tipo e dimensão do elemento, uso/coordenadas de ROI, layout e versão do MATLAB/toolboxes), além de um identificador inequívoco da execução. Uma comparação controlada deve manter todos os fatores constantes e variar uma configuração por vez.

O conjunto tem 40 imagens e a avaliação mede correspondência textual exata e erro de caracteres. Não foram localizados, nos artefatos citados, intervalos de confiança, avaliação em conjunto independente ou avaliação estatística; portanto, os resultados devem ser entendidos como descritivos deste conjunto, não como estimativa de desempenho geral.

## 6. Conclusão

O fluxo principal compara OCR direto nas placas recortadas com OCR após Black Top-hat e complemento, sem aplicação de ROI. A implementação atual utiliza elemento quadrado; com `raio=51`, o lado efetivo é 103 pixels. Os resultados principais sem ROI mostram acurácia de 0,00% para e1 e 2,50% para e2, mas CER global de 83,87% e 87,46%, respectivamente. A execução específica com ROI e `square` 51×51 apresenta resultados diferentes e deve ser reportada separadamente. Não há resultados documentados de elemento disco.

As diferenças de parâmetros e de CER entre os registros reforçam a necessidade de preservar a separação por execução e melhorar o registro de proveniência antes de conclusões comparativas mais amplas.

## 7. Instruções de execução

1. Abra a raiz do projeto no MATLAB e confirme a disponibilidade dos dados locais necessários. O Ground Truth precisa ter todas as anotações verificadas para o fluxo principal.
2. No Command Window, execute:

   ```matlab
   raizProjeto = pwd;
   addpath(genpath(raizProjeto));
   run(fullfile(raizProjeto, 'main.m'));
   ```

3. O fluxo principal reutiliza os CSVs existentes quando aplicável e contém proteções contra sobrescrita de resultados. `runBaseline`, `runProposed` e `evaluateRecognition` interrompem a execução se os seus respectivos arquivos de saída já existirem. Preserve esses arquivos; para uma nova execução, use uma cópia de trabalho isolada e identifique os parâmetros da execução.
4. Para inspecionar o operador, execute `experiments/validateTopHat.m` ou `src/utils/testApplyTopHat.m`. São testes exploratórios e não substituem as métricas consolidadas.
5. Para testar ROI separadamente, execute:

   ```matlab
   [resultados, resumo, comparacao] = testAllPlateROIs(raizProjeto, true, 51);
   relatorioROI = generateROIResultsReport(raizProjeto);
   ```

   Esse comando usa elemento `square` de lado 51, aplica a mesma regra ROI em e1/e2 e grava em diretórios próprios. Não interprete esses resultados como os do `main.m`.

O processamento morfológico requer funções do Image Processing Toolbox; a chamada `ocr` requer o Computer Vision Toolbox. A disponibilidade e as versões devem ser verificadas na instalação MATLAB utilizada.

## 8. Referências

- SOILLE, Pierre. *Morphological Image Analysis: Principles and Applications*. Seção 4.5.2, “Application to the Correction of Uneven Illumination”. Edição, ano e demais dados bibliográficos não foram registrados nos arquivos locais do projeto.
- MathWorks. [Recognize Text Using Optical Character Recognition (OCR)](https://www.mathworks.com/help/vision/ug/recognize-text-using-optical-character-recognition-ocr.html).
- UFPR. [Layout-Independent ALPR](https://web.inf.ufpr.br/vri/publications/layout-independent-alpr/).
