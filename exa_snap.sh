#!/bin/bash

filesystems=(testfs) ## File Systems to Snapshot
retention=4 ## Days

for f in ${filesystems[@]}
do
	existing_snaps=$(iml snapshot list ${f} | grep ${f} | wc -l)
	echo "$(date +%Y%m%d_%H%M%S) ${existing_snaps} currently exist for ${f} (prior to run)" >> /var/log/exa_snap/snapshot.log
	if [ ${existing_snaps} -lt ${retention} ]; then
		echo "$(date +%Y%m%d_%H%M%S) Creating snapshot for ${f}" >> /var/log/exa_snap/snapshot.log
		iml snapshot create ${f} ${f}_$(date +%Y%m%d_%H%M)
		if [ $? -eq 0 ]; then
			echo "$(date +%Y%m%d_%H%M%S) Snapshot created, exiting run" >> /var/log/exa_snap/snapshot.log
		else
			echo "$(date +%Y%m%d_%H%M%S) Error creating snapshot" >> /var/log/exa_snap/snapshot.log
		fi
	else
		echo "$(date +%Y%m%d_%H%M%S) Creating snapshot for ${f}" >> /var/log/exa_snap/snapshot.log
		iml snapshot create ${f} ${f}_$(date +%Y%m%d_%H%M)
		if [ $? -eq 0 ]; then
                        echo "$(date +%Y%m%d_%H%M%S) Snapshot created" >> /var/log/exa_snap/snapshot.log
                else
                        echo "$(date +%Y%m%d_%H%M%S) Error creating snapshot; aborting run" >> /var/log/exa_snap/snapshot.log
			exit 1
                fi
		to_remove=$((existing_snaps-retention+1))
		echo "$(date +%Y%m%d_%H%M%S) Need to remove ${to_remove} snapshots from the system" >> /var/log/exa_snap/snapshot.log
		remove_names=($(iml snapshot list ${f} | tail -n +4 | awk -v d=${f} '$2 == d {print $0}'| head -n ${to_remove} | awk '{print $4}' | xargs))
		for r in ${remove_names[@]}
		do
			echo "$(date +%Y%m%d_%H%M%S) Removing snapshot ${r} for file system ${f}" >> /var/log/exa_snap/snapshot.log
			iml snapshot destroy ${f} ${r}
			if [ $? -eq 0 ]; then
               		       	echo "$(date +%Y%m%d_%H%M%S) Snapshot destroyed successfully" >> /var/log/exa_snap/snapshot.log
                	else
                        	echo "$(date +%Y%m%d_%H%M%S) Error creating snapshot; aborting run" >> /var/log/exa_snap/snapshot.log
				exit 1
                	fi
		done	
	fi
done
