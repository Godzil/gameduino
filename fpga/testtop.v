  
module top(
  input SCK,  // arduino 13
  input MOSI, // arduino 11
  inout MISO, // arduino 12
  input SSEL, // arduino 9

  output flashMOSI,
  input  flashMISO,
  output flashSCK,
  output flashSSEL

  );

  assign flashMOSI = MOSI;
  assign MISO = flashMISO;
  assign flashSCK = SCK;
  assign flashSSEL = SSEL;

endmodule // top
