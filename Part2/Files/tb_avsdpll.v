module tb_pll();
   
    
  reg VSSD;
  reg EN_VCO;
 
  reg VSSA;
  reg VDDD;
  reg VDDA;
  reg VCO_IN;
  reg REF;
  reg c = 1'b1;
  wire CLK;


 avsdpll dut(.CLK(CLK), .VCO_IN(VCO_IN), .ENb_CP(c),.ENb_VCO(EN_VCO), .REF(REF));
  
  initial
   begin
   {REF,EN_VCO}=0;
   VCO_IN = 1'b0 ;
   VDDA = 1.8;
   VDDD = 1.8;
   VSSA = 0;
   VSSD = 0;
   
   end
   
   initial
 begin
    $dumpfile("tb_pll.vcd");
    $dumpvars(0,tb_pll);
 end
 
   initial
    begin
   // repeat(2)
  //begin
    // EN_VCO = 1;
    //#100 REF = ~REF;
     
    //end
 //repeat(2)
  //begin
    // EN_VCO = 1;
     //#50 REF = ~REF;

     //end

    repeat(400)
  begin
     EN_VCO = 1;
     #100 REF = ~REF;
     #(83.33/2)  VCO_IN = ~VCO_IN;
     
     end
     
      $finish;
    end
endmodule
