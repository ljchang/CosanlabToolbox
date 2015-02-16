function [byte] = inp(address)

global cogent;

byte = io32(cogent.io.ioObj,address);
