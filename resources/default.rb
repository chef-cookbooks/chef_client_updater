#
# Cookbook:: chef_client_updater
# Resource:: updater
#
# Copyright:: 2016-2017, Will Jordan
# Copyright:: 2016-2017, Chef Software Inc.
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

provides :chef_client_updater

actions [:update]
default_action :update

attribute :channel, kind_of: [String, Symbol], default: :stable
attribute :prevent_downgrade, kind_of: [TrueClass, FalseClass], default: false
attribute :version, kind_of: [String, Symbol], default: :latest
attribute :post_install_action, kind_of: String, default: 'exec'
attribute :exec_command, kind_of: String, default: $PROGRAM_NAME.split(' ').first
attribute :exec_args, kind_of: Array, default: ARGV
attribute :download_url_override, kind_of: String
attribute :checksum, kind_of: String
