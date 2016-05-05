# Imports #
import re
import sys
import pprint

#-##############################################################################
# Definitions #
#-#
CODE_SIZE                = 0x0200
FILL_ADDRESS_SPACE_START = 0x01A0 # 256
CODE_ADDRESS_SPACE_START = 0x0000

p = pprint.PrettyPrinter(indent=2)

global_labels = {}
curr_opcode = ''

bcd = {
'0' : '0000',
'1' : '0001',
'2' : '0010',
'3' : '0011',
'4' : '0100',
'5' : '0101',
'6' : '0110',
'7' : '0111',
'8' : '1000',
'9' : '1001',
'A' : '1010',
'B' : '1011',
'C' : '1100',
'D' : '1101',
'E' : '1110',
'F' : '1111',
'0000' : '0',
'0001' : '1',
'0010' : '2',
'0011' : '3',
'0100' : '4',
'0101' : '5',
'0110' : '6',
'0111' : '7',
'1000' : '8',
'1001' : '9',
'1010' : 'A',
'1011' : 'B',
'1100' : 'C',
'1101' : 'D',
'1110' : 'E',
'1111' : 'F',
}

# Create read/write files #
try:
    inFile = sys.argv[1]
    outFile = sys.argv[2]
except:
    print("assembler.py <inputFileName> <outputFileName>")
    sys.exit(2)

source = open(inFile, 'r+') # allow to specify filename later on
binary_code = open(re.sub(r'[.]', '_bin.', outFile), 'w')
machine_code = open(outFile, 'w')

def parse_instruction(instr):
    """
    Parse a P3D-VPU instruction to binary/hex format
    """
    # Initialize each instruction to 1's (default) #
    binary_instr = ['0'] * 16

    # Get instruction template #
    template = instructions_list[instr['instr']]
    opcode = list(template['opcode'])
    i = 0

    # write opcode #
    for bit in opcode:
        binary_instr[i] = bit
        i += 1

    parameters = template['params']
    params = instr['params']
    # process parameters #
    if len(params) is not len(parameters):
        print('***ERROR*** Number of parameters does not match for instruction at line %s' % instr['line'])
        return

    p = 0
    for param in params:
        # Check type - reg/immd/label #
        parsed_param = parameter_types[parameters[p]['type']](instr, param, parameters[p]['size'])
        i = 15 - parameters[p]['start']

        # Write Binary (could make hex later?) #
        for bit in parsed_param:
            binary_instr[i] = bit
            i += 1

        # Next parameter #
        p += 1

    hex_instr = bcd[ ''.join(binary_instr[0:4])  ] + \
                bcd[ ''.join(binary_instr[4:8])  ] + \
                bcd[ ''.join(binary_instr[8:12]) ] + \
                bcd[ ''.join(binary_instr[12:])  ]

    binary_instr = ''.join(binary_instr)

    return hex_instr, binary_instr

def parse_reg(instr, param, size):
    """
    Parse a register parameter to a binary/hex value
    """
    if param not in registers:
        print('***ERROR*** Invalid register symbol used!')
    else:
        return list(registers[param])[-size:]

def hex_to_binary(hex):
    """
    Parse hex value to binary digits
    """
    binary = ''
    for h in hex:
        binary += bcd[h.upper()]

    # Sign Extend #
    if curr_opcode == 'LDU':
        binary = binary + '0' * (16 - len(binary))
    elif curr_opcode == 'LDL':
        binary = '0' * (16 - len(binary)) + binary
    else:
        binary = binary[0] * (16 - len(binary)) + binary

    return binary

def decimal_to_binary(type, decimal, size):
    """
    Parse positive and negative numbers to binary/hex format
    """
    binary = ''
    if type == 'dp':
        if '-' in decimal:
            print('***WARNING*** Assigning negative number for a positive type!')
        binary = bin(int(decimal))[2:]
        binary = '0' * (16 - len(binary)) + binary
    elif type == 'dn':
        binary = bin(int(decimal))[3:]
        if(len(binary)) > size:
            print('***WARNING*** Decimal value: %s specified is over capacity: %s' % (decimal, size))

        foundOne = False
        binaryNext = ''
        for b in str(binary)[::-1]:
            # Rebuild 2's complement #
            if not foundOne:
                binaryNext += b
            else:
                binaryNext += ('0' if b == '1' else '1')
            if b == '1':
                foundOne = True

        binary = '1' * (16 - len(binaryNext)) + binaryNext[::-1]
    elif type == 'du' or type == 'dl':
        if '-' in decimal:
            binary = decimal_to_binary('dn', decimal[1:], size)
        else:
            binary = decimal_to_binary('dp', decimal, size)
        print(binary)
    else:
        print("***ERROR*** Invalid immediate type: " + type)
    
    return binary

