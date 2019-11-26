# RPi Power Logger
These files are for my Raspberry Pi Zero based power data logger hat. 
 
License is MIT so do what you want with it just don't litigate me. 

Have had quite a few times where I needed actual run times of various battery powered devices. Built this device to collect both the battery voltage, current, and average power as well as up to 8 other voltage rails.

The simple use case is to put channel 0 in line with your battery powered device. This channel is based on the TI INA233 Bidirectional current and power sensor. It supports up to 36Vin and a wide range of currents depending on your choice for R17 and scaling factor. See the INA233 datasheet for more info. In my case of small battery powered devices I have optimized for a max current of 2A. Note the INA233 is set up for high side sensing and the RPi must be powered externally with a common ground with the circuit under test. Once inserted in the power lines just log into the Pi and start the perl script. It will generate a ./Power_data.csv file with all the readings taken every second until you kill the process. 

More advanced setups can use channels 1 - 8 to monitor internal voltage rails. I use this to see which rail is failing first and if any become unstable when the battery voltage is low. Channels 1 - 3 support up to 4V max, channles 4 - 6 support up to 6V max, and channels 7 and 8 support up to 15V max. Note all channels are on a common ground reference.

There is configuration variables in the Perl script for which channels to sample, time between samples, max sample time, and some INA233 configuration. (see Raspbian-Perl directory for more info)

## KiCad
This is a KiCad 5.1.4 project. Both the original KiCad logics, PCB files and a xlsx bill of material can be found here as well as a PDF file of the logics and a top side image of the PCB.   

## Raspbian-Perl
This is the perl script I use to collect the data on the Raspberry Pi. Sample output .csv file of just channel 0 and a processed graph in xlsx format are also included. 


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
