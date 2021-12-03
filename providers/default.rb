#
# Cookbook:: chef_client_updater
# Resource:: updater
#
# Copyright:: 2016-2018, Will Jordan
# Copyright:: 2016-2020, Chef Software Inc.
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
# cookbook. This is a poor example cookbook of how to write Chef Infra code.

include ::ChefClientUpdaterHelper

use_inline_resources # cookstyle: disable ChefDeprecations/UseInlineResourcesDefined

provides :chef_client_updater if respond_to?(:provides) # cookstyle: disable ChefModernize/RespondToProvides

def load_mixlib_install
  gem 'mixlib-install', '~> 3.12'
  require 'mixlib/install'
rescue LoadError
  Chef::Log.info('mixlib-install gem not found. Installing now')
  chef_gem 'mixlib-install' do
    version '~> 3.12'
    compile_time true if respond_to?(:compile_time) # cookstyle: disable ChefModernize/RespondToCompileTime
    if new_resource.rubygems_url
      clear_sources true if respond_to?(:clear_sources)
      if respond_to?(:source)
        source new_resource.rubygems_url
      elsif respond_to?(:options)
        options "--source #{new_resource.rubygems_url}"
      end
    end
  end

  require 'mixlib/install'
end

def load_mixlib_versioning
  require 'mixlib/versioning'
rescue LoadError
  Chef::Log.info('mixlib-versioning gem not found. Installing now')
  chef_gem 'mixlib-versioning' do
    compile_time true if respond_to?(:compile_time) # cookstyle: disable ChefModernize/RespondToCompileTime
    if new_resource.rubygems_url
      clear_sources true if respond_to?(:clear_sources)
      options "--source #{new_resource.rubygems_url}" if respond_to?(:options)
    end
  end

  require 'mixlib/versioning'
end

def update_rubygems
  compatible_rubygems_versions = '>= 2.6.11'
  target_version = '2.7.8' # should be bumped to latest 2.x, but ruby < 2.3.0 support is necessary
  nodoc_rubygems_versions = '>= 3.0'

  rubygems_version = Gem::Version.new(Gem::VERSION)
  Chef::Log.debug("Found gem version #{rubygems_version}. Desired version is #{compatible_rubygems_versions}")
  return if Gem::Requirement.new(compatible_rubygems_versions).satisfied_by?(rubygems_version)

  # only rubygems >= 1.5.2 supports pinning, and we might be coming from older versions
  pin_rubygems_range = '>= 1.5.2'
  pin = Gem::Requirement.new(pin_rubygems_range).satisfied_by?(rubygems_version)

  converge_by "upgrade rubygems #{rubygems_version} to #{pin ? target_version : 'latest'}" do
    if new_resource.rubygems_url
      gem_bin = "#{Gem.bindir}/gem"
      if !::File.exist?(gem_bin) && windows?
        gem_bin = "#{Gem.bindir}/gem.cmd" # on Chef Infra Client 13+ the rubygem executable is gem.cmd, not gem
      end
      raise 'cannot find omnibus install' unless ::File.exist?(gem_bin)
      source = "--clear-sources --source #{new_resource.rubygems_url}"
      if Gem::Requirement.new(nodoc_rubygems_versions).satisfied_by?(rubygems_version)
        shell_out!("#{gem_bin} update --system #{target_version} --no-document #{source}")
      else
        shell_out!("#{gem_bin} update --system #{target_version} --no-rdoc --no-ri #{source}")
      end
    else
      require 'rubygems/commands/update_command'
      args = if Gem::Requirement.new(nodoc_rubygems_versions).satisfied_by?(rubygems_version)
               ['--no-document', '--system' ]
             else
               ['--no-rdoc', '--no-ri', '--system' ]
             end
      args.push(target_version) if pin
      Gem::Commands::UpdateCommand.new.invoke(*args)
    end
  end
end

def load_prerequisites!
  update_rubygems
  load_mixlib_install
  load_mixlib_versioning
end

