# Action: 
#	1. Run server processes on the server machine
#	2. ssh into client machines and run the run-machine.sh script

drop_shm
export ROCE=1			# Don't use RoCE on Apt
export APT=0

NUM_SERVERS=2			# Number of server processes on the server machine	
NUM_CLIENT_MACHINES=1	# Number of client machines

rm -rf client-tput		# Re-create a folder for clients to write their stuff into
mkdir client-tput

for i in `seq 1 $NUM_SERVERS`; do
	id=`expr $i - 1`
	sock_port=`expr 5500 + $i - 1`

	if [ $APT -eq 1 ]		# There is only one socket on Apt's r320 nodes
	then
		sudo -E ./main $id $sock_port &
	else
		if [ $ROCE -eq 1 ]	# Susitna's RoCE RNIC is connected to CPU 0
		then
			core=`expr 0 + $id`
			sudo -E numactl --physcpubind $core --interleave 0,1 ./main $id $sock_port &
		else				# Susitna's IB RNIC is connected to CPU 3
			core=`expr 32 + $id`
			sudo -E numactl --physcpubind $core --interleave 4,5 ./main $id $sock_port &
		fi
	fi

	if [ $i -eq 1 ]			# Give the master server plenty of time to setup
	then
		sleep 2
	else
		sleep .1
	fi
done

sleep 100000
