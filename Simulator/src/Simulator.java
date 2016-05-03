import java.io.*;
import java.util.*;

public class Simulator {

	public static void main(String[] args) {
		if(args.length == 0) {
			System.out.println("User did not provide program on the command line");
			System.exit(0);
		}
		ArrayList<String> instr = new ArrayList<String>(); //instruction memory
		int[] regFile = new int[32]; //register file
		int[] mem = new int[1600]; //system memory
		boolean[] flags = new boolean[4]; //flags
		try { //read in program
			File progname = new File(args[0]);
			FileReader fileReader = new FileReader(progname);
			BufferedReader bufferedReader = new BufferedReader(fileReader);
			String line;
			String[] parsedInstr = new String[2];
			//TODO prevent empty lines from getting into instruction memory
			while ((line = bufferedReader.readLine()) != null) {
				parsedInstr = line.split("//");
				if(parsedInstr[0].length() != 0 && !line.equals("\t+") && !line.equals("\\s+")) {
					instr.add(parsedInstr[0]);
				}
			}
			fileReader.close();
		} catch (IOException e) {
			System.out.println("That file doesn't exist");
			System.exit(0);
		}
		
		for(int i = 0; i < regFile.length; i++) { //initialize reg file to 0's
			regFile[i] = 0;
		}
		
		for(int i = 0; i < instr.size(); i++) {
			String[] currInstr = instr.get(i).split(" +"); //split instructinos into their components
			System.out.print("Instruction: "); //printing format text
			for(int j = 0; j < currInstr.length; j++) {
				currInstr[j] = currInstr[j].replaceAll("\t", "");
				System.out.print(currInstr[j] + " ");
			}
			System.out.println();
			int startIndex = 0; //figure out where actual instruction is
			boolean lineLabeled = false; //is there a label on this line
			if(currInstr[0].indexOf('_') != -1) {
				startIndex = 1;
				lineLabeled = true;
			}
			switch(currInstr[startIndex]) { //master instruction case statement
				case "AND":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
                				}
								
	            				System.out.println("In case AND");
					            break;
				case "OR":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case OR");
								break;
				case "XOR":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case XOR");
								break;
				case "NOT":  	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case NOT");
								break;
				case "ADD":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ADD");
								break;
				case "ADDI":    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ADDI");
								break;
				case "LSL": 	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case LSL");
								break;
				case "LSR": 	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case LSR");
								break;
				case "ASR":  	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ASR");
								break;
				case "ROL":  	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ROL");
								break;
				case "ROR":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ROR");
								break;
				case "MOV":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case MOV");
								break;
				case "SWAP":    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case SWAP");
								break;
				case "LDR":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case LDR");
								break;
				case "LDU":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case LDU");
								break;
				case "LDL":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case LDL");
								break;
				case "ST":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ST");
								break;
				case "J":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case J");
								break;
				case "JR":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case JR");
								break;
				case "B":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case B");
								break;
				case "BEQ":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case BEQ");
								break;
				case "BNE":     if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
									}
								System.out.println("In case BNE");
								break;
				case "BGT":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
									}
									System.out.println("In case BGT");
								break;
				case "BGE":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
										System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
										System.exit(0);
								}
								System.out.println("In case BGE");
								break;
				case "BLT":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case BLT");
								break;
				case "BLE":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case BLE");
								break;
				case "BOF":	    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case BOF");
								break;
				case "NOP":	    if((!lineLabeled && currInstr.length != 1) || (lineLabeled && currInstr.length != 2)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case NOP");
								break;
				case "WAIT":    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case WAIT");
								break;
				case "DPT":	    if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case DPT");
								break;
				case "DLINE":	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case DLINE");
								break;
				case "DTRI":	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case DTRI");
								break;
				case "DPOLY":	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args");
									System.exit(0);
				                }
					            System.out.println("In case DPOLY");
								break;
				case "FILL":    if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case FILL");
								break;
				case "RMVI":	if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case RMVI");
								break;
				case "RMVR":	if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case RMVR");
								break;
				case "RMVALL":	if((!lineLabeled && currInstr.length != 1) || (lineLabeled && currInstr.length != 2)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case RMVALL");
								break;
				case "TRN":	    if((!lineLabeled && currInstr.length != 4) || (lineLabeled && currInstr.length != 5)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case TRN");
								break;
				case "TRNALL":	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case TRNALL");
								break;
				case "ROTR":	if((!lineLabeled && currInstr.length != 4) || (lineLabeled && currInstr.length != 5)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ROTR");
								break;
				case "ROTL":	if((!lineLabeled && currInstr.length != 4) || (lineLabeled && currInstr.length != 5)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case ROTL");
								break;
				case "SCALE":   if((!lineLabeled && currInstr.length != 4) || (lineLabeled && currInstr.length != 5)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case SCALE");
								break;
				case "REFLECT":	if((!lineLabeled && currInstr.length != 3) || (lineLabeled && currInstr.length != 4)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case REFLECT");
								break;
				case "MATC":	if((!lineLabeled && currInstr.length != 1) || (lineLabeled && currInstr.length != 2)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case MATC");
								break;
				case "MATU":	if((!lineLabeled && currInstr.length != 2) || (lineLabeled && currInstr.length != 3)) {
									System.out.println("Line " + (i + 1) + " : Incorrect number of args" + '\n');
									System.exit(0);
								}
								System.out.println("In case MATU");
								break;
				case "HALT":	System.out.println("Processor Halted");
								System.exit(0);
								break;
				default:        System.out.println("defaulted");

			}
		}
		System.exit(0);
	}
	
	/*
	 * Method for converting the hex immediates in the program to the
	 * appropriate integer number.
	 * 
	 * @params hex  a string containing the hex version of a number
	 * @return the integer value of the hex number
	 */
	private int convertHex(String hex) {
		String[] parseHex = hex.split("x");
		Integer hexNum = Integer.parseInt(parseHex[1], 16);
		return hexNum.intValue();
	}
	
	/*
	 * Method for the register strings read into instruction memory to be 
	 * converted into an index for the register file
	 * 
	 * @params reg the string name of a register
	 * @return the integer index into the register file
	 */
	private int parseReg(String reg) {
		switch(reg) {
			case "R0" : return 0;
			case "R1" : return 1;
			case "R2" : return 2;
			case "R3" : return 3;
			case "R4" : return 4;
			case "R5" : return 5;
			case "R6" : return 6;
			case "R7" : return 7;
			case "R8" : return 8;
			case "R9" : return 9;
			case "R10" : return 10;
			case "R11" : return 11;
			case "R12": return 12;
			case "R13" : return 13;
			case "R14" : return 14;
			case "R15" : return 15;
			case "R16" : return 16;
			case "R17" : return 17;
			case "R18" : return 18;
			case "R19" : return 19;
			case "R20" : return 20;
			case "SP" : return 20;
			case "R21" : return 21;
			case "FP" : return 21;
			case "R22" : return 22;
			case "FS" : return 22;
			case "R23" : return 23;
			case "RO" : return 23;
			case "R24" : return 24;
			case "V0" : return 24;
			case "R25" : return 25;
			case "V1" : return 25;
			case "R26" : return 26;
			case "V2" : return 26;
			case "R27" : return 27;
			case "V3" : return 27;
			case "R28": return 28;
			case "V4": return 28;
			case "R29" : return 29;
			case "V5" : return 29;
			case "R30" : return 30;
			case "V6" : return 30;
			case "R31" : return 31;
			case "V7" : return 31;
			default : return -1;
		}
	}
	
}
