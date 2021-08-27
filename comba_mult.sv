module comba_mult #(
  // For user modification
  parameter WORD_WIDTH    = 16,
  parameter A_WIDTH       = 64,
  parameter B_WIDTH       = 64,
  parameter SUM_WIDTH     = 32,
  parameter INPUT_REG_EN  = 1,
  parameter OUTPUT_REG_EN = 0,
  parameter DEVICE        = "CycloneV", // "CycloneV" or "ECP5" available
  // NOT for user modification
  parameter MULT_WIDTH    = A_WIDTH+B_WIDTH
)(
  input                     rst_i,
  input                     clk_i,

  input                     valid_i,
  input   [A_WIDTH-1:0]     a_num_i,
  input   [B_WIDTH-1:0]     b_num_i,
  output                    ready_o,

  output                    valid_o,
  output  [MULT_WIDTH-1:0]  result_o,
  input                     ready_i
);

localparam A_WORDS_AMOUNT   = A_WIDTH / WORD_WIDTH + ( A_WIDTH % WORD_WIDTH != 0 );
localparam B_WORDS_AMOUNT   = B_WIDTH / WORD_WIDTH + ( B_WIDTH % WORD_WIDTH != 0 );

localparam MULT_WORD_WIDTH  = 2*WORD_WIDTH;

localparam PART_MULT_WORDS_AMOUNT = A_WORDS_AMOUNT + B_WORDS_AMOUNT - 1;
localparam SUM_EXTEND_WIDTH       = ( A_WORDS_AMOUNT > B_WORDS_AMOUNT ) ? ( $clog2( A_WORDS_AMOUNT ) ):( $clog2( B_WORDS_AMOUNT ) );
localparam PART_MULT_WORDS_WIDTH  = MULT_WORD_WIDTH + SUM_EXTEND_WIDTH;
localparam MULT_WORDS_AMOUNT      = MULT_WIDTH / MULT_WORD_WIDTH + ( MULT_WIDTH % MULT_WORD_WIDTH != 0 );

localparam MAX_DSP_SUM        = ( A_WORDS_AMOUNT > B_WORDS_AMOUNT ) ? ( A_WORDS_AMOUNT ):( B_WORDS_AMOUNT );
localparam DSP_STAGES_AMOUNT  = ( DEVICE == "CycloneV" ) ? ( MAX_DSP_SUM / 2 ):
                                                           ( MAX_DSP_SUM / 4 );

localparam VALID_REG_WIDTH    = INPUT_REG_EN + DSP_STAGES_AMOUNT + MULT_WORDS_AMOUNT;

logic [A_WORDS_AMOUNT-1:0][WORD_WIDTH-1:0]          a_num;
logic [B_WORDS_AMOUNT-1:0][WORD_WIDTH-1:0]          b_num;

logic [DSP_STAGES_AMOUNT-1:0][PART_MULT_WORDS_WIDTH-1:0] mult_words_comb     [PART_MULT_WORDS_AMOUNT-1:0];//[DSP_STAGES_AMOUNT-1:0];
logic [DSP_STAGES_AMOUNT-1:0][PART_MULT_WORDS_WIDTH-1:0] mult_words_tmp      [PART_MULT_WORDS_AMOUNT-1:0];//[DSP_STAGES_AMOUNT-1:0];
logic [PART_MULT_WORDS_WIDTH-1:0] mult_words          [PART_MULT_WORDS_AMOUNT-1:0];

logic [MULT_WORDS_AMOUNT-1:0][PART_MULT_WORDS_WIDTH-1:0] mult_res_comb;
logic [MULT_WORDS_AMOUNT-1:0][PART_MULT_WORDS_WIDTH-MULT_WORD_WIDTH-1:0] overflow;
logic [MULT_WORDS_AMOUNT-1:0][MULT_WORD_WIDTH-1:0] mult_res;

logic [PART_MULT_WORDS_AMOUNT+DSP_STAGES_AMOUNT:0] valid;

generate
  if( INPUT_REG_EN )
    begin : gen_input_num_latch

      always_ff @( posedge clk_i )
        if( valid_i && ready_o )
          begin
            a_num <= a_num_i;
            b_num <= b_num_i;
          end

    end
  else
    begin : gen_input_num_comb

      assign a_num = a_num_i;
      assign b_num = b_num_i;

    end
endgenerate

int a_ind;
int b_ind;
int dsp_stage;
int sum_amount;
int b_ind_max;

always_comb
  for( int part_num = 0; part_num < PART_MULT_WORDS_AMOUNT; part_num++ )
    begin
      if( part_num > B_WORDS_AMOUNT-1 )
        a_ind = part_num - B_WORDS_AMOUNT + 1;
      else
        a_ind = 0;
      if( part_num > B_WORDS_AMOUNT-1 )
        b_ind = B_WORDS_AMOUNT - 1;
      else
        b_ind = part_num;
      b_ind_max = b_ind;
      mult_words_comb[part_num] = '{ DSP_STAGES_AMOUNT{ '0 } };
      sum_amount = 0;
      dsp_stage = 0;
      while( ( a_ind <= A_WORDS_AMOUNT-1 ) && ( b_ind >= 0 ) )
        begin
            mult_words_comb[part_num][dsp_stage] += a_num[a_ind]*b_num[b_ind];
            a_ind++;
            b_ind--;
            sum_amount++;
            if( b_ind_max % 3 == 0 )
              if( sum_amount % 3 == 0 )
                begin
                  dsp_stage++;
                  sum_amount = 0;
                end
            else
              if( sum_amount % 2 == 0 )
                begin
                  dsp_stage++;
                  sum_amount = 0;
                end
        end
    end

