
`include "defs.vh"

module grain128a
  (
   input  CLK_I,
   input  CLKEN_I,
   input  ARESET_I,

   input  KEY_I,
   input  IV_I,
   input  INIT_I,

   output KEYSTREAM_O,
   output KEYSTREAM_VALID_O
   );

   reg [127:0] lfsr, nfsr;


   assign KEYSTREAM_VALID_O = valid;
   assign KEYSTREAM_O = y;

   wire        y = h
               ^ lfsr[93]
               ^ nfsr[2] ^ nfsr[15] ^ nfsr[36] ^ nfsr[45] ^ nfsr[64] ^ nfsr[73]^ nfsr[89]
               ;

   wire        h =
               (nfsr[12] & lfsr[8]) ^ (lfsr[13] & lfsr[20])
	           ^ (nfsr[95] & lfsr[42]) ^ (lfsr[60] & lfsr[79])
	           ^ (nfsr[12] & nfsr[95] & lfsr[94])
               ;

   wire        g =
	           nfsr[0] ^ nfsr[26] ^ nfsr[56] ^ nfsr[91] ^ nfsr[96]
	           ^ (nfsr[3] & nfsr[67]) ^ (nfsr[11] & nfsr[13]) ^ (nfsr[17] & nfsr[18])
	           ^ (nfsr[27] & nfsr[59]) ^ (nfsr[40] & nfsr[48]) ^ (nfsr[61] & nfsr[65])
	           ^ (nfsr[68] & nfsr[84])
               // these terms were added in grain128a
               ^(nfsr[88] & nfsr[92] & nfsr[93] & nfsr[95])
               ^(nfsr[22] & nfsr[24] & nfsr[25])
               ^(nfsr[70] & nfsr[78] & nfsr[82])
               ;

   wire        f = lfsr[0] ^ lfsr[7] ^ lfsr[38] ^ lfsr[70] ^ lfsr[81] ^ lfsr[96];


   // shift registers
   always @(posedge CLK_I)
     if(CLKEN_I) begin
       case(state)
         S_KEYIV, S_KEYIV1, S_KEYIV0:
           nfsr <= { KEY_I, nfsr[127:1] };
         default:
           nfsr <= { g ^ lfsr[0] ^ (y & !valid) ,nfsr[127:1] };
       endcase // case (state)

       case(state)
         S_KEYIV:
           lfsr <= { IV_I, lfsr[127:1] };
         S_KEYIV1:
           lfsr <= { 1'b1, lfsr[127:1] };
         S_KEYIV0:
           lfsr <= { 1'b0, lfsr[127:1] };
         default:
           lfsr <= { f ^ (y & !valid), lfsr[127:1] };
       endcase // case (state)

     end

   // counter
   reg [7:0] cnt;
   always @(posedge CLK_I) begin
     if(CLKEN_I) begin
       if(state == S_NORMAL && INIT_I)
         cnt <= 0;
       else
         cnt <= cnt + 1;
     end
   end



   // state machine
   localparam
     S_NORMAL = 0,
     S_KEYIV = 1,
     S_KEYIV1 = 2,
     S_KEYIV0 = 3;


   reg [1:0] state;
   reg       valid;
   always @(posedge CLK_I, posedge ARESET_I) begin
     if(ARESET_I) begin
       state <= S_NORMAL;
       valid <= 0;
     end else if(CLKEN_I) begin
       case(state)
         S_NORMAL:
           if(INIT_I) begin
             state <= S_KEYIV;
             valid <= 0;
           end else if(cnt == 128 - 1)
             valid <= 1;

         S_KEYIV:
           if(cnt == 96 - 1)
             state <= S_KEYIV1;

         S_KEYIV1:
           if(cnt == 128 - 2)
             state <= S_KEYIV0;

         S_KEYIV0:
           state <= S_NORMAL;

         default:
           state <= S_NORMAL;
       endcase
     end
   end

endmodule
