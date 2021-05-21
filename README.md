# Lustre Tools
Tools for managing, administering, and/or wrangling Lustre file systems

## Exa Snap
This script will managed the snapshotting of various Lustre file systems that run on DDN's ExaScaler product.  A custom retention of number of snapshots kept can be configured.  Metrics about the snapshot run for shipment to InfluxDB will be added soon.  The script does log by default to /var/log/exa_snap/snapshot.log
