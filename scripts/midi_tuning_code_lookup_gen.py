def get_tuning_code (byte): #delta_phase
	n = 32
	fc = 48E6
	
	tuning_code = ((2**n)*(2**((byte-69)/12))*440)/fc

	tuning_code_int = round(tuning_code)
	
	return tuning_code_int
	
	
for i in range(0,127):
	print ("8'd%d:	tuning_code = 32'd%d;" % (i, get_tuning_code(i)))