# why would we use this when mixlib-install has a current_version method?
# well mixlib-version parses the manifest JSON, which might not be there.
# ohai handles this better IMO
# @return String with the version details
# @return nil when product is not installed
#
def current_version
  case new_resource.product_name
  when 'chef', 'angrychef', 'cinc', 'angrycinc'
    node['chef_packages']['chef']['version']
  when 'chefdk'
    versions = Mixlib::ShellOut.new('chef -v').run_command.stdout # cookstyle: disable ChefModernize/ShellOutHelper
    # There is a verbiage change in newer version of Chef Infra
    version = versions.match(/(ChefDK Version(.)*:)\s*([\d.]+)/i) || versions.match(/(Chef Development Kit Version(.)*:)\s*([\d.]+)/i)

    return version[-1].to_s.strip if version
  end
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
  cur_version = current_version
  des_version = desired_version
  if cur_version.nil?
    Chef::Log.debug("#{new_resource.product_name} is not installed. Proceeding with installing its #{des_version} version.")
    true
  else
    cur_version = Mixlib::Versioning.parse(current_version)
    Chef::Log.debug("The current #{new_resource.product_name} version is #{cur_version} and the desired version is #{des_version}")
    necessary = new_resource.prevent_downgrade ? (des_version > cur_version) : (des_version != cur_version)
    Chef::Log.debug("A Chef Infra Client upgrade #{necessary ? 'is' : "isn't"} necessary")
    necessary
  end
end

def eval_post_install_action
  return unless new_resource.post_install_action == 'exec'

  if Chef::Config[:interval] || Chef::Config[:client_fork]
    Chef::Log.warn 'post_install_action "exec" not supported for Chef Infra Client running forked -- changing to "kill".'
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
    env = {}
    unless node['chef_client']['chef_license'].nil?
      env['CHEF_LICENSE'] = node['chef_client']['chef_license']
    end
    Kernel.exec(env, new_resource.exec_command, *new_resource.exec_args)
  when 'kill'
    if Chef::Config[:client_fork] && Process.ppid != 1 && !windows?
      Chef::Log.warn 'Chef Infra Client is running forked with a supervisor. Sending KILL to parent process!'
      Process.kill('KILL', Process.ppid)
    end
    Chef::Log.warn 'New Chef Infra Client installed and client process exit is allowed and/or specified. Now forcing Chef Infra Client to exit. Disregard any failure messages.'
    exit(213)
  else
    raise "Unexpected post_install_action behavior: #{new_resource.post_install_action}"
  end
end

def chef_install_dir
  node['chef_client_updater']['chef_install_path'] || (windows? ? 'c:/opscode/chef' : '/opt/chef')
end

def chef_backup_dir
  "#{chef_install_dir}.upgrade"
end

def chef_broken_dir
  "#{chef_install_dir}.broken"
end

def chef_upgrade_log
  "#{chef_install_dir}_upgrade.log"
end

# cleanup cruft from *prior* runs
def cleanup
  if ::File.exist?(chef_backup_dir)
    converge_by("remove #{chef_backup_dir} from previous Chef Infra Client run") do
      FileUtils.rm_rf chef_backup_dir
    end
  end
  if ::File.exist?(chef_upgrade_log)
    converge_by("remove #{chef_upgrade_log} from previous Chef Infra Client run") do
      FileUtils.rm_rf chef_upgrade_log
    end
  end
  if ::File.exist?(chef_broken_dir) && new_resource.event_log_service_restart
    converge_by("remove #{chef_broken_dir} from previous Chef Infra Client run") do
      event_log_ps_code
      FileUtils.rm_rf chef_broken_dir
    end
  end
  # When running under init this cron job is created after an update
  cron 'chef_client_updater' do
    action :delete
  end unless platform_family?('windows')
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
# out of the way. on both platforms we must clean up the old install to not leave behind any old
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

  remote_file "#{Chef::Config[:file_cache_path]}/handle.zip" do
    source new_resource.handle_zip_download_url
    not_if { ::File.file?(node['chef_client_updater']['handle_exe_path']) }
  end.run_action(:create)

  Kernel.spawn("c:/windows/system32/schtasks.exe /F /RU SYSTEM /create /sc once /ST \"#{upgrade_start_time}\" /tn Chef_upgrade /tr \"powershell.exe -ExecutionPolicy Bypass \"#{chef_install_dir}\"/../chef_upgrade.ps1 2>&1 > #{chef_upgrade_log}\"")
  FileUtils.rm_rf "#{chef_install_dir}/bin/chef-client.bat"
end

def uninstall_ps_code
  <<-EOH
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

      Write-Output "Removing installed product {$msi_guid}"
      Start-Process msiexec.exe -Wait -ArgumentList "/x {$msi_guid} /q"
    }

    installed_remove
  EOH
end

