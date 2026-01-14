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
    //inizializziamo i valori
    pay_ok_i = 0; 
    car_i = 0; 
    clear_i = 0;
    gate_open_o =0;
    gate_close = 1;
    L_green_o = 0;
    L_yellow_o = 0;
    L_red_o = 1;
    car_count = 0;
    timer = 0;

    //stati della FSM
    localparam waiting = 3'b000; 
    localparam pre_opening = 3'b001;
    localparam opening = 3'b010;
    localparam open = 3'b011; 
    localparam closing = 3'b100;

    reg [2:0] cs,ns; //ci serviremo di 3 bit per gli stati

    reg [1:0] timer, next_timer; //timer per i cicli

    reg [7:0] car_count_next;
    reg [8:0] temp;

    temp = 1;

    always @(posedge clk or negedge reset) begin 
        if(cnt_reset_i) begin
            car_count__o <= 0;
        end
        else begin 
            car_count__o <= car_count_next;
        end
        if (!reset_i) //reset attivo basso e se l'operazione è effettuabile
        begin
            pay_ok_i <= 0; //reset dei valori al default
            car_i <= 0; 
            clear_i <= 0;
            gate_open_o <=0;
            gate_close <= 1;
            L_green_o <= 0;
            L_yellow_o <= 0;
            L_red_o <= 1;
            car_count <= 0;
            timer <= 0;
            cs <= waiting; 
        end
        else 
        begin
            cs <= ns; //aggiorniamo lo stato in corrispondenza del clk
            timer <= next_timer; //incremento del timer
        end

        always @(*) //transizione degli stati
        begin 
            ns = cs;
            next_timer = timer; //di default ns e next_timer restano invariati

            case(cs)
                waiting : begin  //logica del waiting
                    next_timer=2'b00;
                    L_green_o = 0;
                    L_red_o = 1;
                    if(car_i and pay_ok_i) begin 
                        ns = pre_opening; 
                        gate_close_o=1;
                    end
                end
                pre_opening : begin //logica del pre_opening
                    L_red_o=0;
                    L_yellow_o=1;
                    if(timer==2'd2) begin 
                        ns = opening; 
                    end
                    next_timer = timer + 2'd1;
                end
                opening: begin //logica dell'opening
                    if(clear_i) begin 
                        L_yellow = 0;
                        L_green_o = 1;
                        gate_open_o = 1;
                        if (timer == 2'd1) begin 
                            ns = open; 
                        end else begin 
                            next_timer = timer + 2'd1;
                        end
                    end
                end
                open : begin //logica di open
                    clear_i=0;
                    gate_open_o=0;
                    L_green_o=1; //teoricamente lo era ancora dallo stato precedente
                    if(timer == 2'd3) begin 
                        ns = closing;
                    end else begin 
                        next_timer = timer + 2'd1;
                    end
                end
                closing : begin //logica di closing
                    if(!temp[8]) begin
                    car_count_next = car_count+ 2'd1;
                    end
                    L_green_o = 0;
                    L_yellow_o = 1;
                    gate_close_o =1;
                    if(timer == 2'd1) begin 
                        ns = waiting;
                    end
                    else begin
                        next_timer = timer + 2'd1;
                     end
                end
        end
    end
endmodule