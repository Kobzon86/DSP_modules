import math
import matplotlib.pyplot as plt
import numpy as np
import scipy.signal

from scipy.signal import kaiserord, lfilter, firwin, freqz

class integrator:
	def __init__(self):
		self.yn  = 0
		self.ynm = 0
	
	def update(self, inp):
		self.ynm = self.yn
		self.yn  = (self.ynm + inp)
		return (self.yn)
		
class comb:
	def __init__(self):
		self.xn  = 0
		self.xnm = 0
	
	def update(self, inp):
		self.xnm = self.xn
		self.xn  = inp
		return (self.xn - self.xnm)



sample_rate = 100.0
nsamples = 256
t = np.arange(nsamples) / sample_rate
x = np.cos(2*np.pi*0.5*t) + 0.2*np.sin(2*np.pi*2.5*t+0.1) + \
0.2*np.sin(2*np.pi*15.3*t) + 0.1*np.sin(2*np.pi*16.7*t + 0.1) + \
0.1*np.sin(2*np.pi*23.45*t+.8)

# print(x)
#------------------------------------------------
# Create a FIR filter and apply it to x.
#------------------------------------------------

# The Nyquist rate of the signal.
nyq_rate = sample_rate / 2.0

# The desired width of the transition from pass to stop,
# relative to the Nyquist rate.  We'll design the filter
# with a 5 Hz transition width.
width = 5.0/nyq_rate

# The desired attenuation in the stop band, in dB.
ripple_db = 60.0

# Compute the order and Kaiser parameter for the FIR filter.
N, beta = kaiserord(ripple_db, width)

# The cutoff frequency of the filter.
cutoff_hz = 10.0

# Use firwin with a Kaiser window to create a lowpass FIR filter.
taps = firwin(N, cutoff_hz/nyq_rate, window=('kaiser', beta))

# print(N)
# print(taps)
# Use lfilter to filter x with the FIR filter.
filtered_fir = lfilter(taps, 1.0, x)

#------------------------------------------------
# Create a IIR filter and apply it to x.
#------------------------------------------------

fs = 30  # sampling rate, Hz
# define IIR lowpass filter with 2.5 Hz cutoff frequency
b, a = scipy.signal.iirfilter(4, Wn=2.5, fs=fs, btype="low", ftype="butter")
# a = [1.0, 1.0, 1.0, 1.0, 1.0]
# b = [1.0, 1.0, 1.0, 1.0, 1.0]
print(b, a, sep="\n")
filtered_iir = scipy.signal.lfilter(b, a, x)

#------------------------------------------------
# Create a CIC filter and apply it to x.
#------------------------------------------------

## Configuration
decimation         = 4 		# any integer; powers of 2 work best.
stages             = 4			# pipelined I and C stages
## Seperate Stages - these should be the same unless you specifically want otherwise.
c_stages = stages
i_stages = stages

output_samples   = []

## Generate Integrator and Comb lists (Python list of objects)
intes = [integrator() for a in range(i_stages)]
combs = [comb()	      for a in range(c_stages)]

## Calculate normalising gain
gain = (decimation * 1) ** stages

## Decimating CIC Filter
for (s, v) in enumerate(x):
	z = v
	for i in range(i_stages):
		z = intes[i].update(z)
	
	if (s % decimation) == 0: # decimate is done here
		for c in range(c_stages):
			z = combs[c].update(z)
			j = z
		output_samples.append(j/gain) # normalise the gain

## Crude function to FFT and slice data, with 20log10 result
def fft_this(data):
	N = len(data)
	# return (20*np.log10(np.abs(np.fft.fft(data)) / N)[:N // 2])
	return (20*np.log10(np.abs(np.fft.fft(data)) / N))

calculated_fft = np.abs(np.fft.fft(x))
# print(calculated_fft)
## Plot some graphs
print("Preparing graphs... ", end="")
plt.figure(1)
plt.suptitle("H")

plt.subplot(2,4,1)
plt.title("Time domain input")
plt.plot(x)
plt.grid()

plt.subplot(2,4,5)
plt.title("Frequency domain input")
# plt.plot(fft_this(x))
plt.plot(calculated_fft )


plt.subplot(2,4,2)
plt.title("Time domain FIR output")
plt.plot(filtered_fir)
plt.grid()

plt.subplot(2,4,6)
plt.title("Frequency domain FIR output")
# plt.plot(fft_this(x))
plt.plot(np.abs(np.fft.fft(filtered_fir)) )

plt.subplot(2,4,3)
plt.title("Time domain IIR output")
plt.plot(filtered_iir)
plt.grid()

plt.subplot(2,4,7)
plt.title("Frequency domain IIR output")
# plt.plot(fft_this(x))
plt.plot(np.abs(np.fft.fft(filtered_iir)) )

plt.subplot(2,4,4)
plt.title("Time domain CIC output")
plt.plot(output_samples)
plt.grid()

plt.subplot(2,4,8)
plt.title("Frequency domain CIC output")
# plt.plot(fft_this(x))
plt.plot(np.abs(np.fft.fft(output_samples)) )

plt.grid()
plt.tight_layout()
## Show graphs
plt.show()