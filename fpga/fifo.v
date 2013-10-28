module fifo ( clk, datain, wr, dataout, rd, fullness);
  parameter WIDTH = 1;

  input clk;
  input [WIDTH-1:0] datain;
  input wr;
  output [WIDTH-1:0] dataout;
  input rd;
  output reg [4:0] fullness;

  always @(posedge clk)
  begin
    fullness <= (fullness + wr - rd);
  end
  wire [3:0] readaddr = (fullness - 1);

  genvar i;

  generate
    for (i = 0; i < WIDTH; i=i+1) begin : srl16
      SRL16E fifo16(
        .CLK(clk),
        .CE(wr),
        .D(datain[i]),
        .A0(readaddr[0]),
        .A1(readaddr[1]),
        .A2(readaddr[2]),
        .A3(readaddr[3]),
        .Q(dataout[i]));
    end
  endgenerate

endmodule
