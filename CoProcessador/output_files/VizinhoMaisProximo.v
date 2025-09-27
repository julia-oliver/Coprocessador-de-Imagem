`timescale 1ns / 1ps
module VizinhoMaisProximo (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,          // já vem como pulso de 1 ciclo
    input  wire [7:0] pixel_in,
    input  wire [1:0] zoom_select,   // 00=1x, 01=2x, 10=4x

    output reg  [18:0] ram_addr,
    output wire [14:0] rom_addr,
    output reg        wren,
    output reg  [7:0] pixel_out,
    output reg        done,
    output reg        led_test
);

    parameter LARGURA_ORIG = 160;
    parameter ALTURA_ORIG  = 120;

    // -----------------------------
    // FSM
    // -----------------------------
    localparam IDLE    = 2'b00;
    localparam PROCESS = 2'b01;
    localparam FINAL   = 2'b10;

    reg [1:0] estado, prox_estado;

    // -----------------------------
    // Contadores
    // -----------------------------
    // Contadores para a posição na imagem de SAÍDA
    reg [9:0] cont_x_saida, cont_y_saida;

    reg [2:0] block_size_reg;

    // -----------------------------
    // Captura BLOCK_SIZE no start
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            block_size_reg <= 1;
        else if (start) begin
            case (zoom_select)
                2'b01: block_size_reg <= 2;
                2'b10: block_size_reg <= 4;
		2'b11: block_size_reg <= 8;
                default: block_size_reg <= 1;
            endcase
        end
    end

    // -----------------------------
    // Tamanho da saída
    // -----------------------------
    wire [9:0] LARGURA_SAIDA = LARGURA_ORIG * block_size_reg;
    wire [9:0] ALTURA_SAIDA  = ALTURA_ORIG  * block_size_reg;

    // -----------------------------
    // FSM Síncrona
    // -----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            estado       <= IDLE;
            prox_estado  <= IDLE;
            cont_x_saida <= 0;
            cont_y_saida <= 0;
            ram_addr     <= 0;
            pixel_out    <= 0;
            wren         <= 0;
            done         <= 0;
            led_test     <= 0;
        end else begin
            estado <= prox_estado;

            case (estado)
                // ---------------- IDLE ----------------
                IDLE: begin
                    prox_estado <= IDLE;
                    if (start) begin
                        cont_x_saida <= 0;
                        cont_y_saida <= 0;
                        ram_addr     <= 0;
                        wren         <= 0;
                        done         <= 0;
			pixel_out    <= 0;
			led_test     <= 0;
                        prox_estado  <= PROCESS;
                    end
                end

                // ---------------- PROCESS ----------------
                PROCESS: begin
                    wren      <= 1'b1;
                    pixel_out <= pixel_in;
                    prox_estado <= PROCESS;
                    ram_addr  <= cont_y_saida * LARGURA_SAIDA + cont_x_saida;

                    // Avança para o próximo pixel de SAÍDA
                    if (cont_x_saida == LARGURA_SAIDA-1) begin
                        cont_x_saida <= 0;
                        if (cont_y_saida == ALTURA_SAIDA-1) begin
                            prox_estado <= FINAL;
                        end else begin
                            cont_y_saida <= cont_y_saida + 1;
                        end
                    end else begin
                        cont_x_saida <= cont_x_saida + 1;
                    end
                end

                // ---------------- FINAL ----------------
                FINAL: begin
                    wren        <= 0; // Para de escrever na RAM
                    done        <= 1'b1;
                    prox_estado <= IDLE;
                    led_test    <= ~led_test;
                end
            endcase
        end
    end

    // -----------------------------
    // Endereço ROM
    // -----------------------------
    // Calcula as coordenadas do pixel original
    // usando divisão inteira
    wire [9:0] rom_x = cont_x_saida / block_size_reg;
    wire [9:0] rom_y = cont_y_saida / block_size_reg;
    assign rom_addr = rom_y * LARGURA_ORIG + rom_x;

endmodule