`include "defs.vh"
`timescale 1ns/100ps

module tb_grain128a();

   // testvectors
   localparam
     COUNT = 4,
     KEYIN = {
              128'h00000000000000000000000000000000,
              128'h0123456789abcdef123456789abcdef0,
              128'h00000000000000000000000000000000,
              128'h0123456789abcdef123456789abcdef0
              },
     IVIN = {
             96'h000000000000000000000000,
             96'h0123456789abcdef12345678,
             96'h800000000000000000000000,
             96'h8123456789abcdef12345678
             },
     KEYOUT = {
               128'hc0207f221660650b6a952ae26586136f,
               128'hf88720c13f46e6a43c07eeed89161a4d,
               128'h564b362219bd90e301f259cf52bf5da9,
               128'h7f2acdb7adfb701f8d2083b3c32b43f1
               };


   // Clock and reset
   initial begin
     rst = 1;
     # 400 rst = 0;
   end

   initial begin
     clk = 0;
     forever
	   clk = #50 !clk;
   end

   // dut
   reg                  clk, clken, rst;
   wire                 key, iv, init;
   wire                 key_out, key_valid_out;
   grain128a dut
     (
      .CLK_I(clk),
      .CLKEN_I(clken),
      .ARESET_I(rst),

      .KEY_I(key),
      .IV_I(iv),
      .INIT_I(init),

      .KEYSTREAM_O(key_out),
      .KEYSTREAM_VALID_O(key_valid_out)
      );


   // dummy clock enable is randomly set
   reg [3:0]       lfsr;
   always @(posedge clk, posedge rst) begin
     if(rst) begin
	   lfsr <= 15;
	   clken <= 0;
     end else begin
	   lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[0] };
	   clken <= lfsr[0];
     end
   end

   // state machine
   localparam
     S_RESET = 0,
     S_IDLE = 1,
     S_INIT = 2,
     S_KEYIV = 3,
     S_KEY = 4,
     S_READ = 5,
     S_DONE = 6
              ;

   assign init = state == S_INIT;

   reg [2:0] state;
   always @(posedge clk, posedge rst)
     if(rst) begin
       state <= S_RESET;
     end else if(clken) begin
       case(state)
         S_RESET: state <= S_IDLE;
         S_IDLE: state <= S_INIT;
         S_INIT: state <= S_KEYIV;
         S_KEYIV: if(cnt == 96-1) state <= S_KEY;
         S_KEY: if(cnt == 128-1) state <= S_READ;
         S_READ: if(cnt == 256-1) state <= S_DONE;
         S_DONE: state <= S_IDLE;
         default: state <= S_RESET;
       endcase
     end


   // shift in data, gather result
   assign key = keyin[127];
   assign iv = ivin[95];
   reg [127:0] keyin, keyout, keystream;
   reg [95:0]  ivin;

   always @(posedge clk, posedge rst)
     if(rst) begin
     end else if(clken) begin
       if(state == S_INIT) begin
         keyin = KEYIN >> (i * 128);
         keyout = KEYOUT >> (i * 128);
         ivin = IVIN >> (i * 96);

         $display("Round %d:", i);
         $display("IV      = %h", ivin);
         $display("KEY-IN  = %h", keyin);
         $display("KEY-OUT = %h", keyout);
       end


       if(state == S_KEYIV || state == S_KEY)
         keyin = keyin << 1;

       if(state == S_KEYIV)
         ivin = ivin << 1;

       if(state == S_RESET)
         keystream = 0;
       else if(state == S_READ && key_valid_out)
         keystream = { keystream[126:0], key_out };
     end


   // counter
   reg [7:0] cnt;
   always @(posedge clk, posedge rst)
     if(rst)
       state <= S_RESET;
     else if(clken) begin
       if(state == S_KEYIV || state == S_KEY)
         cnt <= cnt + 1;
       else if(state == S_READ) begin
         if(key_valid_out)
           cnt <= cnt + 1;
       end else
         cnt <= 0;
     end


   // tester
   integer i;
   initial begin

     // wait until reset is done
     @(negedge rst);

     for(i = 0; i < COUNT; i++) begin

       // wait until a round is done
       while( !(state == S_DONE && clken == 1))
         @(posedge clk);

       if(keyout != keystream) begin
         $display("%t: round %d, wanted %h got %h", $time, i, keyout, keystream);
         $finish(-1);
       end

       // next
       @(posedge clk);
     end

     $display("All okay");
     $finish(0);
   end

   initial begin
     $dumpfile("build/tb_grain128a.vcd");
     $dumpvars;

     #1000000 $display("Failed to terminate normally");
     $finish;
   end

endmodule // tb_grain128a
