module CIC #(
    parameter MODE  = "DEC"             , // only decimation
    parameter M     = 3                 ,
    parameter R     = 2                 ,
    parameter IW    = 8                 ,
    parameter CW    = 8                 ,
    parameter OW    = IW + (M*$clog2(R)),
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



logic in_valid;
always_comb begin
  axis_i_tready = axis_o_tready;
  in_valid      = axis_i_tvalid && axis_i_tready;
end

logic signed [OW-1:0] integrator_dl[M];

logic signed [OW-1:0] integrator_sum[M];

always_comb begin : proc_integrator_sum
    foreach (integrator_sum[i]) begin
        if( i == 0 )
            integrator_sum[i] = $signed(axis_i_tdata) + integrator_dl[i];
        else
            integrator_sum[i] = integrator_dl[i-1] + integrator_dl[i];
    end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_integrator_dl
    if(~rst_n) begin
        foreach (integrator_dl[i]) begin
            integrator_dl[i] <= '0;
        end
    end else begin
        if(in_valid)begin
            foreach (integrator_dl[i]) begin
                integrator_dl[i] <= integrator_sum[i];
            end

        end
    end
end



logic signed [OW-1:0] comb_dl[M+1];
logic signed [OW-1:0] comb_sum_dl[M];
logic signed [OW-1:0] comb_sum[M];

logic [$clog2(R)-1:0]cntr;
wire comb_en = cntr == ( R - 1 );
always_ff @(posedge clk or negedge rst_n) begin : proc_cnounter
    if(~rst_n) begin
        cntr <= 0;
    end else begin
        if( comb_en )
            cntr <= '0;
        else 
            cntr <= cntr + $size(cntr)'(in_valid);
    end
end



always_comb begin : proc_comb_sum
    foreach (comb_sum[i]) begin
        comb_sum[i] = comb_dl[i] - comb_sum_dl[i];
    end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_comb_dl
    if(~rst_n) begin
        foreach (comb_dl[i]) begin
            comb_dl[i] <= '0;
        end
        foreach (comb_sum_dl[i]) begin
            comb_sum_dl[i] <= '0;
        end
    end else begin
        if(comb_en)begin
            foreach (comb_dl[i]) begin
                if(i == 0)
                    comb_dl[i] <= integrator_dl[M-1];
                else
                    comb_dl[i] <= comb_sum[i-1];                    
            end

            foreach (comb_sum_dl[i]) begin
                comb_sum_dl[i] <= comb_dl[i];
            end         
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_axi_out
    if(~rst_n) begin
        axis_o_tvalid <= 0;
        axis_o_tdata <= '0;
    end else begin
        axis_o_tvalid <= comb_en;
        axis_o_tdata <= (TRUNCATE == "TRUE") ? comb_dl[M]>>>(M*$clog2(R)) : comb_dl[M];
    end
end
    
endmodule : CIC
