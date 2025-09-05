# Cookbook:: cape
# Provider:: config

include Cape::Helper

action :add do
  begin

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
