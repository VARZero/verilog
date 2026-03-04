`timescale 1ns / 1ps

parameter BAUDRATE = 9600;
localparam BAUDRATE_TIME_NS = 1_000_000_000 / BAUDRATE;

interface uart_sys_interface(
    input           clk
);
    logic           rst;

    // uart_rx -> FIFO
    logic          i_uart_rx;
    logic          i_rxfifo_pop;
    logic [7:0]    o_rxfifo_data;
    logic          o_rxfifo_valid;
    logic          o_rx_full;
    logic          o_rx_empty;

    // FIFO -> uart_tx
    logic          o_uart_tx;
    logic          i_txfifo_push;
    logic [7:0]    i_txfifo_data;
    logic          o_tx_busy;
    logic          o_tx_done;
endinterface // uart_sys_interface

class trans_genBroadcast;
    // uart_rx
    rand bit        rx_valid;
    rand bit [7:0]  rx_transfer_char;

    // rx_fifo
    rand bit        rxfifo_get;
    rand bit [4:0]  rxfifo_get_times;

    // uart_tx
    rand bit        tx_valid;
    rand bit [7:0]  tx_input_data;

    //function display(string name);
    //endfunction // display
endclass // trans_gen2drvNscb

class trans_mon2scb;
    // rx
    logic [7:0]     rxfifo_data[0:31];
    bit   [4:0]     rxfifo_cnt;
    logic           rx_full;
    logic           rx_empty;
    
    // tx 
    logic [9:0]     uart_tx_seq;
endclass // trans_mon2scb

class generator;
    trans_genBroadcast trgb;
    mailbox #(trans_genBroadcast) gen2drv_mbox;
    mailbox #(trans_genBroadcast) gen2mon_mbox;
    mailbox #(trans_genBroadcast) gen2scb_mbox;
    event gen_next_ev;

    function new(mailbox #(trans_genBroadcast) gen2drv_mbox, mailbox #(trans_genBroadcast) gen2mon_mbox,
                 mailbox #(trans_genBroadcast) gen2scb_mbox, event gen_next_ev);
                    this.gen2drv_mbox = gen2drv_mbox;
                    this.gen2mon_mbox = gen2mon_mbox;
                    this.gen2scb_mbox = gen2scb_mbox;
                    this.gen_next_ev = gen_next_ev;
    endfunction // new()

    task run(int run_times);
        repeat (run_times) begin
            trgb = new();
            trgb.randomize();
            if (trgb.rxfifo_get_times == 0) trgb.rxfifo_get = 0;
            gen2drv_mbox.put(trgb);
            gen2mon_mbox.put(trgb);
            gen2scb_mbox.put(trgb);
            //$display("g %h %h %h %h", trgb.rx_valid, trgb.rx_transfer_char, trgb.tx_valid, trgb.tx_input_data);
            @(gen_next_ev);
        end
    endtask // run()
endclass // generator

class driver;
    trans_genBroadcast trgd;
    mailbox #(trans_genBroadcast) gen2drv_mbox;
    virtual uart_sys_interface uart_sys_if;
    event drv2mon_event; 

    bit [9:0] rx_bit_frame;
    logic temp;
    shortint rx_frame_idx;
    shortint rxfifo_idx;

    function new(mailbox #(trans_genBroadcast) gen2drv_mbox, virtual uart_sys_interface uart_sys_if,
                 event drv2mon_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_sys_if = uart_sys_if;
        this.drv2mon_event = drv2mon_event;
    endfunction // new()

    task preset();
        uart_sys_if.rst = 1;
        uart_sys_if.i_uart_rx = 1;
        uart_sys_if.i_rxfifo_pop = 0;
        uart_sys_if.i_txfifo_push = 0;
        uart_sys_if.i_txfifo_data = 0;
        @(posedge uart_sys_if.clk);
        uart_sys_if.rst = 0;
        @(posedge uart_sys_if.clk);
    endtask // preset

    task create_rx_frame_stream(trans_genBroadcast trgd);
        // Create rx frame
        rx_bit_frame = {1'b1, trgd.rx_transfer_char, 1'b0}; // Stop / Data[MSB:LSB] / Start

        for (rx_frame_idx = 0; rx_frame_idx < 10; rx_frame_idx++) begin
            uart_sys_if.i_uart_rx = rx_bit_frame[rx_frame_idx];
            #(BAUDRATE_TIME_NS);
        end
        
        -> drv2mon_event;
    endtask // create_rx_frame_stream

    task create_rxfifo_instruction(trans_genBroadcast trgd);
        for (rxfifo_idx = 0; rxfifo_idx < trgd.rxfifo_get_times; rxfifo_idx++) begin
            @(posedge uart_sys_if.clk); #2;
            uart_sys_if.i_rxfifo_pop = 1'b1;
            @(posedge uart_sys_if.clk); #1;
            uart_sys_if.i_rxfifo_pop = 1'b0;
            if (~uart_sys_if.o_rxfifo_valid) break;
        end
    endtask // create_rxfifo_instruction

    task create_tx_instruction(trans_genBroadcast trgd);
        // Create tx instruction a tick
        @(posedge uart_sys_if.clk); #1;
        uart_sys_if.i_txfifo_push = trgd.tx_valid;
        uart_sys_if.i_txfifo_data = trgd.tx_input_data;
        @(posedge uart_sys_if.clk); #1;
        uart_sys_if.i_txfifo_push = 0;
        uart_sys_if.i_txfifo_data = 0;
    endtask // create_tx_instruction

    task run();
        forever begin
            gen2drv_mbox.get(trgd);
            fork
                if (trgd.rx_valid) create_rx_frame_stream(trgd);
                if (trgd.rxfifo_get) create_rxfifo_instruction(trgd);
                if (trgd.tx_valid) create_tx_instruction(trgd);
            join
            //$display("d %h %h %h %h", trgd.rx_valid, trgd.rx_transfer_char, trgd.tx_valid, trgd.tx_input_data);
        end
    endtask // run()
endclass // driver

class monitor;
    trans_genBroadcast trgm;
    trans_mon2scb trms;
    mailbox #(trans_genBroadcast) gen2mon_mbox;
    mailbox #(trans_mon2scb) mon2scb_mbox;
    virtual uart_sys_interface uart_sys_if;
    event drv2mon_event; 

    shortint bit_seq;

    function new(mailbox #(trans_genBroadcast) gen2mon_mbox, mailbox #(trans_mon2scb) mon2scb_mbox, 
                 virtual uart_sys_interface uart_sys_if, event drv2mon_event);
        this.gen2mon_mbox = gen2mon_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_sys_if = uart_sys_if;
        this.drv2mon_event = drv2mon_event;
    endfunction // new()

    task wait_rx_transaction();
        @(drv2mon_event);
    endtask // wait_rx_transaction

    task receiver_rxfifo_data(trans_mon2scb trms);
        trms.rxfifo_cnt = 0;
        while (uart_sys_if.o_rxfifo_valid) begin
            if (uart_sys_if.i_rxfifo_pop) begin
                trms.rxfifo_data[trms.rxfifo_cnt] = uart_sys_if.o_rxfifo_data; 
                $display("~ %h / %h ~ %t", trms.rxfifo_data[trms.rxfifo_cnt], uart_sys_if.o_rxfifo_data, $time); 
                trms.rxfifo_cnt++;
            end

            @(negedge uart_sys_if.clk);
        end

        trms.rx_full = uart_sys_if.o_rx_full;
        trms.rx_empty = uart_sys_if.o_rx_empty;
    endtask // receiver_rxfifo_data

    task receiver_tx_frame_stream(trans_mon2scb trms);
        while (~uart_sys_if.o_tx_busy) begin @(posedge uart_sys_if.clk); #1; end 
        while (uart_sys_if.o_uart_tx == 1'b1) begin @(posedge uart_sys_if.clk); #1; end // Wait Start
        for (bit_seq = 0; bit_seq < 9; bit_seq++) begin
            trms.uart_tx_seq[bit_seq] = uart_sys_if.o_uart_tx;
            #(BAUDRATE_TIME_NS); 
        end
        trms.uart_tx_seq[9] = uart_sys_if.o_uart_tx;
        while (~uart_sys_if.o_tx_done) begin @(posedge uart_sys_if.clk); #1; end
    endtask // receiver_tx_frame_stream

    task run();
        forever begin
            trms = new();
            gen2mon_mbox.get(trgm);
            fork
                if (trgm.rx_valid) wait_rx_transaction();
                if (trgm.rxfifo_get) receiver_rxfifo_data(trms);
                if (trgm.tx_valid) receiver_tx_frame_stream(trms);
            join
            mon2scb_mbox.put(trms);
            //$display("m %h %h %h %h", trgm.rx_valid, trgm.rx_transfer_char, trgm.tx_valid, trgm.tx_input_data);
        end
    endtask // run()
endclass // monitor

class scoreboard;
    trans_genBroadcast trgs;
    trans_mon2scb trms;
    mailbox #(trans_genBroadcast) gen2scb_mbox;
    mailbox #(trans_mon2scb) mon2scb_mbox;
    event gen_next_ev;

    logic [9:0] compare_seq;

    logic [7:0] compare_fifo [$:32];
    logic [7:0] compare_fifo_data;
    shortint compare_fifo_cnt;

    integer try_cnt, rx_cnt, pass_rxfifo_cnt, fail_rxfifo_cnt, pass_tx_cnt, fail_tx_cnt;

    function new(mailbox #(trans_genBroadcast) gen2scb_mbox, mailbox #(trans_mon2scb) mon2scb_mbox,
                 event gen_next_ev);
                    this.gen2scb_mbox = gen2scb_mbox;
                    this.mon2scb_mbox = mon2scb_mbox;
                    this.gen_next_ev = gen_next_ev;
    endfunction // new()

    task run();
        try_cnt = 0;
        rx_cnt = 0;
        pass_rxfifo_cnt = 0;
        fail_rxfifo_cnt = 0;
        pass_tx_cnt = 0;
        fail_tx_cnt = 0;
        forever begin 
            gen2scb_mbox.get(trgs);
            mon2scb_mbox.get(trms);
            
            try_cnt++;

            if (trgs.rxfifo_get) begin
                /*    
                (성공)
                - fifo가 부족하게 차서 입력된 횟수에 비해 부족하게 나온경우         (1)
                - 입력된 횟수만큼 나온경우                                        (2)
                (실패)
                - fifo가 부족하지도 않은데 횟수에 비해 적게 나온경우                (3)
                */

                for (compare_fifo_cnt = 0; compare_fifo_cnt < trgs.rxfifo_get_times; compare_fifo_cnt++) begin
                    if (compare_fifo.size() == 0) begin
                        if (trms.rx_empty) begin // (1) Compare FIFO and Logic FIFO are Empty
                            // pass
                            $display("%t : PASS uart fifo rx (EMPTY) Count = %d", $time, compare_fifo_cnt);
                            pass_rxfifo_cnt++;
                        end
                        else begin // (1, But) Compare FIFO is not empty but Logic FIFO is empty
                            // fail 
                            $display("%t : !!!FAIL!!! uart fifo rx (EMPTY) Count = %d", $time, compare_fifo_cnt);
                            fail_rxfifo_cnt++;
                        end
                        break;
                    end

                    // (2)
                    compare_fifo_data = compare_fifo.pop_back();
                    if (compare_fifo_data === trms.rxfifo_data[compare_fifo_cnt]) begin
                        // pass
                        $display("\t- PASS uart fifo rx data { %h : %h }", compare_fifo_data, trms.rxfifo_data[compare_fifo_cnt]);
                    end
                    else begin
                        // fail
                        $display("\t- !!!FAIL!!! uart fifo rx data { %h : %h }", compare_fifo_data, trms.rxfifo_data[compare_fifo_cnt]);
                    end
                end

                if (compare_fifo_cnt == (trgs.rxfifo_get_times-1)) begin
                    // pass
                    $display("%t : PASS uart fifo rx", $time);
                    pass_rxfifo_cnt++;
                end
            end

            if (trgs.rx_valid) begin
                compare_fifo.push_front(trgs.rx_transfer_char);
                $display("Compare Data Push %d", compare_fifo.size());
                rx_cnt++;
            end

            if (trgs.tx_valid) begin
                compare_seq = {1'b1, trgs.tx_input_data, 1'b0};
                
                if (compare_seq === trms.uart_tx_seq) begin
                    // pass
                    $display("%t : PASS uart tx : Expected TX SEQ = %b, Receving TX SEQ = %b",
                             $time, compare_seq, trms.uart_tx_seq);
                    pass_tx_cnt++;
                end
                else begin
                    // fail
                    $display("%t : !!FAIL!! uart tx : Expected TX SEQ = %b, Receving TX SEQ = %b",
                             $time, compare_seq, trms.uart_tx_seq);
                    fail_tx_cnt++;
                end
            end
            -> gen_next_ev;
            //$display("s %h %h %h %h", trgs.rx_valid, trgs.rx_transfer_char, trgs.tx_valid, trgs.tx_input_data);
        end
    endtask // run()
endclass // scoreboard

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(trans_genBroadcast) gen2drv_mbox;
    mailbox #(trans_genBroadcast) gen2mon_mbox;
    mailbox #(trans_genBroadcast) gen2scb_mbox;

    mailbox #(trans_mon2scb) mon2scb_mbox;

    event drv2mon_event;
    event gen_next_ev;

    function new(virtual uart_sys_interface uart_sys_if);
        gen2drv_mbox = new();
        gen2mon_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, gen2mon_mbox, gen2scb_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, uart_sys_if, drv2mon_event);
        mon = new(gen2mon_mbox, mon2scb_mbox, uart_sys_if, drv2mon_event);
        scb = new(gen2scb_mbox, mon2scb_mbox, gen_next_ev);
    endfunction // new();
    
    task run(int run_times);
        drv.preset();
        fork
            gen.run(run_times);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #(BAUDRATE_TIME_NS*11);
        
        $stop;
    endtask // run()
endclass // environment

module tb_uart_sys_sv();

    logic clk;

    environment env;

    uart_sys_interface uart_sys_if(clk);

    uart_sys dut (
        .clk                (clk),
        .rst                (uart_sys_if.rst),
        .i_uart_rx          (uart_sys_if.i_uart_rx),
        .i_rxfifo_pop       (uart_sys_if.i_rxfifo_pop),
        .o_rxfifo_data      (uart_sys_if.o_rxfifo_data),
        .o_rxfifo_valid     (uart_sys_if.o_rxfifo_valid),
        .o_rx_full          (uart_sys_if.o_rx_full),
        .o_rx_empty         (uart_sys_if.o_rx_empty),
        .o_uart_tx          (uart_sys_if.o_uart_tx),
        .i_txfifo_push      (uart_sys_if.i_txfifo_push),
        .i_txfifo_data      (uart_sys_if.i_txfifo_data),
        .o_tx_busy          (uart_sys_if.o_tx_busy),
        .o_tx_done          (uart_sys_if.o_tx_done)
    );

    always #5 begin clk = ~clk; end

    initial begin
        clk = 1;
        env = new(uart_sys_if);
        env.run(100);
    end

endmodule
