# Services
default[:redborder][:cape][:service] = false
default[:redborder][:cape_api][:service] = false

# Config files
# default[:redborder][:cape][:uploads3] = '/opt/rb/var/cuckoo/modules/reporting/uploads3.py'
# default[:redborder][:cape][:uploadscoreaerospike] = '/opt/rb/var/cuckoo/modules/reporting/uploadscoreaerospike.py'
# default[:redborder][:cape][:hdfs_conf] = '/opt/rb/var/cuckoo/modules/reporting/uploadhdfs.py'
# default[:redborder][:cape][:zookeeper_conf] = '/opt/rb/var/cuckoo/modules/reporting/uploadzookeeper.py'

# Libvirtd performance values
default[:redborder][:cape][:libvirtd_max_clients] = node['cpu']['total'] * 8
default[:redborder][:cape][:libvirtd_max_workers] = default[:redborder][:cape][:libvirtd_max_clients].to_i / 2
default[:redborder][:cape][:libvirtd_min_workers] = node["cpu"]["total"]
default[:redborder][:cape][:libvirtd_max_requests] = default[:redborder][:cape][:libvirtd_max_clients].to_i / 2
default[:redborder][:cape][:libvirtd_max_client_requests] = default[:redborder][:cape][:libvirtd_max_clients].to_i / 4

# Aerospike upload score reporting module
# default[:redborder][:cape][:cape_weight_file] = '/opt/rb/var/rb-sequence-oozie/workflow/cape_loader.yml'
# default[:redborder][:cape][:aerospike_config_file] = '/opt/rb/var/rb-sequence-oozie/conf/aerospike.yml'
# default[:redborder][:cape][:malware_weights_file] = '/opt/rb/var/rb-sequence-oozie/conf/weights.yml'

# Virtual guests Network
default[:redborder][:cape][:interface_ip] = '192.168.122.1'

# Machines
default[:redborder][:cape][:machines] = []

# Cuckoomon optimized
# default[:redborder][:cape][:cuckoomon] = '/opt/rb/var/cuckoo/analyzer/windows/dll/cuckoomon.dll'
