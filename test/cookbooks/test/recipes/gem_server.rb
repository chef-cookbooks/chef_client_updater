# Build a gem server for testing

rubygems_ips = shell_out('dig +short rubygems.org').stdout.split("\n")
deny_rubygems = rubygems_ips.map do |rubygems_ip|
  "ufw deny out from any to #{rubygems_ip}"
end.join("\n")

bash 'local gem server' do
  code <<-EOH
#!/bin/bash -x
pkill -9 gem
apt-get -q -y update
apt-get -q -y install ruby2.3
if [[ -z `/usr/bin/gem list 'mixlib-install'` ]]; then
  /usr/bin/gem install 'mixlib-install'
  /usr/bin/gem install 'mixlib-versioning'
  /usr/bin/gem install 'thor' -v '0.20.0'
fi
/usr/bin/gem server -d /var/lib/gems/2.3.0 2>/dev/null 1>/dev/null </dev/null &
apt-get -q -y install ufw
ufw --force enable
ufw allow ssh
#{deny_rubygems}
  EOH
end

# This step should fail if the firewall rules work
chef_gem 'chef-ruby-lvm' do
  compile_time false
  ignore_failure true
  timeout 15
end
