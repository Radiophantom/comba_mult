`timescale 1ns/1ps

module comba_mult_tb;

parameter A_WIDTH = 64;
parameter B_WIDTH = 64;
parameter MULT_WIDTH = A_WIDTH+B_WIDTH;

parameter A_NUM_COEF = A_WIDTH / 32 + ( A_WIDTH % 32 != 0 );
parameter B_NUM_COEF = B_WIDTH / 32 + ( B_WIDTH % 32 != 0 );

parameter RND_VALID = 1;
parameter RND_READY = 1;

bit clk;
bit rst;

bit                   valid_i;
bit [A_WIDTH-1:0]     a_num;
bit [B_WIDTH-1:0]     b_num;
bit                   ready_o;

bit                   valid_o;
bit [MULT_WIDTH-1:0]  result;
bit                   ready_i;

comba_mult #(
  .A_WIDTH       ( A_WIDTH ),
  .B_WIDTH       ( B_WIDTH ),
  .INPUT_REG_EN  ( 1       ),
  .OUTPUT_REG_EN ( 0       )
) dut (  
  .rst_i    ( rst     ),
  .clk_i    ( clk     ),

  .valid_i  ( valid_i ),
  .a_num_i  ( a_num   ),
  .b_num_i  ( b_num   ),
  .ready_o  ( ready_o ),

  .valid_o  ( valid_o ),
  .result_o ( result  ),
  .ready_i  ( ready_i )
);

bit [MULT_WIDTH-1:0] ref_result_q [$];
bit [MULT_WIDTH-1:0] ref_result;

bit valid;
bit ready;

initial
  begin
    fork
      forever #5 clk = ~clk;
    join_none

    rst = 1'b1;
    @( posedge clk );
    rst = 1'b0;
    @( posedge clk );

    fork
      repeat( 100 )
        begin
          valid = 1'b1;
          if( RND_VALID )
            valid = $urandom_range( 1 );
          while( ~valid )
            begin
              @( posedge clk );
              valid = $urandom_range( 1 );
            end
          valid_i <= valid;
          a_num   <= { A_NUM_COEF{ $urandom_range( 2**32-1, 0 ) } };
          b_num   <= { B_NUM_COEF{ $urandom_range( 2**32-1, 0 ) } };
          do
            @( posedge clk );
          while( ~ready_o );
          valid_i <= 1'b0;
          ref_result_q.push_back( a_num*b_num );
        end
      repeat( 100 )
        begin
          ready = 1'b1;
          if( RND_READY )
            ready = $urandom_range( 1 );
          while( ~ready )
            begin
              @( posedge clk );
              ready = $urandom_range( 1 );
            end
          ready_i <= ready;
          do
            @( posedge clk );
          while( ~valid_o );
          ref_result = ref_result_q.pop_front();
          if( ref_result != result )
            begin
              $display("Error occured. Expected result: %0h. Observed: %0h", ref_result, result );
              $stop();
            end
          ready_i <= 1'b0;
        end
    join

    $display("Everything is FINE");
    $stop();

  end

endmodule : comba_mult_tb

