`define YES
`include "revision.v"

module lfsre(
    input clk,
    output reg [16:0] lfsr);
wire d0;

xnor(d0,lfsr[16],lfsr[13]);

always @(posedge clk) begin
    lfsr <= {lfsr[15:0],d0};
end
endmodule

module oldram256x1s(
  input d,
  input we,
  input wclk,
  input [7:0] a,
  output o);

  wire sel0 = (a[7:6] == 0);
  wire o0;
  RAM64X1S r0(.O(o0), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel0 & we));

  wire sel1 = (a[7:6] == 1);
  wire o1;
  RAM64X1S r1(.O(o1), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel1 & we));

  wire sel2 = (a[7:6] == 2);
  wire o2;
  RAM64X1S r2(.O(o2), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel2 & we));

  wire sel3 = (a[7:6] == 3);
  wire o3;
  RAM64X1S r3(.O(o3), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel3 & we));

  assign o = (a[7] == 0) ? ((a[6] == 0) ? o0 : o1) : ((a[6] == 0) ? o2 : o3);
endmodule

module ring64(
  input clk,
  input i,
  output o);

  wire o0, o1, o2;
  SRL16E ring0( .CLK(clk), .CE(1), .D(i),  .A0(1), .A1(1), .A2(1), .A3(1), .Q(o0));
  SRL16E ring1( .CLK(clk), .CE(1), .D(o0), .A0(1), .A1(1), .A2(1), .A3(1), .Q(o1));
  SRL16E ring2( .CLK(clk), .CE(1), .D(o1), .A0(1), .A1(1), .A2(1), .A3(1), .Q(o2));
  SRL16E ring3( .CLK(clk), .CE(1), .D(o2), .A0(1), .A1(1), .A2(1), .A3(1), .Q(o));
endmodule