def wait_for_chef_client_or_reschedule_upgrade_task_function
  <<-EOH
  Function WaitForChefClientOrRescheduleUpgradeTask {
    <# Wait for running Chef Infra Client to finish up to n times. If it has not finished after maxcount tries, then reschedule the upgrade task inMinutes minutes in the future and exit.
    #>
    param(
          [Parameter(Mandatory=$false)]
          [Int]$maxcount = 5,
          [Parameter(Mandatory=$false)]
          [Int]$inMinutes = 10
    )

    # Try maxcount times waiting for given process (chef-client) to finish before rescheduling the upgrade task inMinutes into the future
    $count = 0
    $status = (Get-WmiObject Win32_Process -Filter "name = 'ruby.exe'" | Select-Object CommandLine | select-string 'opscode').count
    while ($status -gt 0) {
      $count++
      if ($count -gt $maxcount) {
        Write-Output "Chef Infra Client cannot be upgraded while in use. Rescheduling the upgrade in $inMinutes minutes..."
        RescheduleTask Chef_upgrade $inMinutes
        exit 0
      }
      Write-Output "Chef Infra Client cannot be upgraded while in use - Attempt $count of $maxcount. Sleeping for 60 seconds and retrying..."
      Start-Sleep 60
      $status = (Get-WmiObject Win32_Process -Filter "name = 'ruby.exe'" | Select-Object CommandLine | select-string 'opscode').count
    }
  }
  EOH
end

def reschedule_task_function
  <<-EOH
  Function RescheduleTask {
    <# Reschedule a named scheduled task the given number of minutes in the future
       The named scheduled task is expected to have an existing one-time TimeTrigger (which Chef_upgrade has)
    #>
    param(
          [Parameter(Mandatory=$true)]
          [String]$taskName,
          [Parameter(Mandatory=$true)]
          [Int]$minutes
    )

    $newDateTime = ((Get-Date).AddMinutes($minutes)).ToString("yyyy-MM-ddTHH:mm:ss")
    try
    {
        $task = Get-ScheduledTask -TaskName $taskName -TaskPath '\\'

        # Multiple triggers or types can exist. If the first trigger is not a daily, we'll bail out.
        # This could be made more resilient, but the task is ours to not foul up.
        if (($task.Triggers[0].ToString() -eq "MSFT_TaskDailyTrigger") -or
           ($task.Triggers[0].ToString() -eq "MSFT_TaskTimeTrigger")) {
              $newTrigger = $task.Triggers[0].Clone()
              $newTrigger.StartBoundary = $newDateTime
              $task.Triggers[0].StartBoundary = $newDateTime
        }
        else {
            throw "Error rescheduling $taskname task trigger. Valid trigger not found."
        }
        # Assure this task will run even if the scheduled time is missed
        $newTaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable
        # Updates the scheduled task with new setting and new trigger.
        $task = Set-ScheduledTask -TaskName $taskName -TaskPath '\\' -Settings $newTaskSettings -trigger $task.triggers
    }
    catch {
      $_.Exception.Message
    }
  }
  EOH
end

