require 'json'

# Configuration to be applied inside VM
module GuestConfig
  # Extend Hash to create keys dynamically
  class DynamicHash < Hash
    def self.new
      Hash.new { |hash, key| hash[key] = new }
    end

    def self.deep_copy(hash)
      # Marshal.dump throws error: TypeError: can't dump hash with default proc
      JSON.parse(hash.to_json, symbolize_names: true)
    end
  end

  @network = DynamicHash.new

  # CentOS/RHEL 7
  @network[:redhat7][:config_file][:path] = '/etc/sysconfig/network-scripts/ifcfg-eth0'
  @network[:redhat7][:config_file][:content] = <<~'DOC'
    BOOTPROTO=none
    DEFROUTE=yes
    DEVICE=eth0
    DNS1=%<dns1>s
    DNS1=%<dns2>s
    GATEWAY=%<gateway_ip>s
    IPADDR=%<ip>s
    NAME=eth0
    ONBOOT=yes
    PREFIX=%<prefix_length>d
    TYPE=Ethernet
  DOC
  @network[:redhat7][:apply_cmd] = 'sudo systemctl restart network --no-block'

  # RHEL 8
  @network[:redhat8] = DynamicHash.deep_copy(@network[:redhat7])
  @network[:redhat8][:apply_cmd] = 'sudo nmcli con reload && ' \
    '{ nohup sh -c "sudo nmcli con down eth0 && sudo nmcli con up eth0" > /tmp/vagrant-network-apply.log 2>&1 & }'

  # Ubuntu
  @network[:ubuntu][:config_file][:path] = '/etc/netplan/01-netcfg.yaml'
  @network[:ubuntu][:config_file][:content] = <<~'DOC'
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [%<ip>s/%<prefix_length>d]
          gateway4: %<gateway_ip>s
          nameservers:
            addresses: [%<dns1>s, %<dns2>s]
  DOC
  @network[:ubuntu][:apply_cmd] = 'sudo netplan apply &'

  module_function

  def _get_os_symbol(box)
    pattern_to_os_id_map = {
      # Debian
      ubuntu: 'ubuntu',
      # RHEL 7
      centos: 'redhat7',
      rhel7: 'redhat7',
      # RHEL 8
      'almalinux/8': 'redhat8',
      rhel8: 'redhat8',
      rocky8: 'redhat8'
    }
    key = pattern_to_os_id_map.keys.find { |pattern| box.include?(pattern.to_s) }
    pattern_to_os_id_map[key].to_sym
  end

  def get_network_config(target_ip, network_spec, box)
    os_id = _get_os_symbol(box)

    template_values = {
      ip: target_ip,
      prefix_length: network_spec[:vnic][:prefix_length],
      gateway_ip: network_spec[:vnic][:ip],
      dns1: network_spec[:dns][:dns1],
      dns2: network_spec[:dns][:dns2]
    }

    {
      config_file_path: @network[os_id][:config_file][:path],
      config_file_content: format(@network[os_id][:config_file][:content], template_values),
      apply_cmd: @network[os_id][:apply_cmd]
    }
  end
end
