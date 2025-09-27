module Replicacao #(
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

    reg [1:0] fator_zoom;
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
    reg [9:0] cont_x_orig, cont_y_orig;   // Posição na ROM
    reg [9:0] block_x, block_y;           // Posição dentro do bloco
    reg [7:0] pixel_hold;                 // Armazena o pixel atual da ROM

    reg [2:0] block_size_reg;             // valor do zoom 
    reg read_wait;                        // Flag para aguardar latência da ROM

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
            cont_x_orig  <= 0;
            cont_y_orig  <= 0;
            block_x      <= 0;
            block_y      <= 0;
            ram_addr     <= 0;
            pixel_out    <= 0;
            pixel_hold   <= 0;
            wren         <= 0;
            done         <= 0;
            read_wait    <= 0;
        end else begin
            estado <= prox_estado;

            case (estado)
                // ---------------- IDLE ----------------
                IDLE: begin
                    prox_estado <= IDLE;
                    if (start) begin
                        cont_x_orig <= 0;
                        cont_y_orig <= 0;
                        block_x     <= 0;
                        block_y     <= 0;
                        ram_addr    <= 0;
                        pixel_out   <= 0;
                        wren        <= 0;
                        done        <= 0;
                        read_wait   <= 0;  // Inicia sem aguardar
                        prox_estado <= PROCESS;
                    end
                end

                // ---------------- PROCESS ----------------
                PROCESS: begin
                    wren <= 1'b0;  // Por padrão não escreve
                    prox_estado <= PROCESS;

                    if (!read_wait) begin
                        // Primeira fase: coloca endereço na ROM, aguarda dado válido
                        read_wait <= 1'b1;
                    end else begin
                        // Segunda fase: pixel_in agora é válido, processa
                        pixel_hold <= pixel_in;
                        pixel_out <= pixel_in;
                        wren <= 1'b1;
                        
                        ram_addr <= (cont_y_orig * block_size_reg + block_y) * LARGURA_SAIDA
                                  + (cont_x_orig * block_size_reg + block_x);

                        if (block_x == block_size_reg-1 && block_y == block_size_reg-1) begin
                            // Terminou o bloco atual, avança para próximo pixel da ROM
                            block_x <= 0;
                            block_y <= 0;
                            read_wait <= 1'b0;  // Vai aguardar novo endereço

                            if (cont_x_orig == LARGURA_ORIG-1) begin
                                cont_x_orig <= 0;
                                if (cont_y_orig == ALTURA_ORIG-1) begin
                                    prox_estado <= FINAL;
                                end else begin
                                    cont_y_orig <= cont_y_orig + 1;
                                end
                            end else begin
                                cont_x_orig <= cont_x_orig + 1;
                            end
                        end else begin
                            // Continua no mesmo bloco, não avança endereço ROM
                            if (block_x < block_size_reg-1)
                                block_x <= block_x + 1;
                            else begin
                                block_x <= 0;
                                block_y <= block_y + 1;
                            end
                            // Mantém read_wait = 1 (não precisa aguardar, mesmo pixel)
                        end
                    end
                end

                // ---------------- FINAL ----------------
                FINAL: begin
                    wren        <= 0;
                    done        <= 1'b1;
                    prox_estado <= IDLE;
                end
            endcase
        end
    end

    // -----------------------------
    // Endereço ROM
    // -----------------------------
    assign rom_addr = cont_y_orig * LARGURA_ORIG + cont_x_orig;

endmodule