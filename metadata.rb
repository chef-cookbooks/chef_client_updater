name 'chef_client_updater'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Upgrades chef-client to specified releases'
long_description 'Upgrades chef-client to specified releases'
version '1.0.0'

%w(amazon centos debian mac_os_x opensuse opensuseleap oracle redhat scientific solaris suse ubuntu windows aix).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/omnibus_updater'
issues_url 'https://github.com/chef-cookbooks/omnibus_updater/issues'

depends 'compat_resource'

chef_version '>= 12.1' if respond_to?(:chef_version)
