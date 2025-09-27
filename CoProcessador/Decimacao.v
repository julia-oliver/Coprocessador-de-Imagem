module Decimacao #(
    parameter LARGURA_ORIGINAL = 160,
    parameter ALTURA_ORIGINAL  = 120
)(
    input clk,
    input reset,
    input start,  // Sinal de controle

    // Seleção do fator de decimação
    input [1:0] zoom_select, // 2'b00: 1x, 2'b01: 2x, 2'b10: 4x, 2'b11: 8x
    
    // Dados de entrada e saida de pixel
    input [7:0] pixel_in,
    output reg [7:0] pixel_out,
    
    // Endereço e controle para a memória de origem
    output wire [14:0] rom_addr,
    // Endereço e controle para a memória de destino
    output reg wren_ram,
    output wire [18:0] ram_addr,
    output reg done
);
    // -----------------------------
    // Máquina de Estado
    // -----------------------------
    localparam INICIO = 2'b00;
    localparam PROCESSAMENTO = 2'b01;
    localparam FINAL = 2'b10;
    
    reg [1:0] estado, prox_estado;
    
    // -----------------------------
    // Contadores
    // -----------------------------
    reg [9:0] cont_x_orig;
    reg [9:0] cont_y_orig;
    
    // Contadores para o endereço de destino
    reg [9:0] cont_x_dest;
    reg [9:0] cont_y_dest;
    
    // Fator de decimação
    reg [2:0] block_size_reg;

    // Lógica principal síncrona
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado <= INICIO;
            cont_x_orig <= 0;
            cont_y_orig <= 0;
            cont_x_dest <= 0;
            cont_y_dest <= 0;
            block_size_reg <= 1;
            wren_ram <= 1'b0;
            pixel_out <= 0;
            done <= 0;
        end else begin
            estado <= prox_estado;
            wren_ram <= 1'b0; // Reseta o sinal de escrita por padrão
            
            case(estado)
                INICIO: begin
                    if(start) begin
                        cont_x_orig <= 0;
                        cont_y_orig <= 0;
                        cont_x_dest <= 0;
                        cont_y_dest <= 0;
                        done <= 0;
                        case (zoom_select)
                            2'b01: block_size_reg <= 2;
                            2'b10: block_size_reg <= 4;
                            2'b11: block_size_reg <= 8;
                            default: block_size_reg <= 1;
                        endcase
                        prox_estado <= PROCESSAMENTO;
                    end else begin
                        prox_estado <= INICIO;
                    end
                end
                
                PROCESSAMENTO: begin
                    prox_estado <= PROCESSAMENTO;

                    // Lógica de decimação: usa pixel_in diretamente (como o Vizinho Mais Próximo)
                    if ((cont_x_orig % block_size_reg) == 0 && (cont_y_orig % block_size_reg) == 0) begin
                        pixel_out <= pixel_in;
                        wren_ram <= 1'b1; // Habilita a escrita na memoria de destino
                        
                        // Incrementa contadores de destino apenas se a decimação for TRUE
                        if (cont_x_dest == (LARGURA_ORIGINAL/block_size_reg)-1) begin
                            cont_x_dest <= 0;
                            cont_y_dest <= cont_y_dest + 1;
                        end else begin
                            cont_x_dest <= cont_x_dest + 1;
                        end
                    end

                    // Lógica para avançar os contadores de origem a cada pulso de clock
                    if (cont_x_orig == LARGURA_ORIGINAL - 1) begin
                        cont_x_orig <= 0;
                        if (cont_y_orig == ALTURA_ORIGINAL - 1) begin
                            prox_estado <= FINAL;
                        end else begin
                            cont_y_orig <= cont_y_orig + 1;
                        end
                    end else begin
                        cont_x_orig <= cont_x_orig + 1;
                    end
                end
                
                FINAL: begin
                    done <= 1'b1;
                    prox_estado <= INICIO; // Volta para o estado inicial após o término
                end
                
                default: prox_estado <= INICIO;
            endcase
        end
    end

    // Mapeamento de endereço para a memoria de origem
    assign rom_addr = (cont_y_orig * LARGURA_ORIGINAL) + cont_x_orig;
  
    // Mapeamento de endereço para a memoria de destino
    assign ram_addr = (cont_y_dest * (LARGURA_ORIGINAL / block_size_reg)) + cont_x_dest;
    
endmodule