class generator;

    //--------------------------------------------------
    // Mailbox
    //--------------------------------------------------
    mailbox #(transaction) gen2drv;

    //--------------------------------------------------
    // Number of Transactions
    //--------------------------------------------------
    int num_transactions = 20;

    //--------------------------------------------------
    // Constructor
    //--------------------------------------------------
    function new(mailbox #(transaction) mb);
        gen2drv = mb;
    endfunction

    //--------------------------------------------------
    // Run
    //--------------------------------------------------
    task run();

        transaction tr;

        repeat(num_transactions)
        begin

            tr = new();

            // Randomize transaction
            assert(tr.randomize())
            else
                $fatal("Randomization Failed");

            //----------------------------
            // Expected Values
            //----------------------------

            tr.exp_x1    = 5;
            tr.exp_x2    = 7;
            tr.exp_x3    = 12;
            tr.exp_x4    = 12;
            tr.exp_x5    = 55;
            tr.exp_mem10 = 12;

            //----------------------------
            // Decode instruction name
            //----------------------------

            case(tr.instr[6:0])

                7'b0110011 : tr.instr_name = "ADD/SUB";

                7'b0010011 : tr.instr_name = "ADDI";

                7'b0000011 : tr.instr_name = "LW";

                7'b0100011 : tr.instr_name = "SW";

                7'b1100011 : tr.instr_name = "BEQ";

                default    : tr.instr_name = "UNKNOWN";

            endcase

            //----------------------------
            // Sample Functional Coverage
            //----------------------------

            tr.sample();

            //----------------------------
            // Display
            //----------------------------

            tr.display();

            //----------------------------
            // Send to Driver
            //----------------------------

            gen2drv.put(tr.copy());

        end

    endtask

endclass
