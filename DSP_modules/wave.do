onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /TB_ALL/clk
add wave -noupdate /TB_ALL/rst_n
add wave -noupdate -format Analog-Step -height 74 -max 24320.0 -min -21760.0 /TB_ALL/axis_i_tdata
add wave -noupdate /TB_ALL/axis_i_tvalid
add wave -noupdate /TB_ALL/axis_ifft_tvalid
add wave -noupdate /TB_ALL/axis_ifft_tlast
add wave -noupdate -format Analog-Step -height 74 -max 7114.1199999999999 /TB_ALL/ifft_output_aligned
add wave -noupdate /TB_ALL/ifft_aligned_valid
add wave -noupdate -divider FIR
add wave -noupdate -format Analog-Step -height 74 -max 19731.0 -min -18860.0 /TB_ALL/axis_fir_tdata
add wave -noupdate /TB_ALL/axis_fir_tvalid
add wave -noupdate -format Analog-Step -height 74 -max 1613963.6771777114 /TB_ALL/fir_fft_output_aligned
add wave -noupdate /TB_ALL/fir_fft_aligned_valid
add wave -noupdate -divider IIR
add wave -noupdate -format Analog-Step -height 74 -max 22352.000000000004 -min -20853.0 /TB_ALL/axis_iir_tdata
add wave -noupdate /TB_ALL/axis_iir_tvalid
add wave -noupdate -format Analog-Step -height 74 -max 2003054.9482557885 /TB_ALL/iir_fft_output_aligned
add wave -noupdate /TB_ALL/iir_fft_aligned_valid
add wave -noupdate -divider CIC
add wave -noupdate -format Analog-Step -height 74 -max 18889.000000000004 -min -18931.0 /TB_ALL/axis_cic_tdata
add wave -noupdate /TB_ALL/axis_cic_tvalid
add wave -noupdate /TB_ALL/axis_cic_fft_tlast
add wave -noupdate -format Analog-Step -height 74 -max 435675.0 /TB_ALL/cic_fft_output_aligned
add wave -noupdate /TB_ALL/cic_fft_aligned_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4851 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {18900 ps}
