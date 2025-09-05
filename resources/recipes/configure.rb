#
# Cookbook Name:: cape
# Recipe:: default
#
# Copyright 2025, redborder
#
# All rights reserved - Do Not Redistribute

# Chef::Recipe.include Cape::Helper
extend Cape::Helpers

s3_sevice = new_resource.s3_service
s3_secrets = {}

begin
  s3_secrets = data_bag_item('passwords', 's3').to_hash
rescue
  s3_secrets = {}
end

# cape_config 'config' do
#   action :add
# end

bucket_created_dg = Chef::DataBagItem.load("rBglobal", "malware-bucket") rescue bucket_created_dg =  {}
if !bucket_created_dg["user"].nil? and !bucket_created_dg["user"]["key_id"].nil? and !bucket_created_dg["user"]["key_secret"].nil?
  s3_secrets["key_id_malware"]     = bucket_created_dg["user"]["key_id"]
  s3_secrets["key_secret_malware"] = bucket_created_dg["user"]["key_secret"]
else
  s3_secrets["key_id_malware"]     = s3_secrets["key_id"]
  s3_secrets["key_secret_malware"] = s3_secrets["key_secret"]
end

user "cape"

group "libvirtd" do
  members "cape"
end

# Configure tcpdump
execute 'config_tcpdump' do
  command 'setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump'
end

# link "/opt/rb/var/cape/log" do
#   to "/var/log/cape"
# end

config_files = %w(api cuckoomx integrations mitmdump proxmox virtualbox vsphere
auxiliary distributed multi qemu vmware web
aws esx logging physical reporting vmwarerest xenserver
az externalservices malheur polarproxy routing vmwareserver
hosts memory processing smtp_sinkhole vpn)

config_files.each do |config|
  template "/opt/CAPEv2/conf/#{config}.conf" do
    source "#{config}.erb"
    mode '0644'
    owner 'root'
    group 'root'
  end
end

template '/opt/CAPEv2/conf/cuckoo.conf' do
  source 'cuckoo.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables ({
    :interface_ip => node[:redborder][:cape][:interface_ip]
  })
end

template 'opt/CAPEv2/conf/kvm.conf' do
  source 'kvm.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create_if_missing
end

if node[:redborder][:cape_api][:service] == true
  delMachines
  addMachine
end

# template node[:redborder][:cape][:uploads3] do
#   source 'uploads3.erb'
#   mode '0644'
#   owner 'root'
#   group 'root'
#   variables(:key_id => s3_secrets["key_id_malware"],
#             :key_secret => s3_secrets["key_secret_malware"],
#             :key_hostname => s3_secrets["hostname"])
# end

# template node[:redborder][:cape][:uploadscoreaerospike] do
#   source 'uploadscoreaerospike.erb'
#   mode '0644'
#   owner 'root'
#   group 'root'
#   variables ({
#     :cape_weight_file => node[:redborder][:cape][:cape_weight_file],
#     :aerospike_config_file => node[:redborder][:cape][:aerospike_config_file],
#     :malware_weights_file => node[:redborder][:cape][:malware_weights_file]
#   })
# end

# template node[:redborder][:cape][:hdfs_conf] do
#   source 'uploadhdfs.erb'
#   mode '0644'
#   owner 'root'
#   group 'root'
#   variables ({
#     :hadoop_server => node[:redborder][:cape][:hadoop_server],
#     :hadoop_port => node[:redborder][:cape][:hadoop_port],
#     :hadoop_path => node[:redborder][:cape][:hadoop_path]
#   })
# end

template "/etc/libvirt/libvirtd.conf" do
  source 'libvirtd.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables ({ :libvirtd_max_clients => node[:redborder][:cape][:libvirtd_max_clients], :libvirtd_max_workers => node[:redborder][:cape][:libvirtd_max_workers], :libvirtd_min_workers => node[:redborder][:cape][:libvirtd_min_workers], :libvirtd_max_requests => node[:redborder][:cape][:libvirtd_max_requests], :libvirtd_max_client_requests => node[:redborder][:cape][:libvirtd_max_client_requests]
  })
end

# template node[:redborder][:cape][:zookeeper_conf] do
#   source 'uploadzookeeper.erb'
#   mode '0644'
#   owner 'root'
#   group 'root'
# end
