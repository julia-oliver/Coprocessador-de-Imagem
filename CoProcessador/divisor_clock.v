module divisor_clock (
    input clk_50, // Clock de entrada (50MHz)
	 input reset,  // Sinal de reset
    output clk_25 // Clock dividido gerado na saída
);

	flipflop_d (D, clk_50, reset, clk_25);// Instância do flip-flop tipo D
	
	not (D,clk_25); // Inversão para realimentar D
endmodule