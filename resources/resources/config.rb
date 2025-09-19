# Cookbook:: cape
# Resource:: config

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, kind_of: String, default: 'cape'
attribute :group, kind_of: String, default: 'cape'
attribute :ipaddress_sync, kind_of: String, default: '127.0.0.1'
attribute :cape_interface_ip, kind_of: String, default: '192.168.122.1'
attribute :cape_interface, kind_of: String, default: 'virbr0'
attribute :cape_web_ip, kind_of: String, default: '0.0.0.0'
attribute :cape_web_port, kind_of: Integer, default: 8099
attribute :cape_result_server_ip, kind_of: String, default: '192.168.122.1'
attribute :cape_result_server_port, kind_of: Integer, default: 2042
attribute :cape_min_freespace, kind_of: Integer, default: 15000