def open_handle_functions
  <<-EOH
  Function Get-OpenHandle {
    param(
          [Parameter(ValueFromPipelineByPropertyName=$true)]
          $Search
    )
    $handleOutput = &#{node['chef_client_updater']['handle_exe_path']} -accepteula -nobanner -a -u $Search
    $handleOutput | foreach {
      if ($_ -match '^(?<program>\\S*)\\s*pid: (?<pid>\\d*)\\s*type: (?<type>\\S*)\\s*(?<user>\\S*)\\s*(?<handle>\\S*):\\s*(?<file>(\\\\\\\\)|([a-z]:).*)') {
        $matches | select @{n="User";e={$_.user}},@{n="Path";e={$_.file}},@{n="Handle";e={$_.handle}},@{n="Type";e={$_.type}},@{n="HandlePid";e={$_.pid}},@{n="Program";e={$_.program}}
      }
    }
  }

  Function Destroy-Handle {
    param(
          [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
          $Handle,
          [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
          $HandlePid
    )

    $handleOutput = &#{node['chef_client_updater']['handle_exe_path']} -accepteula -nobanner -c $Handle -p $HandlePid -y
    '      Destroyed handle {0} from pid {1}' -f $Handle, $HandlePid | echo
  }

  Function Destroy-OpenChefHandles {
    echo '[*] Destroying open Chef handles.'
    Get-OpenHandle -Search opscode | foreach {
      '  [+] Destroying handle that {0} (pid: {1}) has on {2}' -f $_.Program, $_.HandlePid, $_.Path | echo
      Destroy-Handle -Handle $_.Handle -HandlePid $_.HandlePid
    }
    echo '[*] Completed destroying open Chef handles.'
  }
  EOH
end

# Restart EventLog Service & its dependent services to release lock of files.
def event_log_ps_code
  powershell_script 'EventLog Restart' do
    code <<-EOH
    $windows_kernel_version = (Get-CimInstance -class Win32_OperatingSystem).Version
    if (-Not ($windows_kernel_version.Contains('6.0') -or $windows_kernel_version.Contains('6.1'))) {
      # Get Dependent Services for Eventlog that are running
      $depsvcsrunning = Get-Service -Name 'EventLog' | Select-Object -ExpandProperty DependentServices |
                        Where-Object Status -eq 'Running' | Select-Object -ExpandProperty Name
      # Attempt to preemptively stop Dependent Services
      $depsvcsrunning | ForEach-Object {
        Stop-Service -Name "$_" -Force -ErrorAction SilentlyContinue
      }
      # Stop EventLog Service - First Politely, then Forcibly
      try {
        Stop-Service -Name 'EventLog' -Force -ErrorAction Stop
      } catch {
        $process='svchost.exe'
        $data = Get-CimInstance Win32_Process -Filter "name = '$process'" | Select-Object ProcessId, CommandLine | Where-Object {$_.CommandLine -Match "LocalServiceNetworkRestricted"}
        $data = $data.ProcessId
        Stop-Process -Id $data -Force
        Start-Sleep -Seconds 10
      }
      # Restart EventLog Service, if Not AutoStarted
      $evtlogstate = Get-Service -Name 'EventLog'
      if ($evtlogstate.Status -eq 'Stopped') {
        Start-Service -Name 'EventLog'
      }
      # Restart Dependent Services - if Stopped
      $depsvcsrunning | ForEach-Object {
        $svcstate = Get-Service -Name "$_"
        if ($svcstate.Status -eq 'Stopped') {
          Start-Service -Name "$_" -ErrorAction SilentlyContinue
        }
      }
    }
    EOH
  end
end

def execute_install_script(install_script)
  if windows?
    cur_version = current_version
    cur_version = Mixlib::Versioning.parse(cur_version) if cur_version
    uninstall_first = if !cur_version.nil? && desired_version < cur_version
                        uninstall_ps_code
                      else
                        ''
                      end

    post_action = if new_resource.post_install_action == 'exec'
                    new_resource.exec_command
                  else
                    ''
                  end

    license_provided = node['chef_client']['chef_license'] || ''

    powershell_script 'Chef Infra Client Upgrade Script' do
      code <<-EOH
        $command = {
          $timestamp = Get-Date
          Write-Output "Starting upgrade at $timestamp"

          Get-Service chef-client -ErrorAction SilentlyContinue | stop-service
          Get-Service push-jobs-client -ErrorAction SilentlyContinue | stop-service

          #{reschedule_task_function}
          #{wait_for_chef_client_or_reschedule_upgrade_task_function}

          WaitForChefClientOrRescheduleUpgradeTask

          if (!(Test-Path "#{node['chef_client_updater']['handle_exe_path']}")) {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory("#{Chef::Config[:file_cache_path]}/handle.zip", "#{Chef::Config[:file_cache_path]}")
          }

          #{open_handle_functions}

          if (Test-Path "#{node['chef_client_updater']['handle_exe_path']}") {
            Destroy-OpenChefHandles
          }

          Remove-Item "#{chef_install_dir}" -Recurse -Force

          if (test-path "#{chef_install_dir}") {
            Write-Output "Removing #{chef_install_dir} did not completely succeed."
            Write-Output "It is likely now in a bad state, not even usable as a backup."
            Write-Output "Attempting to move #{chef_install_dir} to #{chef_broken_dir}"
            Move-Item "#{chef_install_dir}" "#{chef_broken_dir}"
          }

          if (test-path "#{chef_install_dir}") {
            Write-Output "#{chef_install_dir} still exists, upgrade will be aborted. Exiting (3)..."
            exit 3
          }

          Write-Output "Attempting to uninstall product"
          #{uninstall_first}

          Write-Output "Running product install script..."
          try {
            #{install_script}
          }
          catch {
            Write-Output "An error occurred while trying to install product"
            Write-Output $_

            # Might need more testing about different ways the installation could fail
            Move-Item "#{chef_backup_dir}" "#{chef_install_dir}"

            exit 100
          }
          Write-Output "Install script finished"

          Remove-Item "#{chef_install_dir}/../chef_upgrade.ps1"
          c:/windows/system32/schtasks.exe /delete /f /tn Chef_upgrade

          if ('#{desired_version}' -ge '15') {

            SET CHEF_LICENSE '#{license_provided}'

            #{chef_install_dir}/embedded/bin/ruby.exe -e "
              begin
                require 'chef/VERSION'
                require 'license_acceptance/acceptor'
                acceptor = LicenseAcceptance::Acceptor.new(provided: '#{license_provided}')
                if acceptor.license_required?('chef', Chef::VERSION)
                  license_id = acceptor.id_from_mixlib('chef')
                  acceptor.check_and_persist(license_id, Chef::VERSION)
                end
              rescue LoadError
                puts 'License acceptance might not be needed !'
              end
            "
          }

          #{post_action}

          Get-Service push-jobs-client -ErrorAction SilentlyContinue | start-service

          $timestamp = Get-Date
          Write-Output "Finished upgrade at $timestamp"
        }

        $http_proxy = $env:http_proxy
        $no_proxy = $env:no_proxy
        $set_proxy = "`$env:http_proxy=`'$http_proxy`'"
        $set_no_proxy = "`$env:no_proxy=`'$no_proxy`'"

        Set-Content -Path "#{chef_install_dir}/../chef_upgrade.ps1" -Value "$set_proxy", "$set_no_proxy"
        Add-Content "#{chef_install_dir}/../chef_upgrade.ps1" "`n$command"

      EOH
      action :nothing
    end.run_action(:run)
  else
    upgrade_command = Mixlib::ShellOut.new(install_script, timeout: new_resource.install_timeout)
    upgrade_command.run_command
    if upgrade_command.exitstatus != 0
      raise "Error updating Chef Infra Client. exit code: #{upgrade_command.exitstatus}.\nSTDERR: #{upgrade_command.stderr}\nSTDOUT: #{upgrade_command.stdout}"
    end
  end
end

def license_acceptance!
  if node['chef_client']['chef_license'].nil?
    Chef::Log.debug 'No license acceptance configuration found, skipping.'
    return
  end

  license_acceptance = shell_out("#{chef_install_dir}/bin/chef-apply -e 'exit 0'", timeout: 60, environment: { 'CHEF_LICENSE' => "#{node['chef_client']['chef_license']}" })

  unless license_acceptance.error?
    Chef::Log.debug 'Successfully accepted license.'
    return
  end

  msg = ['Something went wrong while accepting the license.']
  unless license_acceptance.stdout.empty?
    msg << 'STDOUT:'
    msg << license_acceptance.stdout
  end
  unless license_acceptance.stderr.empty?
    msg << 'STDERR:'
    msg << license_acceptance.stderr
  end
  Chef::Log.warn msg.join("\n")
end

action :update do
  begin
    load_prerequisites!

    if update_necessary?
      converge_by "upgrade #{new_resource.product_name} #{current_version} to #{desired_version}" do
        # we have to get the script from mixlib-install..
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
    # sysvinit won't restart after we exit, potentially use cron to do so
    # either trust the chef-client cookbook's init scripts or the users choice
    if (node['chef_client'] && node['chef_client']['init_style'] == 'init') || node['chef_client_updater']['restart_chef_via_cron']
      Chef::Log.warn 'Chef Infra Client was upgraded, scheduling Chef Infra Client start via cron in 5 minutes'
      cron_time = Time.now + 300
      start_cmd = if platform_family?('aix')
                    '/usr/bin/startsrc -s chef > /dev/console 2>&1'
                  else
                    '/etc/init.d/chef-client start'
                  end

      license_acceptance!

      r = cron 'chef_client_updater' do
        hour cron_time.hour
        minute cron_time.min
        command start_cmd
      end

      r.run_action(:create)
    end

    raise
  rescue Exception => e # rubocop:disable Lint/RescueException
    if ::File.exist?(chef_backup_dir)
      Chef::Log.warn "CHEF INFRA CLIENT UPGRADE ABORTED due to #{e}: rolling back to #{chef_backup_dir} copy"
      move_opt_chef(chef_backup_dir, chef_install_dir) unless platform_family?('windows')
    else
      Chef::Log.warn "NO #{chef_backup_dir} DIR TO ROLL BACK TO!"
    end
    raise
  end
end
