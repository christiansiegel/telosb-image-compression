# create the message classes
sh mig-create.sh

# compile the java code
javac *.java

# send image to mote
SerialComm serial@/dev/ttyUSB0:telosb w img/aerial.tiff

# trigger transmission
SerialComm serial@/dev/ttyUSB0:telosb t

# receive image from mote
SerialComm serial@/dev/ttyUSB0:telosb r aerial-received.png
