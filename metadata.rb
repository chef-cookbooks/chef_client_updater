name 'chef_client_updater'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Upgrades chef-client to specified releases'
version '3.8.2'

chef_version '>= 11' if respond_to?(:chef_version) # cookstyle: disable ChefModernize/RespondToInMetadata

%w(amazon centos debian mac_os_x opensuseleap oracle redhat scientific solaris2 suse ubuntu windows aix).each do |os|
  supports os
end

unless defined?(Ridley) # cookstyle: disable ChefModernize/RespondToInMetadata
  source_url 'https://github.com/chef-cookbooks/chef_client_updater' if respond_to?(:source_url) # cookstyle: disable ChefModernize/RespondToInMetadata
  issues_url 'https://github.com/chef-cookbooks/chef_client_updater/issues' if respond_to?(:issues_url) # cookstyle: disable ChefModernize/RespondToInMetadata
end
