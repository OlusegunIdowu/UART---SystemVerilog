# UART (SystemVerilog)


A UART (Universal Asynchronous Receiver-Transmitter) built in SystemVerilog, with a parameterised FIFO in front of the transmitter. Developed and verified entirely through simulation, with no physical FPGA board required.

## Overview

| Module | Role |
|---|---|
| Baud rate generator | Divides the system clock down to a rate the transmitter and receiver can both follow, so they send and receive at the same rate |
| Transmitter (TX) | Turns a byte into a frame: start bit, 8 data bits (LSB first), stop bit |
| Receiver (RX) | Detects the incoming frame and reconstructs the original byte |
| TX FIFO | Queues bytes so several can be written at once while the TX sends them one at a time |
| Testbenches | Loopback, FIFO unit test, and FIFO-to-RX integration test |

## Repository Layout

```
baud rate generator/   baud_rate_gen.sv
transmitter/           uart_tx.sv
reciever/              uart_rx.sv
fifo/                  fifo.sv, uart_tx_fifo.sv, fifo_tb.sv, uart_fifo_tb.sv
uart_tx_rx_tb.sv       loopback testbench
Makefile               make test
```

## Inputs / Outputs

**TX**

| Signal | Description |
|---|---|
| data | The byte to be transmitted |
| send | Single-cycle pulse that tells the TX to start transmission |
| busy | High while the TX is transmitting |
| tx_signal | The serial output, bits sent LSB to MSB |

**RX**

| Signal | Description |
|---|---|
| rx_signal | Serial input the RX reconstructs the byte from |
| data_out | The reconstructed byte |
| data_valid | Single-cycle pulse announcing that the byte is ready |

**Baud rate generator**

| Signal | Description |
|---|---|
| clk | System clock for the whole design |
| rst_n | Active-low reset, resets the counter and tick |
| tick | The rate at which TX and RX move |

**TX FIFO wrapper (`uart_tx_fifo`)**

| Signal | Description |
|---|---|
| push, push_data | Write a byte into the FIFO |
| fifo_full, fifo_empty | FIFO status flags |
| tx_signal | Serial output from the internal TX |

## States

| op code | state | description |
|---------|-------|-------------|
| 2'b00 | IDLE | State returned to after every completed transmission, transitions to START |
| 2'b01 | START | Drives the start bit of tx_signal, transitions to DATA |
| 2'b10 | DATA | Sends bits one after another LSB to MSB (TX) / reconstructs them into a byte (RX). After 8 bits it transitions to STOP |
| 2'b11 | STOP | Drives/reads the stop bit, ends the transmission and transitions back to IDLE |

## UART Frame Format

| Phase | Line level |
|---|---|
| IDLE | High |
| START | Low for 1 bit period |
| DATA | High or low depending on the bits transmitted (LSB first) |
| STOP | High for 1 bit period |

## Design Decisions

- **Parameterisation:** `clk_frq` and `baud_rate` are module parameters on `baud_gen`, so the same module works for any clock speed or baud rate. `baud_cycle` is derived from them as a localparam rather than hardcoded.
- **Oversampling:** the baud generator produces one tick per bit period (1x) rather than 16x oversampling. This is enough here because TX and RX share the same clock and tick in simulation, so there is no timing drift. On separate hardware with independent clocks, 16x oversampling would be needed so RX samples bit centres rather than transition edges.
- **Counter sizing:** the baud counter is sized with `$clog2(baud_cycle)`, so it is always exactly wide enough and stays correct if `clk_frq` or `baud_rate` change.
- **Bit order:** data is sent and received LSB first, the standard UART convention. TX sends `byte_reg[0]` each bit period and shifts right. RX inserts each new bit at the top with `{rx_signal, byte_reg[7:1]}` so the bits land back in their original order after 8 bits.
- **Handshake signals:** `send` (TX) and `data_valid` (RX) are single-cycle pulses because each only announces one event. `busy` (TX) is held high for the whole transmission because it describes an ongoing state, and it stops a new byte being loaded mid-transmission.
- **FSM structure:** TX and RX are both 4-state FSMs (IDLE, START, DATA, STOP) mirroring the frame format, so each state handles exactly one part of the frame for one bit period.
- **Frame format:** standard 8-N-1 (1 start bit, 8 data bits, no parity, 1 stop bit). Parity and stop-bit checking were left out of the first working version.
- **FIFO:** a synchronous FIFO with a pointer one bit wider than the address, which distinguishes full from empty without a counter. The oldest byte is always visible on the read port (first-word fall-through). Writes while full and reads while empty are ignored.
- **FIFO to TX controller:** a byte is sent only when the FIFO is not empty and the TX is not busy. `send` is a single-cycle pulse that pops the FIFO on the same cycle, and the controller then waits for `busy` to rise before queuing the next byte.
- **Verification strategy:** testbenches check results automatically and print PASS/FAIL per check instead of relying on waveform inspection alone.

## Diagrams

Core UART:

```
data ->|         |  tx_signal       |        | -> data_out
send ->|    tx   | ---------------> |   rx   | -> data_valid
busy <-|         |        rx_signal |        |
             ^                          ^
             |------------tick----------|----------
                                                  |
               clk   -> |                     |   |
               rst_n -> | baud rate generator | --|
                        |                     |
```

With the TX FIFO:

```
push -> [ FIFO ] -> controller -> send, data -> [ tx ] -> tx_signal -> [ rx ] -> data_out
         |  ^           ^                          |
   full, empty          |-------- busy ------------|
```

## Verification

| Testbench | What it checks | Command |
|---|---|---|
| `uart_tx_rx_tb.sv` | TX to RX loopback: 3 bytes sent and received intact | `make test_loopback` |
| `fifo/fifo_tb.sv` | Empty/full flags, first-in-first-out order, overflow and underflow ignored, pointer wrap-around | `make test_fifo` |
| `fifo/uart_fifo_tb.sv` | 8 bytes written on consecutive clock cycles all arrive at the RX in order | `make test_uart_fifo` |

Each testbench prints PASS/FAIL per check, and `make test` fails if any check fails. GitHub Actions runs `make test` on every push.

## How to Simulate

Requirements: Icarus Verilog and make.

```
make test
```

Or run the pieces manually:

```
iverilog -g2012 -o loopback_sim "baud rate generator/baud_rate_gen.sv" "reciever/uart_rx.sv" "transmitter/uart_tx.sv" uart_tx_rx_tb.sv
vvp loopback_sim
```


## Future Work

- **Stop-bit validity checking:** RX currently assumes the stop bit is correct. A more robust version would check the line is high during STOP and flag a framing error.
- **RX-side FIFO:** buffer received bytes so they are not lost if they arrive faster than they are read.
- **16x oversampling:** makes RX robust on real hardware with independent clocks.
- **Hardware deployment:** testing on a real FPGA board against a USB-serial adapter, rather than simulation alone.