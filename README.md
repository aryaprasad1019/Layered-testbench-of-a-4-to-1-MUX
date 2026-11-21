# Layered Testbench of a 4:1 Multiplexer

## Project Overview
This project implements a layered testbench for verifying a 4:1 Multiplexer (MUX) using SystemVerilog.

A 4:1 MUX is a combinational circuit that selects one of four input signals based on a 2-bit select line and forwards the selected input to the output.

## Design Details
The design consists of:
- Four 1-bit data inputs: d0, d1, d2, d3
- One 2-bit select input: sel
- One 1-bit output: y

## Boolean Expression
The output equation is:

Y = (~S1 & ~S0 & D0) | (~S1 & S0 & D1) | (S1 & ~S0 & D2) | (S1 & S0 & D3)

## Testbench Architecture
The layered testbench consists of the following components:

- **Interface:** Connects the testbench components with the design.
- **Transaction:** Stores the input and output information.
- **Generator:** Generates 20 input transactions.
- **Driver:** Applies the generated inputs to the DUT.
- **Monitor:** Observes the inputs and output.
- **Scoreboard:** Compares the actual output with the expected output.
- **Environment:** Connects and manages the testbench components.

## Project Files
- `design.sv` – RTL implementation of the 4:1 Multiplexer.
- `testbench.sv` – SystemVerilog layered testbench.

## Verification
The design is verified using 20 transactions. The scoreboard checks whether the output of the DUT matches the expected output for each transaction.

## Simulation Platform
EDA Playground
Project Link:https://edaplayground.com/x/wpj_

## Technologies Used
- SystemVerilog
- Layered Testbench Architecture
- EDA Playground

## Author
Arya Prasad
