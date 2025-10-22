// PWM Generator with 10MHz PWM output with variable Duty Cycle
// Two debounced buttons are used to control the duty cycle (step size: 10%)
module pwm #(
   parameter DBNC_CNT_MAX = 1000 
)(
   input  clk, // 100MHz clock input 
   input  rst,
   input  incr_duty, // input to increase 10% duty cycle 
   input  decr_duty, // input to decrease 10% duty cycle 
   output PWM_OUT // 10MHz PWM output signal 
);
   reg[15:0] dbnc_cntr; // debounce counter 
   reg  debnc;
   reg  incr_duty1, incr_duty2;
   reg  decr_duty1, decr_duty2;

   reg[3:0] counter_PWM=0; // counter for creating 10Mhz PWM signal
   reg[3:0] DUTY_CYCLE=5; // initial duty cycle is 50%

   // Debouncing 2 buttons for inc/dec duty cycle 
   // Firstly generate slow "debnc" pulse
   always_ff @(posedge clk or posedge rst) // async reset
   debounce: begin
      if (rst) begin
         dbnc_cntr <= 0;
         debnc <= 0;
      end
      else begin
         dbnc_cntr <= dbnc_cntr + 1;
         debnc <= 0;
         if (dbnc_cntr >= DBNC_CNT_MAX) begin
            dbnc_cntr <= 0;
            debnc <= 1;
         end
      end
   end

   // vary the duty cycle using the debounced buttons above
   always_ff @(posedge clk)
   vary_duty_cycle: begin
      // avoid metastability
      incr_duty1 <= incr_duty;
      incr_duty2 <= incr_duty1;
      decr_duty1 <= decr_duty;
      decr_duty2 <= decr_duty1;
      // increase duty cycle when enabled by debnc 
      if (incr_duty2==1 && debnc==1 && DUTY_CYCLE <= 9)
         DUTY_CYCLE <= DUTY_CYCLE + 1; // increase duty cycle by 10%
      // decrease duty cycle when enabled by debnc 
      else if (decr_duty2==1 && debnc==1 && DUTY_CYCLE>=1)
         DUTY_CYCLE <= DUTY_CYCLE - 1; //decrease duty cycle by 10%
   end

   // Create 10MHz PWM signal with variable duty cycle controlled by 2 buttons 
   always_ff @(posedge clk)
   pwm_counter: begin
      counter_PWM <= counter_PWM + 1;
      if (counter_PWM >= 9)
         counter_PWM <= 0;
   end

   assign PWM_OUT = counter_PWM < DUTY_CYCLE ? 1:0;

endmodule
