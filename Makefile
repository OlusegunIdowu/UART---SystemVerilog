IVERILOG ?= iverilog
VVP      ?= vvp

BAUD = "baud rate generator/baud_rate_gen.sv"
RX   = reciever/uart_rx.sv
TX   = transmitter/uart_tx.sv
FIFO = fifo/fifo.sv fifo/uart_tx_fifo.sv

.PHONY: all test test_loopback test_fifo test_uart_fifo synth clean

all: test

test: test_loopback test_fifo test_uart_fifo

test_loopback:
	$(IVERILOG) -g2012 -o loopback_sim $(BAUD) $(RX) $(TX) uart_tx_rx_tb.sv
	$(VVP) loopback_sim > loopback.log
	cat loopback.log
	@test "$$(grep -c '^PASS' loopback.log)" -eq 3
	@! grep -q '^FAIL' loopback.log

test_fifo:
	$(IVERILOG) -g2012 -o fifo_sim fifo/fifo.sv fifo/fifo_tb.sv
	$(VVP) fifo_sim > fifo.log
	cat fifo.log
	@grep -q "ALL TESTS PASSED" fifo.log

test_uart_fifo:
	$(IVERILOG) -g2012 -o uart_fifo_sim $(BAUD) $(RX) $(TX) $(FIFO) fifo/uart_fifo_tb.sv
	$(VVP) uart_fifo_sim > uart_fifo.log
	cat uart_fifo.log
	@grep -q "ALL TESTS PASSED" uart_fifo.log

synth:
	mkdir -p build
	yosys -l build/yosys_uart.log -p "read_verilog -sv transmitter/uart_tx.sv fifo/fifo.sv fifo/uart_tx_fifo.sv; synth_ice40 -top uart_tx_fifo -json build/uart.json" > /dev/null
	nextpnr-ice40 --hx8k --package ct256 --json build/uart.json --pcf-allow-unconstrained --freq 50 -l build/pnr_uart.log > /dev/null
	grep "Max frequency" build/pnr_uart.log | tail -n 1
	grep "ICESTORM_LC" build/pnr_uart.log | tail -n 1

clean:
	rm -f *_sim *.vcd *.log
	rm -rf build