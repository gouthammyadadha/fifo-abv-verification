# FIFO Assertion-Based Verification (ABV)

A SystemVerilog-based synchronous FIFO design and verification project focused on Assertion-Based Verification (ABV), timing behavior analysis, and debugging of practical FIFO corner cases.

This project explores how FIFO behavior changes depending on implementation choices such as registered reads vs combinational reads and how those choices affect latency, timing, and race conditions.

---

## Project Objective

The goal of this project was not only to build a FIFO, but to understand:

- synchronous FIFO behavior
- timing relationships
- read/write synchronization
- latency tradeoffs
- race conditions
- assertion-based verification
- waveform-driven debugging

The project was used as a bridge between simulation-only RTL understanding and real hardware-oriented thinking.

---

## FIFO Architecture

### Features

- Synchronous FIFO
- Shared clock for read/write
- Parameterized depth and width
- Full and empty flag generation
- Read/write pointer management
- Assertion-Based Verification

```text
+------------------------------------------------+
|                Synchronous FIFO                |
|                                                |
|   +----------+        Memory       +---------+ |
|   | Write Ptr| ------------------> |         | |
|   +----------+                     |  FIFO   | |
|                                    | Memory  | |
|   +----------+ <------------------ |         | |
|   | Read Ptr |                     +---------+ |
|   +----------+                                   
|                                                |
| Full Flag  | Empty Flag | Read Data | Write Data |
+------------------------------------------------+
```

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

## Timing Observation

A key debugging observation was:

- read enable activated on one edge
- read data becoming visible mid-cycle
- interaction between stimulus edge and RTL sampling edge

This led to investigation of:

- sampling edge behavior
- clock-to-Q delay concepts
- synchronous design principles
- race conditions caused by testbench timing

---

## Practical Learning Outcomes

This project helped develop understanding of:

- why synchronous designs intentionally use registered outputs
- why some latency is acceptable for timing reliability
- how race conditions appear in simulation
- differences between ideal simulation behavior and synthesizable hardware behavior
- how waveform debugging helps identify protocol/timing issues

---

## Tools Used

- SystemVerilog
- SVA Assertions
- Cadence Xcelium
- SimVision
- GTKWave
- Linux simulation workflow

---

## Suggested Repository Structure

```text
fifo-abv-verification/
├── rtl/              # FIFO RTL
├── tb/               # Testbench
├── assertions/       # SVA properties
├── waveforms/        # Simulation screenshots
├── docs/             # Timing/debug notes
└── README.md
```

---

## Portfolio Relevance

Relevant for:

- Design Verification
- Assertion-Based Verification
- RTL Debugging
- FPGA Validation
- Timing Analysis
- Hardware-Oriented Verification
- Junior ASIC/SoC DV roles

---

## Future Improvements

Planned future work:

- FPGA deployment
- timing constraint experiments
- CDC-based FIFO exploration
- asynchronous FIFO implementation
- functional coverage
- constrained-random testing
- formal verification experiments
