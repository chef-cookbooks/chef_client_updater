#
# Cookbook:: chef_client_updater
# Attributes:: default
#
# Copyright:: 2016-2020, Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# stable or current channel
default['chef_client_updater']['channel'] = 'stable'

# prevent a newer client "updating" to an older client
default['chef_client_updater']['prevent_downgrade'] = false

# the version to install (ex: '12.12.13') or 'latest'
default['chef_client_updater']['version'] = '19.1.6'

# kill the client post install or exec the client post install for non-service based installs
default['chef_client_updater']['post_install_action'] = Chef::Config[:no_fork] ? 'exec' : 'kill'

# the download URL (for use in an air-gapped environment)
default['chef_client_updater']['download_url_override'] = 'https://chef-hab-migration-tool-bucket.s3.amazonaws.com/rc2_hab_pkg_chef_client/rc2_tar_folder/chef-chef-infra-client-19.1.rc2.tar.gz?AWSAccessKeyId=AKIAW4FPVFT6BIP2EQW7&Signature=Q91HiSIzOxffl52La8EvqSXSqWk%3D&Expires=1756222682'

# the checksum of the package from "download_url_override"
default['chef_client_updater']['checksum'] = nil

# Root installation path for chef-client for when a custom path is used.
# Defaults to 'C:/opscode/chef' on Windows and '/opt/chef' for everything else.
default['chef_client_updater']['chef_install_path'] = nil

# delay for triggering Chef Infra Client upgrade in seconds
default['chef_client_updater']['upgrade_delay'] = nil

# name of the product to upgrade (chef or chefdk)
default['chef_client_updater']['product_name'] = nil

# download URL for Sysinternals handle.zip (Windows only)
default['chef_client_updater']['handle_zip_download_url'] = nil
default['chef_client_updater']['handle_exe_path'] = "#{Chef::Config[:file_cache_path]}/handle.exe"

# The Eventlog service will be restarted immediately prior to cleanup broken chef to release any open file locks.
default['chef_client_updater']['event_log_service_restart'] = true

# Set to 'accept' or 'accept-no-persist' to accept the license. Provided to client execution
# in a backwards compatible way. Use the same attribute from the chef-client cookbook to
# avoid duplication.
default['chef_client']['chef_license'] = nil

# Set this to use internal or custom rubygems server.
# Use the same attribute from the chef-client cookbook to avoid duplication.
# Example "http://localhost:8808/"
default['chef_client_updater']['rubygems_url'] = Chef::Config[:rubygems_url]

# Attributes for Migrate tool
default['chef_client_updater']['migrate_download_url'] = 'https://chef-hab-migration-tool-bucket.s3.amazonaws.com/rc2_hab_pkg_chef_client/rc2_migration_tool/migration-tools_Linux_x86_64.tar.gz?AWSAccessKeyId=AKIAW4FPVFT6BIP2EQW7&Signature=hbgCCCl9r48WHDP%2FFQtNTN9pFJw%3D&Expires=1756222424'
default['chef_client_updater']['license_key'] = 'tmns-65560889-4977-46bf-8a29-5ba93f914ba8-3190'
default['chef_client_updater']['license_server'] = 'https://services.chef.io'
default['chef_client_updater']['preserve'] = false
default['chef_client_updater']['symlink'] = false
default['chef_client_updater']['fstab'] = 'apply'
default['chef_client_updater']['process_config'] = 'error'
default['chef_client']['selinux_profile'] = nil
default['chef_client_updater']['selinux_ignore_warnings'] = false
default['chef_client_updater']['habitat_upgrade'] = nil

# Hook scripts to run before the client update
default['chef_client_updater']['pre_install_script'] = []

# Hook scripts to run after the client update but before post-install action
default['chef_client_updater']['post_install_script'] = []
