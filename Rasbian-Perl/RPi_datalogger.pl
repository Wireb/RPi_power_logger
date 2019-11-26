######################################################################################################################################################
#Copyright (c) 2019 Peter Shabino
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this hardware, software, and associated documentation files 
#(the "Product"), to deal in the Product without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
#distribute, sublicense, and/or sell copies of the Product, and to permit persons to whom the Product is furnished to do so, subject to the 
#following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Product.
#
#THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
#FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
#WITH THE PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
######################################################################################################################################################
# 22Sep2019 PJS V0 new

############################
# common install issue / tips
## update packages
# sudo apt-get update
## I2C tools
# sudo apt-get install libi2c-dev i2c-tools build-essential
## install cpanm
# curl -L https://cpanmin.us | perl - --sudo App::cpanminus
## git if you don't have it
# sudo apt-get install git
## get latest bmc packages
# wget http://www.open.com.au/mikem/bcm2835/bcm2835-1.59.tar.gz
# tar xvfz bcm2835-1.59.tar.gz 
# cd bcm2835-1.59/
# ./configure 
# make
# sudo make install
## install WiringPi if not already installed
# sudo apt-get install wiringpi
## get perl libs
#sudo cpanm RPi::WiringPi
# others may be needed had to go though many to find one that worked with I2C properly
## activate the I2C bus 
# sudo raspi-config
# -> Interfacing Options
# -> I2C
# select yes to "enable ARM I2C interface"
# select finish
## Verify devices are seen
# sudo i2cdetect -y 1
# is should return at least devices 40 and 48 if all is well with the drivers and RPi Battery Power Logger hat. 
############################


use strict;
use warnings; 
use RPi::WiringPi;
use RPi::Const qw(:all);




############################
# configuration value start
############################
my $output_file = "./Power_data.csv";	# output file path and name for readings
my $stop_file = "./stop";				# file to create to stop the loop
my $channels = "12345678"; 				# optional voltage channels enables. Valid values are 1 to 8. If that number is in this string (any order) the data will be collected along with the power data. 
my $sample_every = 1;					# sample every x seconds. A value of 0 will sample as fast as possible but the time data will still be in seconds (future upgrade sub second time base) 
my $stop_time = 0;						# in s 0 = run forever
############################
# configuration value end
############################

# constants (See INA233 datasheet for more info!!)
my $max_current = 2;	# in Amps
my $R_shunt = 0.075;  	# in Ohms

my $start_time = 0;
my $time = 0;
my $pi = "";
my %i2c_devices = ();
my $i = 0;
my $value = 0;
my $stop = 0;



if(-e $stop_file){
	print("Found stop file removing it\n");
	unlink($stop_file);
}

print("Open IO connections to the PI\n");
$pi = RPi::WiringPi->new;

############# 
## test code to see if your modules are installed correctly. 
## Put a led and series resistor between pins 39 (IO 21) and 40 (GND) and uncomment this code. 
## LED should blink at a 0.5Hz duty cycle if all is well
## ctrl-c to stop the code.
#my $pin = $pi->pin(21);
#$pin -> mode(OUTPUT);
#print("Test mode IO 21 (pin 39) blinking 0.5Hz\n");
#print("To stop this program run \"touch ".$stop_file."\"\n");
#do{
#	$pin->write(LOW);
#	sleep(1);
#	$pin->write(HIGH);
#	sleep(1);	
#}while(!-e $stop_file);
############# 

# chip addresses from datasheet (convert to 7 bit) or "sudo i2cdetect -y 1"
print("	INA233 setup\n");
$i2c_devices{"INA233"} = $pi->i2c(0X40);
print("	NCD9830 setup\n");
$i2c_devices{"NCD9830"} = $pi->i2c(0x48);


# enable the NCD9830 ADC and internal ref
$i2c_devices{"NCD9830"}->write(0x8C); # Data to write
# set up the INA233 cal (2A max scale = 0xC5, 0x20)
$value = $max_current / (2 ** 15);
$value = 0.00512 / ($value * $R_shunt);
$value = sprintf("%.0f", $value);
$value = sprintf("%X", $value);
$i2c_devices{"INA233"}->write_block([hex(substr($value, 2, 2)), hex(substr($value, 0, 2))], 0xD4); # Data to write, register
# set up devices	(enable accumulator autoclear and latched alert) 
$i2c_devices{"INA233"}->write_block([0x06], 0xD5); # Data to write, register

