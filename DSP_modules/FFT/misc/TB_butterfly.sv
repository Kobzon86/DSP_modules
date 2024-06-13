module TB_butterfly ();
    logic clk   = 0;
    logic rst_n = 0;
    always begin
        #10 clk = !clk;
    end
    parameter            WIDTH        = 16;
    parameter            TW_WIDTH     = 10;
    logic [   WIDTH-1:0] a_real       = 0 ;
    logic [   WIDTH-1:0] a_imag       = 0 ;
    logic [   WIDTH-1:0] b_real       = 0 ;
    logic [   WIDTH-1:0] b_imag       = 0 ;
    logic [TW_WIDTH-1:0] twiddle_real = 0 ;
    logic [TW_WIDTH-1:0] twiddle_imag = 0 ;
    logic [     WIDTH:0] y1_real          ;
    logic [     WIDTH:0] y1_imag          ;
    logic [   WIDTH+2:0] y2_real          ;
    logic [   WIDTH+2:0] y2_imag          ;
    logic                i_valid      = 0 ;
    logic                o_valid          ;


    butterfly #(
        .WIDTH   (WIDTH   ),
        .TW_WIDTH(TW_WIDTH)
    ) inst_butterfly_fft (
        .clk         (clk         ),
        .rst_n       (rst_n       ),
        .a_real      (a_real      ),
        .a_imag      (a_imag      ),
        .b_real      (b_real      ),
        .b_imag      (b_imag      ),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag),
        .y1_real     (y1_real     ),
        .y1_imag     (y1_imag     ),
        .y2_real     (y2_real     ),
        .y2_imag     (y2_imag     ),
        .i_valid     (i_valid     ),
        .o_valid     (o_valid     )
    );
    int i = 0;

    real soft_y1_real_q[$];
    real soft_y1_imag_q[$];
    real soft_y2_real_q[$];
    real soft_y2_imag_q[$];

    function void soft_buttterfly(logic[WIDTH-1:0] a_real, logic[WIDTH-1:0] a_imag, logic[WIDTH-1:0] b_real, logic[WIDTH-1:0] b_imag, logic[TW_WIDTH-1:0] tw_real, logic[TW_WIDTH-1:0] tw_imag);

        automatic real  r_a_real = $itor($signed(a_real));
        automatic real  r_a_imag = $itor($signed(a_imag));
        automatic real  r_b_real = $itor($signed(b_real));
        automatic real  r_b_imag = $itor($signed(b_imag));
        automatic real  r_tw_real = $itor($signed(tw_real))/$itor( (1<<(TW_WIDTH-2)) );
        automatic real  r_tw_imag = $itor($signed(tw_imag))/$itor( (1<<(TW_WIDTH-2)) );

        soft_y1_real_q.push_back(  r_a_real + r_b_real );
        soft_y1_imag_q.push_back(  r_a_imag + r_b_imag );
        soft_y2_real_q.push_back(  ( (r_a_real - r_b_real) * r_tw_real - (r_a_imag - r_b_imag) * r_tw_imag) );
        soft_y2_imag_q.push_back(  ( (r_a_real - r_b_real) * r_tw_imag + (r_a_imag - r_b_imag) * r_tw_real) );
    endfunction : soft_buttterfly


    initial begin
        #100 rst_n = 1'b1;
        #200 ;
        while(1)begin
            @(posedge clk)begin
                a_real = $random();
                a_imag = $random();
                b_real = $random();
                b_imag = $random();
                twiddle_real = $urandom_range(-1<<(TW_WIDTH-2),1<<(TW_WIDTH-2));
                twiddle_imag = $urandom_range(-1<<(TW_WIDTH-2),1<<(TW_WIDTH-2));
                soft_buttterfly(a_real,a_imag,b_real,b_imag,twiddle_real,twiddle_imag);
                i_valid = 1'b1;
            end
            repeat($urandom_range(0,4))begin
                @(posedge clk)
                    i_valid = 1'b0;
            end
        end
    end

    function real abs(real a);
        if(a<0)
            return -a;
        else
            return a;
    endfunction : abs

    always begin
        @(posedge clk)begin
            if (o_valid) begin
                automatic real y1_r = soft_y1_real_q.pop_front();
                automatic real y1_i = soft_y1_imag_q.pop_front();
                automatic real y2_r = soft_y2_real_q.pop_front();
                automatic real y2_i = soft_y2_imag_q.pop_front();


                if( abs( ( y1_r - $signed(y1_real) ) ) > 2.0 )begin
                    $display("%0t soft_y1_r = %0f, hard_y1_r = %0f",$time,y1_r,$signed(y1_real));
                    $stop;
                end
                if( abs( ( y1_i - $signed(y1_imag) ) ) > 2.0 )begin

                    $display("%0t soft_y1_i = %0f, hard_y1_i = %0f",$time,y1_i,$signed(y1_imag));
                    $stop;
                end
                if( abs( ( y2_r - $signed(y2_real) ) ) > 2.0 )begin
                    $display("%0t soft_y2_r = %0f, hard_y2_r = %0f",$time,y2_r,$signed(y2_real));
                    $stop;
                end
                if( abs( ( y2_i - $signed(y2_imag) ) ) > 2.0 )begin
                    $display("%0t soft_y2_i = %0f, hard_y2_i = %0f",$time,y2_i,$signed(y2_imag));
                    $stop;
                end

            end

        end

    end
endmodule : TB_butterfly
