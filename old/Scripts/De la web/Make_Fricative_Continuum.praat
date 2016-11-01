# # ## ### ##### ########  #############  ##################### 
# Create synthetic fricative continuum
# by Matthew B. Winn
# August 2014
#
# this script filters  white noise to create fricatives according to the dimensions that you specify
# frequency interpolation can be linear, logarithmic, Bark scale, or Greenwood (cochlear spacing)
##################################
##################### 
############# 
######## 
#####
###
##
#
#

form Input Enter specifications for Fricative continuum settings
comment Enter parameter levesl for continuum endpoints in the Left and Right columns

natural number_of_steps 8

#comment PEAK FREQUENCIES
	real left_peak1 2500
	real right_peak1End 2500

	real left_peak2 5200
	real right_peak2End 5200

	real left_peak3 7000
	real right_peak3End 7000

optionmenu interpolation: 4
       option Linear interpolation
       option Logarithmic interpolation
       option Use Greenwood function
       option Use Bark scale

comment Fricative peak slope (in dB / octave)
comment (e.g. 20 is broad, 90 is sharp)
	real left_slope1 35
	real right_slope1End 25
	real left_slope2 45
	real right_slope2End 55
	real left_slope3 40
	real right_slope3End 55


comment RELATIVE AMPLITUDES (relative to second peak)
	integer left_amp1 5
	integer right_amp1End -25

	integer left_amp3 -4
	integer right_amp3End 20


#comment fricative duration, rise time and fall time
	real left_duration 200
	real right_durationEnd 200

	real left_risetime 150
	real right_risetimeEnd 150

	real left_falltime 40
	real right_falltimeEnd 40

	real left_intensity 70
	real right_intensityEnd 70
	
#comment filename prefix for steps and full items w/vowels: 
	sentence left_prefix Step_
	sentence right_fullPrefix VowelName_

#comment append fricative to another soundfile in the list?
    optionmenu append_to_vowel: 1
       option No - create isolated fricatives
       option Yes -  fricative at the beginning
       option Yes - friative at the end

     boolean draw 1
endform


#
#
##
###
#####
########
#############
#####################
##################################
# First, convert variables from form,
# and establish some other variables;
# scroll to the bottom of the script for details
call convertVariables

call makeContinuumValues

# Make the continuum
for thisStep from 1 to steps
# first, lookup the relevant continuum values 
   call assignVariableLevels
	# yields: peak1, peak2, peak3, slope1, slope2, slope3, 
	# yields: amp1, amp2, amp3
	# yields: duration, risetime, falltime, intensity 

   # create broadband noise to filter
      	Create Sound from formula... Noise 1 0 duration samplerate randomGauss(0,0.1)

   for thisPeak from 1 to numpeaks
	select Sound Noise
	temp_int = Get intensity (dB)
	# adjust the intensity for this peak
	new_int = temp_int + amp'thisPeak'
	Copy... Noise_temp
	Scale intensity... new_int		

	# filter the sound around the center frequency
	    call filterOctaveRolloff Noise_temp peak'thisPeak' slope'thisPeak' 'prefix$''thisStep'_peak'thisPeak'

	# cleanup temp
		select Sound Noise_temp
		Remove

	# create exponential curve for amplitude envelope
	# power by which cosine envelope is shaped is detemined 
	# by which peak is being modulated;
	# higher peaks have slightly slower-onset envlopes
	   power = 0.5+(thisPeak/2)
	   call applyEnvelope "'prefix$''thisStep'_peak'thisPeak'" risetime falltime power

   endfor

   # put all the peaks together
   	call blend3Peaks "'prefix$''thisStep'_peak1" "'prefix$''thisStep'_peak2" "'prefix$''thisStep'_peak3" 'prefix$''thisStep'

   # scale the final intensity of this continuum step
   # (intensity determined from assignVariableLevels procedure)
   	call scaleIntensity "'prefix$''thisStep'" intensity

   # cleanup
   	call removePeakFiles
endfor

# attach the vowel, if necessary
	call appendVowel

