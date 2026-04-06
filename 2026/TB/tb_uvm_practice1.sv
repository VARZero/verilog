`include "uvm_macros.svh"
import uvm_pkg::*;

interface adder_if ();
	logic [7:0] a; 
	logic [7:0] b; 
	logic [8:0] y; 
endinterface // adder_if

class adder_seq_item extends uvm_sequence_item;
	rand logic [7:0] a;
	rand logic [7:0] b;
	logic [7:0] y;

	function new(string name = "ADDER_SEQ_ITEM");
	endfunction // new()

	`uvm_object_utils_begin(adder_seq_item)
		`uvm_field_int(a, UVM_DEFAULT)
		`uvm_field_int(b, UVM_DEFAULT)
		`uvm_field_int(y, UVM_DEFAULT)
	`uvm_object_utils_end

endclass // adder_seq_item

class adder_sequence extends uvm_sequence;
	`uvm_object_utils(adder_sequence)

	adder_seq_item a_seq_item;

	function new(string name = "ADDER_SEQ");
		super.new(name);
	endfunction // new()

	virtual task body();
		a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM");

		repeat(100) begin
			start_item(a_seq_item);
			if (!a_seq_item.randomize()) begin
				`uvm_error("SEQ_ITEM", "Fail to generate random value!");
			end
			`uvm_info("SEQ", "Data send to Driver", UVM_NONE);
			finish_item(a_seq_item);
		end
	endtask // body
endclass // adder_sequence	

class adder_driver extends uvm_driver #(adder_seq_item);
	`uvm_component_utils(adder_driver)

	virtual adder_if a_if;
	adder_seq_item a_seq_item;

	function new(string name = "ADDER_DRV", uvm_component c);
		super.new(name, c);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);
		if (!uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if)) begin
			`uvm_fatal(get_name(), "Unable to access adder interface");
		end
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		$display("Display run phase");
		forever begin
			seq_item_port.get_next_item(a_seq_item);
			a_if.a <= a_seq_item.a;
			a_if.b <= a_seq_item.b;
			#10;
			seq_item_port.item_done();
		end
	endtask // run_phase
endclass // adder_driver

class adder_monitor extends uvm_monitor;
	`uvm_component_utils(adder_monitor)

	uvm_analysis_port #(adder_seq_item) send;
	virtual adder_if a_if;
	adder_seq_item a_seq_item;

	function new(string name = "ADDER_MON", uvm_component c);
		super.new(name, c);
		send = new("WRITE", this);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);
		if (!uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if)) begin
			`uvm_fatal(get_name(), "Unable to access adder interface");
		end
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		forever begin
			#10;
			a_seq_item.a = a_if.a;
			a_seq_item.b = a_if.b;
			a_seq_item.y = a_if.y;
			`uvm_info("MON", "Send data to Scoreboard", UVM_LOW);
			send.write(a_seq_item);
		end
	endtask // run_phase
endclass // adder_monitor

class adder_agent extends uvm_agent;
	`uvm_component_utils(adder_agent)

	adder_driver a_drv;
	adder_monitor a_mon;
	uvm_sequencer #(adder_seq_item) a_sqr;

	function new(string name = "ADDER_AGT", uvm_component c);
		super.new(name, c);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a_drv = adder_driver::type_id::create("DRV", this);
		a_mon = adder_monitor::type_id::create("MON", this);
		a_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SEQ", this);
	endfunction // build_phase	

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a_drv.seq_item_port.connect(a_sqr.seq_item_export);
	endfunction // connect_phase
endclass // adder_agent

class adder_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(adder_scoreboard)
	uvm_analysis_imp #(adder_seq_item, adder_scoreboard) recv;

	function new(string name = "ADDER_SCB", uvm_component c);
		super.new(name, c);
		recv = new("READ", this);
	endfunction // new()

	virtual function void write(adder_seq_item data);
		`uvm_info("SCB", "Data received from Monitor", UVM_LOW);
		if (data.a + data.b == data.y) begin
			`uvm_info("SCB", $sformatf("PASS! a:%0d + b:%0d = y:%0d", data.a, data.b, data.y), UVM_LOW);
		end
		else begin
			`uvm_error("SCB", $sformatf("FAIL! a:%0d + b:%0d != y:%0d", data.a, data.b, data.y));
		end
	endfunction // write()
endclass // adder_scoreboard

class adder_environment extends uvm_env;
	`uvm_component_utils(adder_environment)

	adder_agent a_agt;
	adder_scoreboard a_scb;

	function new(string name = "ADDER_ENV", uvm_component c);
		super.new(name, c);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a_agt = adder_agent::type_id::create("AGT", this);
		a_scb = adder_scoreboard::type_id::create("SCB", this);
	endfunction // build_phase
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a_agt.a_mon.send.connect(a_scb.recv);
	endfunction // connect_phase
endclass // adder_environment

class adder_test extends uvm_test;
	`uvm_component_utils(adder_test)

	adder_sequence a_seq;
	adder_environment a_env;

	function new(string name = "ADDER_TEST", uvm_component c);
		super.new(name, c);
	endfunction // new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a_seq = adder_sequence::type_id::create("SEQ", this);
		a_env = adder_environment::type_id::create("ENV", this);
	endfunction // build_phase

	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
			a_seq.start(a_env.a_agt.a_sqr);
		phase.drop_objection(this);
	endtask // run_phase

	virtual function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		uvm_top.print_topology();
	endfunction // report_phase
endclass // adder_test

module tb_top ();

	adder_if a_if ();

	adder dut (
		.a(a_if.a),
		.b(a_if.b),
		.y(a_if.y)
	);

	initial begin
		$fsdbDumpvars(0);
		$fsdbDumpfile("build/wave.fsdb");
	end

	initial begin
		uvm_config_db#(virtual adder_if)::set(null, "*", "a_if", a_if);
		run_test("adder_test");
	end

endmodule

