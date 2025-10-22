module alarm_clk (
    input rst, /* Active high reset pulse, to set the time to the input hour and minute (as defined by the H_in1, H_in0, M_in1, and M_in0 inputs) and the second to 00. It should also set the alarm value to 0.00.00, and to set the Alarm (output) low. For normal operation, this input pin should be 0*/
    input clk, /* A 10Hz input clock. This should be used to generate each real-time second*/
    input [1:0] H_in1, /*A 2-bit input used to set the most significant hour digit of the clock (if LD_time=1), or the most significant hour digit of the alarm (if LD_alarm=1). Valid values are 0 to 2. */
    input [3:0] H_in0, /* A 4-bit input used to set the least significant hour digit of the clock (if LD_time=1), or the least significant hour digit of the alarm (if LD_alarm=1). Valid values are 0 to 9.*/
    input [3:0] M_in1, /*A 4-bit input used to set the most significant minute digit of the clock (if LD_time=1), or the most significant minute digit of the alarm (if LD_alarm=1). Valid values are 0 to 5.*/
    input [3:0] M_in0, /*A 4-bit input used to set the least significant minute digit of the clock (if LD_time=1), or the least significant minute digit of the alarm (if LD_alarm=1). Valid values are 0 to 9. */
    input LD_time, /* If LD_time=1, the time should be set to the values on the inputs H_in1, H_in0, M_in1, and M_in0. The second time should be set to 0. If LD_time=0, the clock should act normally (i.e. second should be incremented every 10 clock cycles).*/
    input LD_alarm, /* If LD_alarm=1, the alarm time should be set to the values on the inputs H_in1, H_in0, M_in1, and M_in0. If LD_alarm=0, the clock should act normally.*/
    input STOP_al, /* If the Alarm (output) is high, then STOP_al=1 will bring the output back low. */
    input AL_ON, /* If high, the alarm is ON (and Alarm will go high if the alarm time equals the current time). If low, the alarm function is OFF. */
    output reg Alarm, /* This will go high if the alarm time equals the current time, and AL_ON is high. This will remain high, until STOP_al goes high, which will bring Alarm back low.*/
    output reg [1:0] H_out1,
    /* The most significant digit of the hour. Valid values are 0 to 2. */
    output reg [3:0] H_out0,
    /* The least significant digit of the hour. Valid values are 0 to 9. */
    output reg [3:0] M_out1,
    /* The most significant digit of the minute. Valid values are 0 to 5.*/
    output reg [3:0] M_out0, /* The least significant digit of the minute. Valid values are 0 to 9. */
    output reg [3:0] S_out1, /* The most significant digit of the minute. Valid values are 0 to 5. */
    output reg [3:0] S_out0 /* The least significant digit of the minute. Valid values are 0 to 9. */
);

    // internal signal
    reg strb_1Hz; // 1-s clock
    reg [3:0] strb_cnt; // counter for creating 1-Hz strobe 
    reg [4:0] Hr_cnt;   // counter for hours
    reg [1:0] a_hour1;  // alarm most significant hour digit
    reg [3:0] a_hour0;  // alarm least significant hour digit
    reg [3:0] a_min1;   // alarm most significant minute digit
    reg [3:0] a_min0;   // alarm least significant minute digit
    reg [3:0] a_sec1;   // alarm most significant second digit
    reg [3:0] a_sec0;   // alarm least significant minute digit

    /*************************************************/
    /******** Create 1-Hz strobe ****************/
    /*************************************************/
    always_ff @(posedge clk or posedge rst)
    Strobe: begin
        if(rst) begin
            strb_cnt <= 0;
            strb_1Hz <= 0;
        end
        else begin
            strb_cnt <= strb_cnt + 1;
            strb_1Hz <= 0;
            if (strb_cnt >= 9) begin
                strb_cnt <= 0;
                strb_1Hz <= 1;
            end
        end
    end

    /*************************************************/
    /************* Clock operation**************/
    /*************************************************/
    always_ff @(posedge clk or posedge rst)
    main: begin
        if(rst) begin // reset high => set alarm and time to 00.00.00
            a_hour1 <= 2'b00;
            a_hour0 <= 4'b0000;
            a_min1 <= 4'b0000;
            a_min0 <= 4'b0000;
            a_sec1 <= 4'b0000;
            a_sec0 <= 4'b0000;
            Hr_cnt <= 4'b0000;
            M_out1 <= 4'b0000;
            M_out0 <= 4'b0000;
            S_out1 <= 4'b0000;
            S_out0 <= 4'b0000;
        end
        else begin
            if (strb_1Hz) begin
                if (LD_alarm) begin // LD_alarm =1 => set alarm clock to H_in, M_in
                    a_hour1 <= H_in1;
                    a_hour0 <= H_in0;
                    a_min1 <= M_in1;
                    a_min0 <= M_in0;
                    a_sec1 <= 4'b0000;
                    a_sec0 <= 4'b0000;
                end
                if (LD_time) begin // LD_time =1 => set time to H_in, M_in
                    Hr_cnt <= H_in1*10 + H_in0;
                    M_out1 <= M_in1;
                    M_out0 <= M_in0;
                    S_out1 <= 4'b0000;
                    S_out0 <= 4'b0000;
                end
                else begin // LD_time =0 , clock operates normally
                    S_out0 <= S_out0 + 1;
                    if (S_out0 >= 9) begin
                        S_out0 <= 0;
                        S_out1 <= S_out1 + 1;
                        if (S_out1 >= 5) begin
                            S_out1 <= 0;
                            M_out0 <= M_out0 + 1;
                            if (M_out0 >= 9) begin
                                M_out0 <= 0;
                                M_out1 <= M_out1 + 1;
                                if (M_out1 >= 5) begin
                                    M_out1 <= 0;
                                    Hr_cnt <= Hr_cnt + 1;
                                    if (Hr_cnt >= 23) begin // can you enhance this?
                                        Hr_cnt <= 0;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    /*************************************************/
    /***OUTPUT OF THE CLOCK HOURS**********************/
    /*************************************************/
    always_ff @(posedge clk)
    Hour_outputs: begin
        if (Hr_cnt >= 20) begin
            H_out1 <= 2;
            H_out0 <= Hr_cnt - 20;
        end
        else if (Hr_cnt >=10) begin
            H_out1  = 1;
            H_out0 <= Hr_cnt - 10;
        end
        else begin
            H_out1 = 0;
            H_out0 = Hr_cnt;
        end
    end
    
    /*************************************************/
    /******** Alarm function******************/
    /*************************************************/
    always_ff @(posedge clk or posedge rst)
    alarm: begin
        if (rst) 
            Alarm <= 0; // set alarm output to low 
        else begin
            if ({a_hour1,a_hour0,a_min1,a_min0,a_sec1,a_sec0} == {H_out1,H_out0,M_out1,M_out0,S_out1,S_out0})
            begin // if alarm time equals clock time, it will set the Alarm signal with AL_ON=1
                if(AL_ON) Alarm <= 1;
            end
            if(STOP_al) Alarm <= 0; // when STOP_al = 1, reset the Alarm signal
        end
    end

