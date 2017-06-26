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

use_inline_resources

include Chef::Mixin::ShellOut

provides :chef_client_updater if respond_to?(:provides)

def load_mixlib_install
  gem 'mixlib-install', '~> 3.2', '>= 3.2.1'
  require 'mixlib/install'
rescue LoadError
  Chef::Log.info('mixlib-install gem not found. Installing now')
  chef_gem 'mixlib-install' do
    version '>= 3.2.1'
    compile_time true if respond_to?(:compile_time)
  end

  require 'mixlib/install'
end

def load_mixlib_versioning
  require 'mixlib/versioning'
rescue LoadError
  Chef::Log.info('mixlib-versioning gem not found. Installing now')
  chef_gem 'mixlib-versioning' do
    compile_time true if respond_to?(:compile_time)
  end

  require 'mixlib/versioning'
end

def update_rubygems
  gem_bin = "#{Gem.bindir}/gem"
  raise 'cannot find omnibus install' unless ::File.exist?(gem_bin)

  rubygems_version = Gem::Version.new(shell_out("#{gem_bin} --version").stdout.chomp)
  target_version = '2.6.11'
  return if Gem::Requirement.new(">= #{target_version}").satisfied_by?(rubygems_version)

  converge_by "upgrading rubygems to #{target_version} was #{rubygems_version}" do
    # note that the rubygems that we're upgrading is likely so old that you can't pin a version
    shell_out!("#{gem_bin} update --system --no-rdoc --no-ri")
  end
end

def load_prerequisites!
  update_rubygems
  load_mixlib_install
  load_mixlib_versioning
end

def mixlib_install
  load_mixlib_install
  detected_platform = Mixlib::Install.detect_platform
  options = {
    product_name: 'chef',
    platform_version_compatibility_mode: true,
    platform: detected_platform[:platform],
    platform_version: detected_platform[:platform_version],
    architecture: detected_platform[:architecture],
    channel: new_resource.channel.to_sym,
    product_version: new_resource.version == 'latest' ? :latest : new_resource.version,
  }
  if new_resource.download_url_override && new_resource.checksum
    options[:install_command_options] = { download_url_override: new_resource.download_url_override, checksum: new_resource.checksum }
  end
  Mixlib::Install.new(options)
end

# why would we use this when mixlib-install has a current_version method?
# well mixlib-version parses the manifest JSON, which might not be there.
# ohai handles this better IMO
def current_version
  node['chef_packages']['chef']['version']
end

def desired_version
  new_resource.version.to_sym == :latest ? mixlib_install.available_versions.last : new_resource.version
end

# why wouldn't we use the built in update_available? method in mixlib-install?
# well that would use current_version from mixlib-install and it has no
# concept of preventing downgrades
def update_necessary?
  load_mixlib_versioning
  cur_version = Mixlib::Versioning.parse(current_version)
  # we have to "resolve" partial versions like "12" through mixlib-install before comparing them here
  des_version =
    if new_resource.download_url_override
      # probably in an air-gapped environment.
      Mixlib::Versioning.parse(desired_version)
    else
      Mixlib::Versioning.parse(mixlib_install.artifact_info.version)
    end
  Chef::Log.debug("The current chef-client version is #{cur_version} and the desired version is #{desired_version}")
  new_resource.prevent_downgrade ? (des_version > cur_version) : (des_version != cur_version)
end

def eval_post_install_action
  return unless new_resource.post_install_action == 'exec'

  if Chef::Config[:interval]
    Chef::Log.warn 'post_install_action "exec" not supported for long-running client process -- changing to "kill".'
    new_resource.post_install_action = 'kill'
  end

  return if Process.respond_to?(:exec)
  Chef::Log.warn 'post_install_action Process.exec not available -- changing to "kill".'
  new_resource.post_install_action = 'kill'
end

def run_post_install_action
  # make sure the passed action will actually work
  eval_post_install_action

  case new_resource.post_install_action
  when 'exec'
    if Chef::Config[:local_mode]
      Chef::Log.info 'Shutting down local-mode server.'
      if Chef::Application.respond_to?(:destroy_server_connectivity)
        Chef::Application.destroy_server_connectivity
      elsif defined?(Chef::LocalMode) && Chef::LocalMode.respond_to?(:destroy_server_connectivity)
        Chef::LocalMode.destroy_server_connectivity
      end
    end
    Chef::Log.warn 'Replacing ourselves with the new version of Chef to continue the run.'
    Kernel.exec(new_resource.exec_command, *new_resource.exec_args)
  when 'kill'
    if Chef::Config[:client_fork] && Process.ppid != 1 && !windows?
      Chef::Log.warn 'Chef client is defined for forked runs. Sending TERM to parent process!'
      Process.kill('TERM', Process.ppid)
    end
    Chef::Log.warn 'New chef-client installed. Forcing chef exit!'
    exit(213)
  else
    raise "Unexpected post_install_action behavior: #{new_resource.post_install_action}"
  end
end

def chef_install_dir
  windows? ? 'c:/opscode/chef' : '/opt/chef'
end

def chef_backup_dir
  windows? ? 'c:/opscode/chef.upgrade' : '/opt/chef.upgrade'
end

# cleanup cruft from *prior* runs
def cleanup
  if ::File.exist?(chef_backup_dir) # rubocop:disable Style/GuardClause
    converge_by("removing #{chef_backup_dir}") do
      FileUtils.rm_rf chef_backup_dir
    end
  end
end

def windows?
  platform_family?('windows')
end

# windows does not like having running open files nuked behind it so we have to move the old file
# out of the way.  on both platforms we must clean up the old install to not leave behind any old
# gem files.
#
def move_opt_chef(src, dest)
  converge_by("moving all files under #{src} to #{dest}") do
    FileUtils.rm_rf dest
    raise "rm_rf of #{dest} failed" if ::File.exist?(dest) # detect mountpoints that were not deleted
    FileUtils.mv src, dest
  end
rescue => e
  # this handles mountpoints
  converge_by("caught #{e}, falling back to copying and removing from #{src} to #{dest}") do
    begin
      FileUtils.rm_rf dest
    rescue
      nil
    end # mountpoints can throw EBUSY
    begin
      FileUtils.mkdir dest
    rescue
      nil
    end # mountpoints can throw EBUSY
    FileUtils.cp_r Dir.glob("#{src}/*"), dest
    FileUtils.rm_rf Dir.glob("#{src}/*")
  end
end

def execute_install_script(install_script)
  if windows?
    powershell_script 'name' do
      code <<-EOH
    #{install_script}
      EOH
      action :nothing
    end.run_action(:run)
  else
    upgrade_command = Mixlib::ShellOut.new(install_script)
    upgrade_command.run_command
  end
end

action :update do
  begin
    cleanup

    load_prerequisites!

    if update_necessary?
      converge_by "Upgraded chef-client #{current_version} to #{desired_version}" do
        # we have to get the script from mibxlib-install..
        install_script = mixlib_install.install_command
        # ...before we blow mixlib-install away
        move_opt_chef(chef_install_dir, chef_backup_dir)

        execute_install_script(install_script)
        run_post_install_action
      end
    end
  rescue SystemExit
    raise
  rescue Exception => e # rubocop:disable Lint/RescueException
    if ::File.exist?(chef_backup_dir)
      Chef::Log.warn "CHEF UPGRADE ABORTED due to #{e}: rolling back to #{chef_backup_dir} copy"
      move_opt_chef(chef_backup_dir, chef_install_dir)
    else
      Chef::Log.warn "NO #{chef_backup_dir} DIR TO ROLL BACK TO!"
    end
    raise
  end
end
