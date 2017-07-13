raise 'This test is only for RHEL 6' unless platform_family?('rhel') && node['platform_version'].to_i == 6

chef_client_updater 'Install latest Chef' do
  version '12.19.36'
  download_url_override 'https://packages.chef.io/files/stable/chef/12.19.36/el/6/chef-12.19.36-1.el6.x86_64.rpm'
  checksum '89e8e6e9aebe95bb31e9514052a8926f61d82067092ca3bc976b0bd223710c81'
  post_install_action 'exec'
end