# draw pretty pictures
   if draw = 1
	call drawSpectra
   endif


# disable saving for now
# (You can alway manually save it with a separate script)
#call saveInfoWindow "'outDirectory$'" Continuum_info

##################################
#####################
#############
########
#####
###
##
#
#
procedure filterOctaveRolloff .name$ .cf .rolloff.per.octave .newname$
   select Sound '.name$'
   Filter (formula)...  if x > 1 then self*10^(-(abs((log10(x/.cf)/log10(2)))*.rolloff.per.octave)/20) else self fi
   Rename... '.newname$'
endproc

procedure drawSpectra
   Erase all
   select Sound 'prefix$'1
   for thisFricative from 2 to steps
	plus Sound 'prefix$''thisFricative'
   endfor
   
   numberOfSelectedSounds = numberOfSelected ("Sound")
   
   for thisSelectedSound to numberOfSelectedSounds
   	sound'thisSelectedSound' = selected("Sound",thisSelectedSound)
   endfor
   
   for thisSound from 1 to numberOfSelectedSounds
      redgradient = ('thisSound'-1)/('numberOfSelectedSounds'-1)
   	r = redgradient
   	g = 0.0
   	b = 1-redgradient
      Colour... {'r','g','b'}
   
      select sound'thisSound'
   	name$ = selected$("Sound")
   	To Spectrum... yes
   	Cepstral smoothing... 'smoothing'
   	Rename... 'name$'_smooth
   	select Spectrum 'name$'
   	Remove
   	select Spectrum 'name$'_smooth
   	Draw... drawHzLow drawHzHigh drawDBLow drawDBHigh yes
   	select Spectrum 'name$'_smooth
   	Remove
   endfor
   
   # x-axis (frequency) labels
      Marks bottom every: 1, 1000, "yes", "yes", "no"

endproc

procedure saveInfoWindow outputDirectory$ outputFileName$
   # first delete the file if it already exists
      filedelete 'outputDirectory$'/'outputFileName$'.txt
   # create the file
      fappendinfo 'outputDirectory$'/'outputFileName$'.txt
endproc

procedure getVowelInfo
   if append_to_vowel = 0
	#take no action
	print 'newline$'
	numchannels = 1
   else
	pause Select the soundfile to combine with the fricatives
	vowel$ = selected$("Sound")
	numchannels = Get number of channels
	samplerate = Get sampling frequency
	print 'vowel$' was used as the vowel'newline$'

   endif
endproc

procedure appendVowel
   call getVowelInfo

   if append_to_vowel = 0
	#take no action
	print 'newline$'
   elsif append_to_vowel = 1
	select Sound 'vowel$'
	Convert to mono
	Rename... vowel2
	for thisFricative from 1 to steps
	    select Sound 'prefix$''thisFricative'
	    plus Sound vowel2
	    Concatenate
		# use this line for a simple filename
		# Rename... 'fullPrefix$''thisFricative'
		# use this line instead to maintain the original vowel filename in the ultimate name
		  Rename... 'prefix$''thisFricative'_'vowel$'
	endfor
	select Sound vowel2
	Remove

   elsif append_to_vowel = 2
     for thisFricative from 1 to steps
	select Sound 'vowel$'
	Convert to mono
	Rename... vowel2

	select Sound 'prefix$''thisFricative'
	Copy... Fricative2

	select Sound vowel2
	plus Sound Fricative2
	Concatenate
		# use this line for a simple filename
		# Rename... 'fullPrefix$''thisFricative'
		# use this line instead to maintain the original vowel filename in the ultimate name
		   Rename... 'prefix$''thisFricative'_'vowel$'

	select Sound Fricative2
	plus Sound vowel2
	Remove
     endfor
   endif
endproc

procedure removePeakFiles
	select Sound 'prefix$''thisStep'_peak1
	plus Sound 'prefix$''thisStep'_peak2
	plus Sound 'prefix$''thisStep'_peak3
	plus Sound Noise
	Remove
endproc

