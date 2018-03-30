#
# Author:: Dheeraj Dubey (<dheeraj.dubey@msystechnologies.com>)
# Cookbook::  chef-client_updater
# Library:: helpers
#
# Copyright:: 2012-2018, Dheeraj Dubey
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

require 'chef/mixin/shell_out'

module Opscode
  module ChefClient
    # helper methods for use in chef-client recipe code
    module Helpers
      include Chef::DSL::PlatformIntrospection
      include Chef::Mixin::ShellOut

      def find_chef_client
        if node['platform'] == 'windows'
          existence_check = :exists?
          # Where will also return files that have extensions matching PATHEXT (e.g.
          # *.bat). We don't want the batch file wrapper, but the actual script.
          which = 'set PATHEXT=.exe & where'
          Chef::Log.debug "Using exists? and 'where', since we're on Windows"
        else
          existence_check = :executable?
          which = 'which'
          Chef::Log.debug "Using executable? and 'which' since we're on Linux"
        end

        # try to use the bin provided by the node attribute
        if ::File.send(existence_check, node['chef_client_updater']['bin'])
          Chef::Log.debug 'Using chef-client bin from node attributes'
          node['chef_client_updater']['bin']
        # last ditch search for a bin in PATH
        elsif (chef_in_path = shell_out("#{which} chef-client").stdout.chomp) && ::File.send(existence_check, chef_in_path)
          Chef::Log.debug 'Using chef-client bin from system path'
          chef_in_path
        else
          raise "Could not locate the chef-client bin in any known path. Please set the proper path by overriding the node['chef_client_updater']['bin'] attribute."
        end
      end
    end
  end
end

Chef::DSL::Recipe.send(:include, Opscode::ChefClient::Helpers)
