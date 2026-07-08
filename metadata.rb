name 'chef_client_updater'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Upgrades chef-client to specified releases'
version '3.14.0'

chef_version '>= 11' # cookstyle: disable ChefModernize/RespondToInMetadata

%w(amazon centos debian mac_os_x opensuseleap oracle redhat scientific solaris2 suse ubuntu windows aix).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/chef_client_updater' # cookstyle: disable ChefModernize/RespondToInMetadata
issues_url 'https://github.com/chef-cookbooks/chef_client_updater/issues'
