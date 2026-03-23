
`default_nettype none

module tt_um_reaction_game (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] u_in,     // IOs: Input path
    output wire [7:0] u_out,    // IOs: Output path
    output wire [7:0] u_oe,     // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // State definitions
    localparam IDLE    = 2'b00;
    localparam RUNNING = 2'b01;
    localparam DONE    = 2'b10;

    reg [1:0] state;
    reg [23:0] clk_counter; // For timing the "seconds"
    reg [7:0] reaction_time;
    reg led_flash;

    // Use input pin 0 for the button
    wire btn = ui_in[0];

    // Assign outputs: reaction_time in binary to LEDs
    // When in IDLE, the last LED (bit 7) flashes.
    assign uo_out = (!ui_in[0])
              ? 8'd50
              : ((state == IDLE) ? {led_flash, 7'b0} : reaction_time);
    
    // Set other IOs to 0
    assign u_out = 8'b0;
    assign u_oe  = 8'b0;

    // Logic for 1-second ticks (assuming 10MHz clock)
    // 10,000,000 cycles = 1 second
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            clk_counter <= 0;
            reaction_time <= 0;
            led_flash <= 0;
        end else begin
            case (state)
                IDLE: begin
                    reaction_time <= 0;
                    // Flash the LED roughly every 0.5 seconds
                    if (clk_counter >= 5_000_000) begin
                        clk_counter <= 0;
                        led_flash <= !led_flash;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end

                    // Start the game when button is pressed
                    if (btn) begin
                        state <= RUNNING;
                        clk_counter <= 0;
                        led_flash <= 0;
                    end
                end

                RUNNING: begin
                    // Increment the second counter
                    if (clk_counter >= 10_000_000) begin
                        clk_counter <= 0;
                        if (reaction_time < 8'hFF) // Cap at 255
                            reaction_time <= reaction_time + 1;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end

                    // Stop when button is released (or pressed again depending on toggle logic)
                    // For this version: press to start, release to stop.
                    if (!btn) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    // Wait for a reset or a long press to go back to IDLE
                    if (btn) state <= IDLE;
                end
            endcase
        end
    end
endmodule
