#
# Cookbook::  chef_client_updater
# Attributes:: default
#
# Copyright:: 2016-2018, Chef Software Inc.
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
default['chef_client_updater']['version'] = 'latest'

# kill the client post install or exec the client post install for non-service based installs
default['chef_client_updater']['post_install_action'] = 'kill'

# the download URL (for use in an air-gapped environment)
default['chef_client_updater']['download_url_override'] = nil

# the checksum of the package from "download_url_override"
default['chef_client_updater']['checksum'] = nil

# Root installation path for chef-client for when a custom path is used.
# Defaults to 'C:/opscode/chef' on Windows and '/opt/chef' for everything else.
default['chef_client_updater']['chef_install_path'] = nil

# delay for triggering Chef client upgrade in seconds
default['chef_client_updater']['upgrade_delay'] = nil

# name of the product to upgrade (chef or chefdk)
default['chef_client_updater']['product_name'] = nil
