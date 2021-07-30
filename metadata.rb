name 'chef_client_updater'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Upgrades chef-client to specified releases'
version '3.12.0'

source_url 'https://github.com/chef-cookbooks/chef_client_updater' if respond_to?(:source_url) # cookstyle: disable Chef/Modernize/RespondToInMetadata
issues_url 'https://github.com/chef-cookbooks/chef_client_updater/issues' if respond_to?(:issues_url) # cookstyle: disable Chef/Modernize/RespondToInMetadata

chef_version '>= 12.5' if respond_to?(:chef_version) # cookstyle: disable Chef/Modernize/RespondToInMetadata

%w(amazon centos debian mac_os_x opensuseleap oracle redhat scientific solaris2 suse ubuntu windows aix).each do |os|
  supports os
end
