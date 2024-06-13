`include "IIRcoefs.svh"

module IIR #(
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
	input                 rst_n        ,
	                                     /////////////////////input AXIst
	input        [IW-1:0] axis_i_tdata ,
	// input        [ IW_FULL/8-1:0] axis_i_tkeep ,
	// input                axis_i_tuser ,
	input                 axis_i_tvalid,
	output logic          axis_i_tready,
	// input                axis_i_tlast ,
	                                     /////////////////////output AXIst
	output logic [OW-1:0] axis_o_tdata ,
	// output logic [ OW_FULL/8-1:0] axis_o_tkeep ,
	// output logic         axis_o_tuser ,
	output logic          axis_o_tvalid,
	input                 axis_o_tready
	// output logic         axis_o_tlast
);

///////////////////////////
/////Feed-forward structure
///////////////////////////

logic signed[OW-1:0] ff_delay_line[N+1];

logic signed[IW+CW-1:0] ff_mult_results[$size(ff_delay_line)];

logic valid_delay;

logic in_valid;
always_comb begin
  axis_i_tready = axis_o_tready;
  in_valid      = axis_i_tvalid && axis_i_tready;
end

logic signed [CW-1:0] ff_coefs[N+1];
initial begin
	foreach (ff_coefs[i]) begin
		ff_coefs[i] = ( CFW > 0 ) ? ( coefs_b[i]*(1<<CFW) ) : ( coefs_b[i]*(1<<(CW-2)) );
	end
end



always_ff @(posedge clk or negedge rst_n) begin : proc_ff_delay
	if(~rst_n) begin
		valid_delay <= 0;
		foreach (ff_delay_line[i]) begin
			ff_delay_line[i] <= '0;
		end
	end else begin
		if(axis_o_tready)
			valid_delay <= in_valid;
		
		if(in_valid)begin
			ff_delay_line[$size(ff_delay_line)-1] <= ff_mult_results[$size(ff_delay_line)-1];
			for(int i = 0; i<$size(ff_delay_line)-1; i++) begin
				ff_delay_line[i] <= ff_delay_line[i+1] + ff_mult_results[i];
			end
		end
	end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_ff_mults
	if(~rst_n) begin
		foreach (ff_mult_results[i]) begin
			ff_mult_results[i] <= '0;
		end
	end else begin
		if (in_valid) begin
			foreach (ff_mult_results[i]) begin
				ff_mult_results[i] <= $signed(axis_i_tdata) * ff_coefs[i];
			end
		end
	end
end



///////////////////////////
/////Feed-back structure
///////////////////////////


logic signed [OW-1:0] fb_delay_line[N];

logic signed [OW+CW-1:0] fb_mult_results[$size(fb_delay_line)];


logic signed [CW-1:0] fb_coefs[N];
initial begin
	foreach (fb_coefs[i]) begin
		fb_coefs[i] = ( CFW > 0 ) ? ( coefs_a[i]*(1<<CFW) ) : ( coefs_a[i]*(1<<(CW-2)) );
	end
end



always_ff @(posedge clk or negedge rst_n) begin : proc_fb_delay
	if(~rst_n) begin
		foreach (fb_delay_line[i]) begin
			fb_delay_line[i] <= '0;
		end
	end else begin
		if(in_valid)begin
			fb_delay_line[$size(fb_delay_line)-1] <= fb_mult_results[$size(fb_delay_line)-1]/(2**CFW);
			for(int i = 0; i<$size(fb_delay_line)-1; i++) begin
				fb_delay_line[i] <= fb_delay_line[i+1] + fb_mult_results[i]/(2**CFW);
			end
		end
	end
end

always_comb begin : proc_fb_mults
	foreach (fb_mult_results[i]) begin
		fb_mult_results[i] = ( ( ff_delay_line[0] + fb_delay_line[0] ) * fb_coefs[i] );
	end
end

////////////////////////////
logic signed [OW-1:0] output_reg;
always_ff @(posedge clk or negedge rst_n) begin : proc_axi_out
	if(~rst_n) begin
		axis_o_tvalid <= 0;
		output_reg <= '0;
	end else begin
		axis_o_tvalid <= valid_delay;
		output_reg <= ff_delay_line[0] + fb_delay_line[0];
	end
end
assign axis_o_tdata = (TRUNCATE == "TRUE") ? output_reg>>>CFW : output_reg;

endmodule : IIR