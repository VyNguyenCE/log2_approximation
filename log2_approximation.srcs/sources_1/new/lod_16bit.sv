`timescale 1ns / 1ps

// Leading One Detector (LOD) 16-bit
// Determines the position of the most significant set bit (MSB)
module lod_16bit (
    input  logic [15:0] in_x,
    output logic [3:0]  k_out,      // MSB bit position (0 to 15)
    output logic        zero_flag   // Flag set high when in_x == 0
);
    assign zero_flag = (in_x == 16'h0000);

    always_comb begin
        if      (in_x[15]) k_out = 4'd15;
        else if (in_x[14]) k_out = 4'd14;
        else if (in_x[13]) k_out = 4'd13;
        else if (in_x[12]) k_out = 4'd12;
        else if (in_x[11]) k_out = 4'd11;
        else if (in_x[10]) k_out = 4'd10;
        else if (in_x[9])  k_out = 4'd9;
        else if (in_x[8])  k_out = 4'd8;
        else if (in_x[7])  k_out = 4'd7;
        else if (in_x[6])  k_out = 4'd6;
        else if (in_x[5])  k_out = 4'd5;
        else if (in_x[4])  k_out = 4'd4;
        else if (in_x[3])  k_out = 4'd3;
        else if (in_x[2])  k_out = 4'd2;
        else if (in_x[1])  k_out = 4'd1;
        else if (in_x[0])  k_out = 4'd0;
        else               k_out = 4'd0;
    end
endmodule