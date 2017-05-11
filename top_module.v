`timescale 1ns / 1ps
module top_module(
    input clk_40MHz,
    output wire [2:0] LEDG,
    output LEDERR,
    output en_prog_clock,
    output UART_TX,
    output GND
    );

    /* define regs */
    reg [32:0] counter = 0;
    reg state;
    //reg clk_10MHz;
    
        
    reg	[3:0] tx_index;
    initial	tx_index = 4'h0;
    
    wire tx_busy;
    //reg	tx_stb;
        
    /* assign outputs to signals */
    assign LEDG[0] = state;
    //assign LEDG[1] = 1'b1;
    //assign LEDG[2] = 1'b0;
    assign en_prog_clock = 1'b1; // enable 40 MHz board clock on P13
    assign GND = 1'b0; // debug connector gnd
    assign LEDERR = 1'b0;
    
    
    /* Simple counter, to sanity check that we are clocked properly */
    always @ (posedge clk_40MHz) begin
        counter = counter + 1;
        state <= counter[22]; // <------ data to change
        //clk_10MHz <= counter[2];
    end
    
    // UART stuff
    reg r_Tx_DV ;
    wire w_Tx_Done;
    reg [7:0] r_Tx_Byte = 8'h00;
    //assign tx_busy = (!w_Tx_Done);

    // Generate data to send
    
    reg	[7:0] message [0:15];
    initial begin
        message[ 0] = "H";
        message[ 1] = "e";
        message[ 2] = "l";
        message[ 3] = "l";
        message[ 4] = "o";
        message[ 5] = ",";
        message[ 6] = " ";
        message[ 7] = "W";
        message[ 8] = "o";
        message[ 9] = "r";
        message[10] = "l";
        message[11] = "d";
        message[12] = "!";
        message[13] = " ";
        message[14] = 8'hd;
        message[15] = "\n";
    end

    
    always @(posedge clk_40MHz)
        r_Tx_Byte <= message[tx_index];

    //reg new_DV = 1'b0;

    //always @(posedge w_Tx_Done)
	always @(posedge clk_40MHz)
		//if ((r_Tx_DV)&&(!tx_busy))
        //if ((new_DV)&&(w_Tx_Done))
        if ((w_Tx_Done)&&(r_Tx_DV))
            tx_index <= tx_index + 1'b1;
            
	initial	r_Tx_DV = 1'b0;
	always @(posedge clk_40MHz)
        if (w_Tx_Done)
            r_Tx_DV <= 1'b0;
		else if (state)
			r_Tx_DV <= 1'b1;
		else if ((r_Tx_DV)&&(!tx_busy)&&(tx_index==4'hf))
        //else if ((r_Tx_DV)&&(w_Tx_Done)&&(tx_index==4'hf))
            r_Tx_DV <= 1'b0;
 
 	//always @(posedge clk_40MHz)
    //    new_DV = r_Tx_DV && w_Tx_Done;
 
    // 115200 baud with 40 MHz clock
    //parameter c_CLOCK_PERIOD_NS = 25; // 115200 with 10 MHz
    parameter c_CLKS_PER_BIT    = 347; // 115200
    //parameter c_CLKS_PER_BIT    = 4166; // 9600

    assign LEDG[1] = w_Tx_Done;
    assign LEDG[2] = r_Tx_DV;
    
    uart_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST
    (.i_Clock(clk_40MHz),
     .i_Tx_DV(r_Tx_DV),
     .i_Tx_Byte(r_Tx_Byte),
     .o_Tx_Active(tx_busy),
     .o_Tx_Serial(UART_TX),
     .o_Tx_Done(w_Tx_Done)
     );

    // Counter to digits thing aka bin2bcd
    parameter c_INPUT_WIDTH = 32;
    parameter c_DECIMAL_DIGITS = 10;
    
    //reg [c_DECIMAL_DIGITS*4-1:0] BCD_values;
    wire [39:0] BCD_values;
    wire BCD_data_valid = 1'b0;

    // from https://www.nandland.com/vhdl/modules/double-dabble.html
    Binary_to_BCD
    #(.INPUT_WIDTH(c_INPUT_WIDTH),
    .DECIMAL_DIGITS(c_DECIMAL_DIGITS))
    BIN2BCD_INST
      (
       .i_Clock(clk_40MHz),
       .i_Binary(counter),
       .i_Start(w_Tx_Done),
       .o_BCD(BCD_values),  
       .o_DV(BCD_data_valid)
       );

endmodule