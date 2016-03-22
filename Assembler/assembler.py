# Imports #
import sys
import pprint

#-##############################################################################
# Definitions #
#-#
FILL_ADDRESS_SPACE_START = 0x0800
CODE_ADDRESS_SPACE_START = 0x0000

p = pprint.PrettyPrinter(indent=2)

global_labels = {}

# Create read/write files #
source = open('file.txt', 'r+') # allow to specify filename later on
machine_code = open('instr.hex', 'w')

def parse_instruction(instr):
    """
    
    """
    print('parse %s' % instr['instr'])
    
    # Initialize each instruction to 1's (default) #
    binary_instr = ['1'] * 16

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
        parsed_param = parameter_types[parameters[p]['type']](param, parameters[p]['size'])
        i = 15 - parameters[p]['start']

        # Write Binary (could make hex later?) #
        for bit in parsed_param:
            binary_instr[i] = bit
            i += 1

        # Next parameter #
        p += 1

    print(binary_instr)

def parse_reg(param, size):
    """
    
    """
    if param not in registers:
        print('***ERROR*** Invalid register symbol used!')
    else:
        return list(registers[param])[0:size]

def parse_immd(param, size):
    """
    
    """
    # check type - hex/binary/decimal(signed/upper/lower) #
    return list(param)[0:size] #temp

def parse_label(param, size):
    """
    
    """
    # do a look up #
    try:
        label_value = global_labels[param]
    except IndexError as e:
        print('***ERROR*** Undeclared label %s was used' % param)
        return

    label_bits = parse_immd(str(label_value), size)

    return label_bits[0:size]

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
'R16'   : '10000',
'R17'   : '10001',
'R18'   : '10010',
'R19'   : '10011',  'RT'    : '10011',  # Jump Return Register (PC + 1)
'R20'   : '10100',  'RO'    : '10100',  # Return Object Register
'R21'   : '10101',  'FS'    : '10101',  # Flags Register
'R22'   : '10110',  'SP'    : '10110',  # Stack Pointer
'R23'   : '10111',  'FP'    : '10111',  # Frame Pointer
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
'J'     :{'opcode'      : '01101',
          'params'      : [{'type'   : 'label',
                            'start'  : 9,
                            'size'   : 10,
                           },
                          ]
         },
'JR'    :{'opcode'      : '01101',
          'params'      : [{'type'   : 'reg',
                            'start'  : 4,
                            'size'   : 5,
                           },
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
print('\nALL INSTRUCTIONS:\n')
#p.pprint(instructions)

# Second pass for label linking + instruction generation #
for instr in instructions:
    # Parse entire instruction now #
    parse_instruction(instr)

#-##############################################################################
# Clean Up #
#-#
source.close()
machine_code.close()
