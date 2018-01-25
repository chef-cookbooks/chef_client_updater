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

use_inline_resources

include Chef::Mixin::ShellOut

provides :chef_client_updater if respond_to?(:provides)

def load_mixlib_install
  gem 'mixlib-install', '~> 3.9'
  require 'mixlib/install'
rescue LoadError
  Chef::Log.info('mixlib-install gem not found. Installing now')
  chef_gem 'mixlib-install' do
    version '~> 3.9'
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
  if !::File.exist?(gem_bin) && windows?
    gem_bin = "#{Gem.bindir}/gem.cmd" # on Chef Client 13+ the rubygem executable is gem.cmd, not gem
  end
  raise 'cannot find omnibus install' unless ::File.exist?(gem_bin)

  rubygems_version = Gem::Version.new(shell_out("#{gem_bin} --version").stdout.chomp)
  target_version = '2.6.11'
  Chef::Log.debug("Found gem version #{rubygems_version}. Desired version is at least #{target_version}")
  return if Gem::Requirement.new(">= #{target_version}").satisfied_by?(rubygems_version)

  converge_by "upgrade rubygems #{rubygems_version} to latest" do
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
  Chef::Log.debug("Platform detected as #{detected_platform} by mixlib_install")
  options = {
    product_name: new_resource.product_name,
    platform_version_compatibility_mode: true,
    platform: detected_platform[:platform],
    platform_version: detected_platform[:platform_version],
    architecture: detected_platform[:architecture],
    channel: new_resource.channel.to_sym,
    product_version: new_resource.version == 'latest' ? :latest : new_resource.version,
  }
  if new_resource.download_url_override
    raise('Using download_url_override in the chef_client_updater resource requires also setting checksum property!') unless new_resource.checksum
    Chef::Log.debug("Passing download_url_override of #{new_resource.download_url_override} and checksum of #{new_resource.checksum} to mixlib_install")
    options[:install_command_options] = { download_url_override: new_resource.download_url_override, checksum: new_resource.checksum }
  end
  Chef::Log.debug("Passing options to mixlib-install: #{options}")
  Mixlib::Install.new(options)
end

# why would we use this when mixlib-install has a current_version method?
# well mixlib-version parses the manifest JSON, which might not be there.
# ohai handles this better IMO
# @return String
def current_version
  node['chef_packages']['chef']['version']
end

# the version we WANT TO INSTALL. If the user specifies a version in X.Y.X format
# we use that without looking it up. If :latest or a non-X.Y.Z format version we
# look it up with mixlib-install to determine the latest version matching the request
# @return Mixlib::Versioning::Format::PartialSemVer
def desired_version
  if new_resource.version.to_sym == :latest # we need to find what :latest really means
    version = Mixlib::Versioning.parse(mixlib_install.available_versions.last)
    Chef::Log.debug("User specified version of :latest. Looking up using mixlib-install. Value maps to #{version}.")
  elsif new_resource.download_url_override # probably in an air-gapped environment.
    version = Mixlib::Versioning.parse(new_resource.version)
    Chef::Log.debug("download_url_override specified. Using specified version of #{version}")
  elsif new_resource.version.split('.').count == 3 # X.Y.Z version format given
    Chef::Log.debug("User specified version of #{new_resource.version}. No need check this against Chef servers.")
    version = Mixlib::Versioning.parse(new_resource.version)
  else # lookup their shortened version to find the X.Y.Z version
    version = Mixlib::Versioning.parse(Array(mixlib_install.artifact_info).first.version)
    Chef::Log.debug("User specified version of #{new_resource.version}. Looking up using mixlib-install as this is not X.Y.Z format. Value maps to #{version}.")
  end
  version
end

