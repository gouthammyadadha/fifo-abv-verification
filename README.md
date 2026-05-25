# FIFO Assertion-Based Verification (ABV)

This project implements and verifies a synchronous FIFO using **SystemVerilog** with a strong focus on Assertion-Based Verification (ABV), timing behavior analysis, and debugging of practical FIFO corner cases.

The project explores how FIFO behavior changes depending on implementation choices such as registered reads versus combinational reads and how those choices affect latency, timing, and race conditions.

---

## Project Objective

The objective of this project was not only to implement a FIFO, but also to understand:

- synchronous FIFO behavior
- timing relationships
- read/write synchronization
- latency tradeoffs
- race conditions
- assertion-based verification
- waveform-driven debugging

This project helped bridge the gap between simulation-only RTL understanding and hardware-oriented verification thinking.

---

## FIFO Architecture

### Features

- Synchronous FIFO
- Shared clock for read/write
- Parameterized depth and width
- Full and empty flag generation
- Read/write pointer management
- Assertion-Based Verification



---

## Verification Focus

### Assertions Used

- No write when FIFO is full
- No read when FIFO is empty
- Pointer update correctness
- Reset behavior checks
- Data consistency checks
- Simultaneous read/write behavior

### Verification Methods

- Directed testing
- Assertion-Based Verification
- Waveform analysis
- Timing observation
- Edge-sensitive stimulus analysis

---

## Major Debugging Insights

### Registered Read vs Combinational Read

One of the major observations during this project was the difference between:

- registered read FIFOs
- combinational read FIFOs

### Registered Read

Advantages:
- safer timing
- synchronous behavior
- easier timing closure
- realistic FPGA/ASIC implementation style

Disadvantages:
- introduces read latency
- data becomes available one clock cycle later

### Combinational Read

Advantages:
- reduced apparent latency
- immediate data visibility

Disadvantages:
- timing risks
- race conditions
- unstable behavior under some conditions
- harder synthesis timing closure

---

## Timing Observations

Key observations during debugging:

- read enable activating on one edge
- read data appearing mid-cycle
- interaction between stimulus edge and RTL sampling edge

This led to exploration of:

- sampling edge behavior
- clock-to-Q delay concepts
- synchronous design principles
- race conditions caused by testbench timing

---

## Key Learning Outcomes

- Understanding why synchronous FIFOs commonly use registered outputs
- Understanding timing versus latency tradeoffs
- Identifying race conditions in simulation
- Understanding differences between simulation behavior and synthesizable hardware behavior
- Using waveform analysis to debug timing-related issues

---

## Tools Used

- SystemVerilog
- SVA Assertions
- Cadence Xcelium
- SimVision
- GTKWave
- Linux simulation workflow
