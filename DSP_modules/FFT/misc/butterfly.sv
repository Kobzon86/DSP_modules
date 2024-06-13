module butterfly #(
    parameter WIDTH    = 16,
    parameter TW_WIDTH = 10
) (
    input                              clk         ,
    input                              rst_n       ,
    input                              clk_en      ,
    // Input data
    input  logic signed [   WIDTH-1:0] a_real      ,
    input  logic signed [   WIDTH-1:0] a_imag      ,
    input  logic signed [   WIDTH-1:0] b_real      ,
    input  logic signed [   WIDTH-1:0] b_imag      ,
    input  logic signed [TW_WIDTH-1:0] twiddle_real,
    input  logic signed [TW_WIDTH-1:0] twiddle_imag,
    // Output data
    output logic signed [     WIDTH:0] y1_real     ,
    output logic signed [     WIDTH:0] y1_imag     ,
    output logic signed [   WIDTH+2:0] y2_real     ,
    output logic signed [   WIDTH+2:0] y2_imag     ,
    //valid
    input                              i_valid     ,
    output                             o_valid
);
    // Internal signals
    logic signed [WIDTH+TW_WIDTH-1:0] mult_rr;
    logic signed [WIDTH+TW_WIDTH-1:0] mult_ii;
    logic signed [WIDTH+TW_WIDTH-1:0] mult_ri;
    logic signed [WIDTH+TW_WIDTH-1:0] mult_ir;

    logic signed [WIDTH+1:0] b_tw_real;
    logic signed [WIDTH+1:0] b_tw_imag;
    logic signed [  WIDTH:0] add_real ;
    logic signed [  WIDTH:0] add_imag ;
    logic signed [  WIDTH:0] sub_real ;
    logic signed [  WIDTH:0] sub_imag ;

    logic [1:0] valid_delay;

    logic [WIDTH:0] a_real_dl;
    logic [WIDTH:0] a_imag_dl;

    //valid delay
    assign o_valid = valid_delay[1];
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            valid_delay <= 0;
        end else begin
            if(clk_en)begin
                valid_delay <= $size(valid_delay)'({valid_delay, i_valid});
            end
        end
    end

    // Butterfly
    always_comb begin
        add_real = a_real + b_real;
        add_imag = a_imag + b_imag;
        sub_real = a_real - b_real;
        sub_imag = a_imag - b_imag;
    end

    // Twiddle factor multiplication
    always_ff @(posedge clk) begin
        if (clk_en) begin
            mult_rr <= sub_real * twiddle_real;
            mult_ii <= sub_imag * twiddle_imag;
            mult_ri <= sub_real * twiddle_imag;
            mult_ir <= sub_imag * twiddle_real;
        end
    end
    // Delays and outputs
    always_ff @(posedge clk) begin
        if (clk_en) begin
            a_real_dl <= add_real;
            a_imag_dl <= add_imag;

            y1_real <= $signed(a_real_dl);
            y1_imag <= $signed(a_imag_dl);
            y2_real <= $size(y2_real)'( ( mult_rr>>>(TW_WIDTH-2) ) - ( mult_ii>>>(TW_WIDTH-2) ) );
            y2_imag <= $size(y2_real)'( ( mult_ri>>>(TW_WIDTH-2) ) + ( mult_ir>>>(TW_WIDTH-2) ) );
        end
    end
endmodule
