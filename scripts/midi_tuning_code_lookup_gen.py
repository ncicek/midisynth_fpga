def get_tuning_code (byte): #delta_phase
	fc = float(16E6/256/3)
	
	tuning_code = ( (2**output_bits) * (2**((byte-69)/12.0)) * 440 ) / fc
	tuning_code_int = int(round(tuning_code))
	
	return tuning_code_int
	
	
#for i in range(0,127):
	#print ("8'd%d:	tuning_code = 32'd%d;" % (i, get_tuning_code(i)))

	
input_bits = 7
output_bits = 32

fo = open("tuning_lookup.txt", "wb")
for i in range(2**input_bits):
	
	tuning_code = get_tuning_code(i)
	if (tuning_code >= 2**output_bits):
		print("too high")
		raise()
	
	#compose a line of verilog
	string = str(input_bits) + "'" + "d" + str(i) + ":	tuning_code = " + str(output_bits) + "'d" + str(tuning_code) + ";"

	fo.write(string+'\n');

	#print (string, file=fo)
fo.close()