sleep(1);

# clear the energy accumulator
$i2c_devices{"INA233"}->write(0xD6); # Data to write / reg
# chuck this reading (looks bad every time
read_INA233_energy(\%i2c_devices, $max_current);
sleep(1);

print("	Read current chip values\n");
print("		INA233 ",read_INA233_voltage(\%i2c_devices),"V\n");
print("		INA233 ",read_INA233_current(\%i2c_devices, $max_current),"A\n");
print("		INA233 ",read_INA233_power(\%i2c_devices, $max_current),"W instant\n");
print("		INA233 ",read_INA233_energy(\%i2c_devices, $max_current),"W average\n");
for($i = 1; $i <= 8; $i++){
	print("		NCD9830 Vreg".$i." ",read_NCD9830_voltage(\%i2c_devices, $i),"V\n");
}

if(-e $output_file && join(" ",@ARGV) !~ m/-overwrite/i){
	print("Output file found overwrite?\n");
	if(<STDIN> !~ m/y/i){
		exit(-1);
	}
	unlink($output_file);
}

print("Open output file ".$output_file."\n");
open(OUT, ">".$output_file) || die("Unable to open ".$output_file." for write\n");
# set up to flush right away. 
$i = select(OUT); 
$| = 1; 
select($i);
print(OUT "time(s),Vbat(V),Ibat(A),Pbat(W inst),Pbat(W ave),");
for($i = 1; $i <= 8; $i++){
	if($channels =~ m/$i/i){
		print(OUT "Vreg".$i."(V),");
	}
}
print(OUT "\n");


print("Starting data collection on channels ".$channels." every ".$sample_every."s\n");
print("To stop this program run \"touch ".$stop_file."\"\n");
if($stop_time != 0){
	print("Auto stop enabled for ".$stop_time."s \n");
}

$start_time = time();
$time = $start_time;
do{
	print(OUT (time()-$start_time),",");
	print(OUT read_INA233_voltage(\%i2c_devices),",",read_INA233_current(\%i2c_devices, $max_current),",",read_INA233_power(\%i2c_devices, $max_current),",",read_INA233_energy(\%i2c_devices, $max_current),",");
	for($i = 1; $i <= 8; $i++){
		if($channels =~ m/$i/i){
			print(OUT read_NCD9830_voltage(\%i2c_devices, $i),",");
		}
	}
	print(OUT "\n");
	
	while(time() < ($time + $sample_every)){
		# wait for next sample window. 
	}
	$time = time();
	
	if($stop_time != 0 && (time()-$start_time) >= $stop_time){
		$stop = 1;
	}
	

}while(!-e $stop_file && $stop == 0);



print("All done exit now\n");
$pi->cleanup;

exit(0);



#######################################################################################################################################################################
sub read_INA233_power{
	my $i2c_devices = $_[0];
	my $max_current = $_[1];
	
	my @bytes = ();
	my $value = 0;

	@bytes = $i2c_devices{"INA233"}->read_block(2, 0x97); # num bytes to read, register address
	#print(join(" ",@bytes),"\n");
	$value = ($bytes[1] << 8) + $bytes[0];
	#print($value," raw\n");
	$value = (1/(1/(25 * ($max_current/(2**15)))))*($value * (10 ** -0) - 0);  # (1/m)*(Y * 10^-R - b) From data sheet m = 8, Y = value, R = 2, b = 0 for voltage readings) 
	#print($value,"\n");
	$value = sprintf("%.5f", $value); 			# round off
	#print($value,"\n");

	return($value);
} # end sub read_INA233_current()

