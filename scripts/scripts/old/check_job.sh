#!/bin/bash

started=false;

while [ "$started" = false ]
do	
	line=$(ssh amda@cedar.calculcanada.ca sq | grep $1); 
	echo $line;
	if ! echo $line | grep -o PD ; then
		started=true;
		play yee.wav;
		notify -i "Cedar" -t "La tache $1 est commencée!";
	else
		echo "sorry dudio pal";
		sleep 100;
	fi
done

	
	
		
