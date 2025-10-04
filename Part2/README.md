# BabySoC: Hands-on Functional Modelling

This documentation covers the **hands-on functional modeling of the BabySoC**, focusing on building a strong understanding of **SoC fundamentals**. It guides the reader through the process of simulating and analyzing the design using **Icarus Verilog** for functional verification and **GTKWave** for waveform visualization. The objective is to bridge theoretical concepts of SoC design with practical modeling experience.

---

## Table of Contents

1. [Cloning the VSDBabySoC Repository](#cloning-the-vsdbabysoc-repository)  
2. [Analysing the Contents of VSDBabySoC](#analysing-the-contents-of-vsdbabysoc)  
   - Verilog Source Files (`*.v`)  
     - `avsddac.v` – DAC Module  
     - `avsdpll.v` – PLL Module  
     - `rvmyth.tlv` – RISC-V CPU Core  
     - `vsdbabysoc.v` – Top-Level Integration Module  
   - Testbench (`testbench.v`)
3. [RTL Simulation of Modules](#rtl-simulation-of-modules)
   - `avsddac.v`
   - `avsdpll.v`
   - `rvmyth.v`
4. [Pre-synthesis Simulation of VSDBabySoC](#pre-synthesis-simulation-of-vsdbabysoc)  
   - Installing Dependencies  
   - Compiling `rvmyth.tlv` with Sandpiper  
   - Compiling Source Files with Icarus Verilog  
   - Viewing Waveforms with GTKWave
5. [Signal Analysis](#signal-analysis)  
   - Observed Signals (`CLK`, `reset`, `OUT`, `RV_TO_DAC[9:0]`, `OUT (real)`)  
6. [Summary](#summary)

---

## Cloning the VSDBabySoC Repository:

Before cloning the repository, navigate to the folder where you want to store your work.

```bash
cd ~/Documents/Verilog/Labs
```

> [!Note]
> I prefer storing my work in a `Labs` folder under `~/Documents/Verilog`, but this is optional.  
> You can also clone the repository directly into your `home` directory if you prefer.

Once you are in the desired folder, clone the required sources from the [VSDBabySoC Repository](https://github.com/manili/VSDBabySoC):

```bash
git clone https://github.com/manili/VSDBabySoC.git
cd VSDBabySoC
```
and use,

```bash
ls
```
to list out the files inside the `VSDBabySoC` folder and verify its contents.

![gitclone](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/gitclone.png)

---

## Analysing the Contents of VSDBabySoC

After cloning the repository, it is important to understand the structure of the files and directories.  
This helps in navigating the design, identifying modules, and preparing for simulation.

File Structure:

```
VSDBabySoC/
├── LICENSE
├── Makefile
├── README.md
├── images/
└── src/
    ├── module/
    |  ├── avsddac.v
    |  ├── avsdpll.v
    |  ├── rvmyth.tlv
    |  └── vsdbabysoc.v
    ├── include/
        ├── sandpiper.vh
        ├── sandpiper_gen.vh
...
```

![fstruct](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/fstruct.png)

---

### **Verilog Source Files (`*.v`)**:  

These files hold the RTL implementation of the BabySoC, defining its core modules and functional behavior.

- **`avsddac.v`** – Implements the DAC (Digital-to-Analog Converter) module of the SoC.  
    ```verilog
    module avsddac (
        OUT,
        D,
        VREFH,
        VREFL
    );

        output      OUT;
        input [9:0] D;
        input       VREFH;
        input       VREFL;


        reg  real OUT;
        wire real VREFL;
        wire real VREFH;

        real NaN;
        wire EN;

        wire [10:0] Dext;    // unsigned extended

        assign Dext = {1'b0, D};
        assign EN = 1;

        initial begin
            NaN = 0.0 / 0.0;
            if (EN == 1'b0) begin
                OUT <= 0.0;
            end
            else if (VREFH == NaN) begin
                OUT <= NaN;
            end
            else if (VREFL == NaN) begin
                OUT <= NaN;
            end
            else if (EN == 1'b1) begin
                OUT <= VREFL + ($itor(Dext) / 1023.0) * (VREFH - VREFL);
            end
            else begin
                OUT <= NaN;
            end
        end

        always @(D or EN or VREFH or VREFL) begin
            if (EN == 1'b0) begin
                OUT <= 0.0;
            end
            else if (VREFH == NaN) begin
                OUT <= NaN;
            end
            else if (VREFL == NaN) begin
                OUT <= NaN;
            end
            else if (EN == 1'b1) begin
                OUT <= VREFL + ($itor(Dext) / 1023.0) * (VREFH - VREFL);
            end
            else begin
                OUT <= NaN;
            end
        end
    endmodule
    ```

    - Inputs:
        - `D`: A 10-bit digital input from the processor.
        - `VREFH`: Reference voltage for the DAC.

    - Output:
        - `OUT`: Analog output signal.


- **`avsdpll.v`** – Implements the PLL (Phase-Locked Loop) module for clock management.

    ```verilog
    module avsdpll (
        output reg  CLK,
        input  wire VCO_IN,
        input  wire ENb_CP,
        input  wire ENb_VCO,
        input  wire REF
    );

        real period, lastedge, refpd;

        initial begin
            lastedge = 0.0;
            period = 25.0; // 25ns period = 40MHz
            CLK <= 0;
        end

        // Toggle clock at rate determined by period
        always @(CLK or ENb_VCO) begin
            if (ENb_VCO == 1'b1) begin
                #(period / 2.0);
                CLK <= (CLK === 1'b0);
            end
            else if (ENb_VCO == 1'b0) begin
                CLK <= 1'b0;
            end
            else begin
                CLK <= 1'bx;
            end
        end

        // Update period on every reference rising edge
        always @(posedge REF) begin
            if (lastedge > 0.0) begin
                refpd = $realtime - lastedge;
                // Adjust period towards 1/8 the reference period
                //period = (0.99 * period) + (0.01 * (refpd / 8.0));
                period =  (refpd / 8.0) ;
            end
            lastedge = $realtime;
        end
    endmodule 
    ```
    - Inputs:
        - `VCO_IN`, `ENb_CP`, `ENb_VCO`, `REF`: Control and reference signals for PLL operation.

    - Output:
        - `CLK`: A stable clock signal for synchronizing the core and other modules.


- **`rvmyth.tlv`** - This code implements a behavioral functional model of a RISC-V CPU core, handling instruction decoding, ALU operations, register file access, memory operations, and branch/jump logic for simulation and verification purposes. 

    <pre>
        m4_include_lib(['https://raw.githubusercontent.com/shivanishah269/risc-v-core/master/FPGA_Implementation/riscv_shell_lib.tlv'])
    
        // Module interface, either for Makerchip, or not.

        m4_ifelse_block(M4_MAKERCHIP, 1, ['

        // Makerchip module interface.

        m4_makerchip_module
        wire CLK = clk;
        logic [9:0] OUT;
        assign passed = cyc_cnt > 300;
        '], ['

        // Custom module interface for BabySoC.

        module rvmyth(
            output reg [9:0] OUT,
            input CLK,
            input reset
        );
        wire clk = CLK;
        '])
    </pre>

    **...**

    For the full source file, see [rvmyth.tlv](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Files/rvmyth.tlv)

    - Inputs:
        - `CLK`: Clock signal generated by the PLL.
        - `reset`: Initializes or resets the processor.

    - Outputs:
        - `OUT`: A 10-bit digital signal representing processed data to be sent to the DAC.

- **`vsdbabysoc.v`** – Top-level module that integrates all submodules to form the complete BabySoC.  

    ```verilog
    module vsdbabysoc (
        output wire OUT,
        //
        input  wire reset,
        //
        input  wire VCO_IN,
        input  wire ENb_CP,
        input  wire ENb_VCO,
        input  wire REF,

        // input  wire VREFL,
        input  wire VREFH
    );

        wire CLK;
        wire [9:0] RV_TO_DAC;

        rvmyth core (
            .OUT(RV_TO_DAC),
            .CLK(CLK),
            .reset(reset)
        );

        avsdpll pll (
            .CLK(CLK),
            .VCO_IN(VCO_IN),
            .ENb_CP(ENb_CP),
            .ENb_VCO(ENb_VCO),
            .REF(REF)
        );

        avsddac dac (
            .OUT(OUT),
            .D(RV_TO_DAC),
            // .VREFL(VREFL),
            .VREFH(VREFH)
        );

    endmodule
    ```
    - Inputs:
        - `reset`: Resets the core processor.
        - `VCO_IN`, `ENb_CP`, `ENb_VCO`, `REF`: PLL control signals.
        - `VREFH`: DAC reference voltage.

    - Outputs:
        - `OUT`: Analog output from DAC.

    - Connections:
        - `RV_TO_DAC` - A 10-bit bus that connects the RISC-V core output to the DAC input.
        - `CLK` - The clock signal generated by the PLL.


---

### **Testbench (`testbench.v`)**  

This testbench exists specifically for the **BabySoC** and is used to verify the functionality of the complete design. It provides the necessary input stimuli, monitors outputs, and generates waveforms for simulation using `GTKWave`. Essentially, it allows functional testing of BabySoC’s instruction execution, ALU operations, register file, and memory interactions in a controlled simulation environment.

Depending on the simulation setup, the generated waveform files `pre_synth_sim.vcd` or `post_synth_sim.vcd` capture signal activity for the BabySoC design. These files can be opened in `GTKWave` to visualize and analyze the behavior of the SoC during simulation.

---

Before compiling the Verilog source files, the `rvmyth.tlv` file must first be converted to a `.v` file using **sandpiper**.

Ensure that all required dependencies are installed to avoid compilation issues:

```bash
sudo apt install make python python3 python3-pip git iverilog gtkwave docker.io
cd ~
pip3 install pyyaml click sandpiper-saas
```
To compile the `rvmyth.tlv` file with **sandpiper**, run:

```bash
python3 -m sandpiper -i ~/Documents/Verilog/Labs/VSDBabySoC/src/module/rvmyth.tlv -o rvmyth.v  --bestsv --noline -p verilog --outdir ~/Documents/Verilog/Labs/VSDBabySoC/src/module
```

This command stores the compiled `rvmyth.v` and `rvmyth_gen.v` files inside `~/Documents/Verilog/Labs/VSDBabySoC/src/module`.

![sandpaper](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/sandpaper.png)

---

## RTL Simulation of Modules

**`avsddac.v`**

```bash
iverilog -o ~/Documents/Verilog/Labs/avsddac.vvp ~/Documents/Verilog/Labs/VSDBabySoC/src/module/avsddac.v ~/Documents/Verilog/Labs/tb_avsddac.v
```
> Testbench ported from [rvmyth_avsddac_interface](https://github.com/vsdip/rvmyth_avsddac_interface/blob/main/iverilog/Pre-synthesis/avsddac_tb_test.v) repository

```bash
cd ~/Documents/Verilog/Labs
vvp avsddac.vvp
gtkwave tb_avsddac.vcd
```

_Workflow_ :

![workflowdac](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/workflowdac.png)

_Waveform_:

![waveformdac](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/waveformdac.png)

_Analysis_ :

- D = 3FE -> Dext = 1022
- OUT = VREFL + ( (Dext​ / 1023)  * (VREFH−VREFL) )
- OUT = 0 + (1022 / 1023) * 3.3 ≈ 3.2968 V
- Waveform: OUT ≈ 3.297 V while D stays at 3FE
- Demonstrates DAC step behavior near full scale

---

**`avsdpll.v`**

```bash
iverilog -o ~/Documents/Verilog/Labs/avsdpll.vvp ~/Documents/Verilog/Labs/VSDBabySoC/src/module/avsdpll.v ~/Documents/Verilog/Labs/tb_avsdpll.v
```
> Testbench ported from [rvmyth_avsdpll_interface](https://github.com/vsdip/rvmyth_avsdpll_interface/blob/main/verilog/pll_tb.v) repository

```bash
cd ~/Documents/Verilog/Labs
vvp avsdpll.vvp
gtkwave tb_avsdpll.vcd
```

_Workflow_ :

![workflowpll](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/workflowpll.png)

_Waveform_:

![waveformpll](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/waveformpll.png)

_Analysis_ :

- REF: input clock, slower reference signal
- Each rising edge of REF recalculates refpd (REF period)
- CLK: output clock, toggles continuously when ENb_VCO = 1
- CLK frequency = 8 × REF frequency (since period = refpd / 8)
- When ENb_VCO = 0 → CLK forced to 0
- When ENb_VCO = X → CLK becomes X (unknown)

---

**`rvmyth.v`**

```bash
iverilog -o ~/Documents/Verilog/Labs/rvmyth.vvp -I  ~/Documents/Verilog/Labs/VSDBabySoC/src/include -I  ~/Documents/Verilog/Labs/VSDBabySoC/src/module  ~/Documents/Verilog/Labs/VSDBabySoC/src/module/rvmyth.v ~/Documents/Verilog/Labs/tb_rvmyth.v ~/Documents/Verilog/Labs/VSDBabySoC/src/module/clk_gate.v
```
> Testbench ported from [rvmyth](https://github.com/kunalg123/rvmyth/blob/main/tb_mythcore_test.v) repository

```bash
cd ~/Documents/Verilog/Labs
vvp rvmyth.vvp
gtkwave tb_rvmyth.vcd
```

_Workflow_ :

![workflowrvmyth](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/workflowrvmyth.png)

_Waveform_:

![waveformrvmyth](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/waveformrvmyth.png)

_Analysis_ :

- CLK     : Provides timing for the core.
- RESETn  : Initializes core to known state.
- OUT     : 10-bit Register output.

---

## Pre-synthesis Simulation of VSDBabySoC

Compilation of the source files are done through `iverilog` by using the following commands,

```bash
iverilog -o ~/Documents/Verilog/Labs/pre_synth_sim.vvp -DPRE_SYNTH_SIM \
    -I  ~/Documents/Verilog/Labs/VSDBabySoC/src/include -I  ~/Documents/Verilog/Labs/VSDBabySoC/src/module \
    ~/Documents/Verilog/Labs/VSDBabySoC/src/module/testbench.v
```

> [!Note]
> -**o** `Output File (.vvp)`, to specify where the compiled file must be stored. \
> -**DPRE_SYNTH_SIM**, enable pre-synthesis simulation mode via macro (set inside the testbench). \
> -**I** `Source Directory`, to specify the directory where verilog files that contains submodules are stored. \
> **../testbench.v**, testbench file (drives the design). \
> Clearly specify the directories, and ensure that the mentioned files are actually present in those locations.

To view the _waveform_,

```bash
cd ..
vvp pre_synth_sim.vvp
gtwave pre_synth_sim.vcd
```
---

*Workflow* :

![workflow](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/workflow.png)

*Waveform* :

![waveform](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/waveform.png)

---

## Signal Analysis :

In this waveform, the following signals are observed:

- `CLK`: The input clock signal for the RVMYTH core, sourced from the PLL.
- `reset`: The input reset signal for the RVMYTH core, provided by an external source.
- `OUT`: The output signal of the VSDBabySoC module, which originates from the DAC. Due to simulation limitations, it behaves as a Digital signal, although it is a Analog signal.
- `RV_TO_DAC[9:0]`: A 10-bit output from the RVMYTH core, originally intended for the DAC.
- `OUT (real)`: A real-type wire representing the DAC output, capable of simulating analog values, and originally sourced from the DAC.

---

## Post-synthesis Simulation of VSDBabySoc

_Synthesis_ :

Synthesis requires the header files essential for the `rvmyth` module, \
these are `sp_verilog.vh`, `sandpiper.vh`, `sandpiper_gen.vh`

`sp_verilog.vh` – includes core Verilog macros and parameter definitions  

`sandpiper.vh` – defines integration-specific settings used by SandPiper  

`sandpiper_gen.vh` – contains tool-generated parameters and configuration values  

These files need to be present in the working directory of `yosys` inorder to ensure error free synthesis. This is done using the following commands,

```bash
cd ~/Documents/Verilog/Labs/VSDBabySoC
cp -r src/include/sp_verilog.vh .
cp -r src/include/sandpiper.vh .
cp -r src/include/sandpiper_gen.vh .
```

Now inside the `../VSDBabySoC` folder, run `yosys`.

```bash
yosys
```

In `yosys`, perform the following commands to read the required verilog files.

```bash
read_verilog src/module/vsdbabysoc.v 
read_verilog -I ~/Documents/Verilog/Labs/VSDBabySoC/src/include/ ~/Documents/Verilog/Labs/VSDBabySoC/src/module/rvmyth.v
read_verilog -I ~/Documents/Verilog/Labs/VSDBabySoC/src/include/ ~/Documents/Verilog/Labs/VSDBabySoC/src/module/clk_gate.v
```

Then, the liberty files,

```bash
read_liberty -lib ~/Documents/Verilog/Labs/VSDBabySoC/src/lib/avsdpll.lib 
read_liberty -lib ~/Documents/Verilog/Labs/VSDBabySoC/src/lib/avsddac.lib 
read_liberty -lib ~/Documents/Verilog/Labs/VSDBabySoC/src/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```

Synthesize `vsdbabysoc`, specifying it as the top module,

```bash
synth -top vsdbabysoc
```

Convert D Flip-Flops into equivalent Standard Cell instances by,

```bash
dfflibmap -liberty ~/Documents/Verilog/Labs/VSDBabySoC/src/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```

Perform Optimization and Technology mapping using the following commands,

```bash
opt
abc -liberty ~/Documents/Verilog/Labs/VSDBabySoC/src/lib/sky130_fd_sc_hd__tt_025C_1v80.lib -script +strash;scorr;ifraig;retime;{D};strash;dch,-f;map,-M,1,{D}
```

> [!TIP]

| Command        | Purpose                                                                     |
| -------------- | --------------------------------------------------------------------------- |
| `strash`       | Structural hashing — converts logic network to an AIG (And-Inverter Graph). |
| `scorr`        | Sequential redundancy removal — detects equivalent registers.               |
| `ifraig`       | Combinational equivalence simplification.                                   |
| `retime`       | Moves flip-flops for timing optimization.                                   |
| `{D}`          | Placeholder or marker for design partition (used internally by Yosys/ABC).  |
| `strash`       | Re-run structural hashing after retiming.                                   |
| `dch,-f`       | Performs combinational optimization (don’t-care-based).                     |
| `map,-M,1,{D}` | Maps the logic to gates in the provided `.lib` standard cell library.       |


Then, conduct final optimisations and clean-up through,

```bash
flatten
setundef -zero
clean -purge
rename -enumerate
```
> [!TIP]

- flatten          : Remove hierarchy, make a flat netlist
- setundef -zero   : Replace undefined signals with 0
- clean -purge     : Delete unused/duplicate logic
- rename -enumerate: Systematically rename nets and cells

To check the statistics of the synthesised design run,

```bash
stat
```

<pre>

=== vsdbabysoc ===

        +----------Local Count, excluding submodules.
        | 
     4740 wires
     6214 wire bits
     4740 public wires
     6214 public wire bits
        7 ports
        7 port bits
     5924 cells
        8   $scopeinfo
        1   avsddac
        1   avsdpll
       10   sky130_fd_sc_hd__a2111oi_0
        1   sky130_fd_sc_hd__a211o_2
       26   sky130_fd_sc_hd__a211oi_1
        4   sky130_fd_sc_hd__a21boi_0
        1   sky130_fd_sc_hd__a21o_2
      667   sky130_fd_sc_hd__a21oi_1
        1   sky130_fd_sc_hd__a221o_2
      167   sky130_fd_sc_hd__a221oi_1
        3   sky130_fd_sc_hd__a22o_2
      119   sky130_fd_sc_hd__a22oi_1
        4   sky130_fd_sc_hd__a311oi_1
        1   sky130_fd_sc_hd__a31o_2
      346   sky130_fd_sc_hd__a31oi_1
        2   sky130_fd_sc_hd__a32oi_1
       21   sky130_fd_sc_hd__a41oi_1
       11   sky130_fd_sc_hd__and2_2
        1   sky130_fd_sc_hd__and3_2
      597   sky130_fd_sc_hd__clkinv_1
     1144   sky130_fd_sc_hd__dfxtp_1
        1   sky130_fd_sc_hd__lpflow_inputiso0p_1
       13   sky130_fd_sc_hd__mux2i_1
      848   sky130_fd_sc_hd__nand2_1
      249   sky130_fd_sc_hd__nand3_1
        1   sky130_fd_sc_hd__nand3b_1
       44   sky130_fd_sc_hd__nand4_1
      404   sky130_fd_sc_hd__nor2_1
       34   sky130_fd_sc_hd__nor3_1
        2   sky130_fd_sc_hd__nor4_1
        1   sky130_fd_sc_hd__o2111a_1
       21   sky130_fd_sc_hd__o2111ai_1
        1   sky130_fd_sc_hd__o211a_1
       49   sky130_fd_sc_hd__o211ai_1
        6   sky130_fd_sc_hd__o21a_1
      867   sky130_fd_sc_hd__o21ai_0
        1   sky130_fd_sc_hd__o21ba_2
       18   sky130_fd_sc_hd__o21bai_1
        7   sky130_fd_sc_hd__o221ai_1
      154   sky130_fd_sc_hd__o22ai_1
        1   sky130_fd_sc_hd__o2bb2ai_1
        2   sky130_fd_sc_hd__o311ai_0
        3   sky130_fd_sc_hd__o31ai_1
        1   sky130_fd_sc_hd__o32ai_1
        1   sky130_fd_sc_hd__o41ai_1
       12   sky130_fd_sc_hd__or2_2
        1   sky130_fd_sc_hd__or3_2
        1   sky130_fd_sc_hd__or4_2
       13   sky130_fd_sc_hd__xnor2_1
       32   sky130_fd_sc_hd__xor2_1
</pre>

Then finally write the netlist using,

```bash
write_verilog -noattr ~/Documents/Verilog/Labs/vsdbabysoc_synth.v
```
![workflowsynth]()

_Simulation_ :

Ensure the following files are in the working directory (`Labs` in my case) before compilation.

```
vsdbabysoc_synth.v
avsddac.v
avsdpll.v
primitives.v
sky130_fd_sc_hd.v
```

this is done using,

```bash
cp -r ~/Documents/Verilog/Labs/VSDBabySoC/src/module/avsddac.v .
cp -r ~/Documents/Verilog/Labs/VSDBabySoC/src/module/avsdpll.v .
cp -r ~/Documents/Verilog/Labs/VSDBabySoC/src/gls_model/sky130_fd_sc_hd.v .
cp -r ~/Documents/Verilog/Labs/VSDBabySoC/src/gls_model/primitives.v .
```


Compilation of the netlist with the testbench must be done, of course through `iverilog` using the following command,

```bash
iverilog -o ~/Documents/Verilog/Labs/vsdbabysoc_synth.vvp -DPOST_SYNTH_SIM -DFUNCTIONAL -DUNIT_DELAY=#1 -I ~/Documents/Verilog/Labs/VSDBabySoC/src/include -I ~/Documents/Verilog/Labs/VSDBabySoC/src/module -I  ~/Documents/Verilog/Labs/VSDBabySoC/src/gls_model ~/Documents/Verilog/Labs/VSDBabySoC/src/module/testbench.v
```

Then, to view the waveform,

```bash
vvp vsdbabysoc_synth.vvp
gtkwave post_synth_sim.vcd 
```
---

_Workflow_ :

![workflowpostsynth]()

_Waveform:_

![waveformpostsynth]()

## Pre-Synthesis vs Post-Synthesis

![comparison](comparison)

**We see that there are no mismatches in functionality and the VSDBabySoC design works in its intended way after synthesis.**

---

## Summary

VSDBabySoC is a simplified, educational SoC designed to teach CPU-memory-peripheral interaction and functional modeling. It includes a minimal RVMYTH CPU, memory, basic peripherals, a simple bus, PLL, and 10-bit DAC. Functional modeling allows simulation and verification of system behavior before RTL, providing a hands-on, safe platform to learn core SoC concepts.

---
