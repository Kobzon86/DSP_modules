module stage_math_wraper #(
    parameter WIDTH    = 16,
    parameter TW_WIDTH = 10,
    parameter N        = 8
) (
    input                    clk    ,
    input                    rst_n  ,
    input                    i_valid,
    output logic             o_valid,
    input                    clk_en     ,
    input        [WIDTH-1:0] x_real ,
    input        [WIDTH-1:0] x_imag ,
    output logic [  WIDTH:0] y_real ,
    output logic [  WIDTH:0] y_imag
);

    logic [N/2-1:0][1:0][WIDTH-1:0] data_dl    ;
    logic [N/2-1:0][1:0][  WIDTH:0] data_out_dl;

    logic [N/2-1:0] vl_dl;

    logic [WIDTH:0] y1_real;
    logic [WIDTH:0] y1_imag;
    logic [WIDTH:0] y2_real;
    logic [WIDTH:0] y2_imag;

    logic [TW_WIDTH-1:0] twiddle_real;
    logic [TW_WIDTH-1:0] twiddle_imag;

    logic bf_valid;


    logic [1:0][WIDTH-1:0] a,b;

    logic [  $clog2(N/2):0] cntr_in ;
    logic [$clog2(N/2)+1:0] cntr_out;

    wire math_en = cntr_in[$clog2(N/2)];

    logic output_mux;

    always_ff @(posedge clk) begin
        if (clk_en) begin
            data_dl <= i_valid  ? {data_dl, {x_real, x_imag}} : data_dl;

            data_out_dl <= ( bf_valid || output_mux ) ? {data_out_dl, {y2_real, y2_imag}} : data_out_dl;

            a <= data_dl[N/2-1];

            b <= {x_real, x_imag};

            {y_real,y_imag} <= output_mux ? data_out_dl[N/2-1] : {y1_real, y1_imag};
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin : proc_counters
        if(~rst_n) begin
            cntr_in  <= '0;
            cntr_out <= '0;
        end else begin
            if (clk_en) begin
                cntr_in  <= cntr_in + $size(cntr_in)'(i_valid);
                cntr_out <= cntr_out + $size(cntr_out)'(bf_valid) - $size(cntr_out)'(output_mux);
            end
        end
    end


    logic bf_en;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            output_mux <= '0;
            bf_en      <= '0;
            o_valid    <= '0;
        end else begin
            if(clk_en) begin
                bf_en <= math_en && i_valid;

                if( ( cntr_out == N/2-1 ) && bf_valid )
                    output_mux <= 1'b1;
                else if (cntr_out == 'd1)
                    output_mux <= 1'b0;
                else
                    output_mux <= output_mux;

                o_valid <= output_mux ? 1'b1 : bf_valid;
                
            end
        end
    end


    butterfly #(
        .WIDTH   (WIDTH   ),
        .TW_WIDTH(TW_WIDTH)
    ) inst_butterfly (
        .clk         (clk         ),
        .rst_n       (rst_n       ),
        .clk_en      (clk_en      ),
        .a_real      (a[1]        ),
        .a_imag      (a[0]        ),
        .b_real      (b[1]        ),
        .b_imag      (b[0]        ),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag),
        .y1_real     (y1_real     ),
        .y1_imag     (y1_imag     ),
        .y2_real     (y2_real     ),
        .y2_imag     (y2_imag     ),
        .i_valid     (bf_en       ),
        .o_valid     (bf_valid    )
    );


    twidle_coefs #(
        .WIDTH(TW_WIDTH),
        .N    (N       )
    ) inst_twidle_coefs (
        .clk        (clk                    ),
        .i_num      ((N==2) ? 2'd0 : cntr_in),
        .o_coef_real(twiddle_real           ),
        .o_coef_imag(twiddle_imag           )
    );

endmodule : stage_math_wraper