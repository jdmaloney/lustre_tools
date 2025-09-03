# Lustre Tools
Tools for managing, administering, and/or wrangling Lustre file systems

## Exa Snap
This script will managed the snapshotting of various Lustre file systems that run on DDN's ExaScaler product.  A custom retention of number of snapshots kept can be configured.  Metrics about the snapshot run for shipment to InfluxDB will be added soon.  The script does log by default to /var/log/exa_snap/snapshot.log


## Quota
A fairly flexible and extensible quota command for users to use to check their quotas in a given environment with Lustre file systems. This command currently handles user and group based quotas.   

## Lustre Map
A quick script that will map all targets to hosts and pools in Lustre.  There are optional config blocks that allow you to tie pools to tiers (eg. NVME tier or HDD tier) or to certain paths if you allocate different paths to certain pools, eg. the nvme pool maps to /fs0/nvme and the hdd pool maps to /fs0/hdd.
