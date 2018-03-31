#!/bin/bash

if [ $# -lt 1 ]
then
	echo "Usage: $0 <dlx_assembly_file>.asm"
	exit 1
fi

asmfile=`echo $1 | sed s/[.].*//g`

echo "Cleaning dir..."
rm -f $asmfile.bin*
rm -f $asmfile.list
rm -f *.in
rm -f *.mem

echo "Compiling $asmfile..."
perl utils/dlxasm.pl -o $asmfile.bin -list $asmfile.list -debug $1

#cat $asmfile.bin | hexdump -v -e '/1 "%02X" /1 "%02X" /1 "%02X" /1 "%02X\n"' > $asmfile\_dump.txt
./utils/conv2iram $asmfile.bin > iram.mem
./utils/conv2dram data.in > data.mem
