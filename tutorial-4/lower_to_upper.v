module lower_to_upper (
    input i_Clock,
    input i_Reset,
    input i_Data_Empty,
    input [7:0] i_data,
    output [7:0] o_data,
    output o_write_enable,
    output o_read_enable
    );

    // Internal registers
    reg r_read_enable;
    reg r_read_en_delay;

    // Shift register to delay one clock cycle
    always @(posedge i_Clock) begin
        r_read_en_delay <= o_write_enable;
        r_read_enable <= r_read_en_delay;
    end

    // Outputs
    assign o_write_enable = ~i_Data_Empty;
    assign o_read_enable = r_read_enable;
    assign o_data = i_data - 8'h20;
    
endmodule