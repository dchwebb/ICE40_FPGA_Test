module top
	(
		//input wire i_Clock,
		input wire reset_n,
		output reg led,
		output wire test,
		output wire o_DAC_MOSI,
		output wire o_DAC_SCK,
		output wire o_DAC_CS

	);

	wire Reset;
	assign Reset = ~reset_n;
	wire Clock_48MHz;

	//PLL_24M pll_24 (.ref_clk_i(i_Clock), .rst_n_i(reset_n), .lock_o(), .outcore_o(Clock_24MHz), .outglobal_o());
	//PLL_48MHz pll_48 (.ref_clk_i(i_Clock), .rst_n_i(reset_n), .outcore_o(Clock_48MHz), .outglobal_o());
	HSOSC	#(.CLKHF_DIV (2'b00)) int_osc (
		.CLKHFPU (1'b1),  // I
		.CLKHFEN (1'b1),  // I
		.CLKHF   (Clock_48MHz)   // O
	);

	//DAC_Control dac (
		//.i_Clock(clock_24M),
		//.i_Reset(Reset),
		//.i_Data(DAC_Data),
		//.i_Send(DAC_Send),
		//.o_DAC_MOSI(o_DAC_MOSI),
		//.o_DAC_SCK(o_DAC_SCK),
		//.o_DAC_CS(o_DAC_CS)
	//);

	reg DAC_Send;
	reg [23:0] DAC_Data;
	wire DAC_Ready;
	
	DAC_SPI_Out dac(
		.i_Clock(Clock_48MHz),
		.i_Reset(Reset),
		.i_Data(DAC_Data),
		.i_Send(DAC_Send),
		.o_SPI_CS(o_DAC_CS),
		.o_SPI_Clock(o_DAC_SCK),
		.o_SPI_Data(o_DAC_MOSI),
		.o_Ready(DAC_Ready),
		.testdac(test)
	);


	reg [8:0] counter = 1'b0;
	reg [15:0] outcount = 1'b0;
	//reg [7:0] Reset_Counter;

	//always @(posedge Clock_48MHz) begin
		//if (!reset_n) begin
			//Reset <= 1'b1;
			//Reset_Counter <= 1'b0;
		//end

		//if (Reset) begin
			//Reset_Counter <= Reset_Counter + 1'b1;
			//if (Reset_Counter == 250) begin
				//Reset <= 1'b0;
			//end
		//end
	//end


	always @(posedge Clock_48MHz) begin
		if (Reset) begin
			counter <= 1'b0;
			outcount <= 1'b0;
			DAC_Send <= 1'b0;
			led <= 1'b0;
		end
		else begin

			counter <= counter + 1'b1;


			if (counter == 100 && DAC_Ready) begin
				outcount <= outcount + 16'd50;
				DAC_Data <= {8'h31, outcount};
				DAC_Send <= 1'b1;
			end
			else begin
				DAC_Send <= 1'b0;
			end

			if (counter > 16'd2000)
				led <= 1'b1;
			else
				led <= 1'b0;
		end
	end
endmodule