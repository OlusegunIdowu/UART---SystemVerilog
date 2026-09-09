# UART (SystemVerilog)

A UART (Universal Asynchronous Receiver-Transmitter) built using System Verilog. Developed and verified entirely through simulation, with no physical FPGA board required.

# Overview:
    This UART consists of:
        - Baud Rate Generator: Divides the system clock down to a rate the transmitter and reciver can both follow allowing them to send and recieve at the same rate.
        - Transmitter: Turns a byte into data that can be transmitted using the UART -> start bit, 8 data bits LSB to MSB, stop bit.
        - Reciever: Detects the incoming data and recontructs it into the original byte.
        - Testbench: Verifies the TX -> RX pipeline by wiring the TX's output to the RX's input and checking the transmitted bytes are correctly recieved 

# Inputs/Outputs:
    TX:
        - data: The byte to be transmitted.
        - send: A single cycle pulse that tells the TX to start transmision.
        - busy: A signal that states that the TX is currently transmitting data.
        - tx_signal: This the individual bits of the bytes from LSB to MSB
    RX:
        - rx_signal: This is how the RX recieves the bits in order to reconstruct the byte.
        - data_out: The byte reconstructed on the RX side is outputted here.
        - data_valid: A single cycle pulse that alerts the world that the byte is ready
    Baud Rate Generator:
        - clk: The system clock for the whole process. Since this is done digitally its changing value is coded in the testbenches.
        - rst_n: Gives the UART a way to go into a starting state. Resets tick and counter
        - tick: This is the rate TX and RX move at.

# States: 
| op code | state | description                                                                                                                       |
|---------|-------|-----------------------------------------------------------------------------------------------------------------------------------|
| 2'b00   | IDLE  | the state returned to after every completed transmission and transitions to START                                                 |
| 2'b01   | START | drives the starting bit of tx_signal and transitions to DATA                                                                      |
| 2'b10   | DATA  | sends signal of bits one after the other LSB to MSB / recontructs transmitted bits into a byte. after 8 bits it transitions to STOP
| 2'b11   | STOP  | drives/reads the stopping bit for tx_signal ends the data transmision and transitions back to IDLE                                |

# UART Frame Format Signal:
 -  The signal transmitted
| IDLE | START                | DATA                                                        | STOP                  |
| High | Low for 1 bit period | High or low depending on the bits transmitted. (LSB -> MSB) | High for 1 bit period |

# Design Descisions:
- Parameterisation:
    clk_frq and baud_rate are module parameters on baud_gen, allowing the same module to be reused for any clock speed or baud rate without changing the internal logic. baud_cycle is derived from these two parameters as a localparam rather than hardcoded.
- Oversampling:
    The baud generator produces a single tick per bit period (1x) rather than 16x oversampling. This is sufficient here because TX and RX share the exact same clock and tick signal in simulation, so there is no timing drift between them. On separate physical hardware with independent clocks, 16x oversampling would be needed so RX can sample bit centers reliably instead of at transition edges.
- Counter Sizing:
    The baud generator's counter is sized using $clog2(baud_cycle) instead of a fixed bit width. This means the counter is always exactly wide enough to count up to baud_cycle - 1, and stays correct automatically if clk_frq or baud_rate are changed later.
- Bit Order:
    Data is transmitted and received LSB first, matching standard UART convention. TX sends byte_reg[0] each bit period and shifts right afterwards. RX reconstructs the byte in the opposite direction, inserting each new bit at the top of byte_reg with {rx_signal, byte_reg[7:1]} so the bits land back in their original order once all 8 have arrived.
- Handshake Signals:
    send (TX) and data_valid (RX) are both single-cycle pulses rather than held levels, since each only needs to trigger or announce an event once. busy (TX) is held high for the full duration of a transmission instead, since it needs to communicate an ongoing state rather than a single event. This prevents a new byte being loaded into TX while a transmission is still in progress.
- FSM Structure:
    Both TX and RX are built as 4-state FSMs (IDLE, START, DATA, STOP), mirroring the UART frame format directly rather than using a single flat counter. This keeps each state's responsibility limited to driving or reading one part of the frame for exactly one bit period.
- Frame Format:
    No parity bit is used — standard 8-N-1 framing (1 start bit, 8 data bits, 1 stop bit). Parity and stop-bit validity checking were left out of the first working version and are noted as future additions rather than built in immediately.
- Verification Strategy:
    The loopback testbench wires tx_signal directly into rx_signal, testing the full TX-to-RX pipeline in one simulation without needing two physical devices. Results are checked automatically with $display PASS/FAIL output for each byte sent, rather than relying only on visual waveform inspection.

# Diagram:
    
    data ->|         |  tx_signal       |        | -> data_out
    send ->|    tx   | ---------------> |   rx   | -> data_valid
    busy <-|         |        rx_signal |        |
                 ^                          ^
                 |------------tick----------|----------                                                    
                                                      |      
                   clk   -> |                     |   | 
                   rst_n -> | baud rate generator | --|
                            |                     |

# Verification:
    There was mutiple test benches used throughout the building process but the main testbench, uart_tx_rx_tb.sv has only three tests that ensure the inputted byte in the TX and outputed byte in the RX are the same

# How to Simulate:
    Requirements: Icarus Verilog

    Baud Rate Generator:
        cd "baud rate generator"
        iverilog -g2012 -o baud_rate_sim baud_rate_gen.sv baud_rate_gen_tb.sv
        vvp baud_rate_sim
        
    Full Test:
        iverilog -g2012 -o loopback_sim "baud rate generator/baud_rate_gen.sv" "reciever/uart_rx.sv" "transmitter/uart_tx.sv" uart_tx_rx_tb.sv
        vvp loopback_sim



# Future Work:
    - Stop-Bit Validity Checking:
        RX currently assumes the stop bit is always correct. A more robust version would check that the line is high during STOP and flag a framing error if not.

    - FIFO Buffering:
        Adding FIFO buffering for TX and/or RX would allow queuing multiple bytes rather than waiting for one transmission to complete before starting the next.

    - 16x Oversampling:
        Moving RX to 16x oversampling would make the design robust on real hardware with independent clock sources, rather than relying on TX and RX sharing a clock as they do in simulation.

    - Hardware Deployment:
        Testing the design on an actual FPGA board (e.g. iCEBreaker, Tang Nano) would validate it against a real UART peripheral or USB-serial adapter, rather than simulation alone.