# BabySoC: Hands-on Functional Modelling

This documentation covers the **hands-on functional modeling of the BabySoC**, focusing on building a strong understanding of **SoC fundamentals**. It guides the reader through the process of simulating and analyzing the design using **Icarus Verilog** for functional verification and **GTKWave** for waveform visualization. The objective is to bridge theoretical concepts of SoC design with practical modeling experience.

---

## Table of Contents



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

![fstruct](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Images/fstruct.png)


### **Verilog Source Files (`*.v`)**:  

Contains the RTL design for the BabySoC

```
avsddac.v
avsdpll.v  
rvmyth.tlv       
vsdbabysoc.v
```

- **avsddac.v** – Implements the DAC (Digital-to-Analog Converter) module of the SoC.  
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


- **avsdpll.v** – Implements the PLL (Phase-Locked Loop) module for clock management.

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


- **rvmyth.tlv** - This code implements a behavioral functional model of a RISC-V CPU core, handling instruction decoding, ALU operations, register file access, memory operations, and branch/jump logic for simulation and verification purposes. 

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

    For the full source file, see [rvmyth.tlv](https://github.com/navneetprasad1311/vsd-soc-pgrm-w2/blob/main/Part2/Files/rvmyth.tlv).

    - Inputs:
        - `CLK`: Clock signal generated by the PLL.
        - `reset`: Initializes or resets the processor.

    - Outputs:
        - `OUT`: A 10-bit digital signal representing processed data to be sent to the DAC.

- **vsdbabysoc.v** – Top-level module that integrates all submodules to form the complete BabySoC.  

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

### **Documentation / Images / README**:  
  Provides instructions, module descriptions, and any additional notes for understanding the design.

---

