#!/bin/bash
Port=80

function SYNRECV()  { 
	ss -ant | grep -w $Port| grep -c  SYNRECV
}
function ESTAB()    { 
	ss -ant | grep -w $Port| grep -c  ESTAB
} 
function TIMEWAIT() { 
	ss -ant | grep -w $Port| grep -c  TIME-WAIT 
} 
function LISTEN()   { 
	ss -ant | grep -w $Port| grep -c  LISTEN  
} 
$1
