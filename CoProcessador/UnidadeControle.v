module UnidadeControle(
    input  wire        clk_50,
    input  wire        reset,            // Reset topo (ativo alto), usamos !reset internamente
    input  wire        start,            // Botão 
    input  wire [1:0]  SW,               // Tipo de algoritmo
    input  wire [1:0]  zoom_select,      // Fator de redimensionamento
    output wire [1:0]  opcao_Redmn,
    output reg         ready,

    // Saída VGA
    output wire        hsync,
    output wire        vsync,
    output wire [7:0]  vga_r,
    output wire [7:0]  vga_g,
    output wire [7:0]  vga_b,
    output wire        sync,
    output wire        clk,
    output wire        blank
);

    // ---------------------------------------------------------------------
    // Clock
    // ---------------------------------------------------------------------
    wire clock_25;
    divisor_clock divisor_inst (
        .clk_50(clk_50),
        .reset(!reset),
        .clk_25(clock_25)
    );
    wire clk_100;
    clock_100_0002 clock_100_inst (
        .refclk   (clk_50),   //  refclk.clk
        .rst      (0),      //   reset.reset
        .outclk_0 (clk_100), // outclk0.clk
        .locked   ()    //  locked.export
    );


    // ---------------------------------------------------------------------
    // Start pulse (botão ativo-low)
    // ---------------------------------------------------------------------
    reg start_d;
    wire start_pulse;
    always @(posedge clock_25 or negedge reset) begin
        if (!reset) start_d <= 1'b1;
        else start_d <= start;
    end
    assign start_pulse = start_d & ~start; // 1->0 detected

    // ---------------------------------------------------------------------
    // Parâmetros
    // ---------------------------------------------------------------------
    localparam integer ALTURA_ORIGINAL  = 120;
    localparam integer LARGURA_ORIGINAL = 160;

    // ---------------------------------------------------------------------
    // Estados e seleção
    // ---------------------------------------------------------------------
    localparam INICIO  = 2'b00;
    localparam EXECUTE = 2'b01;
    localparam CHECK   = 2'b10;

    localparam REPLICACAO = 2'b00;
    localparam DECIMACAO  = 2'b01;
    localparam VIZINHO_PROXIMO = 2'b10;
    localparam MEDIA_BLOCOS =  2'b11;

    reg [1:0] estado, prox_estado;
    reg [1:0] Tipo_redmn;
    assign opcao_Redmn = Tipo_redmn;

    reg operacao_ativa;
    reg done; // flag combinada do algoritmo ativo

    // ---------------------------------------------------------------------
    // Memórias
    // ---------------------------------------------------------------------
    // ROM : Imagem Original
    wire [14:0] rom_addr_top;
    wire [7:0] rom_pixel;

    MemoriaROM rom_inst (
        .address (rom_addr_top),
        .clock   (clk_100),
        .q       (rom_pixel)
    );

    // RAM : Imagem Redimensionada
    wire [18:0] EnderecoRAM;
    wire [7:0] ram_data_in;
    wire wren_ram;
    wire [7:0] saida_RAM;

    MemoriaImgRED ram_inst (
        .address (EnderecoRAM),
        .clock   (clk_100),
        .data    (ram_data_in),
        .wren    (wren_ram),
        .q       (saida_RAM)
    );

    // ---------------------------------------------------------------------
    // Instancias dos algoritmos
    // ---------------------------------------------------------------------
   
    //Vizinho Mais Proximo (Zoom IN)
    wire done_vmp;
    wire [7:0] pixel_out_vmp;
    wire wren_vmp;
    wire [18:0] ram_addr_vmp;
    wire [14:0] rom_addr_vmp;
   
   
    wire start_vmp = start_pulse & (SW == VIZINHO_PROXIMO);
   
    VizinhoMaisProximo (
    .clk(clock_25),
    .rst(!reset),
    .start(start_vmp),          
    .pixel_in(rom_pixel),
    .zoom_select(zoom_select),  
    .ram_addr(ram_addr_vmp),
    .rom_addr(rom_addr_vmp),
    .wren(wren_vmp),
    .pixel_out(pixel_out_vmp),
    .done(done_vmp)
);
   
    // Replicaçao ( Zoom IN)
    wire done_rep;
    wire [7:0] pixel_out_rep;
    wire wren_rep;
    wire [18:0] ram_addr_rep;
    wire [14:0] rom_addr_rep;

    wire start_rep = start_pulse & (SW == REPLICACAO);

    Replicacao vmp_inst (
        .clk(clock_25),
        .rst(!reset),
        .start(start_rep),
        .zoom_select(zoom_select),
        .pixel_in(rom_pixel),
        .done(done_rep),
        .pixel_out(pixel_out_rep),
        .wren(wren_rep),
        .rom_addr(rom_addr_rep),
        .ram_addr(ram_addr_rep)
    );

    // Decimação (zoom OUT)
    wire done_dcm;
    wire [7:0] pixel_out_dcm;
    wire wren_dcm;
    wire [14:0] rom_addr_dcm;
    wire [18:0] ram_addr_dcm;

    wire start_dcm = start_pulse & (SW == DECIMACAO);

    Decimacao dcm_inst (
        .clk(clock_25),
        .reset(!reset),
        .start(start_dcm),
        .zoom_select(zoom_select),
        .pixel_in(rom_pixel),
        .pixel_out(pixel_out_dcm),
        .rom_addr(rom_addr_dcm),
        .wren_ram(wren_dcm),
        .ram_addr(ram_addr_dcm),
        .done(done_dcm)
    );
   
    //Media de Blocos (zoom OUT)
    wire done_mdb;
    wire [7:0] pixel_out_mdb;
    wire wren_mdb;
    wire [14:0] rom_addr_mdb;
    wire [18:0] ram_addr_mdb;

    wire start_mdb = start_pulse & (SW == MEDIA_BLOCOS);
   
    MediaDeBlocos(
        .clk(clock_25),
        .rst(!reset),
        .start(start_mdb),        
        .pixel_in(rom_pixel),
        .zoom_select(zoom_select),  
        .ram_addr(ram_addr_mdb),
        .rom_addr(rom_addr_mdb),
        .wren(wren_mdb),
        .pixel_out(pixel_out_mdb),
        .done(done_mdb)
    );


    // ---------------------------------------------------------------------
    // Multiplexadores de endereço/ dados / wren / rom_addr
    // - rom_addr_top é selecionado pelo módulo ativo
    // - ram_addr_writer e ram_data_in / writer_wren vem do módulo escritor
    // ---------------------------------------------------------------------
   
    assign rom_addr_top = (SW == REPLICACAO) ? rom_addr_rep :
                          (SW == DECIMACAO)  ? rom_addr_dcm :
                          (SW == VIZINHO_PROXIMO) ? rom_addr_vmp:
                          (SW == MEDIA_BLOCOS) ? rom_addr_mdb:
                          rom_addr_original;  

    wire [18:0] ram_addr_writer = (SW == REPLICACAO) ? ram_addr_rep :
                                  (SW == DECIMACAO)  ? ram_addr_dcm :
                                  (SW == VIZINHO_PROXIMO) ? ram_addr_vmp:
                                  (SW == MEDIA_BLOCOS) ? ram_addr_mdb:
                                  {19{1'b0}};

    wire [7:0] ram_data_writer = (SW == REPLICACAO) ? pixel_out_rep :
                                 (SW == DECIMACAO)  ? pixel_out_dcm :
                                 (SW == VIZINHO_PROXIMO) ? pixel_out_vmp :
                                 (SW == MEDIA_BLOCOS) ? pixel_out_mdb : 8'd0;

    wire writer_wren = (SW == REPLICACAO) ? wren_rep :
                       (SW == DECIMACAO)  ? wren_dcm:
                       (SW == VIZINHO_PROXIMO) ? wren_vmp :
                       (SW == MEDIA_BLOCOS) ? wren_mdb : 1'b0;

    // ---------------------------------------------------------------------
    // IMG_W / IMG_H / offsets (Block_size = escala)
    // ---------------------------------------------------------------------
    wire [3:0] BLOCK_SIZE_val = (zoom_select == 2'b01) ? 4'd2 :
                                (zoom_select == 2'b10) ? 4'd4 :
                                (zoom_select == 2'b11) ? 4'd8 : 4'd1;

    reg [9:0] IMG_W, IMG_H;
    reg [9:0] x_offset, y_offset;

    always @(posedge clock_25 or negedge reset) begin
        if (!reset) begin
            IMG_W <= LARGURA_ORIGINAL;
            IMG_H <= ALTURA_ORIGINAL;
            x_offset <= 10'd0;
            y_offset <= 10'd0;
        end else begin
            //Replicaçao e Vizinho mais proximo
            if ((SW == REPLICACAO & start_pulse) || (SW == VIZINHO_PROXIMO & start_pulse)) begin
                IMG_W <= LARGURA_ORIGINAL * BLOCK_SIZE_val;
                IMG_H <= ALTURA_ORIGINAL  * BLOCK_SIZE_val;
            end else begin
                // Decimaçao e Media de blocos
                if((SW == DECIMACAO & start_pulse) || (SW == MEDIA_BLOCOS & start_pulse))begin
                    IMG_W <= LARGURA_ORIGINAL / BLOCK_SIZE_val;
                    IMG_H <= ALTURA_ORIGINAL  / BLOCK_SIZE_val;
                end
            end
            x_offset <= (640 - IMG_W) / 2;
            y_offset <= (480 - IMG_H) / 2;
        end
    end


    // ---------------------------------------------------------------------
    // Controle de exibição: só exibe após done do módulo que escreveu
    // ---------------------------------------------------------------------
    reg exibe_imagem;
    always @(posedge clock_25 or negedge reset) begin
        if (!reset) exibe_imagem <= 1'b0;
        else if (start_pulse) exibe_imagem <= 1'b0;
        else if ((SW == REPLICACAO && done_rep) || (SW == DECIMACAO && done_dcm) || (SW == VIZINHO_PROXIMO && done_vmp) || (SW == MEDIA_BLOCOS && done_mdb))
            exibe_imagem <= 1'b1;
    end

    // Endereço calculado pela VGA
    wire [9:0] next_x, next_y;
    wire in_image_bounds = (next_x >= x_offset) && (next_x < (x_offset + IMG_W)) &&
                           (next_y >= y_offset) && (next_y < (y_offset + IMG_H));

    wire [18:0] ram_addr_calc;
    assign ram_addr_calc = (next_y - y_offset) * IMG_W + (next_x - x_offset);

    // ---------------------------------------------------------------------
    // Condição reset - exibe imagem original
    // ---------------------------------------------------------------------
    wire idle;
    assign idle = (!operacao_ativa && !exibe_imagem);  // Não está processando nem exibindo resultado
   
    // Endereço da ROM para mostrar imagem original
    wire [14:0] rom_addr_original;
    assign rom_addr_original = (next_y - y_offset) * LARGURA_ORIGINAL + (next_x - x_offset);

    // EnderecoRAM/multiplexado: se exibe -> VGA controla leitura, senão o escritor controla
    assign EnderecoRAM = (exibe_imagem) ? ram_addr_calc : ram_addr_writer;
    assign ram_data_in = (exibe_imagem) ? 8'd0 : ram_data_writer;
    assign wren_ram = (exibe_imagem) ? 1'b0 : writer_wren;

    // ---------------------------------------------------------------------
    // Máquina de Estados 
    // ---------------------------------------------------------------------
    always @(posedge clock_25 or negedge reset) begin
        if (!reset) begin
            estado <= INICIO;
            prox_estado <= INICIO;
            Tipo_redmn <= REPLICACAO;
            operacao_ativa <= 1'b0;
            ready <= 1'b0;
        end else begin
            estado <= prox_estado;
            case (estado)
                INICIO: begin
                    ready <= 1'b0;
                    prox_estado <= INICIO;
                    if (start_pulse && !operacao_ativa) begin
                        operacao_ativa <= 1'b1;
                        Tipo_redmn <= SW;
                        prox_estado <= EXECUTE;
                    end
                end
                EXECUTE: begin
                    // Deixamos os módulos rodando (eles foram startados por start_pulse local)
                    prox_estado <= CHECK;
                end
                CHECK: begin
                    // Espera done do módulo ativo
                    if ((SW == REPLICACAO && done_rep) || (SW == DECIMACAO && done_dcm) || (SW == VIZINHO_PROXIMO && done_vmp) || (SW == MEDIA_BLOCOS && done_mdb)) begin
                        operacao_ativa <= 1'b0;
                        ready <= 1'b1;
                        prox_estado <= INICIO;
                    end else prox_estado <= CHECK;
                end
                default: prox_estado <= INICIO;
            endcase
        end
    end

    // ---------------------------------------------------------------------
    // Saída VGA com multiplexação para imagem original
    // ---------------------------------------------------------------------
   
    wire [7:0] out_vga;
   
    assign out_vga = (idle && in_image_bounds) ? rom_pixel :
                     (exibe_imagem && in_image_bounds) ? saida_RAM : 8'h00;

    vga_driver draw (
        .clock(clock_25),
        .reset(!reset),
        .color_in(out_vga),
        .next_x(next_x),
        .next_y(next_y),
        .hsync(hsync),
        .vsync(vsync),
        .red(vga_r),
        .green(vga_g),
        .blue(vga_b),
        .sync(sync),
        .clk(clk),
        .blank(blank)
    );

endmodule