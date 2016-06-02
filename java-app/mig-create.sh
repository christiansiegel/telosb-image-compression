#!/bin/sh

mig java -target=telosb -java-classname=SerialDataMsg ../telosb-project/src/Serial/SerialMessages.h SerialDataMsg -o SerialDataMsg.java
mig java -target=telosb -java-classname=SerialCmdMsg  ../telosb-project/src/Serial/SerialMessages.h SerialCmdMsg  -o SerialCmdMsg.java
