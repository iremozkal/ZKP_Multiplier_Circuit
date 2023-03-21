pragma circom 2.0.5;

// Remember that you can create your own circuits or use the templates from our library of circuits circomlib.
// You can find other circuit templates here: node_modules/circomlib/circuits/smt

// This circuit template checks that c is the multiplication of a and b.
template Multiplier2 () {  

   // Declaration of signals.  
   // inputs are private by default.
   // outputs are public.
   signal input a;  
   signal input b;  
   signal output c;  

   // Constraints.  
   c <== a * b;  
   // (c <== a * b) is a combination of assigning (c <-- a * b) with a constrain (c === a * b")
}

// Main component
component main = Multiplier2(); 

// component main { public [a] } = Multiplier2(); 
// by this we can define a as public input.

// Follow README flow to create the files.