generate
  if( DSP_STAGES_AMOUNT )
    begin : dsp_stage_enable

      always_ff @( posedge clk_i )
        mult_words_tmp <= mult_words_comb;

      logic [PART_MULT_WORDS_WIDTH-1:0] tmp [PART_MULT_WORDS_AMOUNT-1:0];

      always_comb
        for( int mul_num = 0; mul_num < PART_MULT_WORDS_AMOUNT; mul_num++ )
          begin
            tmp[mul_num] = '0;
            for( int dsp_stage = 0; dsp_stage < DSP_STAGES_AMOUNT; dsp_stage++ )
              tmp[mul_num] += mult_words_tmp[mul_num][dsp_stage];
          end

      always_ff @( posedge clk_i )
        for( int mul_num = 0; mul_num < PART_MULT_WORDS_AMOUNT; mul_num++ )
          mult_words[mul_num] <= tmp[mul_num];

    end
  else
    begin : no_dsp_stage

      logic [PART_MULT_WORDS_WIDTH-1:0] tmp [PART_MULT_WORDS_AMOUNT-1:0];

      always_comb
        for( int mul_num = 0; mul_num < PART_MULT_WORDS_AMOUNT; mul_num++ )
          begin
            tmp[mul_num] = '0;
            for( int dsp_stage = 0; dsp_stage < DSP_STAGES_AMOUNT; dsp_stage++ )
              tmp[mul_num] += mult_words_comb[mul_num][dsp_stage];
          end

      always_ff @( posedge clk_i )
        for( int mul_num = 0; mul_num < PART_MULT_WORDS_AMOUNT; mul_num++ )
          mult_words[mul_num] <= tmp[mul_num];

    end
endgenerate

always_comb
  for( int word_mul_num = 0; word_mul_num < MULT_WORDS_AMOUNT; word_mul_num++ )
    if( word_mul_num == 0 )
      mult_res_comb[word_mul_num] = mult_words[word_mul_num][PART_MULT_WORDS_WIDTH-1:WORD_WIDTH] + mult_words[word_mul_num+1][MULT_WORD_WIDTH-1:0] + ( mult_words[word_mul_num+2][WORD_WIDTH-1:0] << WORD_WIDTH );
    else
      if( word_mul_num == MULT_WORDS_AMOUNT - 1 )
        mult_res_comb[word_mul_num] = mult_words[2*word_mul_num-1][PART_MULT_WORDS_WIDTH-1:MULT_WORD_WIDTH] + mult_words[2*word_mul_num][PART_MULT_WORDS_WIDTH-1:WORD_WIDTH] + overflow[word_mul_num-1];
      else
        mult_res_comb[word_mul_num] = mult_words[2*word_mul_num-1][PART_MULT_WORDS_WIDTH-1:MULT_WORD_WIDTH] + mult_words[2*word_mul_num][PART_MULT_WORDS_WIDTH-1:WORD_WIDTH] + mult_words[2*word_mul_num+1][MULT_WORD_WIDTH-1:0] + ( mult_words[2*word_mul_num+2][WORD_WIDTH-1:0] << WORD_WIDTH ) + overflow[word_mul_num-1];

always_ff @( posedge clk_i )
  for( int word_mul_num = 0; word_mul_num < MULT_WORDS_AMOUNT; word_mul_num++ )
    overflow[word_mul_num] <= mult_res_comb[word_mul_num][PART_MULT_WORDS_WIDTH-1:MULT_WORD_WIDTH];

always_ff @( posedge clk_i )
  for( int word_mul_num = 0; word_mul_num < MULT_WORDS_AMOUNT; word_mul_num++ )
    if( valid[word_mul_num+2] )
      mult_res[word_mul_num] <= mult_res_comb[word_mul_num][MULT_WORD_WIDTH-1:0];

assign result_o = { mult_res, mult_words[0][WORD_WIDTH-1:0] };

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    valid <= '0;
  else
    for( int stage_num = 0; stage_num <= VALID_REG_WIDTH; stage_num++ )
      if( stage_num == 0 )
        valid[stage_num] <= valid_i && ready_o;
      else
        if( stage_num == VALID_REG_WIDTH-1 )
          begin
            if( valid[stage_num-1] )
              valid[stage_num] <= 1'b1;
            else
              if( ready_i )
                valid[stage_num] <= 1'b0;
          end
        else
          valid[stage_num] <= valid[stage_num-1];

assign ready_o = ~( |valid );
assign valid_o = valid[VALID_REG_WIDTH-1];

endmodule : comba_mult

