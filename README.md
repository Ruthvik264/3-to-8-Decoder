# 3-to-8 Decoder Verification using SystemVerilog

## Overview

This project implements and verifies a **3-to-8 Decoder** using **SystemVerilog**.

A layered verification testbench is developed to verify the functionality of the decoder. The testbench separates stimulus generation, DUT driving, signal monitoring, expected-value generation, and result checking into different components.

The verification environment consists of:

* Generator
* Driver
* Monitor
* Reference Model
* Scoreboard
* Environment
* Interface
* Transaction / Packet

---

## Design Under Test

The Design Under Test (DUT) is a **3-to-8 Decoder**.

It accepts a 3-bit input `a` and produces an 8-bit one-hot output `y`.

### Input

```text
a[2:0]
```

### Output

```text
y[7:0]
```

For every input combination, exactly one output bit is asserted.

### Truth Table

| Input `a` | Output `y` |
| --------- | ---------- |
| `000`     | `00000001` |
| `001`     | `00000010` |
| `010`     | `00000100` |
| `011`     | `00001000` |
| `100`     | `00010000` |
| `101`     | `00100000` |
| `110`     | `01000000` |
| `111`     | `10000000` |

---

# Verification Architecture

The testbench follows a layered verification architecture:

```text
              +-------------+
              |  Generator  |
              +------+------+
                     |
                     | Transaction
                     v
              +-------------+
              |   Driver    |
              +------+------+
                     |
                     | Input
                     v
              +-------------+
              |     DUT     |
              |  3-to-8     |
              |   Decoder   |
              +------+------+
                     |
                     | Output
                     v
              +-------------+
              |   Monitor   |
              +------+------+
                     |
                     v
              +----------------+
              | Reference Model|
              +-------+--------+
                      |
                      v
              +---------------+
              |  Scoreboard   |
              +---------------+
```

---

# Testbench Components

## 1. Interface

The `decoder_if` interface contains the signals connecting the testbench and DUT.

```systemverilog
interface decoder_if;
    logic [2:0] a;
    logic [7:0] y;
endinterface
```

The interface allows the testbench classes to access the DUT signals through a virtual interface.

---

## 2. Packet / Transaction

The `packet` class represents a single transaction.

```systemverilog
class packet;
    rand bit [2:0] a;
    bit [7:0] y;
    bit [7:0] expected;
endclass
```

It contains:

* `a` — decoder input
* `y` — actual output observed from the DUT
* `expected` — expected output calculated by the reference model

The input `a` is randomized using SystemVerilog's `randomize()` method.

---

## 3. Generator

The generator creates transactions and sends them to the driver using a mailbox.

```text
Generator
    |
    | gen2driv
    v
Driver
```

The generator creates 20 randomized packets:

```systemverilog
repeat (20) begin
    p = new();
    assert(p.randomize());
    gen2driv.put(p);
end
```

This allows different input combinations to be tested automatically.

---

## 4. Driver

The driver receives packets from the generator and drives the input onto the DUT.

```systemverilog
vif.a = p.a;
```

The driver communicates with the DUT through the virtual interface.

A small delay is introduced after driving the input to allow the combinational decoder output to settle.

---

## 5. Monitor

The monitor observes the DUT input and output.

It captures:

```text
Input  → a
Output → y
```

and sends the captured packet to the reference model and scoreboard path through a mailbox.

The monitor does not modify the DUT signals. It only observes them.

---

## 6. Reference Model

The reference model independently calculates what the decoder output should be.

```systemverilog
p.expected = 8'b1 << p.a;
```

For example:

```text
a = 000
expected = 00000001

a = 001
expected = 00000010

a = 010
expected = 00000100
```

The reference model provides an independent expected result for comparison.

---

## 7. Scoreboard

The scoreboard compares the expected output from the reference model with the actual output observed by the monitor.

```text
Expected output
      |
      |
      v
  Scoreboard <---- Actual output
      |
      v
 PASS / ERROR
```

If both values match:

```text
[PASS]
```

If they do not match:

```text
[ERROR]
```

Example:

```text
[PASS] a=010 output correct: 00000100
```

or:

```text
[ERROR] a=010 expected=00000100 got=00000010
```

---

# Mailbox Communication

The testbench uses mailboxes for communication between components.

### Generator → Driver

```text
gen2driv
```

Carries generated transactions from the generator to the driver.

### Monitor → Reference Model / Scoreboard

```text
mon2ref_sb
```

Carries monitored transactions to the reference model.

### Reference Model → Scoreboard

```text
ref2sb
```

Carries transactions containing expected results to the scoreboard.

This avoids direct coupling between the different verification components.

---

# Verification Flow

The complete flow is:

```text
1. Generator creates a random transaction

          ↓

2. Driver receives the transaction

          ↓

3. Driver drives input `a` to DUT

          ↓

4. DUT generates output `y`

          ↓

5. Monitor observes `a` and `y`

          ↓

6. Reference Model calculates expected output

          ↓

7. Scoreboard compares expected vs actual

          ↓

8. PASS or ERROR is displayed
```

---

# Example

Suppose the generator creates:

```text
a = 3'b101
```

The driver applies:

```text
a = 101
```

The decoder should produce:

```text
y = 00100000
```

The reference model calculates:

```text
expected = 8'b1 << 5
         = 00100000
```

The scoreboard compares:

```text
Expected = 00100000
Actual   = 00100000
```

Result:

```text
[PASS] a=101 output correct: 00100000
```

---

# Random Verification

The input is declared as:

```systemverilog
rand bit [2:0] a;
```

Therefore, SystemVerilog can randomly generate values from:

```text
000
001
010
011
100
101
110
111
```

The generator performs 20 random transactions.

Since the decoder has only 8 possible input combinations, multiple combinations may occur more than once.

---

# Tools Used

* **SystemVerilog**
* **ModelSim / QuestaSim**
* **Git / GitHub**

---

# Project Structure

Recommended repository structure:

```text
3to8-decoder-verification/
│
├── decoder.s
├── tb.s
└── README.md
```

The `decoder.s` file contains the Design Under Test.

The `tb.s` file contains:

* Interface
* Packet
* Generator
* Driver
* Monitor
* Reference Model
* Scoreboard
* Environment
* Top-level testbench

---

# Key SystemVerilog Concepts Demonstrated

This project demonstrates the following SystemVerilog verification concepts:

* Classes
* Object-oriented programming
* Randomization
* Mailboxes
* Virtual interfaces
* Transactions
* Generator
* Driver
* Monitor
* Reference model
* Scoreboard
* Environment
* Parallel execution using `fork`
* Self-checking testbench

---

# Expected Result

The testbench automatically checks the decoder output and prints whether each transaction passes or fails.

Example:

```text
[PASS] a=000 output correct: 00000001
[PASS] a=101 output correct: 00100000
[PASS] a=111 output correct: 10000000
```

If an incorrect DUT output is produced, the scoreboard detects the mismatch:

```text
[ERROR] a=010 expected=00000100 got=00000010
```

---

# Conclusion

This project demonstrates a basic **layered SystemVerilog verification environment** for a 3-to-8 decoder.

Instead of directly checking the DUT inside a single testbench block, the verification environment separates responsibilities into independent components:

```text
Generator
    ↓
Driver
    ↓
DUT
    ↓
Monitor
    ↓
Reference Model
    ↓
Scoreboard
```

This structure provides a foundation for understanding more advanced verification methodologies such as **UVM (Universal Verification Methodology)**.

