import math

def calcCoef(rate, targetRatio):
	return (math.exp(-math.log((1.0 + targetRatio) / targetRatio) / rate))

#parameters
bits = 24
rate = 20000
sustainLevel = 0.7
targetRatioA = 0.3
targetRatioDR = 0.0001
#targetRatioDR = 0.3



#compute values
attackCoef = calcCoef(rate,targetRatioA)
attackBase=(1.0 + targetRatioA) * (1.0 - attackCoef);
decayCoef = calcCoef(rate,targetRatioDR)
decayBase = (sustainLevel - targetRatioDR) * (1.0 - decayCoef)
releaseCoef = calcCoef(rate, targetRatioDR)
releaseBase = -targetRatioDR * (1.0 - releaseCoef)


#convert to fixed point
sustainLevel = int(round(sustainLevel* 2**bits))
attackCoef = attackCoef * 2**bits
attackCoef = int(round(attackCoef))
attackBase = attackBase * 2**bits
attackBase = int(round(attackBase))
decayCoef = decayCoef * 2**bits
decayCoef = int(round(decayCoef))
decayBase = decayBase * 2**bits
decayBase = int(round(decayBase))
releaseCoef = releaseCoef * 2**bits
releaseCoef = int(round(releaseCoef))
releaseBase = releaseBase * 2**bits
releaseBase = int(round(releaseBase))


print ("sustainLevel: " + str(sustainLevel))
print ("attackCoef: " + str(attackCoef))
print ("attackBase: " + str(attackBase))
print ("decayCoef: " + str(decayCoef))
print ("decayBase: " + str(decayBase))
print ("releaseCoef: " + str(releaseCoef))
print ("releaseBase: "+ str(releaseBase))




#raise()
#env_out = (1<<bits)+attackBase + 100

env_out = 0
#print (env_out)
#print ("starting")
exp_table = []
#for x in range(rate):
state = 'attack'
while(1):
	if state == 'attack':
		env_out = (attackBase + (env_out * attackCoef >> bits))
		exp_table.append(env_out)
		if env_out >= ((1<<bits)-1):
			env_out = ((1<<bits)-1)
			state = 'decay'
	if state == 'decay':
		env_out = (decayBase + (env_out * decayCoef >> bits))
		exp_table.append(env_out)
		if env_out <= sustainLevel:
			env_out = ((1<<bits)-1)
			break

print (env_out)
print((1<<bits)-1)


import matplotlib.pyplot as plt
plt.plot(exp_table)
#plt.ylabel('exp')
plt.show()