procedure scaleIntensity .name$ .intensity
	select Sound '.name$'
	Scale intensity... '.intensity'
endproc

procedure applyEnvelope .name$ .risetime .falltime .power
	select Sound '.name$'
	.start = Get start time
	.end = Get end time
	Formula... if x<('.risetime')  
		...then self * ((cos((x-('.risetime' - '.start'))/'.risetime' * pi/2))^'.power')
		...else self endif  
	endif
	
	Formula... if x>('.end' - '.falltime')  
		...then self * cos((x-(.end - '.falltime'))/'.falltime' * pi/2)
		...else self endif
	endif
endproc


procedure blend3Peaks .sound1$ .sound2$ .sound3$ .newname$
	select Sound '.sound1$'
	Copy... '.newname$'
	Formula... self [col] + Sound_'.sound2$' [col] + Sound_'.sound3$' [col]
endproc


procedure assignVariableLevels
	for thisPeak from 1 to numpeaks
	    peak'thisPeak' = peak'thisPeak'_'thisStep'
	    slope'thisPeak' = slope'thisPeak'_'thisStep'
	    amp'thisPeak' = amp'thisPeak'_'thisStep'
	endfor

	duration = duration'thisStep'
	risetime = risetime'thisStep'
	falltime = falltime'thisStep'
	intensity = intensity'thisStep'
endproc

procedure makeContinuumValues
   clearinfo
   if steps >1
    for n from 1 to numpeaks
    # navigate among four different interpolation types
	if interpolation = 1; linear
		# create variable levels
		call makeContinuum0dec steps peak'n'Start peak'n'End "peak'n'_" yes

	elsif interpolation = 2; logarithmic
	   peak'n'Start = log10(peak'n'Start)
	   peak'n'End = log10(peak'n'End)
	   # create variable levels using log values
	   call makeContinuum3dec steps peak'n'Start peak'n'End "peak'n'_" no
	   for .thisLogStep from 1 to steps
	        # convert log values back to Hz values 
		peak'n'_'.thisLogStep' = 10^(peak'n'_'.thisLogStep')
		tempvariable = peak'n'_'.thisLogStep'
		print peak'n'_'.thisLogStep''tab$''tempvariable:0''newline$'
	   endfor
	print 'newline$'

	elsif interpolation = 3;Greenwood
	    # cochlea parameters
		aA = 165.4
		a = 2.1
		length = 35
		k = 0.88

		apicalCochlearPositionPeak'n' = log10((peak'n'Start/'aA')+'k')*'length'/'a'
		basalCochlearPositionPeak'n' = log10((peak'n'End/'aA')+'k')*'length'/'a'

		call makeContinuum3dec steps apicalCochlearPositionPeak'n' basalCochlearPositionPeak'n' "cochlearPosition'n'_" no

	    for .thisGreenwoodStep from 1 to steps
		  peak'n'_'.thisGreenwoodStep' = 'aA'*((10^('a'*cochlearPosition'n'_'.thisGreenwoodStep'/'length'))-'k')
			tempvariable = peak'n'_'.thisGreenwoodStep'
		  print peak'n'_'.thisGreenwoodStep''tab$''tempvariable:0''newline$'
	    endfor
		print 'newline$'

	elsif interpolation = 4; Use Bark scale
		## uses the Hz to Bark conversion from Traunmuller (1990); 
			## Hz to bark: 26.81/(1+(1960/f)) - 0.53
			## bark to Hz: f = 1960 / [26.81 / (z + 0.53) - 1]
			# H. Traunm�ller (1990) "Analytical expressions for the tonotopic sensory scale" 
			# J. Acoust. Soc. Am. 88: 97-100. 
		bark'n'Start = 26.81/(1+(1960/peak'n'Start)) - 0.53
		bark'n'End = 26.81/(1+(1960/peak'n'End)) - 0.53

		call makeContinuum3dec steps bark'n'Start bark'n'End "barkPeak'n'_" no

		for .thisBarkStep from 1 to steps
			peak'n'_'.thisBarkStep' = 1960 / (26.81 / (barkPeak'n'_'.thisBarkStep' + 0.53) - 1)

			tempvariable = peak'n'_'.thisBarkStep'
			print peak'n'_'.thisBarkStep''tab$''tempvariable:0''newline$'
		endfor
		print 'newline$'
	endif
    endfor

	for n from 1 to numpeaks
		call makeContinuum3dec steps slope'n'Start slope'n'End "slope'n'_" yes
	endfor

	for n from 1 to numpeaks
		call makeContinuum3dec steps amp'n'Start amp'n'End "amp'n'_" yes
	endfor
   endif

   # establish continuum values and print them to the info window
	call makeContinuum3dec steps durationStart durationEnd duration 1
	call makeContinuum3dec steps risetimeStart risetimeEnd risetime 1
	call makeContinuum3dec steps falltimeStart falltimeEnd falltime 1
	call makeContinuum3dec steps intensityStart intensityEnd intensity 1
