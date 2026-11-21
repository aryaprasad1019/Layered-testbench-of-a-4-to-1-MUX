module mux4to1 (
  input  logic d0, d1, d2, d3,
  input  logic [1:0] sel,
  output logic y
);
  assign y = sel[1] ? (sel[0] ? d3 : d2) : (sel[0] ? d1 : d0);
endmodule
