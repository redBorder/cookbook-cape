# Services
default['cape']['cape']['registered'] = false
default['cape']['cape-rooter']['registered'] = false
default['cape']['cape-processor']['registered'] = false
default['cape']['cape-web']['registered'] = false

# Libvirtd performance values
default[:redborder][:cape][:libvirtd_max_clients] = node['cpu']['total'] * 8
default[:redborder][:cape][:libvirtd_max_workers] = default[:redborder][:cape][:libvirtd_max_clients].to_i / 2
default[:redborder][:cape][:libvirtd_min_workers] = node["cpu"]["total"]
default[:redborder][:cape][:libvirtd_max_requests] = default[:redborder][:cape][:libvirtd_max_clients].to_i / 2
default[:redborder][:cape][:libvirtd_max_client_requests] = default[:redborder][:cape][:libvirtd_max_clients].to_i / 4

# Machines
default[:redborder][:cape][:machines] = []