endproc

procedure makeContinuum0dec .steps .low .high .prefix$ .printvalues
	for thisStep from 1 to .steps
	# calculate the value
	   temp = (('thisStep'-1)*('.high'-'.low')/('.steps'-1))+'.low'

	# assign the value to a variable name specified by the procedure arguments
	   '.prefix$''thisStep' = temp
		#.value = step_'.prefix$''thisStep'
	.value = '.prefix$''thisStep'
	if .printvalues = 1
	print '.prefix$''thisStep''tab$''.value:0' 'newline$'
	endif

	endfor
	print 'newline$'
endproc

procedure makeContinuum3dec .steps .low .high .prefix$ .printvalues
	for thisStep from 1 to .steps

	temp = (('thisStep'-1)*('.high'-'.low')/('.steps'-1))+'.low'

	'.prefix$''thisStep' = temp
	
	.value = '.prefix$''thisStep'
	if .printvalues = 1
	print '.prefix$''thisStep''tab$''.value:3' 'newline$'
	endif

	endfor
	print 'newline$'
endproc

procedure convertVariables
	yes = 1
	no = 0
	numpeaks = 3

	steps = number_of_steps
	#-----------------------
	peak1Start = left_peak1
	peak1End = right_peak1End
	peak2Start = left_peak2
	peak2End = right_peak2End
	peak3Start = left_peak3
	peak3End = right_peak3End
	#-----------------------
	slope1Start = left_slope1
	slope1End = right_slope1End
	slope2Start = left_slope2
	slope2End = right_slope2End
	slope3Start = left_slope3
	slope3End = right_slope3End
	#-----------------------
	amp1Start = left_amp1
	amp1End = right_amp1End
	amp3Start = left_amp3
	amp3End = right_amp3End
	amp2Start = 0
	amp2End = 0
	temporaryintensity = 50
	#-----------------------
	# convert ms to seconds
	durationStart = left_duration/1000
	durationEnd = right_durationEnd/1000
	#-----------------------
	# convert ms to seconds
	risetimeStart = left_risetime/1000
	risetimeEnd = right_risetimeEnd/1000
	falltimeStart = left_falltime/1000
	falltimeEnd = right_falltimeEnd/1000
	#-----------------------
	intensity = left_intensity
	intensityStart = left_intensity
	intensityEnd =  right_intensityEnd
	#-----------------------
	prefix$ = "'left_prefix$'"
	fullPrefix$ = "'right_fullPrefix$'"
	#-----------------------
	# convert variable level from form 
	append_to_vowel = append_to_vowel-1
	##### 0 means no vowel/word to append
	##### 1 means fricative comes first
	##### 2 means fricative comes second
	#-----------------------
	# options for drawing spectra
	smoothing = 300
	drawHzLow = 0
	drawHzHigh = 10000
	drawDBLow = 5
	drawDBHigh = 40

	# this option will be overridden if you select a vowel to concatenate 
	# (so that both the vowel and fricative have the same samplerate)
	#  so... only change this if you are creating isolated fricatives. 
	samplerate = 44100
endproc

