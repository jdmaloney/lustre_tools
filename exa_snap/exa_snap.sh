#!/bin/bash

source /etc/exa_snap.conf

for f in ${filesystems[@]}
do
	existing_snaps=$(/usr/bin/iml snapshot list ${f} | grep ${f} | wc -l)
	echo "$(date +%Y%m%d_%H%M%S) ${existing_snaps} currently exist for ${f} (prior to run)" >> "${log_path}"
	if [ ${existing_snaps} -lt ${retention} ]; then
		echo "$(date +%Y%m%d_%H%M%S) Creating snapshot for ${f}" >> "${log_path}"
		/usr/bin/iml snapshot create ${f} ${f}_$(date +%Y%m%d_%H%M)
		if [ $? -eq 0 ]; then
			echo "$(date +%Y%m%d_%H%M%S) Snapshot created, exiting run" >> "${log_path}"
		else
			echo "$(date +%Y%m%d_%H%M%S) Error creating snapshot" >> "${log_path}"
		fi
	else
		echo "$(date +%Y%m%d_%H%M%S) Creating snapshot for ${f}" >> "${log_path}"
		/usr/bin/iml snapshot create ${f} ${f}_$(date +%Y%m%d_%H%M)
		if [ $? -eq 0 ]; then
                        echo "$(date +%Y%m%d_%H%M%S) Snapshot created" >> "${log_path}"
                else
                        echo "$(date +%Y%m%d_%H%M%S) Error creating snapshot; aborting run" >> "${log_path}"
			exit 1
                fi
		to_remove=$((existing_snaps-retention+1))
		echo "$(date +%Y%m%d_%H%M%S) Need to remove ${to_remove} snapshots from the system" >> "${log_path}"
		remove_names=($(/usr/bin/iml snapshot list ${f} | tail -n +4 | awk -v d=${f} '$2 == d {print $0}'| head -n ${to_remove} | awk '{print $4}' | xargs))
		for r in ${remove_names[@]}
		do
			echo "$(date +%Y%m%d_%H%M%S) Removing snapshot ${r} for file system ${f}" >> "${log_path}"
			/usr/bin/iml snapshot destroy ${f} ${r}
			if [ $? -eq 0 ]; then
               		       	echo "$(date +%Y%m%d_%H%M%S) Snapshot destroyed successfully" >> "${log_path}"
                	else
                        	echo "$(date +%Y%m%d_%H%M%S) Error creating snapshot; aborting run" >> "${log_path}"
				exit 1
                	fi
		done	
	fi
done
