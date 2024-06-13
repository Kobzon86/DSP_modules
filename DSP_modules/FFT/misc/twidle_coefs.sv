module twidle_coefs #(
    parameter WIDTH = 10,
    parameter N     = 8
) (
    input                  clk   ,
    input  [$clog2(N)-2:0] i_num ,
    output logic[    WIDTH-1:0] o_coef_real,
    output logic[    WIDTH-1:0] o_coef_imag
);

localparam real PI = $acos(-1);

logic [WIDTH*2-1:0] mem[N/2];

initial begin
    $display("%0d points twidle_coefs = ", N);

    foreach (mem[i]) begin
        mem[i][WIDTH*2-1:WIDTH] = $rtoi( $cos( 2*PI*i/N )*( 1<<WIDTH-2 ) );
        mem[i][WIDTH-1:0] = -$rtoi( $sin( 2*PI*i/N )*( 1<<WIDTH-2 ) );

        $display("%0f cos[%0d] = ", $cos( 2*PI*i/N ), i );
        $display("%0f sin[%0d] = ", -$sin( 2*PI*i/N ), i );

    end
end

always_ff @(posedge clk) begin 
    {o_coef_real, o_coef_imag} <= mem[i_num];
end

endmodule : twidle_coefs