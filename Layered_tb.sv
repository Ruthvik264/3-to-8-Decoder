// Interface
interface decoder_if;
    logic [2:0] a;
    logic [7:0] y;
endinterface

// Packet / Transaction Class
class packet;
    rand bit [2:0] a;
    bit [7:0] y;
    bit [7:0] expected;
endclass

// Generator
class generator;
    mailbox gen2driv;
    packet p;

    function new(mailbox gen2driv);
        this.gen2driv = gen2driv;
    endfunction

    task run();
        repeat (20) begin
            p = new();
            assert(p.randomize());
            gen2driv.put(p);
        end
    endtask
endclass

// Driver 
class driver;
    virtual decoder_if vif;
    mailbox gen2driv;

    function new(virtual decoder_if vif, mailbox gen2driv);
        this.vif      = vif;
        this.gen2driv = gen2driv;
    endfunction

    task run();
        packet p;
        forever begin
            gen2driv.get(p);
            vif.a = p.a; 
            #5; 
        end
    endtask
endclass

// Monitor (Combines input and output capture into one component)
class monitor;
    virtual decoder_if vif;
    mailbox mon2ref_sb; 

    function new(virtual decoder_if vif, mailbox mon2ref_sb);
        this.vif = vif;
        this.mon2ref_sb = mon2ref_sb;
    endfunction

    task run();
        packet p;
        forever begin
            @(vif.a);
            #1; 
            p = new();
            p.a = vif.a;
            p.y = vif.y; 
            mon2ref_sb.put(p);
        end
    endtask
endclass

// Reference Model (Calculates expected output)
class reference_model;
    mailbox mon2ref_sb;
    mailbox ref2sb;

    function new(mailbox mon2ref_sb, mailbox ref2sb);
        this.mon2ref_sb = mon2ref_sb;
        this.ref2sb = ref2sb;
    endfunction

    task run();
        packet p;
        forever begin
            mon2ref_sb.get(p);
            p.expected = 8'b1 << p.a; 
            ref2sb.put(p);
        end
    endtask
endclass

// Scoreboard (Compares Expected from Ref Model vs. Actual from Monitor)
class scoreboard;
    mailbox ref2sb;
    
    function new(mailbox ref2sb);
        this.ref2sb = ref2sb;
    endfunction

    task run();
        packet p;
        forever begin
            ref2sb.get(p);

            if (p.expected !== p.y)
                $display("[ERROR] a=%b expected=%b got=%b",
                          p.a, p.expected, p.y);
            else
                $display("[PASS] a=%b output correct: %b",
                          p.a, p.y);
        end
    endtask
endclass

// Environment 
class environment;

    generator gen;
    driver drv;
    monitor mon; // Single monitor
    reference_model refm;
    scoreboard sb;

    mailbox gen2driv;
    mailbox mon2ref_sb;
    mailbox ref2sb;

    virtual decoder_if vif;

    function new(virtual decoder_if vif);
        this.vif = vif;

        gen2driv    = new();
        mon2ref_sb  = new();
        ref2sb      = new();

        gen  = new(gen2driv);
        drv  = new(vif, gen2driv);
        mon  = new(vif, mon2ref_sb);
        refm = new(mon2ref_sb, ref2sb); 
        sb   = new(ref2sb);            
    endfunction

    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            refm.run();
            sb.run();
        join_any
    endtask

endclass

// Design Under Test (DUT)
module decoder(input logic [2:0] a,
               output logic [7:0] y);

    always_comb begin
        y = 8'b0; 

        case (a)
            3'b000: y = 8'b00000001; 
            3'b001: y = 8'b00000010; 
            3'b010: y = 8'b00000100;
            3'b011: y = 8'b00001000;
            3'b100: y = 8'b00010000;
            3'b101: y = 8'b00100000;
            3'b110: y = 8'b01000000;
            3'b111: y = 8'b10000000;
            default: y = 8'b0; 
        endcase
    end
endmodule

// Top Testbench Module
module tb;

    decoder_if dif();
    decoder dut(.a(dif.a), .y(dif.y));

    environment env;

    initial begin
        env = new(dif);
        env.run();
        #200;
        $finish;
    end

endmodule
