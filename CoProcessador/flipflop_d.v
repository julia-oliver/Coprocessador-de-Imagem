module flipflop_d (entrada_dado,clk,reset,saida_registrada);
	input entrada_dado; // Entrada de dado do flip-flop
	input clk; // Sinal de clock (borda de descida)
	input reset; // Sinal de reset síncrono (ativa em nível alto)
	output reg saida_registrada; // Saída armazenada do flip-flop
	always @( negedge clk) begin
		 if(reset)
			saida_registrada <= 1'b0; // saida_registradauando reset ativo, zera a saída saida_registrada
		 else 
		  saida_registrada <= entrada_dado; // Caso contrário, armazena o valor da entrada
	end 
endmodule 