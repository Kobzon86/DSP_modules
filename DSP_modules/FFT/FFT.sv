module FFT #(
    parameter WIDTH    = 16,
    parameter N        = 16,
    parameter TW_WIDTH = 10
) (
    input                                clk          ,
    rst_n,
                                                        /////////////////////input AXIst
    input        [            WIDTH-1:0] axis_i_tdata ,
    input                                axis_i_tvalid,
    output logic                         axis_i_tready,
                                                        /////////////////////output AXIst
    output logic [WIDTH-1+2*$clog2(N):0] axis_o_tdata ,
    output logic                         axis_o_tvalid,
    output logic                         axis_o_tlast ,
    input  logic                         axis_o_tready
);

    logic in_valid;
    always_comb begin
        axis_i_tready = axis_o_tready;
        in_valid      = axis_i_tvalid && axis_i_tready;
    end

    logic [$clog2(N)-1:0][1:0][WIDTH/2-1+$clog2(N):0] y;

    logic o_valid[$clog2(N)];

    genvar i;
    generate
        for (i=0; i < $clog2(N); i++) begin : stage_gen
            stage_math_wraper #(
                .WIDTH   (WIDTH/2 + i),
                .TW_WIDTH(TW_WIDTH   ),
                .N       (N/(1<<i)   )
            ) u0 (
                .clk    (clk                                                 ),
                .rst_n  (rst_n                                               ),
                .i_valid((i == 0) ? in_valid : o_valid[i-1]                  ),
                .o_valid(o_valid[i]                                          ),
                .clk_en (axis_i_tready                                       ),
                .x_real ((i == 0) ? axis_i_tdata[WIDTH-1:WIDTH/2] : y[i-1][1]),
                .x_imag ((i == 0) ? axis_i_tdata[WIDTH/2-1:0] : y[i-1][0]    ),
                .y_real (y[i][1]                                             ),
                .y_imag (y[i][0]                                             )
            );
        end
    endgenerate

    assign axis_o_tdata  = y[$clog2(N)-1];
    assign axis_o_tvalid = o_valid[$clog2(N)-1];

    logic [$clog2(N)-1:0] output_cntr;
    always_ff @(posedge clk or negedge rst_n) begin : proc_
        if(~rst_n) begin
            output_cntr <= '0;
        end else begin
            output_cntr <= output_cntr + $size(output_cntr)'(axis_o_tvalid);
        end
    end

    assign axis_o_tlast = axis_o_tvalid && ( output_cntr == N-1 );

endmodule : FFT

