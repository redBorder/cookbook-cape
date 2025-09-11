# Cookbook:: cape
# Provider:: config

include Cape::Helper

action :add do
  begin

    s3_sevice = new_resource.s3_service
    s3_secrets = {}

    begin
      s3_secrets = data_bag_item('passwords', 's3').to_hash
    rescue
      s3_secrets = {}
    end

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

    execute 'enable_crb_repo' do
      command 'dnf config-manager --set-enabled crb'
      not_if 'dnf repolist enabled | grep -q crb'
    end

    dnf_package 'cape' do
      action :upgrade
    end

    dnf_package 'libvirt-devel' do
      action :install
    end

    
    # cape_config 'config' do
    #   action :add
    # end

   

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
        cookbook 'cape'
        source "#{config}.conf.erb"
        mode '0644'
        owner 'root'
        group 'root'
      end
    end

    template '/opt/CAPEv2/conf/cuckoo.conf' do
      cookbook 'cape'
      source 'cuckoo.conf.erb'
      mode '0644'
      owner 'root'
      group 'root'
      variables ({
        :interface_ip => node[:redborder][:cape][:interface_ip]
      })
    end

    template 'opt/CAPEv2/conf/kvm.conf' do
      cookbook 'cape'
      source 'kvm.conf.erb'
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
    #   cookbook 'cape'
    #   source 'uploads3.conf.erb'
    #   mode '0644'
    #   owner 'root'
    #   group 'root'
    #   variables(:key_id => s3_secrets["key_id_malware"],
    #             :key_secret => s3_secrets["key_secret_malware"],
    #             :key_hostname => s3_secrets["hostname"])
    # end

    # template node[:redborder][:cape][:uploadscoreaerospike] do
    #   cookbook 'cape'
    #   source 'uploadscoreaerospike.conf.erb'
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
    #   cookbook 'cape'
    #   source 'uploadhdfs.conf.erb'
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
      cookbook 'cape'
      source 'libvirtd.conf.erb'
      mode '0644'
      owner 'root'
      group 'root'
      variables ({ :libvirtd_max_clients => node[:redborder][:cape][:libvirtd_max_clients], :libvirtd_max_workers => node[:redborder][:cape][:libvirtd_max_workers], :libvirtd_min_workers => node[:redborder][:cape][:libvirtd_min_workers], :libvirtd_max_requests => node[:redborder][:cape][:libvirtd_max_requests], :libvirtd_max_client_requests => node[:redborder][:cape][:libvirtd_max_client_requests]
      })
    end

    template "/etc/libvirt/network.conf" do
      cookbook 'cape'
      source 'network.conf.erb'
      mode '0644'
      owner 'root'
      group 'root'
    end

    # suricata-update.service
    # suricata-update.timer
    %w(
    cape-rooter.service
    cape-processor.service
    cape.service
    cape-web.service
    ).each do |unit|
      cookbook_file "/etc/systemd/system/#{unit}" do
        cookbook 'cape'
        source unit
        owner 'root'
        group 'root'
        mode '0644'
        # notifies :run, 'execute[systemd-daemon-reload]', :immediately
      end
    end

    execute 'copy suricata systemd service files' do
      command 'cp /opt/CAPEv2/systemd/suricata*.service /etc/systemd/system && cp /opt/CAPEv2/systemd/suricate-update.timer /etc/systemd/system'
    end

    # template node[:redborder][:cape][:zookeeper_conf] do
    #   cookbook 'cape'
    #   source 'uploadzookeeper.conf.erb'
    #   mode '0644'
    #   owner 'root'
    #   group 'root'
    # end


    Chef::Log.info('Cape cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    # service 'aerospike' do
    #   service_name 'aerospike'
    #   ignore_failure true
    #   supports status: true, enable: true
    #   action [:stop, :disable]
    # end

    dnf_package 'cape' do
      action :remove
    end


    Chef::Log.info('Cape cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end
