`timescale 1ns/1ps

module tb_pwm;

   // Parameters
   localparam CLK_PERIOD = 10; // 100MHz clock → 10ns period
   localparam DBNC_CNT_MAX = 1000;

   // DUT signals
   logic clk;
   logic rst;
   logic incr_duty;
   logic decr_duty;
   logic PWM_OUT;

   // Instantiate DUT
   pwm #(.DBNC_CNT_MAX(DBNC_CNT_MAX)) dut (
      .clk(clk),
      .rst(rst),
      .incr_duty(incr_duty),
      .decr_duty(decr_duty),
      .PWM_OUT(PWM_OUT)
   );
// test
   // Clock generation
   initial clkgen: begin 
      clk = 0;
      forever #(CLK_PERIOD/2) clk = ~clk;
   end
   // Stimulus
   initial Stimulus: begin
      // Initialize
      rst = 1;
      incr_duty = 0;
      decr_duty = 0;
      #50;
      rst = 0;

      // Wait for debounce pulse
      repeat (DBNC_CNT_MAX + 10) @(posedge clk);

      // Increase duty cycle
      incr_duty = 1;
      repeat (5) @(posedge clk);
      incr_duty = 0;

      // Wait for debounce pulse
      repeat (DBNC_CNT_MAX + 10) @(posedge clk);

      // Decrease duty cycle
      decr_duty = 1;
      repeat (5) @(posedge clk);
      decr_duty = 0;

      // Observe PWM output for a few cycles
      repeat (100) @(posedge clk);

      $finish;
   end

   // Monitor
   always @(posedge clk) 
   monitor: begin
      $display("Time: %0t | PWM_OUT: %b | DUTY_CYCLE: %0d", $time, PWM_OUT, dut.DUTY_CYCLE);
   end

endmodule