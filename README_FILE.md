## **Synchronous FIFO Design \& Assertion-Based Verification (SystemVerilog + SVA)**

## 

#### **Overview**



This project implements a parameterized synchronous FIFO and verifies it using Assertion-Based Verification (ABV) techniques in SystemVerilog.



The focus is on validating functional correctness, protocol behavior, and timing characteristics using SystemVerilog Assertions (SVA).



#### Features

* Parameterized FIFO (DATA\_WIDTH, DEPTH)
* Synchronous design using single clock
* Registered read output (1-cycle latency)
* Simultaneous read/write support



#### Verification Methodology

* Assertion-Based Verification (SVA)
* Directed + random stimulus
* Scoreboard-based data checking
* Functional coverage for key scenarios



#### Key Assertions Implemented

* No overflow (write when full)
* No underflow (read when empty)
* Correct count increment/decrement
* Stable pointers during illegal operations
* Full/Empty flag correctness
* Simultaneous read/write consistency



#### Debugging \& Key Learning

###### Issue Observed:



Initially observed that rdata appeared with only half-cycle delay instead of a full cycle.



###### Root Cause:

* Testbench was driving rd\_en on negedge
* FIFO samples at posedge (sampling edge)
* Resulted in apparent half-cycle latency



###### Fix:

* Adjusted stimulus timing to avoid race conditions
* Understood difference between: Sampling edge and Clock-to-Q delay



###### Insight:

FIFO behavior was correct — issue was purely due to stimulus timing.



##### Results

* All assertions pass under correct operation
* Intentional protocol violations successfully trigger assertion failures
* Waveforms confirm correct synchronous FIFO behavior



##### Tools Used

* Cadence Xcelium
* SystemVerilog + SVA



##### How to Run



###### Xcelium:

bash

xrun -sv rtl/sync\_fifo.sv tb/tb\_sync\_fifo.sv -access +rwc



##### Waveforms \& Debug



###### Read Latency Observation

(see docs/waveform\_read\_delay.png)



###### Assertion Failure Example

(see docs/assertion\_failure.png)



##### Future Work

* Extend to Asynchronous FIFO (CDC + Gray code)
* Add formal verification
* Build UVM-based verification environment
* Extend to AXI FIFO integration



Author



Goutham Reddy

Master’s in Electrical Engineering (RWU, Germany)

Focus: Design Verification | SystemVerilog | SVA | SoC

