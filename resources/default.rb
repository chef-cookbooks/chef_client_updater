#
# Cookbook:: chef_client_updater
# Resource:: updater
#
# Copyright:: 2016-2018, Will Jordan
# Copyright:: 2016-2018, Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# NOTE: this cookbook uses Chef-11 backwards compatible syntax to support
# upgrades from Chef 11.x and this pattern should not be copied for any modern
# cookbook.  This is a poor example cookbook of how to write Chef.

provides :chef_client_updater

actions [:update]
default_action :update

attribute :channel, kind_of: [String, Symbol], default: :stable
attribute :prevent_downgrade, kind_of: [TrueClass, FalseClass], default: false
attribute :version, kind_of: [String, Symbol], default: :latest
attribute :post_install_action, kind_of: String, default: 'kill'
attribute :exec_command, kind_of: String, default: $PROGRAM_NAME.split(' ').first
attribute :exec_args, kind_of: Array, default: ARGV
attribute :download_url_override, kind_of: String
attribute :checksum, kind_of: String
attribute :upgrade_delay, kind_of: Integer, default: 30
attribute :product_name, kind_of: String, default: 'chef'
