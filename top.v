module smart_gate_controller(
    input wire clk_i, 
    input wire reset_i, 
    input wire car_i,
    input wire pay_ok_i,
    input wire clear_i,
    input wire cnt_reset_i,
    output reg gate_open_o,
    output reg gate_close_o,
    output reg L_red_o,
    output reg L_yellow_o, 
    output reg L_green_o,
    output reg [7:0] car_count__o
);
    // Stati della FSM
    localparam waiting = 3'b000; 
    localparam pre_opening = 3'b001;
    localparam opening = 3'b010;
    localparam open = 3'b011; 
    localparam closing = 3'b100;

    reg [2:0] cs, ns; // current e next state
    reg [1:0] timer, next_timer; // timer conta-cicli
    reg [7:0] car_count, car_count_next;

    // Inizializzazione
    initial begin
        gate_open_o = 0;
        gate_close_o = 1;
        L_green_o = 0;
        L_yellow_o = 0;
        L_red_o = 1;
        car_count = 0;
        timer = 0;
        cs = waiting;
    end

    // Logica sequenziale
    always @(posedge clk_i or negedge reset_i) begin 
        if (!reset_i) begin // reset attivo basso
            gate_open_o <= 0;
            gate_close_o <= 1;
            L_green_o <= 0;
            L_yellow_o <= 0;
            L_red_o <= 1;
            timer <= 0;
            cs <= waiting;
            car_count <= 0;
        end
        else begin
            cs <= ns; 
            timer <= next_timer; 
            car_count <= car_count_next; 
            if (cnt_reset_i) begin
                car_count <= 0;
            end
        end
    end

    // Logica combinatoria 
    always @(*) begin 
        // Valori di default
        ns = cs;
        next_timer = timer;
        car_count_next = car_count;
        
        gate_open_o = 0;
        gate_close_o = 0;
        L_red_o = 0;
        L_yellow_o = 0;
        L_green_o = 0;

        case(cs)
            waiting: begin
                gate_close_o = 1;
                L_red_o = 1;
                next_timer = 2'b00;
                
                if(car_i && pay_ok_i) begin 
                    ns = pre_opening;
                end
            end
            
            pre_opening: begin
                L_yellow_o = 1;
                
                if(timer == 2'd2) begin 
                    ns = opening;
                    next_timer = 0;
                end else begin
                    next_timer = timer + 1;
                end
            end
            
            opening: begin
                if(clear_i) begin 
                    L_green_o = 1;
                    gate_open_o = 1;
                    
                    if(timer == 2'd1) begin 
                        ns = open;
                        next_timer = 0;
                    end else begin 
                        next_timer = timer + 1;
                    end
                end else begin
                    ns = opening;
                end
            end
            
            open: begin
                L_green_o = 1;
                
                if(timer == 2'd3) begin 
                    ns = closing;
                    next_timer = 0;
                end else begin 
                    next_timer = timer + 1;
                end
            end
            
            closing: begin
                L_yellow_o = 1;
                gate_close_o = 1;
                
                // Incrementa contatore auto quando si chiude
                if(timer == 2'd0) begin
                    car_count_next = car_count + 1;
                end
                
                if(timer == 2'd1) begin 
                    ns = waiting;
                    next_timer = 0;
                end else begin
                    next_timer = timer + 1;
                end
            end
            
            default: begin
                ns = waiting;
            end
        endcase
    end

    always @(*) begin
        car_count__o = car_count;
    end

endmodule