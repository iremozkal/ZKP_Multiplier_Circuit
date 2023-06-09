## Circom

`npm install circomlib`  

As a result of the compilation we will also obtain programs to compute the witness. 
We can compile the circuit with the following command:  `circom multiplier.circom --r1cs --wasm --sym –c`

`--r1cs` generates the file `multiplier.r1cs` that contains the R1CS constraint system of the circuit in binary format. 

`--wasm` generates the directory multiplier_js that contains the Wasm code `multiplier2.wasm` and other files needed to generate the witness. 

`--sym` generates the file `multiplier.sym`, a symbols file required for debugging or for printing the constraint system in an annotated mode. 

`--c` generates the directory multiplier_cpp that contains several files (multiplier.cpp, multiplier.dat, and other common files for every compiled program like main.cpp, MakeFile, etc) needed to compile the C code to generate the witness. 

Before creating the proof, we need to calculate all the signals of the circuit that match all the constraints of the circuit. For that, we will use the Wasm module generated by circom that helps to do this job. Using the generated Wasm binary and three JavaScript files, we simply need to provide a file with the inputs and the module will execute the circuit and calculate all the intermediate signals and the output. The set of inputs, intermediate signals and output is called `witness`. 

We are creating `multiplier.input.json` file under the /circuit/multipler.js/ folder.  

In our case, we want to prove that we’re able to factor the number 33.  
So, we assign: {"a": "3", "b": "11"}  

Now, we calculate the witness and generate a binary file witness.wtns containing it in a format accepted by snarkjs. 

/circuit/multiplier_js>   
`node generate_witness.js multiplier.wasm multiplier.input.json witness.wtns `

This file is encoded in a binary format compatible with snarkjs, which is the tool that we use to create the actual proofs. 

## SnarkJS 
`npm install snarkjs`

#### Start a new powers of tau ceremony   
/circuit>  
`snarkjs powersoftau new bn128 14 pot14_0000.ptau -v` 

The new command is used to start a powers of tau ceremony. The first parameter after new refers to the type of curve you wish to use. At the moment, we support both bn128 and bls12-381. 14, is the power of two of the maximum number of constraints that the ceremony can accept: in this case, the number of constraints is 2 ^ 14 = 16,384. The maximum value supported here is 28.   

#### Apply a random beacon   
`snarkjs powersoftau beacon pot14_0000.ptau pot14_beacon.ptau0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon" `  

The beacon command creates a ptau file with a contribution applied in the form of a random beacon. We need to apply a random beacon in order to finalise phase 1 of the trusted setup. The beacon is essentially a delayed hash function evaluated on 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f (in practice this value will be some form of high entropy and publicly available data of your choice). 10 -- just tells snarkjs to perform 2 ^ 10 iterations of this hash function.  

#### Prepare phase 2 (circuit spesific phase)  
`snarkjs powersoftau prepare phase2 pot14_beacon.ptau pot14_final.ptau -v`

prepare phase2 command calculates the encrypted evaluation of the Lagrange polynomials at tau for tau, alpha * tau and beta * tau. It takes the beacon ptau file we generated in the previous step, and outputs a final ptau file which will be used to generate the circuit proving and verification keys. 

#### Setup  
Currently, snarkjs supports 3 proving systems: Groth16, PLONK and FFLONK (Beta version). 
Groth16 requires a trusted ceremony for each circuit. PLONK and FFLONK do not require it, it's enough with the powers of tau ceremony which is universal. 
`snarkjs groth16 setup multiplier.r1cs pot14_final.ptau circuit_0000.zkey`

This generates the reference zkey without phase 2 contributions. 
Do not use this zkey in production, as it's not safe. It requires at least a contribution.  
Note that circuit_0000.zkey (the output of the zkey command above) does not include any contributions yet, so it cannot be used in a final circuit.  
The zkey new command creates an initial zkey file with zero contributions.  
The zkey is a zero-knowledge key that includes both the proving and verification keys as well as phase 2 contributions. 

#### Apply a random beacon 

`snarkjs zkey beacon circuit_0000.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"`

The zkey beacon command creates a zkey file with a contribution applied in the form of a random beacon. We use it to apply a random beacon to the latest zkey after the final contribution has been made (this is necessary in order to generate a final zkey file and finalise phase 2 of the trusted setup).  

#### Verify the final zkey 
`snarkjs zkey verify multiplier.r1cs pot14_final.ptau circuit_final.zkey`  
Before we go ahead and export the verification key as a json, we perform a final check and verify the final protocol transcript (zkey). 
 
#### Export the verification key 
`snarkjs zkey export verificationkey circuit_final.zkey verification_key.json`   
We export the verification key from circuit_final.zkey into verification_key.json.   

#### Create the proof 
`snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json`  
This command generates the files proof.json: contains the actual proof and public.json: contains the values of the public inputs and output. 

#### Verify the proof 
`snarkjs groth16 verify verification_key.json public.json proof.json `  
We use the this command to verify the proof, passing in the verification_key we exported earlier. If all is well, you should see that OK has been outputted to your console. This signifies the proof is valid. 

#### Turn the verifier into a smart contract  
`snarkjs zkey export solidityverifier circuit_final.zkey verifier.sol`  
Finally, we export the verifier as a Solidity smart-contract so that we can publish it on-chain. 

#### Simulate a verification call 
`snarkjs zkey export soliditycalldata public.json proof.json`  
We use soliditycalldata to simulate a verification call, and cut and paste the result directly in the verifyProof field in the deployed smart contract in the remix environment. 


## File Structure

```
├── circuit
│   ├── multiplier_cpp
│   ├── multiplier_js
│   │   ├── generate_witness.js
│   │   ├── multiplier.wasm
│   │   └── witness_calculator.js
│   ├── circuit_0000.zkey
│   ├── circuit_final.zkey
│   ├── multiplier.circom
│   ├── multiplier.r1cs
│   ├── multiplier.sym
│   ├── pot14_0000.ptau
│   ├── pot14_beacon.ptau
│   ├── pot14_final.ptau
│   ├── proof.json
│   ├── public.json
│   ├── verification_key.json
│   ├── verifier.sol
│   └── witness.wtns
├── .gitignore
├── LICENSE.md
├── package-lock.json
├── package.json
└── README.md
```