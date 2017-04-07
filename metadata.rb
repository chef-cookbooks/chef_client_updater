name 'chef_client_updater'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Upgrades chef-client to specified releases'
long_description 'Upgrades chef-client to specified releases'
version '1.0.1'

%w(amazon centos debian mac_os_x opensuse opensuseleap oracle redhat scientific solaris suse ubuntu windows aix).each do |os|
  supports os
end

depends 'compat_resource', '>= 12.16.3'

source_url 'https://github.com/chef-cookbooks/chef_client_updater'
issues_url 'https://github.com/chef-cookbooks/chef_client_updater/issues'

chef_version '>= 12.1' if respond_to?(:chef_version)