module ram256x1s(
  input d,
  input we,
  input wclk,
  input [7:0] a,
  output o);

  wire [1:0] rsel = a[7:6];
  wire [3:0] oo;
  genvar i;
  generate 
    for (i = 0; i < 4; i=i+1) begin : ramx
    RAM64X1S r0(.O(oo[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE((rsel == i) & we));
    end
  endgenerate

  assign o = oo[rsel];
endmodule

module ram448x1s(
  input d,
  input we,
  input wclk,
  input [8:0] a,
  output o);

  wire [2:0] rsel = a[8:6];
  wire [7:0] oo;
  genvar i;
  generate 
    for (i = 0; i < 7; i=i+1) begin : ramx
      RAM64X1S r0(.O(oo[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE((rsel == i) & we));
    end
  endgenerate

  assign o = oo[rsel];
endmodule

module ram400x1s(
  input d,
  input we,
  input wclk,
  input [8:0] a,
  output o);

  wire [2:0] rsel = a[8:6];
  wire [6:0] oo;
  genvar i;
  generate 
    for (i = 0; i < 6; i=i+1) begin : ramx
      RAM64X1S r0(.O(oo[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE((rsel == i) & we));
    end
  endgenerate
  RAM16X1S r6(.O(oo[6]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .D(d), .WCLK(wclk), .WE((rsel == 6) & we));

  assign o = oo[rsel];
endmodule

module ram256x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [7:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      ram256x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram32x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [4:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      RAM32X1S r0(.O(o[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .D(d[i]), .WCLK(wclk), .WE(we));
    end
  endgenerate
endmodule

module ram64x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [5:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      RAM64X1S r0(.O(o[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d[i]), .WCLK(wclk), .WE(we));
    end
  endgenerate
endmodule

module mRAM32X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  output DPO,   // port A out
  output SPO);  // port B out

  parameter INIT = 32'b0;
  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  RAM16X1D
    #( .INIT(INIT[15:0]) ) 
    lo(
    .D(D),
    .WE(WE & !A4),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPO(lDPO),
    .SPO(lSPO));
  RAM16X1D
    #( .INIT(INIT[31:16]) ) 
  hi(
    .D(D),
    .WE(WE & A4),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA4 ? hDPO : lDPO;
  assign SPO = A4 ? hSPO : lSPO;
endmodule

module mRAM64X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input A5,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  input DPRA5,
  output DPO,   // port A out
  output SPO);  // port B out

  parameter INIT = 64'b0;
  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  mRAM32X1D
    #( .INIT(INIT[31:0]) ) 
    lo(
    .D(D),
    .WE(WE & !A5),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPO(lDPO),
    .SPO(lSPO));
  mRAM32X1D
    #( .INIT(INIT[63:32]) ) 
  hi(
    .D(D),
    .WE(WE & A5),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA5 ? hDPO : lDPO;
  assign SPO = A5 ? hSPO : lSPO;
endmodule

module mRAM128X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input A5,
  input A6,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  input DPRA5,
  input DPRA6,
  output DPO,   // port A out
  output SPO);  // port B out
  parameter INIT = 128'b0;

  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  mRAM64X1D
    #( .INIT(INIT[63:0]) ) 
    lo(
    .D(D),
    .WE(WE & !A6),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPO(lDPO),
    .SPO(lSPO));
  mRAM64X1D
    #( .INIT(INIT[127:64]) ) 
    hi(
    .D(D),
    .WE(WE & A6),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA6 ? hDPO : lDPO;
  assign SPO = A6 ? hSPO : lSPO;
endmodule


module mRAM256X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input A5,
  input A6,
  input A7,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  input DPRA5,
  input DPRA6,
  input DPRA7,
  output DPO,   // port A out
  output SPO);  // port B out

  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  mRAM128X1D
    lo(
    .D(D),
    .WE(WE & !A7),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .A6(A6),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPRA6(DPRA6),
    .DPO(lDPO),
    .SPO(lSPO));
  mRAM128X1D
  hi(
    .D(D),
    .WE(WE & A7),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .A6(A6),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPRA6(DPRA6),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA7 ? hDPO : lDPO;
  assign SPO = A7 ? hSPO : lSPO;
endmodule

module ram32x8d(
  input [7:0] ad,
  input wea,
  input wclk,
  input [4:0] a,
  input [4:0] b,
  output [7:0] ao,
  output [7:0] bo
  );
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM32X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .SPO(ao[i]),
        .DPO(bo[i]));
    end
  endgenerate
endmodule

module ram64x8d(
  input [7:0] ad,
  input wea,
  input wclk,
  input [5:0] a,
  input [5:0] b,
  output [7:0] ao,
  output [7:0] bo
  );
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM64X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .A5(a[5]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .DPRA5(b[5]),
        .SPO(ao[i]),
        .DPO(bo[i]));
    end
  endgenerate
endmodule

// Same but latched read port, for CPU
module ram32x8rd(
  input wclk,
  input [15:0] ad,
  input wea,
  input [4:0] a,
  input [4:0] b,
  output reg [15:0] ao,
  output reg [15:0] bo
  );
  wire [15:0] _ao;
  wire [15:0] _bo;
  always @(posedge wclk)
  begin
    ao <= _ao;
    bo <= _bo;
  end
  genvar i;
  generate 
    for (i = 0; i < 16; i=i+1) begin : ramx
      mRAM32X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .SPO(_ao[i]),
        .DPO(_bo[i]));
    end
  endgenerate
endmodule

module ram128x8rd(
  input wclk,
  input [15:0] ad,
  input wea,
  input [6:0] a,
  input [6:0] b,
  output reg [15:0] ao,
  output reg [15:0] bo
  );
  wire [15:0] _ao;
  wire [15:0] _bo;
  always @(posedge wclk)
  begin
    ao <= _ao;
    bo <= _bo;
  end
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM128X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .A5(a[5]),
        .A6(a[6]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .DPRA5(b[5]),
        .DPRA6(b[6]),
        .SPO(_ao[i]),
        .DPO(_bo[i]));
    end
  endgenerate
endmodule

module ram256x8rd(
  input wclk,
  input [7:0] ad,
  input wea,
  input [7:0] a,
  input [7:0] b,
  output reg [7:0] ao,
  output reg [7:0] bo
  );
  wire [7:0] _ao;
  wire [7:0] _bo;
  always @(posedge wclk)
  begin
    ao <= _ao;
    bo <= _bo;
  end
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM256X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .A5(a[5]),
        .A6(a[6]),
        .A7(a[7]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .DPRA5(b[5]),
        .DPRA6(b[6]),
        .DPRA7(b[7]),
        .SPO(_ao[i]),
        .DPO(_bo[i]));
    end
  endgenerate
endmodule

module ram448x9s(
  input [8:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [8:0] o);
  genvar i;
  generate 
    for (i = 0; i < 9; i=i+1) begin : ramx
      ram448x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram400x9s(
  input [8:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [8:0] o);
  genvar i;
  generate 
    for (i = 0; i < 9; i=i+1) begin : ramx
      ram400x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram400x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      ram400x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram400x7s(
  input [6:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [6:0] o);
  genvar i;
  generate 
    for (i = 0; i < 7; i=i+1) begin : ramx
      ram400x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

// SPI can be many things, so to be clear, this implementation:
//   MSB first
//   CPOL 0, leading edge when SCK rises
//   CPHA 0, sample on leading, setup on trailing

module SPI_memory(
  input clk,
  input SCK, input MOSI, output MISO, input SSEL,
  output wire [15:0] raddr,   // read address
  output reg [15:0] waddr,    // write address
  output reg [7:0] data_w,
  input [7:0] data_r,
  output reg we,
  output reg re,
  output mem_clk
);
  reg [15:0] paddr;
  reg [4:0] count;
  wire [4:0] _count = (count == 23) ? 16 : (count + 1);

  assign mem_clk = clk;

  // sync SCK to the FPGA clock using a 3-bits shift register
  reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
  wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
  wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

  // same thing for SSEL
  reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
  wire SSEL_active = ~SSELr[1];  // SSEL is active low
  wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
  wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
  reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
  wire MOSI_data = MOSIr[1];

  assign raddr = (count[4] == 0) ? {paddr[14:0], MOSI} : paddr;

  always @(posedge clk)
  begin
    if (~SSEL_active) begin
      count <= 0;
      re <= 0;
      we <= 0;
    end else
      if (SCK_risingedge) begin
        if (count[4] == 0) begin
          we <= 0;
          paddr <= raddr;
          re <= (count == 15);
        end else begin
          data_w <= {data_w[6:0], MOSI_data};
          if (count == 23) begin
            we <= paddr[15];
            re <= !paddr[15];
            waddr <= paddr;
            paddr <= paddr + 1;
          end else begin
            we <= 0;
            re <= 0;
          end
        end
        count <= _count;
      end
      if (SCK_fallingedge) begin
        re <= 0;
        we <= 0;
      end
  end

  reg readbit;
  always @*
  begin
    case (count[2:0])
    3'd0: readbit <= data_r[7];
    3'd1: readbit <= data_r[6];
    3'd2: readbit <= data_r[5];
    3'd3: readbit <= data_r[4];
    3'd4: readbit <= data_r[3];
    3'd5: readbit <= data_r[2];
    3'd6: readbit <= data_r[1];
    3'd7: readbit <= data_r[0];
    endcase
  end
  assign MISO = readbit;

endmodule

// This is a Delta-Sigma Digital to Analog Converter
`define MSBI 12 // Most significant Bit of DAC input, 12 means 13-bit

module dac(DACout, DACin, Clk, Reset);
output DACout;         // This is the average output that feeds low pass filter
reg DACout;            // for optimum performance, ensure that this ff is in IOB
input [`MSBI:0] DACin; // DAC input (excess 2**MSBI)
input Clk;
input Reset;
reg [`MSBI+2:0] DeltaAdder; // Output of Delta adder
reg [`MSBI+2:0] SigmaAdder; // Output of Sigma adder
reg [`MSBI+2:0] SigmaLatch; // Latches output of Sigma adder
reg [`MSBI+2:0] DeltaB; // B input of Delta adder

always @(SigmaLatch) DeltaB = {SigmaLatch[`MSBI+2], SigmaLatch[`MSBI+2]} << (`MSBI+1);
always @(DACin or DeltaB) DeltaAdder = DACin + DeltaB;
always @(DeltaAdder or SigmaLatch) SigmaAdder = DeltaAdder + SigmaLatch;
always @(posedge Clk or posedge Reset)
begin
  if (Reset) begin
    SigmaLatch <= #1 1'b1 << (`MSBI+1);
    DACout <= #1 1'b0;
  end else begin
    SigmaLatch <= #1 SigmaAdder;
    DACout <= #1 SigmaLatch[`MSBI+2];
  end
end
endmodule

module top(
  input clka,
  output [2:0] vga_red,
  output [2:0] vga_green,
  output [2:0] vga_blue,
  output vga_hsync_n,
  output vga_vsync_n,

  input SCK,  // arduino 13
  input MOSI, // arduino 11
  inout MISO, // arduino 12
  input SSEL, // arduino 9
  inout AUX,  // arduino 2
  output AUDIOL,
  output AUDIOR,

  output flashMOSI,
  input  flashMISO,
  output flashSCK,
  output flashSSEL

  );


  wire mem_clk;
  wire [7:0] host_mem_data_wr;
  reg [7:0] mem_data_rd;
  reg [7:0] latched_mem_data_rd;
  wire [14:0] mem_w_addr;   // Combined write address
  wire [14:0] mem_r_addr;   // Combined read address
  wire [14:0] host_mem_w_addr;
  wire [14:0] host_mem_r_addr;
  wire host_mem_wr;
  wire mem_rd;

  wire vga_clk;
  ck_div #(.DIV_BY(2), .MULT_BY(4)) vga_ck_gen(.ck_in(clka), .ck_out(vga_clk));

  wire [15:0] j1_insn;
  wire [12:0] j1_insn_addr;
  wire [15:0] j1_mem_addr;
  wire [15:0] j1_mem_dout;
  wire j1_mem_wr;

  wire [7:0] j1insnl_read;
  wire [7:0] j1insnh_read;
  wire [7:0] mem_data_rd0;
  wire [7:0] mem_data_rd1;
  wire [7:0] mem_data_rd2;
  wire [7:0] mem_data_rd3;
  wire [7:0] mem_data_rd4;
  wire [7:0] mem_data_rd5;

  wire gdMISO;

  always @(posedge vga_clk)
  if (mem_rd)
    latched_mem_data_rd <= mem_data_rd;

  SPI_memory spi1(
    .clk(vga_clk),
    .SCK(SCK), .MOSI(MOSI), .MISO(gdMISO), .SSEL(SSEL),
    .raddr(host_mem_r_addr),
    .waddr(host_mem_w_addr),
    .data_w(host_mem_data_wr),
    .data_r(latched_mem_data_rd),
    .we(host_mem_wr),
    .re(mem_rd),
    .mem_clk(mem_clk));
  wire host_busy = host_mem_wr | mem_rd;
  wire mem_wr =            host_busy ? host_mem_wr : j1_mem_wr;
  wire [7:0] mem_data_wr = host_busy ? host_mem_data_wr : j1_mem_dout;
  wire [14:0] mem_addr =   host_busy ? (host_mem_wr ? host_mem_w_addr : host_mem_r_addr) : j1_mem_addr;
  assign mem_w_addr =      host_busy ? host_mem_w_addr : j1_mem_addr;
  assign mem_r_addr =      host_busy ? host_mem_r_addr : j1_mem_addr;

  reg signed [15:0] sample_l;
  reg signed [15:0] sample_r;
  reg [6:0] modvoice = 64;
  reg [14:0] bg_color;
  reg [7:0] pin2mode = 0;
  wire pin2f = (pin2mode == 8'h46);
  wire pin2j = (pin2mode == 8'h4A);

  wire flashsel = (AUX == 0) & pin2f;

  assign MISO = SSEL ? (flashsel ? flashMISO : 1'bz) : gdMISO;
  // assign MISO = SSEL ? (1'bz ) : gdMISO;
  // PULLUP MISO_pullup(.O(MISO));
  // IOBUF MISO_iobuf(
  //   .I(gdMISO),
  //   .IO(MISO),
  //   .T(SSEL));


  // user-visible registers
  reg [7:0] frames;
  reg [8:0] scrollx;
  reg [8:0] scrolly;
  reg jkmode;

  wire [7:0] palette16l_read;
  wire [7:0] palette16h_read;
  wire [4:0] palette16_addr;
  wire [15:0] palette16_data;

  // 11'b00001xxxxx0: low
  wire palette16_wr = (mem_wr & (mem_w_addr[14:11] == 5) & (mem_w_addr[10:6] == 1));
  ram32x8d palette16l(
    .a(mem_addr[5:1]),
    .wclk(mem_clk),
    .wea((mem_w_addr[0] == 0) & palette16_wr),
    .ad(mem_data_wr),
    .ao(palette16l_read),
    .b(palette16_addr),
    .bo(palette16_data[7:0]));
  ram32x8d palette16h(
    .a(mem_addr[5:1]),
    .wclk(mem_clk),
    .wea((mem_w_addr[0] == 1) & palette16_wr),
    .ad(mem_data_wr),
    .ao(palette16h_read),
    .b(palette16_addr),
    .bo(palette16_data[15:8]));

  wire [7:0] palette4l_read;
  wire [7:0] palette4h_read;
  wire [4:0] palette4_addr;
  wire [15:0] palette4_data;

  // 11'b00010xxxxx0: low
  wire palette4_wr = (mem_wr & (mem_w_addr[14:11] == 5) & (mem_w_addr[10:6] == 2));
  ram32x8d palette4l(
    .a(mem_addr[5:1]),
    .wclk(mem_clk),
    .wea((mem_w_addr[0] == 0) & palette4_wr),
    .ad(mem_data_wr),
    .ao(palette4l_read),
    .b(palette4_addr),
    .bo(palette4_data[7:0]));
  ram32x8d palette4h(
    .a(mem_addr[5:1]),
    .wclk(mem_clk),
    .wea((mem_w_addr[0] == 1) & palette4_wr),
    .ad(mem_data_wr),
    .ao(palette4h_read),
    .b(palette4_addr),
    .bo(palette4_data[15:8]));

  // Generate CounterX and CounterY
  // A single line is 1040 clocks.  Line pair is 2080 clocks.

  reg [10:0] CounterX;
  reg [9:0] CounterY;
  wire CounterXmaxed = (CounterX==1040);

  always @(posedge vga_clk)
  if(CounterXmaxed)
    CounterX <= 0;
  else
    CounterX <= CounterX + 1;
  wire lastline = (CounterY == 665);
  wire [9:0] _CounterY = lastline ? 0 : (CounterY + 1);

  always @(posedge vga_clk)
  if (CounterXmaxed) begin
    CounterY <= _CounterY;
    if (lastline)
      frames <= frames + 1;
  end

  reg [12:0] comp_workcnt; // Compositor work address
  reg comp_workcnt_lt_400;
  always @(posedge vga_clk)
  begin
    if (CounterXmaxed & (CounterY[0] == 0)) begin
      comp_workcnt <= 0;
      comp_workcnt_lt_400 <= 1;
    end else begin
      comp_workcnt <= comp_workcnt + 1;
      if (comp_workcnt == 399)
        comp_workcnt_lt_400 <= 0;
    end
  end

// horizontal
//   Front porch  56
//   Sync         120
//   Back porch   64

// vertical
//   Front porch  37 lines
//   Sync         6
//   Back porch   23

// `define HSTART (53 + 120 + 61)
`define HSTART 0

  reg vga_HS, vga_VS, vga_active;
  always @(posedge vga_clk)
  begin
    vga_HS <= ((800 + 61) <= CounterX) & (CounterX < (800 + 61 + 120));
    vga_VS <= (35 <= CounterY) & (CounterY < (35 + 6));
    vga_active = ((`HSTART + 1) <= CounterX) & (CounterX < (`HSTART + 1 + 800)) & ((35 + 6 + 21) < CounterY) & (CounterY <= (35 + 6 + 21 + 600));
  end

  wire [10:0] xx = (CounterX - `HSTART);
  wire [10:0] xx_1 = (CounterX - `HSTART + 1);
  wire [10:0] yy = (CounterY + 2 - (35 + 6 + 21 + 1));    // yy range 0-665

  wire [10:0] column = comp_workcnt + scrollx;
  wire [10:0] row    = yy[10:1] + scrolly;
  wire [7:0] glyph;

  wire [11:0] picaddr = {row[8:3], column[8:3]};


  wire en_pic = (mem_addr[14:12] == 0);
  RAM_PICTURE picture(
    .dia(0), 
	 .doa(glyph), 
	 .wea(0),     
	 .ena(1), 
	 .clka(vga_clk), 
	 .addra(picaddr),
    .dib(mem_data_wr), 
	 .dob(mem_data_rd0),      
	 .web(mem_wr), 
	 .enb(en_pic), 
	 .clkb(mem_clk),
	 .addrb(mem_addr)
	 );

  reg [2:0] _column;
  always @(posedge vga_clk)
    _column = column;

  wire en_chr = (mem_addr[14:12] == 1);
  wire [1:0] charout;
  RAM_CHR chars(
    .dia(0), .doa(charout), .wea(0),     .ena(1), .clka(vga_clk), .addra({glyph, row[2:0], _column[2], ~_column[1:0]}),
    .dib(mem_data_wr), .dob(mem_data_rd1),             .web(mem_wr), .enb(en_chr), .clkb(mem_clk), .addrb(mem_addr));

  reg [7:0] _glyph;
  always @(posedge vga_clk)
    _glyph <= glyph;

  wire [4:0] bg_r;
  wire [4:0] bg_g;
  wire [4:0] bg_b;

  wire en_pal = (mem_addr[14:11] == 4'b0100);
  wire [15:0] char_matte;
  RAM_PAL charpalette(
    .DIA(mem_data_wr),
    .WEA(mem_wr),
    .ENA(en_pal),
    .CLKA(mem_clk),
    .ADDRA(mem_addr),
    .DOA(mem_data_rd2),
    .SSRA(0),

    .DIB(0),
    .WEB(0),
    .ENB(1),
    .CLKB(vga_clk),
    .ADDRB({_glyph, charout}),
    .DOB(char_matte),
    .SSRB(0)
  );
  // wire [4:0] bg_mix_r = bg_color[14:10] + char_matte[14:10];
  // wire [4:0] bg_mix_g = bg_color[9:5]   + char_matte[9:5];
  // wire [4:0] bg_mix_b = bg_color[4:0]   + char_matte[4:0];
  // wire [14:0] char_final = char_matte[15] ? {bg_mix_r, bg_mix_g, bg_mix_b} : char_matte[14:0];
  wire [14:0] char_final = char_matte[15] ? bg_color : char_matte[14:0];

  reg [7:0] mem_data_rd_reg;

  // Collision detection RAM is readable during vblank
  // writes coll_d to coll_w_addr during render
  wire coll_rd = (yy >= 600); // 1 means reading
  wire [7:0] coll_d;
  wire [7:0] coll_w_addr;
  wire coll_we;
  wire [7:0] coll_addr = coll_rd ? mem_r_addr[7:0] : coll_w_addr;
  wire [7:0] coll_o;
  ram256x8s coll(.o(coll_o), .a(coll_addr), .d(coll_d), .wclk(vga_clk), .we(~coll_rd & coll_we));
  wire [7:0] screenshot_rd;

  wire [7:0] voicefl_read;
  wire [7:0] voicefh_read;
  wire [7:0] voicela_read;
  wire [7:0] voicera_read;

  reg j1_reset = 0;
  reg spr_disable = 0;
  reg spr_page = 0;

  // Screenshot notes
  // three states, controlled by screenshot_primed, _done:
  //  primed done                         composer.A
  //  0      0     screenshot disabled    write(comp_write)
  //  1      0     screenshot primed      write(comp_write)
  //  1      1     screenshot done        read(mem_r_addr[9:1])

  reg [8:0] screenshot_yy;  // 9 bits, 0-400
  reg screenshot_primed;
  reg screenshot_done;
  wire screenshot_reset;
  wire [8:0] public_yy = coll_rd ? 300 : yy[10:1];

  always @(posedge vga_clk)
  begin
    if (screenshot_reset)
      screenshot_done <= 0;
    else if (CounterXmaxed & screenshot_primed & !screenshot_done & (public_yy == screenshot_yy)) begin
      screenshot_done <= 1;
    end
  end

  always @(mem_data_rd_reg)
  begin
    casex (mem_r_addr[10:0])
    11'h000: mem_data_rd_reg <= 8'h6d;  // Gameduino ident
    11'h001: mem_data_rd_reg <= `REVISION;
    11'h002: mem_data_rd_reg <= frames;
    11'h003: mem_data_rd_reg <= coll_rd;  // called VBLANK, but really "is coll readable?"
    11'h004: mem_data_rd_reg <= scrollx[7:0];
    11'h005: mem_data_rd_reg <= scrollx[8];
    11'h006: mem_data_rd_reg <= scrolly[7:0];
    11'h007: mem_data_rd_reg <= scrolly[8];
    11'h008: mem_data_rd_reg <= jkmode;
    11'h009: mem_data_rd_reg <= j1_reset;
    11'h00a: mem_data_rd_reg <= spr_disable;
    11'h00b: mem_data_rd_reg <= spr_page;
    11'h00c: mem_data_rd_reg <= pin2mode;
    11'h00e: mem_data_rd_reg <= bg_color[7:0];
    11'h00f: mem_data_rd_reg <= bg_color[14:8];
    11'h010: mem_data_rd_reg <= sample_l[7:0];
    11'h011: mem_data_rd_reg <= sample_l[15:8];
    11'h012: mem_data_rd_reg <= sample_r[7:0];
    11'h013: mem_data_rd_reg <= sample_r[15:8];
    11'h014: mem_data_rd_reg <= modvoice;
    11'h01e: mem_data_rd_reg <= public_yy[7:0];
    11'h01f: mem_data_rd_reg <= {screenshot_done, 6'b000000, public_yy[8]};

    11'b00001xxxxx0: mem_data_rd_reg <= palette16l_read;
    11'b00001xxxxx1: mem_data_rd_reg <= palette16h_read;
    11'b00010xxxxx0: mem_data_rd_reg <= palette4l_read;
    11'b00010xxxxx1: mem_data_rd_reg <= palette4h_read;
    11'b001xxxxxxxx:
      mem_data_rd_reg <= coll_rd ? coll_o : 8'hff;
    11'b010xxxxxx00: mem_data_rd_reg <= voicefl_read;
    11'b010xxxxxx01: mem_data_rd_reg <= voicefh_read;
    11'b010xxxxxx10: mem_data_rd_reg <= voicela_read;
    11'b010xxxxxx11: mem_data_rd_reg <= voicera_read;
    11'b011xxxxxxx0: mem_data_rd_reg <= j1insnl_read;
    11'b011xxxxxxx1: mem_data_rd_reg <= j1insnh_read;
    11'b1xxxxxxxxxx: mem_data_rd_reg <= screenshot_rd;
    // default: mem_data_rd_reg <= 0;
    endcase
  end

  reg [17:0] soundcounter;
  always @(posedge vga_clk)
    soundcounter <= soundcounter + 1;
  wire [5:0] viN = soundcounter + 1;
  wire [5:0] vi = soundcounter;

  wire voice_wr = mem_wr & (mem_w_addr[14:11] == 5) & (mem_w_addr[10:8] == 3'b010);
  wire voicefl_wr = voice_wr & (mem_w_addr[1:0] == 2'b00);
  wire voicefh_wr = voice_wr & (mem_w_addr[1:0] == 2'b01);
  wire voicela_wr = voice_wr & (mem_w_addr[1:0] == 2'b10);
  wire voicera_wr = voice_wr & (mem_w_addr[1:0] == 2'b11);

  wire [7:0] voicela_data;
  wire [7:0] voicera_data;
  wire [7:0] voicefl_data;
  wire [7:0] voicefh_data;
  wire [5:0] voice_addr = mem_addr[7:2];

  ram64x8d voicefl(
    .a(voice_addr),
    .wclk(mem_clk),
    .wea(voicefl_wr),
    .ad(mem_data_wr),
    .ao(voicefl_read),
    .b(viN),
    .bo(voicefl_data));

  ram64x8d voicefh(
    .a(voice_addr),
    .wclk(mem_clk),
    .wea(voicefh_wr),
    .ad(mem_data_wr),
    .ao(voicefh_read),
    .b(viN),
    .bo(voicefh_data));

  ram64x8d voicela(
    .a(voice_addr),
    .wclk(mem_clk),
    .wea(voicela_wr),
    .ad(mem_data_wr),
    .ao(voicela_read),
    .b(viN),
    .bo(voicela_data));

  ram64x8d voicera(
    .a(voice_addr),
    .wclk(mem_clk),
    .wea(voicera_wr),
    .ad(mem_data_wr),
    .ao(voicera_read),
    .b(viN),
    .bo(voicera_data));

  assign screenshot_reset = mem_wr & (mem_w_addr[14:11] == 5) & (mem_w_addr[10:0] == 11'h01f);
  always @(posedge mem_clk)
  begin
    if (mem_wr & mem_w_addr[14:11] == 5)
      casex (mem_w_addr[10:0])
      11'h004: scrollx[7:0]   <= mem_data_wr;
      11'h005: scrollx[8]     <= mem_data_wr;
      11'h006: scrolly[7:0]   <= mem_data_wr;
      11'h007: scrolly[8]     <= mem_data_wr;
      11'h008: jkmode         <= mem_data_wr;
      11'h009: j1_reset       <= mem_data_wr;
      11'h00a: spr_disable    <= mem_data_wr;
      11'h00b: spr_page       <= mem_data_wr;
      11'h00c: pin2mode       <= mem_data_wr;
      11'h00e: bg_color[7:0]  <= mem_data_wr;
      11'h00f: bg_color[14:8] <= mem_data_wr;
      11'h010: sample_l[7:0]  <= mem_data_wr;
      11'h011: sample_l[15:8] <= mem_data_wr;
      11'h012: sample_r[7:0]  <= mem_data_wr;
      11'h013: sample_r[15:8] <= mem_data_wr;
      11'h014: modvoice       <= mem_data_wr;

      11'h01e: screenshot_yy[7:0] <= mem_data_wr;
      11'h01f: begin screenshot_primed <= mem_data_wr[7];
               screenshot_yy[8] <= mem_data_wr; end
      endcase
  end

  /*
    0000-0fff Picture
    1000-1fff Character
    2000-27ff Character
    2800-2fff (Unused)
    3000-37ff Sprite values
    3800-3fff Sprite palette
    4000-7fff Sprite image
  */
  always @*
  begin
    case (mem_addr[14:11]) // 2K pages
    4'h0: mem_data_rd <= mem_data_rd0;  // pic
    4'h1: mem_data_rd <= mem_data_rd0;
    4'h2: mem_data_rd <= mem_data_rd1;  // chr
    4'h3: mem_data_rd <= mem_data_rd1;
    4'h4: mem_data_rd <= mem_data_rd2;  // pal
    4'h5: mem_data_rd <= mem_data_rd_reg;
    4'h6: mem_data_rd <= mem_data_rd3;  // sprval
    4'h7: mem_data_rd <= mem_data_rd4;  // sprpal
    4'h8: mem_data_rd <= mem_data_rd5;  // sprimg
    4'h9: mem_data_rd <= mem_data_rd5;  // sprimg
    4'ha: mem_data_rd <= mem_data_rd5;  // sprimg
    4'hb: mem_data_rd <= mem_data_rd5;  // sprimg
    4'hc: mem_data_rd <= mem_data_rd5;  // sprimg
    4'hd: mem_data_rd <= mem_data_rd5;  // sprimg
    4'he: mem_data_rd <= mem_data_rd5;  // sprimg
    4'hf: mem_data_rd <= mem_data_rd5;  // sprimg

    default: mem_data_rd <= 8'h97;
    endcase
  end

  // Sprite memory

  // Stage 1: scan for valid
  reg [8:0] s1_count;

  wire en_sprval = (mem_addr[14:11] == 4'b0110);
  wire [31:0] sprval_data;
  RAM_SPRVAL sprval(
    .DIA(mem_data_wr),
    .WEA(mem_wr),
    .ENA(en_sprval),
    .CLKA(mem_clk),
    .ADDRA(mem_addr),
    .DOA(mem_data_rd3),
    .SSRA(0),

    .DIB(0),
    .WEB(0),
    .ENB(1),
    .CLKB(vga_clk),
    .ADDRB({spr_page, s1_count[7:0]}),
    .DOB(sprval_data),
    .SSRB(0)
  );
  wire [9:0] sprpal_addr;
  wire [15:0] sprpal_data;
  wire en_sprpal = (mem_addr[14:11] == 4'b0111);
  RAM_SPRPAL sprpal(
    .DIA(mem_data_wr),
    .WEA(mem_wr),
    .ENA(en_sprpal),
    .CLKA(mem_clk),
    .ADDRA(mem_addr),
    .DOA(mem_data_rd4),
    .SSRA(0),

    .DIB(0),
    .WEB(0),
    .ENB(1),
    .CLKB(vga_clk),
    .ADDRB(sprpal_addr),
    .DOB(sprpal_data),
    .SSRB(0)
  );
  wire [13:0] sprimg_readaddr;
  wire [7:0] sprimg_data;
  wire en_sprimg = (mem_addr[14] == 1'b1);
//  ram16K_8_8 sprimg(
  RAM_SPRIMG sprimg(
    .dia(mem_data_wr),
    .wea(mem_wr),
    .ena(en_sprimg),
    .clka(mem_clk),
    .addra(mem_addr),
    .doa(mem_data_rd5),
    .ssra(0),

    .dib(0),
    .web(0),
    .enb(1),
    .clkb(vga_clk),
    .addrb(sprimg_readaddr),
    .dob(sprimg_data),
    .ssrb(0)
  );

  // Stage 1: scan for valid

  reg s1_consider;      // Consider the sprval on the next cycle
  wire s2_room;         // Does s2 fifo have room for one entry?
  always @(posedge vga_clk)
  begin
    if (comp_workcnt == 0) begin
      s1_count <= 0;
      s1_consider <= 0;
    end else
      if ((s1_count <= 255) & s2_room) begin
        s1_count <= s1_count + 1;
        s1_consider <= 1;
      end else begin
        s1_consider <= 0;
      end
  end
  wire [31:0] s1_out = sprval_data;
  wire [8:0] s1_y_offset = yy[9:1] - s1_out[24:16];
  wire s1_visible = (spr_disable == 0) & (s1_y_offset[8:4] == 0);
  wire s1_valid = s1_consider & s1_visible;
  reg [8:0] s1_id;
  always @(posedge vga_clk)
    s1_id <= s1_count;

  // Stage 2: fifo
  wire [4:0] s2_fullness;
  wire s3_read;
  wire [40:0] s2_out;
  fifo #(40) s2(.clk(vga_clk),
                .wr(s1_valid), .datain({s1_id, s1_out}),
                .rd(s3_read), .dataout(s2_out),
                .fullness(s2_fullness));
  assign s2_room = (s2_fullness < 14);

  wire s2_valid = s2_fullness != 0;

  // 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
  //    [     image     ] [          y             ]       [PAL] [  ROT ] [           x            ]

  /* Stage 3: read sprimg
    consume s2_out on last cycle 
    out: s3_valid, s3_pal, s3_out, s3_compaddr
  */

  reg [4:0] s3_state;
  reg [3:0] s3_pal;
  reg [31:0] s3_in;
  assign s3_read = (s3_state == 15);
  always @(posedge vga_clk)
  begin
    if (comp_workcnt < 403)
      s3_state <= 16;
    else if (s3_state == 16) begin
      if (s2_valid) begin
        s3_state <= 0;
        s3_in <= s2_out;
      end
    end else begin
      s3_state <= s3_state + 1;
    end
    s3_pal <= s2_out[15:12];
  end
  wire [3:0] s3_yoffset = yy[4:1] - s2_out[19:16];
  wire [3:0] s3_prev_state = (s3_state == 16) ? 0 : (s3_state + 1);
  wire [3:0] readx = (s2_out[9] ? s3_yoffset : s3_prev_state) ^ {4{s2_out[10]}};
  wire [3:0] ready = (s2_out[9] ? s3_prev_state : s3_yoffset) ^ {4{s2_out[11]}};
  assign sprimg_readaddr = {s2_out[30:25], ready, readx};
  wire [7:0] s3_out = sprimg_data;
  wire [8:0] s3_compaddr = s2_out[8:0] + s3_state;
  wire s3_valid = (s3_state != 16) & (s3_compaddr < 400);
  reg [8:0] s3_id;
  reg s3_jk;
  always @(posedge vga_clk)
  begin
    s3_id <= s2_out[40:32];
    s3_jk <= s2_out[31];
  end

  /* Stage 4: read sprpal
    out: s4_valid, s4_out, s4_compaddr
  */
  reg [15:0] sprpal4;
  reg [15:0] sprpal16;
  assign sprpal_addr = {s3_pal[1:0], s3_out};
  reg [8:0] s4_compaddr;
  reg s4_valid;
  reg [8:0] s4_id;
  reg s4_jk;
  wire [3:0] subfield4 = s3_pal[1] ? s3_out[7:4] : s3_out[3:0];
  wire [1:0] subfield2 = s3_pal[2] ? (s3_pal[1] ? s3_out[7:6] : s3_out[5:4]) : (s3_pal[1] ? s3_out[3:2] : s3_out[1:0]);
  assign palette4_addr = {s3_pal[0], subfield2};
  assign palette16_addr = {s3_pal[0], subfield4};
  always @(posedge vga_clk)
  begin
    s4_compaddr <= s3_compaddr;
    s4_valid <= s3_valid;
    s4_id <= s3_id;
    s4_jk <= s3_jk;
    sprpal4 <= palette4_data;
    sprpal16 <= palette16_data;
  end
  wire [15:0] s4_out = s3_pal[3] ? sprpal4 : ((s3_pal[3:2] == 0) ? sprpal_data : sprpal16);

  // Common signals for collision and composite
  wire sprite_write = s4_valid & !s4_out[15];  // transparency

  // Collision detect
  // Have 400x9 occupancy buffer.  If NEW overwrites a fragment OLD
  // (and their groups differ) write OLD to coll[NEW].
  // Reset coll to FF at start of frame.
  // Reset occ to FF at start of line, since sprites drawn 0->ff,
  // ff is impossible and means empty.

  wire coll_scrub = (yy == 0) & (comp_workcnt < 256);
  wire [8:0] occ_addr = comp_workcnt_lt_400 ? comp_workcnt : s4_compaddr;
  wire [8:0] occ_d = comp_workcnt_lt_400 ? 9'hff : {s4_jk, s4_id[7:0]};
  wire [8:0] oldocc;
  wire occ_w = comp_workcnt_lt_400 | sprite_write;
  ram400x9s occ(.o(oldocc), .a(occ_addr), .d(occ_d), .wclk(vga_clk), .we(occ_w));
  assign coll_d = coll_scrub ? 8'hff : oldocc[7:0];
  assign coll_w_addr = coll_scrub ? comp_workcnt : s4_id[7:0];
  // old contents 0xff, never write
  // jkmode=1 and JK's differ, allow write
  wire overwriting = (oldocc[7:0] != 8'hff);
  wire jkpass = (jkmode == 0) | (oldocc[8] ^ s4_jk);
  assign coll_we = coll_scrub | ((403 <= comp_workcnt) & sprite_write & overwriting & jkpass);

  // Composite

  wire comp_read = yy[1];   // which block is reading
  wire [8:0] comp_scanout = xx[9:1];
  wire [8:0] comp_write = (comp_workcnt < 403) ? (comp_workcnt - 3) : s4_compaddr;
  wire comp_part1 = (3 <= comp_workcnt) & (comp_workcnt < 403);
`ifdef NELLY
  wire [14:0] comp_out0;
  wire [14:0] comp_out1;
  RAMB16_S18_S18 composer(
    .DIPA(0),
    .DIA(comp_part1 ? char_final : s4_out),
    .WEA(comp_read == 1 & (comp_part1 | sprite_write)),
    .ENA(1),
    .CLKA(vga_clk),
    .ADDRA({1'b0, (comp_read == 0) ? comp_scanout : comp_write[8:0]}),
    .DOA(comp_out0),
    .SSRA(0),

    .DIPB(0),
    .DIB(comp_part1 ? char_final : s4_out),
    .WEB(comp_read == 0 & (comp_part1 | sprite_write)),
    .ENB(1),
    .CLKB(vga_clk),
    .ADDRB({1'b1, (comp_read == 1) ? comp_scanout : comp_write[8:0]}),
    .DOB(comp_out1),
    .SSRB(0)
  );
  wire [14:0] comp_out = comp_read ? comp_out1 : comp_out0;
`else
  wire ss = screenshot_primed & screenshot_done;  // screenshot readout mode
  wire [15:0] screenshot_rdHL;
  wire [14:0] comp_out;
  // Port A is the write, or read when screenshot is ready
  // Port B is scanout
  RAMB16_S18_S18
  composer(
    .DIPA(0),
    .DIA(comp_part1 ? char_final : s4_out),
    .WEA(!ss & (comp_part1 | sprite_write)),
    .ENA(1),
    .CLKA(vga_clk),
    .ADDRA(ss ? {screenshot_yy[0], mem_r_addr[9:1]} : {comp_read, comp_write[8:0]}),
    .DOA(screenshot_rdHL),
    .SSRA(0),

    .DIPB(0),
    .DIB(0),
    .WEB(0),
    .ENB(1),
    .CLKB(vga_clk),
    .ADDRB({!comp_read, comp_scanout}),
    .DOB(comp_out),
    .SSRB(0)
  );
  assign screenshot_rd = mem_r_addr[0] ? screenshot_rdHL[15:8] : screenshot_rdHL[7:0];
`endif
  assign {bg_r,bg_g,bg_b} = comp_out;

  // Figure out from above signals when composite completes
  // by detecting pipeline idle
  wire composite_complete = (comp_workcnt > 403) & (s1_count == 256) & !s1_consider & !s2_valid & (s3_state == 16) & !s4_valid;

  // Signal generation

  wire [16:0] lfsr;
  lfsre lfsr0(
    .clk(vga_clk),
    .lfsr(lfsr));

  wire [1:0] dith;
  // 0 2
  // 3 1
  assign dith = {(xx[0]^yy[0]), yy[0]};
  wire [5:0] dith_r = (bg_r + dith);
  wire [5:0] dith_g = (bg_g + dith);
  wire [5:0] dith_b = (bg_b + dith);
  wire [2:0] f_r = {3{dith_r[5]}} | dith_r[4:2];
  wire [2:0] f_g = {3{dith_g[5]}} | dith_g[4:2];
  wire [2:0] f_b = {3{dith_b[5]}} | dith_b[4:2];

  wire [2:0] ccc = { charout[1], charout[0], charout[0] };
  assign vga_red =    vga_active ? f_r : 0;
  assign vga_green =  vga_active ? f_g : 0;
  assign vga_blue =   vga_active ? f_b : 0;
  assign vga_hsync_n = ~vga_HS;
  assign vga_vsync_n = ~vga_VS;

  /*
  An 18-bit counter, multiplied by the frequency gives a single bit
  pulse that advances the voice's wave counter.
  Frequency of 4 means 1Hz, 16385 means 4095.75Hz.
  18-bit counter increments every 1/(2**18), or 262144 Hz.
  */
`define MASTERFREQ (1 << 22)
  reg [27:0] d;
  wire [27:0] dInc = d[27] ? (`MASTERFREQ) : (`MASTERFREQ - 50000000);
  wire [27:0] dN = d + dInc;

  reg [16:0] soundmaster;   // This increments at MASTERFREQ Hz
  always @(posedge vga_clk)
  begin
    d = dN;
    // clock B tick whenever d[27] is zero
    if (dN[27] == 0) begin
      soundmaster <= soundmaster + 1;
    end
  end

  wire [6:0] hsin;
  wire [6:0] wavecounter;
  wire [6:0] note = wavecounter[6:0];

`ifdef YES
RAM64X1S #(.INIT(64'b0000000000110101100010001111010010010111100010001101011000000000) /* 0 */
) sin0(.O(hsin[0]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
RAM64X1S #(.INIT(64'b0101010101101100011100010101001111100101010001110001101101010101) /* 1 */
) sin1(.O(hsin[1]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
RAM64X1S #(.INIT(64'b0110011001001001010101001100111111111001100101010100100100110011) /* 2 */
) sin2(.O(hsin[2]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
RAM64X1S #(.INIT(64'b0010110100100100110011000011111111111110000110011001001001011010) /* 3 */
) sin3(.O(hsin[3]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
RAM64X1S #(.INIT(64'b0001110011100011110000111111111111111111111000011110001110011100) /* 4 */
) sin4(.O(hsin[4]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
RAM64X1S #(.INIT(64'b0000001111100000001111111111111111111111111111100000001111100000) /* 5 */
) sin5(.O(hsin[5]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
RAM64X1S #(.INIT(64'b0000000000011111111111111111111111111111111111111111110000000000) /* 6 */
) sin6(.O(hsin[6]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]), .D(0), .WCLK(vga_clk), .WE(0));
`else
ROM64X1 #(.INIT(64'b0000000000110101100010001111010010010111100010001101011000000000) /* 0 */) sin0(.O(hsin[0]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
ROM64X1 #(.INIT(64'b0101010101101100011100010101001111100101010001110001101101010101) /* 1 */) sin1(.O(hsin[1]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
ROM64X1 #(.INIT(64'b0110011001001001010101001100111111111001100101010100100100110011) /* 2 */) sin2(.O(hsin[2]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
ROM64X1 #(.INIT(64'b0010110100100100110011000011111111111110000110011001001001011010) /* 3 */) sin3(.O(hsin[3]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
ROM64X1 #(.INIT(64'b0001110011100011110000111111111111111111111000011110001110011100) /* 4 */) sin4(.O(hsin[4]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
ROM64X1 #(.INIT(64'b0000001111100000001111111111111111111111111111100000001111100000) /* 5 */) sin5(.O(hsin[5]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
ROM64X1 #(.INIT(64'b0000000000011111111111111111111111111111111111111111110000000000) /* 6 */) sin6(.O(hsin[6]), .A0(note[0]), .A1(note[1]), .A2(note[2]), .A3(note[3]), .A4(note[4]), .A5(note[5]));
`endif

  wire signed [7:0] sin = note[6] ? (8'h00 - hsin) : hsin;

  wire voiceshape = voicefh_data[7];
  wire [14:0] voicefreq = {voicefh_data[6:0], voicefl_data};

  wire [35:0] derived = {1'b0, soundmaster} * voicefreq;

  wire highfreq = voicefreq[14];
  wire newpulse = highfreq ? derived[18] : derived[17]; // pulse is a square wave frequency 64*f
  wire oldpulse;
  wire [6:0] nextwavecounter = voiceshape ? lfsr : (wavecounter + (highfreq ? 2 : 1));
  wire [6:0] _wavecounter = (newpulse != oldpulse) ? nextwavecounter : wavecounter;

`ifdef NELLY
  ram64x8s voicestate(
    .a(viN),
    .we(1),
    .wclk(vga_clk),
    .d({_wavecounter, newpulse}),
    .o({wavecounter, oldpulse}));
`else
  wire [8:0] vsi = {_wavecounter, newpulse};
  wire [8:0] vso;
  ring64 vs0(.clk(vga_clk), .i(vsi[0]), .o(vso[0]));
  ring64 vs1(.clk(vga_clk), .i(vsi[1]), .o(vso[1]));
  ring64 vs2(.clk(vga_clk), .i(vsi[2]), .o(vso[2]));
  ring64 vs3(.clk(vga_clk), .i(vsi[3]), .o(vso[3]));
  ring64 vs4(.clk(vga_clk), .i(vsi[4]), .o(vso[4]));
  ring64 vs5(.clk(vga_clk), .i(vsi[5]), .o(vso[5]));
  ring64 vs6(.clk(vga_clk), .i(vsi[6]), .o(vso[6]));
  ring64 vs7(.clk(vga_clk), .i(vsi[7]), .o(vso[7]));
  assign wavecounter = vso[7:1];
  assign oldpulse = vso[0];
`endif

  wire signed [8:0] lamp = voicela_data;
  wire signed [8:0] ramp = voicera_data;
  reg signed [35:0] lmodulated;
  reg signed [35:0] rmodulated;
  always @(posedge vga_clk)
  begin
    lmodulated = lamp * sin;
    rmodulated = ramp * sin;
  end

  // Have lmodulated and rmodulated

  reg signed [15:0] lacc;
  reg signed [15:0] racc;
  wire signed [15:0] lsum = lacc + lmodulated[15:0];
  wire signed [15:0] rsum = racc + rmodulated[15:0];
  wire signed [31:0] lprod = lacc * lmodulated;
  wire signed [31:0] rprod = racc * rmodulated;
  wire zeroacc = (vi == 63);
  wire [15:0] _lacc = zeroacc ? sample_l : ((vi == modvoice) ? lprod[30:15] : lsum);
  wire [15:0] _racc = zeroacc ? sample_r : ((vi == modvoice) ? rprod[30:15] : rsum);
  reg signed [12:0] lvalue;
  reg signed [12:0] rvalue;
  always @(posedge vga_clk)
  begin
    if (vi == 63) begin
      lvalue <= lsum[15:3] /* + sample_l + 32768 */;
      rvalue <= rsum[15:3] /* + sample_r + 32768 */;
    end
    lacc <= _lacc;
    racc <= _racc;
  end

  wire signed [7:0] dither = soundcounter;
//  wire [15:0] dither = {soundcounter[0],
//                       soundcounter[1],
//                       soundcounter[2],
//                       soundcounter[3],
//                       soundcounter[4],
//                       soundcounter[5],
//                       soundcounter[6],
//                       soundcounter[7],
//                       soundcounter[8],
//                       soundcounter[9],
//                       soundcounter[10],
//                       soundcounter[11],
//                       soundcounter[12],
//                       soundcounter[13],
//                       soundcounter[14],
//                       soundcounter[15]
//                       };

`ifdef NELLY
  wire lau_out = lvalue >= dither;
  wire rau_out = rvalue >= dither;

  assign AUDIOL = lau_out;
  assign AUDIOR = rau_out;
`else
  wire [12:0] ulvalue = lvalue ^ 4096;
  wire [12:0] urvalue = rvalue ^ 4096;
  dac ldac(AUDIOL, ulvalue, vga_clk, 0);
  dac rdac(AUDIOR, urvalue, vga_clk, 0);
`endif

  reg [2:0] busyhh;
  always @(posedge vga_clk) busyhh = { busyhh[1:0], host_busy };

  // J1 Peripherals
  reg [7:0] icap_i;   // ICAP in
  reg icap_write;
  reg icap_ce;
  reg icap_clk;

  wire [7:0] icap_o;  // ICAP out
  wire  icap_busy;

  reg j1_p2_dir = 1;    // pin defaults to input
  reg j1_p2_o = 1;

  ICAP_SPARTAN3A ICAP_SPARTAN3A_inst (
    .O(icap_o),
    .BUSY(icap_busy),
    .I(icap_i),
    .WRITE(icap_write),
    .CE(icap_ce),
    .CLK(icap_clk));

  reg dna_read;
  reg dna_shift;
  reg dna_clk;
  wire dna_dout;
  DNA_PORT dna(
    .DOUT(dna_dout),
    .DIN(0),
    .READ(dna_read),
    .SHIFT(dna_shift),
    .CLK(dna_clk));

  wire j1_wr;

  reg [8:0] YYLINE;
  wire [9:0] yyline = (CounterY + 4 - (35 + 6 + 21 + 1));
  always @(posedge vga_clk)
  begin
    // if (xx == 400)
    if (composite_complete)
      YYLINE = yyline[9:1];
  end

  reg [15:0] freqhz = 8000;
  reg [7:0] freqtick;

  reg [26:0] freqd;
  wire [26:0] freqdN = freqd + freqhz - (freqd[26] ? 0 : 50000000);
  always @(posedge vga_clk)
  begin
    freqd = freqdN;
    if (freqd[26] == 0)
      freqtick = freqtick + 1;
  end

  reg [15:0] local_j1_read;
  always @*
  begin
    case ({j1_mem_addr[4:1], 1'b0})
    5'h00: local_j1_read <= YYLINE;
    5'h02: local_j1_read <= icap_o;
    5'h0c: local_j1_read <= freqtick;
    5'h0e: local_j1_read <= AUX;
    5'h12: local_j1_read <= lfsr;
    5'h14: local_j1_read <= soundcounter;
    5'h16: local_j1_read <= flashMISO;
    5'h18: local_j1_read <= dna_dout;

    // default: local_j1_read <= 16'hffff;
    endcase
  end

  wire [0:7] j1_mem_dout_be = j1_mem_dout;
  reg j1_flashMOSI;
  reg j1_flashSCK;
  reg j1_flashSSEL;

  always @(posedge vga_clk)
  begin
    if (j1_wr & (j1_mem_addr[15] == 1))
      case ({j1_mem_addr[4:1], 1'b0})
      // 5'h06: icap_i <= j1_mem_dout;
      // 5'h08: icap_write <= j1_mem_dout;
      // 5'h0a: icap_ce <= j1_mem_dout;
      // 5'h0c: icap_clk <= j1_mem_dout;
      5'h06: {icap_write,icap_ce,icap_clk,icap_i} <= j1_mem_dout;
      5'h08: {dna_read, dna_shift, dna_clk} <= j1_mem_dout;
      5'h0a: freqhz <= j1_mem_dout;
      5'h0e: j1_p2_o <= j1_mem_dout;
      5'h10: j1_p2_dir <= j1_mem_dout;
      5'h18: j1_flashMOSI <= j1_mem_dout;
      5'h1a: j1_flashSCK <= j1_mem_dout;
      5'h1c: j1_flashSSEL <= j1_mem_dout;
      endcase
  end

  assign j1_mem_wr = j1_wr & (j1_mem_addr[15] == 0);
  j0 j(.sys_clk_i(vga_clk),
       .sys_rst_i(j1_reset),
       .insn(j1_insn),
       .insn_addr(j1_insn_addr),
       .mem_wr(j1_wr),
       .mem_addr(j1_mem_addr),
       .mem_dout(j1_mem_dout),
       .mem_din(j1_mem_addr[15] ? local_j1_read : mem_data_rd),
       .pause(host_busy | (busyhh != 0))
       );

  // 0x2b00: j1 insn RAM
  wire jinsn_wr = (mem_wr & (mem_w_addr[14:8] == 6'h2b));
  RAM_CODEL jinsnl(.b(j1_insn_addr), .bo(j1_insn[7:0]),
    .a(mem_addr[7:1]),
    .wclk(vga_clk),
    .wea((mem_w_addr[0] == 0) & jinsn_wr),
    .ad(mem_data_wr),
    .ao(j1insnl_read));
  RAM_CODEH jinsnh(.b(j1_insn_addr), .bo(j1_insn[15:8]),
    .a(mem_addr[7:1]),
    .wclk(vga_clk),
    .wea((mem_w_addr[0] == 1) & jinsn_wr),
    .ad(mem_data_wr),
    .ao(j1insnh_read));

  assign flashMOSI = pin2j ? j1_flashMOSI : MOSI;
  assign flashSCK = pin2j ? j1_flashSCK : SCK;
  assign flashSSEL = pin2f ? AUX : (pin2j ? j1_flashSSEL : 1);

  assign AUX = (pin2j & (j1_p2_dir == 0)) ? j1_p2_o : 1'bz;

endmodule // top