endmodule 
module tb_alarm_clk;
    // Inputs
    reg rst;
    reg clk;
    reg [1:0] H_in1;
    reg [3:0] H_in0;
    reg [3:0] M_in1;
    reg [3:0] M_in0;
    reg LD_time;
    reg LD_alarm;
    reg STOP_al;
    reg AL_ON;

    // Outputs
    wire Alarm;
    wire [1:0] H_out1;
    wire [3:0] H_out0;
    wire [3:0] M_out1;
    wire [3:0] M_out0;
    wire [3:0] S_out1;
    wire [3:0] S_out0;
    // Instantiate the Unit Under Test (UUT)
    alarm_clk uut (
        .rst        (rst),
        .clk        (clk),
        .H_in1      (H_in1),
        .H_in0      (H_in0),
        .M_in1      (M_in1),
        .M_in0      (M_in0),
        .LD_time    (LD_time),
        .LD_alarm   (LD_alarm),
        .STOP_al    (STOP_al),
        .AL_ON      (AL_ON),
        .Alarm      (Alarm),
        .H_out1     (H_out1),
        .H_out0     (H_out0),
        .M_out1     (M_out1),
        .M_out0     (M_out0),
        .S_out1     (S_out1),
        .S_out0     (S_out0)
    );
    // clock 10Hz
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end
    initial begin
        // Initialize Inputs
        rst = 1;
        H_in1 = 1;
        H_in0 = 0;
        M_in1 = 1;
        M_in0 = 4;
        LD_time = 0;
        LD_alarm = 0;
        STOP_al = 0;
        AL_ON = 0; // set clock time to 11h26, alarm time to 00h00 when reset
        // Wait 100 ns for global reset to finish
        #1000;
        rst = 0;
        H_in1 = 1;
        H_in0 = 0;
        M_in1 = 2;
        M_in0 = 0;
        LD_time = 0;
        LD_alarm = 1;
        STOP_al = 0;
        AL_ON = 1; // turn on Alarm and set the alarm time to 11h30
        #1000;
        rst = 0;
        H_in1 = 1;
        H_in0 = 0;
        M_in1 = 2;
        M_in0 = 0;
        LD_time = 0;
        LD_alarm = 0;
        STOP_al = 0;
        AL_ON = 1;
        wait(Alarm); // wait until Alarm signal is high when the alarm time equals clock time
        #1000
        STOP_al = 1; // pulse high the STOP_al to push low the Alarm signal
        #1000
        STOP_al = 0;
        H_in1 = 0;
        H_in0 = 4;
        M_in1 = 4;
        M_in0 = 5;
        LD_time = 1; // set clock time to 11h25
        LD_alarm = 0;
        #1000
        STOP_al = 0;
        H_in1 = 0;
        H_in0 = 4;
        M_in1 = 5;
        M_in0 = 5;
        LD_alarm = 1; // set alarm time to 11h35
        LD_time = 0;
        wait(Alarm); // wait until Alarm signal is high when the alarm time equals clock time
        #1000
        STOP_al = 1; // pulse high the STOP_al to push low the Alarm signal
        #100
        $finish;
    end

 endmodule
