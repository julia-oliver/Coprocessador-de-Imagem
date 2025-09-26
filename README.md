# Coprocessador-de-Imagem
**Introdução e Definição do Problema**

Este projeto aborda o desenvolvimento de um módulo embarcado de Redimensionamento de Imagens focado em sistemas de vigilância e exibição em tempo real , sob o tema "Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog". 

O objetivo principal é projetar e implementar um co-processador gráfico que realize as operações de ampliação (zoom-in) ou redução (downscale) de imagens diretamente em hardware. O desenvolvimento é dividido em etapas, e o foco inicial é a construção de um sistema autossuficiente executado inteiramente na FPGA da placa de desenvolvimento DE1-SoC. 

Este co-processador deve simular um comportamento básico de interpolação visual , permitindo o controle das operações através de chaves e botões da placa , e exibindo a imagem processada via saída VGA. 

**Requisitos Principais**

O desafio central é a implementação correta dos algoritmos de redimensionamento em linguagem Verilog, de forma com que sejam compatíveis com o processador ARM (HPS - Hard Processor System) para possibilitar as etapas futuras do projeto. As imagens de entrada e saída são representadas em escala de cinza, com cada pixel utilizando 8 bits. 
Os requisitos funcionais para o redimensionamento, em passos de 2X, são:

*Aproximação (Zoom in):*
  Vizinho Mais Próximo (Nearest Neighbor Interpolation).
  Replicação de Pixel (Pixel Replication / Block Replication).

*Redução (Zoom out):*
  Decimação / Amostragem (Nearest Neighbor for Zoom Out).
  Média de Blocos (Block Averaging / Downsampling with Averaging).

O sistema só poderá utilizar os componentes disponíveis na placa, sem o uso de processadores externos, com chaves e/ou botões sendo utilizados para determinar a ampliação e redução da imagem.
