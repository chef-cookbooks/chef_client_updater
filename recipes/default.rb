#
# Author:: Tim Smith (<tsmith@chef.io>)
# Cookbook:: chef_client_updater
# Recipe:: default
#
# Copyright:: 2016-2020, Chef Software, Inc.
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

chef_client_updater 'update chef-client' do
  channel node['chef_client_updater']['channel']
  version node['chef_client_updater']['version']
  prevent_downgrade node['chef_client_updater']['prevent_downgrade']
  post_install_action node['chef_client_updater']['post_install_action']
  exec_command node['chef_client_updater']['exec_command'] if node['chef_client_updater']['exec_command']
  download_url_override node['chef_client_updater']['download_url_override'] if node['chef_client_updater']['download_url_override']
  checksum node['chef_client_updater']['checksum'] if node['chef_client_updater']['checksum']
  upgrade_delay node['chef_client_updater']['upgrade_delay'] unless node['chef_client_updater']['upgrade_delay'].nil?
  product_name node['chef_client_updater']['product_name'] if node['chef_client_updater']['product_name']
  handle_zip_download_url node['chef_client_updater']['handle_zip_download_url'] if node['chef_client_updater']['handle_zip_download_url']
  event_log_service_restart node['chef_client_updater']['event_log_service_restart']
  rubygems_url node['chef_client_updater']['rubygems_url'] if node['chef_client_updater']['rubygems_url']
end
