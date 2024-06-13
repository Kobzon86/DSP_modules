`include "TB_all.svh"

module TB_ALL ();
  parameter WIDTH    = 16 ;
  parameter N        = 256;
  parameter TW_WIDTH = 10 ;

  parameter TAPS = 74                    ;
  parameter IW   = WIDTH                 ;
  parameter IFW  = 0                     ;
  parameter CW   = 12                    ;
  parameter CFW  = 8                     ;
  parameter OW   = IW + CW + $clog2(TAPS);

  localparam CIC_FFT_WIDTH = WIDTH*2;
  localparam FIR_FFT_WIDTH = WIDTH*2;
  localparam IIR_FFT_WIDTH = WIDTH*2;

  parameter  M     = 4  ;
  parameter  R     = 4  ;
  localparam N_CIC = N/R;

  parameter IIR_N = 4;

  logic [WIDTH-1:0] axis_i_tdata  = 0;
  logic             axis_i_tvalid = 0;
  logic             axis_i_tready    ;


  ///Input data FFT
  logic signed [WIDTH-1+2*$clog2(N):0] axis_ifft_tdata     ;
  logic                                axis_ifft_tvalid    ;
  logic                                axis_ifft_tready = 1;
  logic                                axis_ifft_tlast     ;
  ///FIR output data
  logic signed [WIDTH-1:0] axis_fir_tdata     ;
  logic                    axis_fir_tvalid    ;
  logic                    axis_fir_tready = 1;
  ///FIR output data FFT
  logic signed [FIR_FFT_WIDTH-1+2*$clog2(N):0] axis_fir_fft_tdata     ;
  logic                                        axis_fir_fft_tvalid    ;
  logic                                        axis_fir_fft_tready = 1;
  logic                                        axis_fir_fft_tlast     ;
  ///IIR output data
  logic signed [WIDTH-1:0] axis_iir_tdata     ;
  logic                    axis_iir_tvalid    ;
  logic                    axis_iir_tready = 1;
  ///IIR output data FFT
  logic signed [IIR_FFT_WIDTH-1+2*$clog2(N):0] axis_iir_fft_tdata     ;
  logic                                        axis_iir_fft_tvalid    ;
  logic                                        axis_iir_fft_tready = 1;
  logic                                        axis_iir_fft_tlast     ;
  ///IIR output data
  logic signed [WIDTH-1:0] axis_cic_tdata     ;
  logic                    axis_cic_tvalid    ;
  logic                    axis_cic_tready = 1;
  ///IIR output data FFT
  logic signed [CIC_FFT_WIDTH-1+2*$clog2(N_CIC):0] axis_cic_fft_tdata;
  // logic signed [43:0] axis_cic_fft_tdata     ;

  logic axis_cic_fft_tvalid    ;
  logic axis_cic_fft_tready = 1;
  logic axis_cic_fft_tlast     ;

  logic clk   = 0;
  logic rst_n = 0;
  always begin
    #10 clk = !clk;
  end








  localparam real PI = $acos(-1);
  int            i  = 0        ;
  initial begin

    axis_ifft_tready = 1;
    axis_fir_fft_tready = 1;
    axis_iir_fft_tready = 1;
    axis_cic_fft_tready = 1;
    #100 rst_n = 1'b1;
    #200 ;
    repeat(N)begin

      @(posedge clk)
        axis_i_tdata[WIDTH-1:WIDTH/2] = x[i++]*64;

      axis_i_tdata[WIDTH/2-1:0] = 0;
      axis_i_tvalid = 1'b1;
      `ifdef FILTERS_BACKPREASSURE_TEST
        if(i == 29)
          repeat(50)begin
            @(posedge clk)begin
              axis_ifft_tready =0;
              axis_fir_fft_tready =0;
              axis_iir_fft_tready =0;
              axis_cic_fft_tready =0;
            end
          end
        axis_ifft_tready    = 1;
        axis_fir_fft_tready = 1;
        axis_iir_fft_tready = 1;
        axis_cic_fft_tready = 1;
      `endif
      `ifdef FILTERS_BACKPREASSURE_TEST
        if(i == 29)
          repeat(50)begin
            @(posedge clk)begin
              axis_fir_fft_tready =0;
              axis_iir_fft_tready =0;
              axis_cic_fft_tready =0;
            end
          end
        axis_fir_fft_tready = 1;
        axis_iir_fft_tready = 1;
        axis_cic_fft_tready = 1;
      `endif
    end
    @(posedge clk)
      axis_i_tdata = 'd0;
    axis_i_tvalid = 1'b0;
    `ifdef FFT_BACKPREASSURE_TEST
      @(posedge clk);
      @(posedge clk);
      repeat(150)begin
        @(posedge clk)begin
          axis_ifft_tready =0;
          axis_fir_fft_tready =0;
          axis_iir_fft_tready =0;
          axis_cic_fft_tready =0;
        end
      end
      axis_ifft_tready    = 1;
      axis_fir_fft_tready = 1;
      axis_iir_fft_tready = 1;
      axis_cic_fft_tready = 1;
    `endif
  end



////////////////////////////////////////////////////
///////////////////////////////Input data FFT
///////////////////////////////////////////////////

  FFT #(
    .WIDTH   (WIDTH   ),
    .N       (N       ),
    .TW_WIDTH(TW_WIDTH)
  ) inst_FFT_input_data (
    .clk          (clk             ),
    .rst_n        (rst_n           ),
    .axis_i_tdata (axis_i_tdata    ),
    .axis_i_tvalid(axis_i_tvalid   ),
    .axis_i_tready(axis_i_tready   ),
    .axis_o_tdata (axis_ifft_tdata ),
    .axis_o_tvalid(axis_ifft_tvalid),
    .axis_o_tlast (axis_ifft_tlast ),
    .axis_o_tready(axis_ifft_tready)
  );



  logic[  $clog2(N/2)+1:0] ifft_cntr_in = 0;
  logic[  $clog2(N/2):0]   ifft_cntr_out = 0;
  always_comb begin
    foreach (ifft_cntr_out[i]) begin
      ifft_cntr_out[$clog2(N/2)-i] = ifft_cntr_in[i];
    end
  end


  logic signed [N-1:0][1:0][WIDTH/2-1+$clog2(N):0] ifft_y_parted[2];
  logic ifft_y_sel = 0;
  real ifft_output_aligned;

  logic ifft_aligned_valid = 0;
  logic ifft_aligned_start;

  real ifft_xre;
  real ifft_xim;
  initial begin
    ifft_aligned_start = 0;
    while(1)begin

      @(posedge clk)begin
        if(axis_ifft_tvalid) begin
          ifft_y_parted[ifft_y_sel][ifft_cntr_out] = axis_ifft_tdata;
          ifft_cntr_in++;
          if(axis_ifft_tlast)begin
            ifft_y_sel = !ifft_y_sel;
            ifft_cntr_in = 0;
            ifft_aligned_start = 1;
          end
        end

      end
    end
  end

logic[  $clog2(N/2):0]   ifft_cntr_aligned = 0;
  initial begin
    // wait(axis_ifft_tlast)
    while(1)begin

      ifft_aligned_valid=0;
      ifft_cntr_aligned = 0;
      if(ifft_aligned_start)begin
        ifft_aligned_start = 0; 
        repeat(N)begin
          @(posedge clk)begin
            ifft_aligned_valid=1;
            ifft_xre = $itor( $signed(ifft_y_parted[!ifft_y_sel][ifft_cntr_aligned][1]) );
            ifft_xim = $itor( $signed(ifft_y_parted[!ifft_y_sel][ifft_cntr_aligned][0]) );
            ifft_output_aligned = $sqrt( ifft_xre*ifft_xre + ifft_xim*ifft_xim ) ;
            ifft_cntr_aligned++;
          end
        end
      end
      ifft_cntr_aligned = 0;
      @(posedge clk);
      ifft_aligned_valid=0;
      ifft_output_aligned = 0;
    end

  end

  int   fft_latency       = 0;
  logic latency_measuring = 0;
  always begin

    @(posedge axis_i_tvalid)begin
      fft_latency       = 0;
      latency_measuring = 1;
    end

    while(!axis_ifft_tvalid)begin
      @(posedge clk)
        if(latency_measuring)
        fft_latency++;
    end

    latency_measuring = 0;


  end

////////////////////////////////////////////////////
///////////////////////////////FIR proccessing and FFT
///////////////////////////////////////////////////


  FIR #(
    .N       (TAPS  ),
    .IW      (IW    ),
    .IFW     (IFW   ),
    .CW      (CW    ),
    .CFW     (CFW   ),
    .OW      (OW    ),
    .TRUNCATE("TRUE")
  ) inst_FIR (
    .clk          (clk            ),
    .rst_n        (rst_n          ),
    .axis_i_tdata (axis_i_tdata   ),
    .axis_i_tvalid(axis_i_tvalid  ),
    .axis_i_tready(               ),
    .axis_o_tdata (axis_fir_tdata ),
    .axis_o_tvalid(axis_fir_tvalid),
    .axis_o_tready(axis_fir_tready)
  );



  FFT #(
    .WIDTH   (FIR_FFT_WIDTH),
    .N       (N            ),
    .TW_WIDTH(TW_WIDTH     )
  ) inst_FFT_FIR_output_data (
    .clk          (clk                          ),
    .rst_n        (rst_n                        ),
    .axis_i_tdata ({axis_fir_tdata,WIDTH'(1'b0)}),
    .axis_i_tvalid(axis_fir_tvalid              ),
    .axis_i_tready(axis_fir_tready              ),
    .axis_o_tdata (axis_fir_fft_tdata           ),
    .axis_o_tvalid(axis_fir_fft_tvalid          ),
    .axis_o_tlast (axis_fir_fft_tlast           ),
    .axis_o_tready(axis_iir_fft_tready          )
  );


  logic[  $clog2(N/2)+1:0] fir_fft_cntr_in = 0;
  logic[  $clog2(N/2):0]   fir_fft_cntr_out = 0;
  always_comb begin
    foreach (fir_fft_cntr_out[i]) begin
      fir_fft_cntr_out[$clog2(N/2)-i] = fir_fft_cntr_in[i];
    end
  end


  logic signed [N-1:0][1:0][FIR_FFT_WIDTH/2-1+$clog2(N):0] fir_fft_y_parted;

  real fir_fft_output_aligned;

  logic fir_fft_aligned_valid = 0;

  real fir_fft_xre;
  real fir_fft_xim;
  initial begin
    while(1)begin
      fir_fft_aligned_valid=0;
      while(fir_fft_cntr_in < N)begin
        @(posedge clk)begin
          if(axis_fir_fft_tvalid) begin
            fir_fft_y_parted[fir_fft_cntr_out] = axis_fir_fft_tdata;
            fir_fft_cntr_in++;
          end

        end
      end

      fir_fft_cntr_in = 0;

      repeat(N)begin
        @(posedge clk)begin
          fir_fft_aligned_valid=1;
          fir_fft_xre = $itor( $signed(fir_fft_y_parted[fir_fft_cntr_in][1]) );
          fir_fft_xim = $itor( $signed(fir_fft_y_parted[fir_fft_cntr_in][0]) );
          fir_fft_output_aligned = $sqrt( fir_fft_xre*fir_fft_xre + fir_fft_xim*fir_fft_xim ) ;
          fir_fft_cntr_in++;
        end
      end
      fir_fft_cntr_in = 0;
      @(posedge clk);
      fir_fft_aligned_valid=0;
      fir_fft_output_aligned = 0;
    end

  end


////////////////////////////////////////////////////
///////////////////////////////FIR proccessing and FFT
///////////////////////////////////////////////////


  IIR #(
    .N       (IIR_N ),
    .IW      (IW    ),
    .IFW     (IFW   ),
    .CW      (CW    ),
    .CFW     (CFW   ),
    .OW      (OW    ),
    .TRUNCATE("TRUE")
  ) inst_IIR (
    .clk          (clk            ),
    .rst_n        (rst_n          ),
    .axis_i_tdata (axis_i_tdata   ),
    .axis_i_tvalid(axis_i_tvalid  ),
    .axis_i_tready(               ),
    .axis_o_tdata (axis_iir_tdata ),
    .axis_o_tvalid(axis_iir_tvalid),
    .axis_o_tready(axis_iir_tready)
  );


  FFT #(
    .WIDTH   (IIR_FFT_WIDTH),
    .N       (N            ),
    .TW_WIDTH(TW_WIDTH     )
  ) inst_FFT_IIR_output_data (
    .clk          (clk                          ),
    .rst_n        (rst_n                        ),
    .axis_i_tdata ({axis_iir_tdata,WIDTH'(1'b0)}),
    .axis_i_tvalid(axis_iir_tvalid              ),
    .axis_i_tready(axis_iir_tready              ),
    .axis_o_tdata (axis_iir_fft_tdata           ),
    .axis_o_tvalid(axis_iir_fft_tvalid          ),
    .axis_o_tlast (axis_iir_fft_tlast           ),
    .axis_o_tready(axis_iir_fft_tready          )
  );


  logic[  $clog2(N/2)+1:0] iir_fft_cntr_in = 0;
  logic[  $clog2(N/2):0]   iir_fft_cntr_out = 0;
  always_comb begin
    foreach (iir_fft_cntr_out[i]) begin
      iir_fft_cntr_out[$clog2(N/2)-i] = iir_fft_cntr_in[i];
    end
  end


  logic signed [N-1:0][1:0][IIR_FFT_WIDTH/2-1+$clog2(N):0] iir_fft_y_parted;

  real iir_fft_output_aligned;

  logic iir_fft_aligned_valid = 0;

  real iir_fft_xre;
  real iir_fft_xim;
  initial begin
    while(1)begin
      iir_fft_aligned_valid=0;
      while(iir_fft_cntr_in < N)begin
        @(posedge clk)begin
          if(axis_iir_fft_tvalid) begin
            iir_fft_y_parted[iir_fft_cntr_out] = axis_iir_fft_tdata;
            iir_fft_cntr_in++;
          end

        end
      end

      iir_fft_cntr_in = 0;

      repeat(N)begin
        @(posedge clk)begin
          iir_fft_aligned_valid=1;
          iir_fft_xre = $itor( $signed(iir_fft_y_parted[iir_fft_cntr_in][1]) );
          iir_fft_xim = $itor( $signed(iir_fft_y_parted[iir_fft_cntr_in][0]) );
          iir_fft_output_aligned = $sqrt( iir_fft_xre*iir_fft_xre + iir_fft_xim*iir_fft_xim ) ;
          iir_fft_cntr_in++;
        end
      end
      iir_fft_cntr_in = 0;
      @(posedge clk);
      iir_fft_aligned_valid=0;
      iir_fft_output_aligned = 0;
    end

  end




////////////////////////////////////////////////////
///////////////////////////////CIC proccessing and FFT
///////////////////////////////////////////////////


  CIC #(
    // .MODE (MODE  ),
    .R       (R     ),
    .M       (M     ),
    .IW      (IW    ),
    .CW      (CW    ),
    .TRUNCATE("TRUE")
  ) inst_CIC (
    .clk          (clk            ),
    .rst_n        (rst_n          ),
    .axis_i_tdata (axis_i_tdata   ),
    .axis_i_tvalid(axis_i_tvalid  ),
    .axis_i_tready(               ),
    .axis_o_tdata (axis_cic_tdata ),
    .axis_o_tvalid(axis_cic_tvalid),
    .axis_o_tready(axis_cic_tready)
  );



  FFT #(
    .WIDTH   (CIC_FFT_WIDTH),
    .N       (N_CIC        ),
    .TW_WIDTH(TW_WIDTH     )
  ) inst_FFT_CIC_output_data (
    .clk          (clk                          ),
    .rst_n        (rst_n                        ),
    .axis_i_tdata ({axis_cic_tdata,WIDTH'(1'b0)}),
    .axis_i_tvalid(axis_cic_tvalid              ),
    .axis_i_tready(axis_cic_tready              ),
    .axis_o_tdata (axis_cic_fft_tdata           ),
    .axis_o_tvalid(axis_cic_fft_tvalid          ),
    .axis_o_tlast (axis_cic_fft_tlast           ),
    .axis_o_tready(axis_cic_fft_tready          )
  );


  logic[  $clog2(N_CIC/2)+1:0] cic_fft_cntr_in = 0;
  logic[  $clog2(N_CIC/2):0]   cic_fft_cntr_out = 0;
  always_comb begin
    foreach (cic_fft_cntr_out[i]) begin
      cic_fft_cntr_out[$clog2(N_CIC/2)-i] = cic_fft_cntr_in[i];
    end
  end


  logic signed [N_CIC-1:0][1:0][CIC_FFT_WIDTH/2-1+$clog2(N_CIC):0] cic_fft_y_parted;

  real cic_fft_output_aligned;

  logic cic_fft_aligned_valid = 0;

  real cic_fft_xre;
  real cic_fft_xim;
  initial begin
    while(1)begin
      cic_fft_aligned_valid=0;
      while(cic_fft_cntr_in < N_CIC)begin
        @(posedge clk)begin
          if(axis_cic_fft_tvalid) begin
            cic_fft_y_parted[cic_fft_cntr_out] = axis_cic_fft_tdata;
            cic_fft_cntr_in++;
          end

        end
      end

      cic_fft_cntr_in = 0;

      repeat(N_CIC)begin
        @(posedge clk)begin
          cic_fft_aligned_valid=1;
          cic_fft_xre = $itor( $signed(cic_fft_y_parted[cic_fft_cntr_in][1]) );
          cic_fft_xim = $itor( $signed(cic_fft_y_parted[cic_fft_cntr_in][0]) );
          cic_fft_output_aligned = $sqrt( cic_fft_xre*cic_fft_xre + cic_fft_xim*cic_fft_xim ) ;
          cic_fft_cntr_in++;
        end
      end
      cic_fft_cntr_in = 0;
      @(posedge clk);
      cic_fft_aligned_valid=0;
      cic_fft_output_aligned = 0;
    end

  end

endmodule : TB_ALL