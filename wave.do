onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /comba_mult_tb/dut/rst_i
add wave -noupdate /comba_mult_tb/dut/clk_i
add wave -noupdate -divider Inputs
add wave -noupdate /comba_mult_tb/dut/valid_i
add wave -noupdate /comba_mult_tb/dut/a_num_i
add wave -noupdate /comba_mult_tb/dut/b_num_i
add wave -noupdate /comba_mult_tb/dut/ready_o
add wave -noupdate -divider Outputs
add wave -noupdate /comba_mult_tb/dut/valid_o
add wave -noupdate /comba_mult_tb/dut/result_o
add wave -noupdate /comba_mult_tb/dut/ready_i
add wave -noupdate -divider {Internal logic}
add wave -noupdate -radix binary /comba_mult_tb/dut/valid
add wave -noupdate /comba_mult_tb/dut/a_num
add wave -noupdate /comba_mult_tb/dut/b_num
add wave -noupdate /comba_mult_tb/dut/mult_words_comb
add wave -noupdate /comba_mult_tb/dut/mult_words_tmp
add wave -noupdate /comba_mult_tb/dut/mult_words
add wave -noupdate /comba_mult_tb/dut/mult_res_comb
add wave -noupdate /comba_mult_tb/dut/overflow
add wave -noupdate /comba_mult_tb/dut/mult_res
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {96570 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 259
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
WaveRestoreZoom {0 ps} {199994 ps}
