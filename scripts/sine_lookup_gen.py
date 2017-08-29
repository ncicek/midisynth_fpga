import math

def convert_to_or_from_twos_comp(val):
	#works both ways
	return (~val + 1)


def get_sine_val (phase_code): #delta_phase

	PI = (math.pi)

	phase_float = float(phase_code * (2*PI) / (2**input_bits))

	sine_discrete = int(round(math.sin(phase_float)*(2**(output_bits-1)-1)))

	two_comp_int = convert_to_or_from_twos_comp(sine_discrete)

	#back = convert_to_or_from_twos_comp(two_comp_int)
	#print (back)

	return (two_comp_int)

def is_positive(val):
	return (val > 0)


input_bits = 10
output_bits = 16

fo = open("foo.txt", "wb")

for i in range(0,2**input_bits):
	sine_val = get_sine_val(i)
	abs_sine_val = abs(sine_val)
	if (abs_sine_val >= 2**output_bits):
		print("too high")
		raise()
	sign = '' if (is_positive(sine_val))  else '-'

	#compose a line of verilog
	string = str(input_bits) + "'" + "d" + str(i) + ":	sine_sample = " + sign + str(output_bits) + "'sd" + str(abs_sine_val) + ";"

	fo.write(string+'\n');

	#print (string, file=fo)
fo.close()
