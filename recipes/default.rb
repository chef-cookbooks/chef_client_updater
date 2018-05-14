#
# Author:: Tim Smith (<tsmith@chef.io>)
# Cookbook:: chef_client_updater
# Recipe:: default
#
# Copyright:: 2016-2018, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This resource will download the Handle.exe tool required from the specified
# URL. If in an airgapped environment, you will need to either override the
# ['chef_client_updater']['handle_download_url'] attribute or alternatively
# ensure the executable files are extracted to Chef::Config[:file_cache_path]
remote_file "#{Chef::Config[:file_cache_path]}/handle.zip" do
  source node['chef_client_updater']['handle_download_url']
  action :create
  not_if { ::File.file?("#{Chef::Config[:file_cache_path]}/handle.exe") }
end if platform_family?('windows')

chef_client_updater 'update chef-client' do
  channel node['chef_client_updater']['channel']
  version node['chef_client_updater']['version']
  prevent_downgrade node['chef_client_updater']['prevent_downgrade']
  post_install_action node['chef_client_updater']['post_install_action']
  download_url_override node['chef_client_updater']['download_url_override'] if node['chef_client_updater']['download_url_override']
  checksum node['chef_client_updater']['checksum'] if node['chef_client_updater']['checksum']
  upgrade_delay node['chef_client_updater']['upgrade_delay'] unless node['chef_client_updater']['upgrade_delay'].nil?
  product_name node['chef_client_updater']['product_name'] if node['chef_client_updater']['product_name']
end