# why wouldn't we use the built in update_available? method in mixlib-install?
# well that would use current_version from mixlib-install and it has no
# concept of preventing downgrades
def update_necessary?
  load_mixlib_versioning
  cur_version = Mixlib::Versioning.parse(current_version)
  des_version = desired_version

  Chef::Log.debug("The current chef-client version is #{cur_version} and the desired version is #{des_version}")
  necessary = new_resource.prevent_downgrade ? (des_version > cur_version) : (des_version != cur_version)
  Chef::Log.debug("A chef-client upgrade #{necessary == true ? 'is' : "isn't"} necessary")
  necessary
end

def eval_post_install_action
  return unless new_resource.post_install_action == 'exec'

  if Chef::Config[:interval] || Chef::Config[:client_fork]
    Chef::Log.warn 'post_install_action "exec" not supported for chef-client running forked -- changing to "kill".'
    new_resource.post_install_action = 'kill'
  end

  return unless windows?

  Chef::Log.warn 'forcing "exec" to "kill" on windows.'
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
    Chef::Log.warn 'Replacing chef-client process with upgraded version and re-running.'
    Kernel.exec(new_resource.exec_command, *new_resource.exec_args)
  when 'kill'
    if Chef::Config[:client_fork] && Process.ppid != 1 && !windows?
      Chef::Log.warn 'Chef client is running forked with a supervisor. Sending TERM to parent process!'
      Process.kill('TERM', Process.ppid)
    end
    Chef::Log.warn 'New chef-client installed and exit is allowed. Forcing chef exit!'
    exit(213)
  else
    raise "Unexpected post_install_action behavior: #{new_resource.post_install_action}"
  end
end

def chef_install_dir
  node['chef_client_updater']['chef_install_path'] || windows? ? 'c:/opscode/chef' : '/opt/chef'
end

def chef_backup_dir
  "#{chef_install_dir}.upgrade"
end

# cleanup cruft from *prior* runs
def cleanup
  if ::File.exist?(chef_backup_dir) # rubocop:disable Style/GuardClause
    converge_by("remove #{chef_backup_dir} from previous chef-client run") do
      FileUtils.rm_rf chef_backup_dir
    end
  end
end

def windows?
  platform_family?('windows')
end

def copy_opt_chef(src, dest)
  FileUtils.mkdir dest
  FileUtils.cp_r "#{src}/.", dest
rescue
  nil
end

# windows does not like having running open files nuked behind it so we have to move the old file
# out of the way.  on both platforms we must clean up the old install to not leave behind any old
# gem files.
#
def move_opt_chef(src, dest)
  converge_by("move all files under #{src} to #{dest}") do
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

def upgrade_start_time
  shifted_time = Time.now + new_resource.upgrade_delay
  shifted_time.strftime('%H:%M')
end

def prepare_windows
  copy_opt_chef(chef_install_dir, chef_backup_dir)
  Kernel.spawn("c:/windows/system32/schtasks.exe /F /RU SYSTEM /create /sc once /ST \"#{upgrade_start_time}\" /tn Chef_upgrade /tr \"powershell.exe -ExecutionPolicy Bypass c:/opscode/chef_upgrade.ps1\"")
  FileUtils.rm_rf "#{chef_install_dir}/bin/chef-client.bat"
end

def uninstall_ps_code
  uninstall_ps_code = <<-EOH
    function guid_from_regvalue($value) {
      $order = 7,6,5,4,3,2,1,0,11,10,9,8,15,14,13,12,17,16,19,18,21,20,23,22,25,24,27,26,29,28,31,30
      $dash_pos = 8,13,18,23

      $guid = ""
      $order | % {
        $letter = $value.Substring($_,1)
        $guid = "$guid$letter"
        if ($dash_pos -contains $guid.length) {$guid = "$guid-"}
      }
      return $guid
    }

    function installed_remove() {
      $installed_product = (get-item HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Installer\\UpgradeCodes\\C58A706DAFDB80F438DEE2BCD4DCB65C).Property
      $msi_guid = guid_from_regvalue $installed_product

      Start-Process msiexec.exe -Wait -ArgumentList "/x {$msi_guid} /q"
    }

    installed_remove
  EOH

  uninstall_ps_code
end

def execute_install_script(install_script)
  if windows?
    cur_version = Mixlib::Versioning.parse(current_version)
    uninstall_first = if desired_version < cur_version
                        uninstall_ps_code
                      else
                        ''
                      end

    powershell_script 'name' do
      code <<-EOH
        $command = {
          Get-Service chef-client -ErrorAction SilentlyContinue | stop-service

          if ((Get-WmiObject Win32_Process -Filter "name = 'ruby.exe'" | Select-Object CommandLine | select-string 'opscode').count -gt 0) { exit 8 }

          Remove-Item "#{chef_install_dir}" -Recurse -Force

          if (test-path "#{chef_install_dir}") { exit 3 }

          #{uninstall_first}
          #{install_script}

          Remove-Item "c:/opscode/chef_upgrade.ps1"
          c:/windows/system32/schtasks.exe /delete /f /tn Chef_upgrade

          Get-Service chef-client -ErrorAction SilentlyContinue | Start-service
          #{chef_install_dir}/bin/chef-client.bat
        }

        $http_proxy = $env:http_proxy
        $set_proxy = "`$env:http_proxy=`'$http_proxy`'"

        Set-Content -Path c:/opscode/chef_upgrade.ps1 -Value $set_proxy
        Add-Content c:/opscode/chef_upgrade.ps1 "`n$command"

      EOH
      action :nothing
    end.run_action(:run)
  else
    upgrade_command = Mixlib::ShellOut.new(install_script)
    upgrade_command.run_command
    if upgrade_command.exitstatus != 0
      raise "Error updating chef-client. exit code: #{upgrade_command.exitstatus}.\nSTDERR: #{upgrade_command.stderr}\nSTDOUT: #{upgrade_command.stdout}"
    end
  end
end

action :update do
  begin
    load_prerequisites!

    if update_necessary?
      converge_by "upgrade chef-client #{current_version} to #{desired_version}" do
        # we have to get the script from mibxlib-install..
        install_script = mixlib_install.install_command
        # ...before we blow mixlib-install away
        platform_family?('windows') ? prepare_windows : move_opt_chef(chef_install_dir, chef_backup_dir)

        execute_install_script(install_script)
      end
      converge_by 'take post install action' do
        run_post_install_action
      end
    else
      cleanup
    end
  rescue SystemExit
    raise
  rescue Exception => e # rubocop:disable Lint/RescueException
    if ::File.exist?(chef_backup_dir)
      Chef::Log.warn "CHEF UPGRADE ABORTED due to #{e}: rolling back to #{chef_backup_dir} copy"
      move_opt_chef(chef_backup_dir, chef_install_dir) unless platform_family?('windows')
    else
      Chef::Log.warn "NO #{chef_backup_dir} DIR TO ROLL BACK TO!"
    end
    raise
  end
end