#######################################################################################################################################################################
sub read_INA233_energy{
	my $i2c_devices = $_[0];
	my $max_current = $_[1];
	
	my @bytes = ();
	my $value = 0;
	my $samples = 0;

	@bytes = $i2c_devices{"INA233"}->read_block(7, 0x86); # num bytes to read, register address
	#print(join(" ",@bytes),"\n");
	if($bytes[3] == 255){
		print("Error energy accumulator overflow detected. Adjust sample freq and try again\n");
		$value = 0;
	}else{
		# create 24 bit value. 
		$value = ($bytes[3] * 2**16) + ($bytes[2] << 8) + $bytes[1];
	}
	#print($value," raw value\n");
	
	$samples = ($bytes[6] << 16) + ($bytes[5] << 8) + $bytes[4];
	#print($samples," samples\n");

	if($samples == 0){
		$value = 0;
	}else{
		$value = $value/$samples;
	}
	#print($value," ave\n");
	
	$value = (1/(1/(25 * ($max_current/(2**15)))))*($value * (10 ** -0) - 0);  # (1/m)*(Y * 10^-R - b) From data sheet m = 8, Y = value, R = 2, b = 0 for voltage readings) 
	$value = sprintf("%.5f", $value); 			# round off
	#print($value,"\n");

	return($value);
} # end sub read_INA233_current()

#######################################################################################################################################################################
sub read_INA233_current{
	my $i2c_devices = $_[0];
	my $max_current = $_[1];
	
	my @bytes = ();
	my $value = 0;

	@bytes = $i2c_devices{"INA233"}->read_block(2, 0x89); # num bytes to read, register address
	#print(join(" ",@bytes),"\n");
	$value = ($bytes[1] << 8) + $bytes[0];
	#print($value," raw\n");
	$value = (1/(1/($max_current/(2**15))))*($value * (10 ** -0) - 0);  # (1/m)*(Y * 10^-R - b) From data sheet m = 8, Y = value, R = 2, b = 0 for voltage readings) 
	$value = sprintf("%.5f", $value); 			# round off

	return($value);
} # end sub read_INA233_current()

#######################################################################################################################################################################
sub read_INA233_voltage{
	my $i2c_devices = $_[0];
	
	my @bytes = ();
	my $value = 0;

	@bytes = $i2c_devices{"INA233"}->read_block(2, 0x88); # num bytes to read, register address
	#print(join(" ",@bytes),"\n");
	$value = ($bytes[1] << 8) + $bytes[0];
	#print($value," raw\n");
	$value = (1/8)*($value * (10 ** -2) - 0);  # (1/m)*(Y * 10^-R - b) From data sheet m = 8, Y = value, R = 2, b = 0 for voltage readings) 
	$value = sprintf("%.3f", $value); 			# round off

	return($value);
} # end sub read_INA233_voltage()

#######################################################################################################################################################################
sub read_NCD9830_voltage{
	my $i2c_devices = $_[0];
	my $channel = $_[1];
	
	my $value = 0;

	# select channel and enable IR and ADC
	# note channel input is Vreg #(counts from 1) ADC counts from 0 
	if($channel == 1){
		$i2c_devices{"NCD9830"}->write(0x8C); # Data to write
	}elsif($channel == 2){
		$i2c_devices{"NCD9830"}->write(0xCC); # Data to write
	}elsif($channel == 3){
		$i2c_devices{"NCD9830"}->write(0x9C); # Data to write
	}elsif($channel == 4){
		$i2c_devices{"NCD9830"}->write(0xDC); # Data to write
	}elsif($channel == 5){
		$i2c_devices{"NCD9830"}->write(0xAC); # Data to write
	}elsif($channel == 6){
		$i2c_devices{"NCD9830"}->write(0xEC); # Data to write
	}elsif($channel == 7){
		$i2c_devices{"NCD9830"}->write(0xBC); # Data to write
	}elsif($channel == 8){
		$i2c_devices{"NCD9830"}->write(0xFC); # Data to write
	}else{
		print("ERROR detected channel ".$channel." is invalid using channel 1 instead.\n");
		$i2c_devices{"NCD9830"}->write(0x8C); # Data to write
	}
	
	
	$value = $i2c_devices{"NCD9830"}->read(); # read byte no addressing
	#print($value," raw\n");
	$value = $value * (2.5/255);
	
	if($channel == 1 || $channel == 2 || $channel == 3){
			$value = ($value/100)*(100+60);
	}elsif($channel == 4 || $channel == 5 || $channel == 6){
			$value = ($value/100)*(100+140);
	}elsif($channel == 7 || $channel == 8){
			$value = ($value/100)*(100+500);
	}else{
		# error case use channel 1
		$value = ($value/100)*(100+60);
	}
	$value = sprintf("%.2f", $value); 			# round off

	return($value);
} # end sub read_INA233_voltage()


	
