`timescale 1ns / 1ps
module MediaDeBlocos #(
		 parameter LARGURA_ORIG = 160,
		 parameter ALTURA_ORIG  = 120
	)(
		 input  wire       clk,
		 input  wire       rst,
		 input  wire       start,          
		 input  wire [7:0] pixel_in,
		 input  wire [1:0] zoom_select,  

		 output reg  [18:0] ram_addr,
		 output wire [14:0] rom_addr,
		 output reg        wren,
		 output reg  [7:0] pixel_out,
		 output reg        done
	);

	// Valor do zoom 
	reg [4:0] escala;

		 // Captura escala no start
		 always @(posedge clk or posedge rst) begin
			  if (rst)
					escala <= 1;
			  else if (start) begin
					case (zoom_select)
	2'b00 : escala <= 1;
						 2'b01: escala <= 2;
						 2'b10: escala <= 4;
	2'b11: escala <= 8;
						 default: escala <= 1;
					endcase
			  end
		 end


	//CALCULOS FIXOS DEPENDENDO DA ESCALA

	// Calculo do tamanho do bloco
	wire [12:0]bloco;
	assign bloco = escala*escala;

	//Calculo da quantidade de blocos por linha e da quantidade de linhas de blocos na imagem original
	wire [9:0] blocos_por_linha, linhas_de_blocos;
	assign blocos_por_linha = LARGURA_ORIG/ escala;
	assign linhas_de_blocos = ALTURA_ORIG/ escala;


	//Variaveis utilizadas pelo algoritmo
	reg [9:0] linha_bloco, coluna_bloco;
	reg [4:0] linha_local, coluna_local;
	reg [7:0] media;
	reg [18:0] soma;
	// Um bit para esperar a latência de leitura
	reg read_wait;

	// Máquina de Estado
	localparam IDLE    = 2'b00;
	localparam PROCESS = 2'b01;
	localparam WRITE   = 2'b10;
	localparam FINAL   = 2'b11;

	reg [1:0] estado, prox_estado;

		 // Ajuste: rom_addr_temp com largura maior
		 reg [18:0] rom_addr_temp;
		 assign rom_addr = rom_addr_temp;

		 // Máquina de Estados (somente o always)
		 always @(posedge clk or posedge rst) begin
			  if (rst) begin
					estado       <= IDLE;
					prox_estado  <= IDLE;
					ram_addr     <= 0;
					rom_addr_temp<= 0;
					pixel_out    <= 0;
					wren         <= 0;
					done         <= 0;
	read_wait    <= 0;
					media        <= 0;
					soma         <= 0;
					linha_bloco  <= 0;
					coluna_bloco <= 0;
					linha_local  <= 0;
					coluna_local <= 0;
			  end
			  else begin
					estado <= prox_estado;

					case (estado)
						 IDLE: begin
							  prox_estado <= IDLE;
							  if (start) begin
									ram_addr      <= 0;
									rom_addr_temp <= 0;
									pixel_out     <= 0;
									media         <= 0;
									wren          <= 0;
									done          <= 0;
									soma          <= 0;
									linha_bloco   <= 0;
									coluna_bloco  <= 0;
									linha_local   <= 0;
									coluna_local  <= 0;
									prox_estado   <= PROCESS;  // Inicia o processamento
							  end
						 end

						 // Estado que calcula a media de um bloco
						 PROCESS: begin
	wren <= 1'b0;
	prox_estado <= PROCESS;

	if (!read_wait) begin
		 // Colocar endereço para a ROM — dado só estará válido no próximo ciclo
		 rom_addr_temp <= (linha_bloco*escala + linha_local) * LARGURA_ORIG
		+ (coluna_bloco*escala + coluna_local);
		 read_wait <= 1'b1; // Agora vamos aguardar o dado
		end
	else begin
	 // Aqui pixel_in corresponde ao rom_addr_temp do ciclo anterior
	 // Se este é o último pixel do bloco, calcula média (incluindo este pixel)
	 if ((coluna_local == escala-1) && (linha_local == escala-1)) begin
		media <= (soma + pixel_in) / bloco;
		prox_estado <= WRITE;
		read_wait <= 1'b0;
		// Nota: não incrementamos coluna/linha_local; serão zerados no WRITE
		 end
	 else begin
	// Acumula o pixel válido e avança o cursor dentro do bloco
	soma <= soma + pixel_in;

	// Avança indices
	if (coluna_local < escala-1) begin
		coluna_local <= coluna_local + 1;
		end
	else begin
		coluna_local <= 0;
		if (linha_local < escala-1) begin
		 linha_local <= linha_local + 1;
		end
	end

	// Pronto para carregar o próximo endereço já no mesmo FSM (voltamos a fase de endereço)
	read_wait <= 1'b0;
			end
		end
	end

						 // Estado que envia o bloco processado para a ram e avança os blocos na memoria rom
						 WRITE: begin
							  prox_estado <= WRITE;

							  // Calcula o endereço do novo pixel na ram e escreve
							  ram_addr <= linha_bloco * blocos_por_linha + coluna_bloco;
							  pixel_out <= media;
							  wren <= 1;
							  soma <= 0;

							  // Zera os contadores locais do bloco para o próximo bloco
							  linha_local <= 0;
							  coluna_local <= 0;

							  // Avança para o proximo bloco
							  if (coluna_bloco < blocos_por_linha -1) begin
									coluna_bloco <= coluna_bloco + 1;
									prox_estado <= PROCESS;
							  end
							  else begin
									coluna_bloco <= 0;
									if (linha_bloco < linhas_de_blocos-1) begin
										 linha_bloco <= linha_bloco + 1;
										 prox_estado <= PROCESS;
									end
									else begin
										 prox_estado <= FINAL;
									end
							  end

						 end

						 FINAL: begin
							  wren <= 0;
							  done        <= 1'b1;
							  prox_estado <= IDLE;
						 end
					endcase
			  end
		 end

	endmodule