require 'yaml'
# require 'aws-sdk'
# require "aws-s3"

module Cape
  module Helper

    def stopMachines #Stop all machines in KVM
      domains = `virsh list --name --all`
      domain_list=domains.split(' ')
      domain_list.each do |d|
        system("virsh destroy #{d} &> /dev/null")
      end
    end

    def stopcape
      Chef::Log.info("Stopping cape service")
      system("service cape stop > /dev/null")
      system("service cape-* stop > /dev/null")
      Chef::Log.info("Stopping cape virtual machines")
      cape_conf = File.readlines("/opt/CAPEv2/conf/kvm.conf").select{|l| l.match /label/}
      cape_conf.each do |m|
        machine=m.split("= ").last.delete("\n")
        system("virsh destroy #{machine} &> /dev/null")
      end
      return 1
    end

    def restartLibvirt
      Chef::Log.info("Stopping virtual machines")
      stopMachines
      Chef::Log.info("Restarting Libvirt service")
      system("service libvirtd restart > /dev/null")
    end

    def restartCape
      # Check if there are machines in cape before restart the service
      cape_conf = File.readlines("/opt/CAPEv2/conf/kvm.conf").select{|l| l.match /machines/}.first
      cape_machines = cape_conf.split("=").last.chomp.delete(' ').split(',')

      if cape_machines.length > 0
        stopCape
        Chef::Log.info("Starting cape service")
        system("service cape start > /dev/null")
      else
        Chef::Log.info("No cape machines loaded. Stoping cape service")
        service 'cape' do
          action :stop
        end
      end
    end

    def delMachines

      # Delete machines from other nodes
      # Get all managers
      managers = `/opt/rb/bin/rb_get_managers.rb -l`.split(' ')
      cape_manager =  YAML.load_file("/opt/rb/etc/managers.yml")["cape"].first rescue []
      # Remove cape_manager from the list
      managers -= [cape_manager]
      managers.each do |manager|
        `/opt/rb/bin/rb_manager_ssh.sh #{manager} rm -f /var/lib/libvirt/images/*`
      end

      # Delete unused machines from Cape manager
      if File.exist?('/opt/CAPEv2/conf/kvm.conf')
        # Check if there are machines to delete from cape
        cape_conf = File.readlines("/opt/CAPEv2/conf/kvm.conf").select{|l| l.match /machines/}.first
        cape_machines = cape_conf.split("=").last.chomp.delete(' ').split(',')
        node_machines = []
        node[:redBorder][:cape][:machines].each do |n|
          node_machines << n['name']
        end
        # Compare machines in node with machines in cape config file
        if (cape_machines - node_machines).any? and cape_machines.length > node_machines.length
          deleted_machines = cape_machines - node_machines
          # Remove machines in deleted_machines
          deleted_machines.each do |machine|
            Chef::Log.info("There are cape machines to remove. Trying to stop cape services...")
            #cape_stop = system("rb_service_cape.rb -s")
            cape_stop = stopCape
            if cape_stop
              success = false
              vm_label = `/usr/bin/python2.6 /opt/CAPEv2/utils/machine.py --get label #{machine}`.delete! "\n"
              vm_ip = `/usr/bin/python2.6 /opt/CAPEv2/utils/machine.py --get ip #{machine}`.delete! "\n"
              # Remove from KVM
              Chef::Log.info("VM #{machine} is going to be removed")
              success = system("rb_remove_vm_cape.sh #{vm_label} #{vm_ip}")
              if success
                Chef::Log.info("VM #{machine} removed from cape sandbox successfully")
                # Remove from cape config file
                system("/usr/bin/python2.6 /opt/CAPEv2/utils/machine.py --delete #{machine}")
              else
                Chef::Log.warn("*********************************************************************")
                Chef::Log.warn("[FAIL] Virtual machine not removed successfully. Something went wrong")
                Chef::Log.warn("*********************************************************************")
              end
              if node[:redborder][:cape][:service] == true
                restartCape
              end
            else
              Chef::Log.warn("*********************************************************************")
              Chef::Log.warn("[FAIL] Virtual machine not removed successfully. Something went wrong")
              Chef::Log.warn("Cape can't be stopped now. Timeout!")
              Chef::Log.warn("*********************************************************************")
            end
          end
        end
      end
    end

    def addMachine
      if File.exist?('/opt/CAPEv2/conf/kvm.conf')
        # Check if there are new machines in the node
        cape_conf = File.readlines("/opt/CAPEv2/conf/kvm.conf").select{|l| l.match /machines/}.first
        cape_machines = cape_conf.split("= ").last.chomp.split(', ')

        # If there are machines in the node
        if !node[:redBorder][:cape][:machines].nil?
          node[:redBorder][:cape][:machines].each do |machine|
            # If there is a machine in the node but not in the cape conf
            unless cape_machines.include?("#{machine['name']}")
              Chef::Log.info("New cape machines to submit.")
              destination = "/var/lib/libvirt/images/#{machine['vm_name']}"

              #Check if VM file needs to be downloaded from local S3
              unless File.exist?(destination)
                if machine["local"]
                  Chef::Log.info("Downloading Virtual Machine from local S3.")

                  config_file = "/root/.s3cfg-redborder"
                  s3_path = "s3://redborder/#{machine['s3_path']}"

                  free_space = `df -P -B1 | grep lv_root | awk '{print $4}'`.to_i rescue 0
                  iso_size = `s3cmd -c #{config_file} info #{s3_path} | grep 'File size' | awk '{print $3}'`.to_i rescue free_space
                  

                  if free_space > iso_size
                    system("s3cmd -c #{config_file} get --skip-existing #{s3_path} #{destination}")
                  else
                    Chef::Log.warn("***********************************************************************")
                    Chef::Log.warn("[FAIL] There is not enough space in disk.")
                    Chef::Log.warn("***********************************************************************")
                  end
                else
                  Chef::Log.info("File is not in local S3. Put it manually in #{destination}")
                end
              end

              #Check if VM file exists in server
              if File.exist?(destination)
                Chef::Log.info("Trying to stop cape services...")
                cape_stop = stopCape
                if cape_stop
                  success = false
                  finish = false
                  Chef::Log.info("Creating Virtual Machine #{machine['name']}. This may take some minutes. Please be patient...")
                  success = system("rb_submit_vm_cape.sh #{destination} #{machine['name']} #{machine['ip']}")
                  if success
                    # Submit VM in cape sandbox
                    finish = system("/usr/bin/python2.6 /opt/CAPEv2/utils/machine.py --add --label #{machine['name']} --ip #{machine['ip']} --platform windows --interface virbr0 #{machine['name']}")
                    if finish
                      Chef::Log::info("VM #{machine['name']} submited to cape sandbox successfully")
                    else
                      Chef::Log.warn("***********************************************************************")
                      Chef::Log.warn("[FAIL] Virtual machine not submitted successfully. Something went wrong")
                      Chef::Log.warn("***********************************************************************")
                      system("rb_remove_vm_cape.sh #{machine['name']} #{machine['ip']}")
                    end
                  else
                    Chef::Log.warn("***********************************************************************")
                    Chef::Log.warn("[FAIL] Virtual machine not submitted successfully. Something went wrong")
                    Chef::Log.warn("***********************************************************************")
                  end
                  if node[:redborder][:cape][:service] == true
                    restartCape
                  end
                else
                  Chef::Log.warn("***********************************************************************")
                  Chef::Log.warn("[FAIL] Virtual machine not submitted successfully. Something went wrong")
                  Chef::Log.warn("Cape can't be stopped now. Timeout!")
                  Chef::Log.warn("***********************************************************************")
                end
              else
                Chef::Log.warn("***********************************************************************")
                Chef::Log.warn("[FAIL] Virtual machine not submitted successfully. VM file not found   ")
                Chef::Log.warn("***********************************************************************")
              end
            end
          end
        end
      end
    end

  end
end