def parse_immd(instr, param, size):
    """
    Parse an immediate value of varying length into binary/hex format
    """
    # Exception for register labels being used as immd for VPU instr #
    if param in registers:
        return list(registers[param])[-size:]
    if param in global_labels:
        return parse_label(instr, param, size)[-size:]
    # check type - hex/binary/decimal(signed/upper/lower) #
    if re.search(r'(0x)', param):
        param = hex_to_binary(param[2:])
    elif re.search(r'(dp)|(dn)|(du)|(dl)', param):
        param = decimal_to_binary(param[:2], param[2:], size)
    elif re.search(r'(i)', param):
        param = param[1:]
        param = param[0] * (16 - len(param)) + param
    else:
        print("***ERROR*** Invalid immediate type: " + param)

    if curr_opcode == 'LDU':
        return list(param)[:size]
    else:
        return list(param)[-size:]

def parse_label(instr, param, size):
    """
    Parse labels to place within instructions
    """
    # do a look up #
    try:
        label_value = global_labels[param]
    except KeyError as e:
        raise Exception('***ERROR*** Undeclared label %s was used' % param)

    # Calculate PC offset #
    if instructions_list[curr_opcode]['opcode'] == '011011' or \
       instructions_list[curr_opcode]['opcode'][:5] == '01110':
        target = int(label_value, base=16)
        pc_plus_one = instr['address'] + 1
        # Change decimals to binary/hex format #
        if target >= pc_plus_one:
            offset = target - pc_plus_one
            label_bits = parse_immd(instr, 'dp'+str(offset), size)
            return label_bits
        else:
            offset = target - pc_plus_one
            label_bits = parse_immd(instr, 'dn'+str(offset), size)
            return label_bits

    label_bits = parse_immd(instr, str(label_value), size)

    return label_bits

parameter_types = {
'reg'   : parse_reg,
'immd'  : parse_immd,
'label' : parse_label,
}

registers = {
# Standard Name     # Special Names     # Description
#-------------------#-------------------#---------------------------------------
'R0'    : '00000',                      # Registers useable for LDU/LDL
'R1'    : '00001',                      # *
'R2'    : '00010',                      # *
'R3'    : '00011',                      # *
'R4'    : '00100',                      # *
'R5'    : '00101',                      # *
'R6'    : '00110',                      # *
'R7'    : '00111',                      # *
'R8'    : '01000',
'R9'    : '01001',
'R10'   : '01010',
'R11'   : '01011',
'R12'   : '01100',
'R13'   : '01101',
'R14'   : '01110',
'R15'   : '01111',
'R16'   : '10000',  'RT'    : '10011',  # Jump Return Register (PC + 1)
'R17'   : '10001',
'R18'   : '10010',
'R19'   : '10011',
'R20'   : '10100',  'SP'    : '10100',  # Stack Pointer
'R21'   : '10101',  'FP'    : '10101',  # Frame Pointer
'R22'   : '10110',  'FS'    : '10110',  # Flags Register
'R23'   : '10111',  'RO'    : '10111',  # Return Object Register
'R24'   : '11000',  'V0'    : '11000',  # Vertex Register0
'R25'   : '11001',  'V1'    : '11001',  # Vertex Register1
'R26'   : '11010',  'V2'    : '11010',  # Vertex Register2
'R27'   : '11011',  'V3'    : '11011',  # Vertex Register3
'R28'   : '11100',  'V4'    : '11100',  # Vertex Register4
'R29'   : '11101',  'V5'    : '11101',  # Vertex Register5
'R30'   : '11110',  'V6'    : '11110',  # Vertex Register6
'R31'   : '11111',  'V7'    : '11111',  # Vertex Register7
}

