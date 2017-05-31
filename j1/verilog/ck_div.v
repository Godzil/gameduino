module ck_div(
input ck_in,
output ck_out,
input sys_rst_i
//output locked;
);
parameter DIV_BY = 1;
parameter MULT_BY = 1;

wire ck_fb;

//DCM #(
//   .CLKDV_DIVIDE(DIV_BY),
//   .DFS_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for frequency synthesis
//   .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
//   .STARTUP_WAIT("TRUE")    // Delay configuration DONE until DCM LOCK, TRUE/FALSE
//) DCM_inst (
//   .CLK0(ck_fb),    
//   .CLKDV(ck_out), 
//   .CLKFB(ck_fb),    // DCM clock feedback
//   .CLKIN(ck_in),     // Clock input (from IBUFG, BUFG or DCM)
//   .RST(0)
//);

DCM #(
   .CLKFX_MULTIPLY(MULT_BY),
   .CLKFX_DIVIDE(DIV_BY),
   .DFS_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for frequency synthesis
   .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
   .STARTUP_WAIT("TRUE")    // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) DCM_inst (
   .CLK0(ck_fb),    
   .CLKFX(ck_out), 
   .CLKFB(ck_fb),    // DCM clock feedback
   .CLKIN(ck_in),     // Clock input (from IBUFG, BUFG or DCM)
   .RST(0)
);

//BUFG BUFG_inst(.I(ck_int), .O(ck_out));

endmodule
