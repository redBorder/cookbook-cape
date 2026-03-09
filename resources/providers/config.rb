# Cookbook:: cape
# Provider:: config

include Cape::Helper

action :add do
  begin

    user = new_resource.user
    group = new_resource.group
    cape_interface_ip = new_resource.cape_interface_ip
    cape_interface = new_resource.cape_interface
    cape_web_ip = new_resource.cape_web_ip
    cape_web_port = new_resource.cape_web_port
    ipaddress_sync = new_resource.ipaddress_sync
    cape_result_server_ip = new_resource.cape_result_server_ip
    cape_result_server_port = new_resource.cape_result_server_port
    cape_min_freespace = new_resource.cape_min_freespace

    dnf_package 'cape' do
      action :upgrade
    end

    # Packages with specific versions
    {
      'libvirt' => '10.10.0',
      'qemu-kvm' => '17:9.1.0',
      'virt-top' => '1.1.1',
      'virt-viewer' => '11.0',
      'bridge-utils' => '1.7.1',
      'p7zip' => '16.02',
    }.each do |pkg, ver|
      dnf_package pkg do
        version ver
        action :upgrade
      end
    end

    # Packages without version constraint
    %w(virtio-win gcc-c++ make python3-devel).each do |pkg|
      dnf_package pkg do
        action :upgrade
      end
    end

    # If cape services are enabled, also download redborder-malware-pythonpyenv
    dnf_package ['redborder-malware-pythonpyenv'] do
      action :upgrade
    end

    group 'libvirtd' do
      members user
    end

    template '/etc/systemd/system/cape-web.service' do
      cookbook 'cape'
      source 'cape-web.service.erb'
      mode '0644'
      owner 'root'
      group 'root'
      sensitive true
      variables(
        cape_web_ip: cape_web_ip,
        cape_web_port: cape_web_port
      )
      notifies :run, 'execute[daemon-reload]', :delayed
    end

    execute 'daemon-reload' do
      command 'systemctl daemon-reload'
      action :nothing
    end

    %w(
    cape
    cape-rooter
    cape-processor
    cape-web
    ).each do |svc|
      service svc do
        service_name svc
        supports status: true, restart: true, enable: true
        action [:enable, :start]
      end
    end

    group 'pcap' do
      action :create
    end

    group 'pcap' do
      append true
      members [user]
      action :modify
    end

    file '/usr/sbin/tcpdump' do
      group 'pcap'
      action :create
    end

    execute 'config_tcpdump' do
      command 'setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump'
      not_if 'getcap /usr/sbin/tcpdump | grep cap_net_admin'
    end

    # This is done like this because cookbook rb-manager needs to enable crb repo first
    dnf_package 'libvirt-devel' do
      version '10.10.0'
      action :upgrade
    end

    service 'libvirtd' do
      service_name 'libvirtd'
      supports status: true, restart: true, enable: true
      action [:enable, :start]
    end

    cape_dirs = %w(logs tmp static)

    cape_dirs.each do |dirs|
      directory "/opt/CAPEv2/#{dirs}" do
        owner user
        group group
        mode '0755'
      end
    end

    directory '/usr/lib/cape' do
      owner user
      group group
      mode '0755'
    end

    config_files = %w(api cuckoo cuckoomx integrations mitmdump proxmox virtualbox vsphere
    auxiliary distributed multi qemu vmware web
    aws esx logging physical reporting vmwarerest xenserver
    az externalservices malheur polarproxy routing vmwareserver
    hosts memory processing smtp_sinkhole vpn)

    config_files.each do |config|
      template "/opt/CAPEv2/conf/#{config}.conf" do
        cookbook 'cape'
        source "#{config}.conf.erb"
        mode '0644'
        owner 'root'
        group 'root'
        sensitive true
        variables(
          interface_ip: cape_interface_ip,
          interface: cape_interface,
          cape_web_ip: cape_web_ip,
          cape_web_port: cape_web_port,
          cape_result_server_ip: cape_result_server_ip,
          cape_result_server_port: cape_result_server_port,
          cape_min_freespace: cape_min_freespace,
          ipaddress_syne: ipaddress_sync
        )
        notifies :restart, 'service[cape]', :delayed
        notifies :restart, 'service[cape-processor]', :delayed
        notifies :restart, 'service[cape-rooter]', :delayed
        notifies :restart, 'service[cape-web]', :delayed
      end
    end

    template 'opt/CAPEv2/conf/kvm.conf' do
      cookbook 'cape'
      source 'kvm.conf.erb'
      mode '0644'
      owner 'root'
      group 'root'
      sensitive true
      action :create_if_missing
      notifies :restart, 'service[cape]', :delayed
      notifies :restart, 'service[cape-processor]', :delayed
      notifies :restart, 'service[cape-rooter]', :delayed
      notifies :restart, 'service[cape-web]', :delayed
    end

    template '/etc/libvirt/libvirtd.conf' do
      cookbook 'cape'
      source 'libvirtd.conf.erb'
      mode '0644'
      owner 'root'
      group 'root'
      sensitive true
      variables(
        libvirtd_max_clients: node['redborder']['cape']['libvirtd_max_clients'],
        libvirtd_max_workers: node['redborder']['cape']['libvirtd_max_workers'],
        libvirtd_min_workers: node['redborder']['cape']['libvirtd_min_workers'],
        libvirtd_max_requests: node['redborder']['cape']['libvirtd_max_requests'],
        libvirtd_max_client_requests: node['redborder']['cape']['libvirtd_max_client_requests']
      )
      notifies :restart, 'service[libvirtd]', :delayed
    end

    template '/etc/libvirt/network.conf' do
      cookbook 'cape'
      source 'network.conf.erb'
      mode '0644'
      owner 'root'
      group 'root'
      sensitive true
    end

    Chef::Log.info('Cape cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin

    %w(
    cape
    cape-rooter
    cape-processor
    cape-web
    ).each do |svc|
      service svc do
        service_name svc
        action [:stop, :disable]
        ignore_failure true
      end
    end

    execute 'daemon-reload' do
      command 'systemctl daemon-reload'
      action :nothing
    end

    dnf_package 'cape' do
      action :remove
    end

    directory '/opt/CAPEv2' do
      recursive true
      action :delete
    end

    directory '/usr/lib/cape' do
      recursive true
      action :delete
    end

    Chef::Log.info('Cape cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    ipaddress_sync = new_resource.ipaddress_sync
    cape_web_port = new_resource.cape_web_port

    service_names = %w(cape-rooter cape-processor cape cape-web)

    service_names.each do |service_name|
      next if node['cape'][service_name]['registered']

      query = {}
      query['ID'] = "#{service_name}-#{node['hostname']}"
      query['Name'] = service_name
      query['Address'] = ipaddress_sync

      query['Port'] = cape_web_port if service_name == 'cape-web'

      json_query = Chef::JSONCompat.to_json(query)

      execute "Register #{service_name} in consul" do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['cape'][service_name]['registered'] = true
      Chef::Log.info("#{service_name} service has been registered in consul")
    end
  rescue => e
    Chef::Log.error("Error registering CAPE services: #{e.message}")
  end
end

action :deregister do
  begin
    service_names = %w(cape-rooter cape-processor cape cape-web)

    service_names.each do |service_name|
      next unless node['cape'][service_name]['registered']

      execute "Deregister #{service_name} from consul" do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/#{service_name}-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['cape'][service_name]['registered'] = false
      Chef::Log.info("#{service_name} service has been deregistered from consul")
    end
  rescue => e
    Chef::Log.error("Error deregistering CAPE services: #{e.message}")
  end
end
