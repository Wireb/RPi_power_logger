# RPi_datalogger.pl
This is the main Perl script for data logging. 
Edit the file in any text editor to configure the following:

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

## Power_data.csv
This is a sample raw CSV file as produced by the above Perl script.

Note only channle 0 was enabled in this sample. If channels 1 - 8 were enabled there would be one more voltage column per enabled channel. 

## Sample_graph.xlsx
Example Microsoft Excel spreadsheet with a graph of the sample data. 




Copyright (c) 2019 Peter Shabino

Permission is hereby granted, free of charge, to any person obtaining a copy of this hardware, software, and associated documentation files 
(the "Product"), to deal in the Product without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Product, and to permit persons to whom the Product is furnished to do so, subject to the 
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Product.

THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
