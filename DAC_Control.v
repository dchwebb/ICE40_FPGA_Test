module DAC_Control
	(
		input wire i_Clock,
		input wire i_Reset,
		input wire [7:0] i_Data,
		input wire i_Send,
		output wire o_DAC_MOSI,
		output wire o_DAC_SCK,
		output wire o_DAC_CS

	);

	reg [7:0] DAC_Data_Send;
	wire [7:0] DAC_Data_Rec;
	reg [4:0] DAC_Addr;
	reg DAC_RW;
	reg DAC_Send;
	localparam SPICR0 = 4'h08;
	localparam SPICR1 = 4'h09;
	localparam SPICR2 = 4'h0A;
	localparam SPIBR = 4'h0B;
	localparam SPITXDR = 4'h0D;
	localparam SPIRXDR = 4'h0E;
	localparam SPICSR = 4'h0F;
	localparam SPISR = 4'h0C;
	localparam SPIINTSR = 4'h06;
	localparam SPIINTCR = 4'h07;


	DAC_SPI dac (
		.spi2_miso_io(),
		.spi2_mosi_io(o_DAC_MOSI),
		.spi2_sck_io(o_DAC_SCK),
		.spi2_scs_n_i(),
		.spi2_mcs_n_o(o_DAC_CS),
		.rst_i(reset_n),
		.ipload_i(),
		.ipdone_o(),
		.sb_clk_i(clock_24M),
		.sb_wr_i(DAC_RW),					// System Read/Write input. R=0, W=1
		.sb_stb_i(DAC_Send),				// System Strobe Signal
		.sb_adr_i(DAC_Addr),				// System Bus Control Registers Address
		.sb_dat_i(DAC_Data_Send),		// System Data Input
		.sb_dat_o(DAC_Data_Rec),
		.sb_ack_o(),
		.spi_pirq_o(),
		.spi_pwkup_o()
	);

	reg [3:0] SM_DAC = 4'b0;
	localparam sm_init0 = 4'd1;
	localparam sm_init1 = 4'd2;
	localparam sm_check_ready = 4'd3;
	localparam sm_send = 4'd4;
	localparam sm_sendclear = 4'd5;
	localparam sm_waiting = 4'd6;

	always @(posedge i_Clock) begin
		if (i_Reset) begin
			SM_DAC <= sm_init0;
		end
	else begin

			case (SM_DAC)
			sm_waiting:
				// Start send
				if (i_Send) begin
					SM_DAC <= sm_check_ready;
				end

			sm_init0:
				// Enable SPI
				if (i_Send) begin
					DAC_Addr <= SPICR1;
					DAC_Data_Send <= 8'b1000_0000;		// SPE
					DAC_Send <= 1'b1;
					DAC_RW <= 1'b1;
					SM_DAC <= sm_init1;
				end
				
			sm_init1:
				// configure Master mode
				if (DAC_Send == 1'b1)
					DAC_Send <= 1'b0;
				else begin
					DAC_Addr <= SPICR2;
					DAC_Data_Send <= 8'b1100_0000;	// Master mode; CSSPIN Hold 	
					DAC_Send <= 1'b1;
					DAC_RW <= 1'b1;
					SM_DAC <= sm_check_ready;
				end

			sm_check_ready:
				// request status register
				if (DAC_Send == 1'b1)
					DAC_Send <= 1'b0;
				else begin
					DAC_Addr <= SPISR;
					DAC_Send <= 1'b1;
					DAC_RW <= 1'b0;
					SM_DAC <= sm_send;
				end

			sm_send:
				// Check ready to transmit (bit 4)
				if (DAC_Send == 1'b1)
					DAC_Send <= 1'b0;
				else begin
					if (DAC_Data_Rec[4]) begin
						DAC_Addr <= SPITXDR;
						DAC_Data_Send <= 8'b1011_0100;		//Dummy byte
						DAC_Send <= 1'b1;
						DAC_RW <= 1'b1;
						SM_DAC <= sm_sendclear;
					end
				end

			sm_sendclear:
				begin
					DAC_Send <= 1'b0;
					SM_DAC <= sm_waiting;
				end
			endcase

		end
	end
endmodule