vlib work

vlog -sv comba_mult.sv comba_mult_tb.sv

vopt +acc -o comba_mult_top comba_mult_tb
vsim comba_mult_top

do wave.do

run -all
