# Testes de Reconhecimento OCR

## Objetivo

Avaliar o comportamento da função `ocr()` do MATLAB no reconhecimento de caracteres de placas veiculares, identificando limitações e possíveis melhorias na segmentação e interpretação do texto.

## Teste 01 — Reconhecimento básico

**Arquivo:** `test01_basicOCR.m`

**Imagem utilizada:** `image_0097.jpg`

### Procedimento

1. Carregar a imagem da placa.
2. Aplicar a função `ocr()` sem configurações adicionais.
3. Consultar o texto e as palavras identificadas.
4. Visualizar as regiões delimitadas pelo OCR.

### Resultado

O algoritmo identificou duas regiões de texto na placa, separando o primeiro caractere dos demais.

Texto reconhecido: XRK320

### Análise

A separação pode estar relacionada ao espaçamento entre os caracteres e à segmentação automática do OCR.

---

## Teste 02 — Configuração do TextLayout

**Arquivo:** `test02_layoutAnalisis.m`

**Objetivo:** Avaliar o reconhecimento utilizando `LayoutAnalysis="Block"`.

**Resultado:** Conseguiu identificar corretamente: 2XRK320, com a imagem 097.

**Análise:** Com a desativação do reconhecimento automático, permitiu-se focar nos caracteres da placa e pode-se visualizar com a binarização e análise de layout que não se dividiu-se.

---

## Teste 03 — Restrição do conjunto de caracteres

**Arquivo:** `test03_characterSet.m`

**Imagem utilizada:** `image_0002.jpg`

### Procedimento

1. Carregar a imagem da placa e convertê-la para escala de cinza.
2. Executar `ocr()` com `LayoutAnalysis="Block"`.
3. Restringir os caracteres permitidos a letras maiúsculas e números:
   `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789`.
4. Exibir no Command Window o texto e as palavras reconhecidas.

### Resultado

**Resultado:** NEVT2L.

### Análise

**Análise:** Sem progresso de resultados.

---

## Teste 04 — OCR com Black Top-hat

**Arquivo:** `test4_black_Tophat.m`

**Imagem utilizada:** `image_0008.jpg`

### Objetivo

Comparar o reconhecimento da placa antes e depois da aplicação do Black
Top-hat, mantendo `LayoutAnalysis="Block"` e o mesmo conjunto de caracteres
nos dois reconhecimentos.

### Procedimento

1. Carregar a imagem e convertê-la para escala de cinza.
2. Executar o OCR da imagem original, restringindo os caracteres a letras
   maiúsculas e números.
3. Binarizar a imagem original e exibir a comparação entre a imagem e sua
   versão binarizada.
4. Aplicar `applyTopHat()`.
5. Binarizar a imagem corrigida e exibir a comparação com a imagem original.
6. Executar novamente o OCR na imagem corrigida com a mesma configuração.
7. Exibir os textos, palavras e caixas delimitadoras reconhecidos.

### Resultados gerados

O script salva em `src/ocr/results/test04/`:

- `image_0008_black_TopHat.png`: imagem corrigida com as caixas do OCR.
- `image_0008_binarized_montage.png`: imagem original e sua binarização.
- `image_0008_binarized.png`: imagem original binarizada.

### Resultado

**Resultado:** Placa reconhecida e acertou todas: EZEZBEH.

### Análise

**Análise:** A correção da iluminação não uniforme com o Black topHat foi possível indetificar corretamente os caracteres da placa.