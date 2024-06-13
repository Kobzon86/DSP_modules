
`include "FIRcoefs.svh"


module FIR #(
  parameter N     = 4                  ,
  parameter IW    = 8                  ,
  parameter IFW   = 0                  ,
  parameter CW    = 8                  ,
  parameter CFW   = 0                  ,
  parameter OW    = IW + CW + $clog2(N),
  parameter OFW   = IFW + CFW          ,
  parameter TRUNCATE = "FALSE"
) (
  input                 clk          ,
  rst_n,
                                       /////////////////////input AXIst
  input        [IW-1:0] axis_i_tdata ,
  input                 axis_i_tvalid,
  output logic          axis_i_tready,
                                       /////////////////////output AXIst
  output logic [OW-1:0] axis_o_tdata ,
  output logic          axis_o_tvalid,
  input                 axis_o_tready
);

logic [OW-1:0] delay_line[N];

logic [IW+CW-1:0] mult_results[N];

logic valid_delay;

logic in_valid;
always_comb begin
  axis_i_tready = axis_o_tready;
  in_valid      = axis_i_tvalid && axis_i_tready;
end

logic [CW-1:0] coefs[N];
initial begin
  foreach (coefs[i]) begin
    coefs[i] = ( CFW > 0 ) ? ( taps[i]*(1<<CFW) ) : ( taps[i]*(1<<(CW-2)) );
  end
end



always_ff @(posedge clk or negedge rst_n) begin : proc_delay
  if(~rst_n) begin
    valid_delay <= 0;
    foreach (delay_line[i]) begin
      delay_line[i] <= '0;
    end
  end else begin
    if(axis_o_tready)
      valid_delay <= in_valid;
    
    if(in_valid)begin
      delay_line[0] <= $signed(mult_results[0]);
      for(int i = 1; i<N; i++) begin
        delay_line[i] <= $signed(delay_line[i-1]) + $signed(mult_results[i]);
      end
    end
  end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_mults
  if(~rst_n) begin
    foreach (mult_results[i]) begin
      mult_results[i] <= '0;
    end
  end else begin
    if (in_valid) begin
      foreach (mult_results[i]) begin
        mult_results[i] <= $signed(axis_i_tdata) * $signed(coefs[(N-1)-i]);
      end
    end
  end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_axi_out
  if(~rst_n) begin
    axis_o_tvalid <= 0;
  end else begin
    axis_o_tvalid <= valid_delay;
  end
end

assign axis_o_tdata = (TRUNCATE == "TRUE") ? delay_line[N-1]>>>CFW : delay_line[N-1];

endmodule : FIR