instructions_list = {
'AND'   :{'opcode'      : '00000',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'OR'    :{'opcode'      : '00001',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'XOR'   :{'opcode'      : '00010',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'NOT'   :{'opcode'      : '00011',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'ADD'   :{'opcode'      : '00100',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'ADDI'  :{'opcode'      : '00100' + '1',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'LSL'   :{'opcode'      : '00101',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 4,
                           },
                          ]
         },
'LSR'   :{'opcode'      : '00110' + '0',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 4,
                           },
                          ]
         },
'ASR'   :{'opcode'      : '00110' + '1',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 3,
                            'size'   : 4,
                           },
                          ]
         },
'ROL'   :{'opcode'      : '00111' + '0',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                          ]
         },
'ROR'   :{'opcode'      : '00111' + '1',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                          ]
         },
'MOV'   :{'opcode'      : '01000' + '0',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'SWAP'  :{'opcode'      : '01000' + '1',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'LDR'   :{'opcode'      : '01001',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'LDU'   :{'opcode'      : '01010',
          'params'      : [{'type'   : 'reg',
                            'start'  : 10,
                            'size'   : 3,
                           },
                           {'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'LDL'   :{'opcode'      : '01011',
          'params'      : [{'type'   : 'reg',
                            'start'  : 10,
                            'size'   : 3,
                           },
                           {'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'ST'   :{'opcode'      : '01100',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'J'     :{'opcode'      : '01101' + '1',
          'params'      : [{'type'   : 'label',
                            'start'  : 9,
                            'size'   : 10,
                           },
                          ]
         },
'JR'    :{'opcode'      : '01101' + '0',
          'params'      : [{'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
                          ]
         },
'B'     :{'opcode'      : '01110' + '000',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BEQ'   :{'opcode'      : '01110' + '001',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BNE'     :{'opcode'      : '01110' + '010',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BGT'     :{'opcode'      : '01110' + '011',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BGE'     :{'opcode'      : '01110' + '100',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BLT'     :{'opcode'      : '01110' + '101',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BLE'     :{'opcode'      : '01110' + '110',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'BOF'     :{'opcode'      : '01110' + '111',
          'params'      : [{'type'   : 'immd',
                            'start'  : 7,
                            'size'   : 8,
                           },
                          ]
         },
'NOP'   :{'opcode'      : '01111',
          'params'      : [
                          ]
         },
'WAIT'  :{'opcode'      : '01111',
          'params'      : [{'type'   : 'immd',
                            'start'  : 10,
                            'size'   : 11,
                           },
                          ]
         },
'DPT'   :{'opcode'      : '10000' + '00',
          'params'      : [{'type'   : 'immd',
                            'start'  : 8,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'DLINE' :{'opcode'      : '10000' + '01',
          'params'      : [{'type'   : 'immd',
                            'start'  : 8,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'DTRI'  :{'opcode'      : '10000' + '10',
          'params'      : [{'type'   : 'immd',
                            'start'  : 8,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'DPOLY' :{'opcode'      : '10000' + '11',
          'params'      : [{'type'   : 'immd',
                            'start'  : 8,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'GETOBJ':{'opcode'      : '10001',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                          ]
         },
'FILL'  :{'opcode'      : '10010',
          'params'      : [{'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'RMVI'  :{'opcode'      : '10011' + '0',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                          ]
         },
'RMVR'  :{'opcode'      : '10011' + '0',
          'params'      : [{'type'   : 'reg',
                            'start'  : 9,
                            'size'   : 5,
                           },
                          ]
         },
'RMVALL':{'opcode'      : '10011' + '1',
          'params'      : [
                          ]
         },
'TRNALL':{'opcode'      : '10100' + '1',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 2,
                           },
                          ]
         },
'TRN'   :{'opcode'      : '10100' + '0',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 2,
                           },
                           {'type'   : 'immd',
                            'start'  : 1,
                            'size'   : 2,
                           },
                          ]
         },
'ROTR'  :{'opcode'      : '10101' + '0',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'ROTL'  :{'opcode'      : '10101' + '1',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'SCALE' :{'opcode'      : '10110',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 3,
                            'size'   : 1,
                           },
                           {'type'   : 'immd',
                            'start'  : 2,
                            'size'   : 3,
                           },
                          ]
         },
'REFLECT':{'opcode'      : '10111',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                           {'type'   : 'immd',
                            'start'  : 1,
                            'size'   : 2,
                           },
                          ]
         },
'MATC'  :{'opcode'      : '11000' + '0',
          'params'      : [
                          ]
         },
'MATU'  :{'opcode'      : '11000' + '1',
          'params'      : [{'type'   : 'immd',
                            'start'  : 9,
                            'size'   : 5,
                           },
                          ]
         },
'HALT'  :{'opcode'      : '11111' + '11111111111',
          'params'      : [
                          ]
         },
'.FILL' :{'opcode'      : '',
          'params'      : [{'type'   : 'immd',
                            'start'  : 15,
                            'size'   : 16,
                           },
                          ]
         },
}

#-##############################################################################
# First pass #
#-#
line_number = 0
instructions = []
address = CODE_ADDRESS_SPACE_START
fill_address = FILL_ADDRESS_SPACE_START
print('\nFIRST PASS\n')
for curr_line in source:
    # Keep track of line number for sake of errors/warnings #
    line_number += 1

    # ignore newlines #
    if curr_line in ['\n', '\r\n'] or curr_line.isspace():
        continue

    entry = {'address'  : None,
             'comment'  : None,
             'instr'    : None,
             'label'    : None,
             'l_address': None,
             'params'   : None,
             'warning'  : None,
             'line'     : line_number,
             }

    # read in line information #
    l = curr_line.rstrip().split();
    element = 0;

    # check for label #
    label = None
    if l[element].startswith('_'):
        label = l[element]
        entry['label'] = label
        element += 1
    elif '#' in l[element] or '//' in l[element]:
        # Omit pure comment lines? Or should we leave em in there? #
        continue

    # check instruction #
    instr = None
    if l[element] in instructions_list:
        instr = l[element]
        entry['instr'] = instr
        element += 1

        # Set label address correctly based on instruction #
        if label is not None:
            if instr == '.FILL':
                global_labels[label] = hex(fill_address)
                entry['address'] = fill_address
                fill_address += 1
            else:
                global_labels[label] = hex(address)
                entry['address'] = address
                address += 1
        else:
            entry['address'] = address
            address += 1
    else:
        print('\t***ERROR*** Invalid Instruction %s' % l[element])
        continue

    # check parameters #
    parameters = []
    while element < len(l):
        if '#' in l[element] or '//' in l[element]:
            break # at comment
        else:
            parameters.append(l[element])
            element += 1

    entry['params'] = parameters

    # check comments #
    comment = ' '.join(l[element:])
    entry['comment'] = comment

    # generate entry #
    instructions.append(entry)

#-##############################################################################
# Second pass #
#-#
print('\nGLOBAL LABELS:\n')
p.pprint(global_labels)

instr_space_to_print_hex = ''
fill_space_to_print_hex = ''
instr_space_to_print_bin = '@'   + str(hex(CODE_ADDRESS_SPACE_START))
fill_space_to_print_bin  = '\n@' + str(hex(FILL_ADDRESS_SPACE_START))
# Second pass for label linking + instruction generation #
print('\nSECOND PASS\n')
for instr in instructions:
    # Parse entire instruction now #
    curr_opcode = instr['instr']
    (parsed_hex, parsed_bin) = parse_instruction(instr)
    if instr['instr'] == '.FILL':
        fill_space_to_print_hex += parsed_hex + '\n'
        fill_space_to_print_bin += '\n' + parsed_bin
    else:
        instr_space_to_print_hex += parsed_hex + '\n'
        instr_space_to_print_bin += '\n' + parsed_bin

#-##############################################################################
# Write to File #
#-#
print('\nWRITTING TO FILE\n')
zeroFill = instr_space_to_print_hex.count('\n')
while(zeroFill < FILL_ADDRESS_SPACE_START):
    instr_space_to_print_hex += '7800\n'
    zeroFill += 1

zeroFill = FILL_ADDRESS_SPACE_START + fill_space_to_print_hex.count('\n')
while(zeroFill < CODE_SIZE-1):
    fill_space_to_print_hex += '7800\n'
    zeroFill += 1
fill_space_to_print_hex += '7800'

binary_code.write(instr_space_to_print_bin)
binary_code.write(fill_space_to_print_bin)
machine_code.write(instr_space_to_print_hex)
machine_code.write(fill_space_to_print_hex)

#-##############################################################################
# Clean Up #
#-#
print('\nDONE\n')
source.close()
machine_code.close()
