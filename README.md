# Coprocessador-de-Imagem

## Introdução e Definição do Problema

Este projeto aborda o desenvolvimento de um módulo embarcado de **Redimensionamento de Imagens** focado em sistemas de vigilância e exibição em tempo real, sob o tema "Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog".

O objetivo principal é projetar e implementar um **co-processador gráfico** que realize as operações de ampliação (zoom-in) ou redução (downscale) de imagens diretamente em hardware. O desenvolvimento é dividido em etapas, e o foco inicial é a construção de um sistema autossuficiente executado inteiramente na FPGA da placa de desenvolvimento **DE1-SoC**.

Este co-processador deve simular um comportamento básico de **interpolação visual**, permitindo o controle das operações através de chaves e botões da placa, e exibindo a imagem processada via saída **VGA**.

##  Requisitos Principais

O desafio central é a implementação correta dos algoritmos de redimensionamento em linguagem **Verilog**, de forma com que sejam compatíveis com o processador ARM (**HPS - Hard Processor System**) para possibilitar as etapas futuras do projeto. As imagens de entrada e saída são representadas em **escala de cinza**, com cada pixel utilizando **8 bits**.

###  Aproximação (Zoom in)
- **Vizinho Mais Próximo** (Nearest Neighbor Interpolation)
- **Replicação de Pixel** (Pixel Replication / Block Replication)

###  Redução (Zoom out)
- **Decimação / Amostragem** (Nearest Neighbor for Zoom Out)
- **Média de Blocos** (Block Averaging / Downsampling with Averaging)

O sistema só poderá utilizar os componentes disponíveis na placa, sem o uso de processadores externos, com chaves e/ou botões sendo utilizados para determinar a ampliação e redução da imagem.

## Fundamentação Teórica

### Representação Digital da Imagem

Neste projeto, as imagens são tratadas em **escala de cinza**. Cada elemento da imagem, ou **pixel**, é representado por um número inteiro de **8 bits**. Isso significa que cada pixel pode assumir 2⁸ = **256 tonalidades de cinza**, variando de **0 (preto)** a **255 (branco)**.

### Algoritmos de Redimensionamento 

O redimensionamento digital de imagens altera a **resolução** (número de pixels). As operações requeridas são a **ampliação (Zoom in)** e a **redução (Zoom out)**, ambas realizadas em passos de **2X**.

###  Ampliação (Zoom in) - Exemplificação em escala 2X

A ampliação cria uma imagem de saída com **o dobro do tamanho** da imagem original. Para preencher os novos pixels criados, são utilizados métodos básicos de interpolação:

- #### *Vizinho Mais Próximo (Nearest Neighbor Interpolation)*

Para determinar o valor de um pixel na imagem ampliada, o algoritmo copia o valor do pixel **mais próximo** (vizinho mais próximo) da imagem original. O resultado é que um bloco de **2×2 pixels** na nova imagem possuirá o **mesmo valor** do pixel correspondente na imagem original.

- #### *Replicação de Pixel (Pixel Replication)*

Método similar ao Vizinho Mais Próximo, onde cada pixel da imagem original é **replicado** em uma matriz 2×2 na imagem ampliada. É essencialmente uma implementação específica da interpolação por vizinho mais próximo para o caso de ampliação 2X.

###  Redução (Zoom out) - Exemplificação em escala 2X

A redução cria uma imagem de saída com **metade do tamanho** da imagem original. Para selecionar quais pixels serão mantidos ou como combinar a informação, são utilizados os seguintes métodos:

- #### *Decimação / Amostragem (Nearest Neighbor for Zoom Out)*

Método onde apenas **um a cada quatro pixels** (em uma janela 2×2) é selecionado para compor a imagem reduzida. Os demais pixels são descartados, resultando em uma perda de informação seletiva.

- #### *Média de Blocos (Block Averaging)*

Cada bloco de **2×2 pixels** na imagem original é combinado em um **único pixel** na imagem reduzida, onde o valor do novo pixel é a **média aritmética** dos quatro pixels originais. Este método preserva melhor as características da imagem original reduzindo o aliasing.
