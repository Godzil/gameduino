// J0 is a stripped-down J1.
// Major changes:
//   stacks are only 16 deep
//   program counter is only 7 bits (128 instructions)
//   DEPTH and LSHIFT instructions removed
//   multiply and swab instructions added

module j0(
   input sys_clk_i, input sys_rst_i,

   output [6:0] insn_addr,
   input [15:0] insn,

   output mem_rd,
   output mem_wr,
   output [15:0] mem_addr,
   output [15:0] mem_dout,
   input [15:0] mem_din,
   input pause
   );

  wire [15:0] immediate = { 1'b0, insn[14:0] };

  wire [15:0] ramrd;

  reg [4:0] dsp;      // Data stack pointer
  reg [4:0] _dsp;
  reg [15:0] st0;     // Top of data stack
  reg [15:0] _st0;
  wire dstkW;         // D stack write

  reg [6:0] pc;
  reg [6:0] _pc;
  reg [4:0] rsp;
  reg [4:0] _rsp;
  reg rstkW;          // R stack write
  reg [15:0] rstkD;   // R stack write value

  wire [6:0] pc_plus_1 = pc + 1;

  // The D and R stacks
  reg [15:0] dstack[0:31];
  reg [15:0] rstack[0:31];

  wire [15:0] st1 = dstack[dsp];
  wire [15:0] rst0 = rstack[rsp];

  // st0sel is the ALU operation.  For branch and call the operation
  // is T, for 0branch it is N.  For ALU ops it is loaded from the instruction
  // field.
  reg [4:0] st0sel;
  always @*
  begin
    case (insn[14:13])
      2'b00: st0sel <= 0;          // ubranch
      2'b10: st0sel <= 0;          // call
      2'b01: st0sel <= 1;          // 0branch
      2'b11: st0sel <= {insn[4], insn[11:8]}; // ALU
      default: st0sel <= 4'bxxxx;
    endcase

    // Compute the new value of T.
    if (insn[15])
      _st0 <= immediate;
    else
      case (st0sel)
        5'b00000: _st0 <= st0;
        5'b00001: _st0 <= st1;
        5'b00010: _st0 <= st0 + st1;
        5'b00011: _st0 <= st0 & st1;
        5'b00100: _st0 <= st0 | st1;
        5'b00101: _st0 <= st0 ^ st1;
        5'b00110: _st0 <= ~st0;
        5'b00111: _st0 <= {16{(st1 == st0)}};
        5'b01000: _st0 <= {16{($signed(st1) < $signed(st0))}};
        5'b01001: _st0 <= st1 >> st0[3:0];
        5'b01010: _st0 <= st0 - 1;
        5'b01011: _st0 <= rst0;
        5'b01100: _st0 <= mem_din;
        5'b01101: _st0 <= st1 * st0;
        5'b01110: _st0 <= {st0[7:0], st0[15:8]};
        5'b01111: _st0 <= {16{(st1 < st0)}};
        default: _st0 <= 16'hxxxx;
      endcase
  end

  wire is_alu = (insn[15:13] == 3'b011);
  wire is_lit = (insn[15]);

  // assign mem_rd = (is_alu & (insn[11:8] == 4'hc));
  assign mem_rd = (st0sel == 5'hc);
  assign mem_wr = is_alu & insn[5];
  assign mem_addr = st0;
  assign mem_dout = st1;

  assign dstkW = is_lit | (is_alu & insn[7]);

  wire [1:0] dd = insn[1:0];  // D stack delta
  wire [1:0] rd = insn[3:2];  // R stack delta

  always @*
  begin
    if (is_lit) begin                       // literal
      _dsp = dsp + 1;
      _rsp = rsp;
      rstkW = 0;
      rstkD = _pc;
    end else if (is_alu) begin             // ALU
      _dsp = dsp + {dd[1], dd[1], dd[1], dd};
      _rsp = rsp + {rd[1], rd[1], rd[1], rd};
      rstkW = insn[6];
      rstkD = st0;
    end else begin                          // jump/call
      // predicated jump is like DROP
      if (insn[15:13] == 3'b001) begin
        _dsp = dsp - 1;
      end else begin
        _dsp = dsp;
      end
      if (insn[15:13] == 3'b010) begin // call
        _rsp = rsp + 1;
        rstkW = 1;
        rstkD = {pc_plus_1, 1'b0};
      end else begin
        _rsp = rsp;
        rstkW = 0;
        rstkD = _pc;
      end
    end

    if (sys_rst_i)
      _pc = pc;
    else
      if ((insn[15:13] == 3'b000) |
          ((insn[15:13] == 3'b001) & (|st0 == 0)) |
          (insn[15:13] == 3'b010))
        _pc = insn[6:0];
      else if (is_alu & insn[12])
        _pc = rst0[7:1];
      else
        _pc = pc_plus_1;
  end

  assign insn_addr = pause ? pc : _pc;
  always @(posedge sys_clk_i)
  begin
    if (sys_rst_i) begin
      pc <= 0;
      dsp <= 0;
      st0 <= 0;
      rsp <= 0;
    end else if (!pause) begin
      pc <= _pc;
      dsp <= _dsp;
      st0 <= _st0;
      rsp <= _rsp;
      if (dstkW)
        dstack[_dsp] = st0;
      if (rstkW)
        rstack[_rsp] = rstkD;
    end
  end

endmodule // j1
