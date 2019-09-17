
if [ .$1 == . ]
then
	echo Usage: bash getPathwaySAOs.sh pathwayName
	exit
fi
if [ ! -e $1 ]
then
	mkdir $1
fi
onSLPs=no
cat *.$1.* | while read name rest
do
	if [ $onSLPs == yes ]
	then
		if [ .$name == . ]
		then
			exit
		fi
		tar -xvzf ../results/*.tgz --wildcards '*.'$name.sao 
		mv *.$name.sao $1
	else
		if [ .$name == .SLPs ]
		then
			onSLPs=yes
		fi
	fi
done

