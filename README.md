# atHostsFromRapid7DNSRecords

Fetches the most recent list of hosts ending in '.at' for further from the Project Sonar Forward DNS dataset
See https://github.com/rapid7/sonar/wiki/Forward-DNS for details on Project Sonar and the Forward DNS dataset.

This script just automates the search for the most recent dataset.
The download actually happens via curl, zcat, ... called via system() so the 13+ GB gets decompressed and
searched for .at domains/hosts "on the fly".
