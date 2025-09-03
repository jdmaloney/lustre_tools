#!/bin/bash

## Command to map targets to hosts/tiers/paths, run from any client

echo "Building Lustre FS Mappings, please wait"
echo ""
tfile=$(mktemp /tmp/lustre_map.XXXXXX)
tfile2=$(mktemp /tmp/lustre_map.XXXXXX)
tfile3=$(mktemp /tmp/lustre_map.XXXXXX)

## MDTS
lfs df --mdt > ${tfile}
for m in $(ls /proc/fs/lustre/mdc | cut -d'-' -f 1-2 | sort -u); do
        m_index=$(grep ${m} ${tfile} | cut -d'[' -f 2 | cut -d']' -f 1 | head -n 1)
        m_ip=$(cat /proc/fs/lustre/mdc/${m}*/import | grep connects | grep -v never | head -n 1 | awk '{print $1}' | cut -d'"' -f 2 | cut -d '@' -f 1)
        m_host=$(nslookup ${m_ip} | grep name | awk '{print $4}' | cut -d'.' -f 1)
        m_fs=$(echo $m | cut -d'-' -f 1)
        ## Optional FS to path mapping
        if [ ${m_fs} == "fs0" ]; then
                m_fs="/my_fs_mountpoint"
        elif [ ${m_fs} == "fs1" ]; then
                m_fs="/my_otherfs_mountpoint"
        else
                mfs=${m_fs}
        fi
        echo "${m_fs},${m_host},${m},${m_index},metadata" >> "${tfile2}"
done

## OSTS
lfs df --ost > ${tfile}
for f in $(ls /proc/fs/lustre/osc | cut -d'-' -f 1 | sort -u); do
        for p in $(lctl pool_list ${f} | tail -n +2 | cut -d'.' -f 2); do
                lctl pool_list ${f}.${p} | cut -d'_' -f 1 | tail -n +2 | awk -v p=${p} '{print p","$1}' >> "${tfile3}"
        done
done
for o in $(ls /proc/fs/lustre/osc | cut -d'-' -f 1-2 | sort -u); do
        o_index=$(grep ${o} ${tfile} | cut -d'[' -f 2 | cut -d']' -f 1 | head -n 1)
        o_ip=$(cat /proc/fs/lustre/osc/${o}*/import | grep connects | grep -v never | head -n 1 | awk '{print $1}' | cut -d'"' -f 2 | cut -d '@' -f 1)
        o_host=$(nslookup ${o_ip} | grep name | awk '{print $4}' | cut -d'.' -f 1)
        o_fs=$(echo $o | cut -d'-' -f 1)
        o_pool=$(awk -v o=$o -F ',' '$2 == o {print $1}' "${tfile3}")
        ## Optional pool to path mapping and FS to path mapping
        if [ ${o_fs} == "fs0" ]; then
                o_fs="/my_fs_mountpoint"
                if [ ${o_pool} == "pool_name_0" ]; then
                        o_pool="/path_with_pfl_to_this_pool"
                elif [ ${o_pool} == "pool_name_1" ]; then
                        o_pool="/path_with_pfl_to_this_other_pool"
                elif [ ${o_pool} == "pool_name_2" ]; then
                        o_pool="/path_with_pfl_to_yet_this_pool"
                else
                        o_pool="Path not mapped"
                fi
        fi
        if [ ${o_fs} == "fs1" ]; then
                o_fs="/my_otherfs_mountpoint"
                if [ ${o_pool} == "pool_name_0" ]; then
                        o_pool="HDD Tier"
                elif [ ${o_pool} == "pool_name_1" ]; then
                        o_pool="NVME Tier"
                else
                        o_pool="Tier not mapped"
                fi
        fi
        echo "${o_fs},${o_host},${o},${o_index},${o_pool}" >> "${tfile2}"
done

rm -f ${tfile}
rm -f ${tfile3}

## Print it out
OLDIFS="$IFS"
IFS=$'\n'
while read -r f
do
        echo "Mapping for File System: $f"
        echo ""
        for h in $(awk -v f=$f -F ',' '$1 == f {print $2}' "${tfile2}" | sort -u); do
                echo "${h} Targets"
                while read -r l; do
                        echo ${l} | awk -F ',' '{print "   ["$4"] "$3" -- "$5}'
                done < <(awk -v h=$h -F ',' '$2 == h {print $0}' "${tfile2}")
        done
        echo ""
done < <(cat ${tfile2} | cut -d',' -f 1 | sort -u)
IFS="$OLDIFS"

rm -f ${tfile2}
