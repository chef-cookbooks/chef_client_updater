# chef_client_updater

![delivery](https://github.com/chef-cookbooks/chef_client_updater/workflows/delivery/badge.svg) [![Cookbook Version](https://img.shields.io/cookbook/v/chef_client_updater.svg)](https://supermarket.chef.io/cookbooks/chef_client_updater)

This cookbook updates the Chef Infra Client

## Requirements

### Platforms

- All platforms with a Chef Infra Client package on downloads.chef.io

### Chef

- Chef 11.6.2+

## Usage

This cookbook provides both a custom resource and a default recipe. The default recipe simply uses the custom resource with a set of attributes. You can add chef_client_updater::default to your run list or use the custom resource in a wrapper cookbook.

### Init System Caveats

When Chef Infra Client runs as a service under a system init daemon such as Sys-V or systemd each Chef Infra Client run forks off from the main chef-client process being managed by the init system. For a Chef Infra Client upgrade to occur, the running Chef Infra Client as well as the parent process must be killed, and a new Chef Infra Client must start using the updated binaries. This cookbook handles killing the chef-client process, but your init system must properly handle starting the service back up. For systemd this can be handled via configuration, and the chef-client cookbook 8.1.1 or later handles this by default. This functionality is not available in sys-v (RHEL 6, AIX, and older platforms).

For systems where the init system will not properly handle starting the service back up automatically (like Sys-V or SRC) this cookbook will attempt to restart the service via a temporary cron job when either of the following conditions are met:

- node['chef_client']['init_style'] == 'init'
- node['chef_client_updater']['restart_chef_via_cron'] == true

### Updating Windows Nodes

On Windows, a one time scheduled task `Chef_upgrade` is created in combination with a PowerShell-based upgrade script and the downloaded [Handle](https://docs.microsoft.com/en-us/sysinternals/downloads/handle) tool. When the Chef_upgrade scheduled task runs, it executes the PowerShell upgrade script, which first determines whether it can successfully stop any existing Chef Infra Client service and associated Ruby processes, since the MSI Installer will fail if there is a running Chef Infra Client service or ruby.exe process. If it cannot it will sleep for one minute and try again up to five times. If after five tries it still hasn't been successful it modifies the `Chef_upgrade` scheduled task to run 10 minutes in the future to try the process again. This eliminates the situation where the scheduled task fails and the Chef Infra Client is no longer configured to run automatically (since the service has been stopped), which in large environments is costly to recover from (requiring reboots of many servers).

Chef does not support installing `chef-client` on windows at a custom location. By default it will install at `c:\opscode`.
Forcing the MSI installer to change the installation directory, will result into premature broken installation.

The PowerShell upgrade script then moves the current installation to a staging directory and that clears the way for the newer installer to run. Any existing file handles to the old installation folder are forcibly removed and the Eventlog service will be restarted immediately prior to the new installation to release any open file locks. After installation, a log file from the upgrade can be found at `c:\opscode\chef_upgrade.log` until the next Chef Infra Client run where it will be cleaned up along with the backup folder. Upon successful installation the `Chef_upgrade` scheduled task is deleted.

On Windows, the recommended `post_install_action` is `exec` instead of `kill` if you intend to run Chef Infra Client periodically. In `chef_client_updater` versions `>= 3.1.0` and `<= 3.2.9`, the updater resource by default started a new Chef Infra Client run after upgrading. Newer versions simply run `chef-client` only if `post_install_action` is set to `exec`. To run a custom other PowerShell command after-upgrade, define `post_install_action` `exec` and define your custom command in `exec_command`

#### Running Chef Infra Client as a Scheduled Task

If you run as a scheduled task, then this will work smoothly. The path to the newly installed Chef Infra Client will be the same and the scheduled task will launch it. Part of this resource's job on the next run is to make sure the staging directory with the older client is removed.

#### Running Chef Infra Client As A Windows Service

If you run Chef Infra Client as a service, things get a tiny bit more complicated. When the new installer runs, the service is removed. This isn't a big deal if you've got the chef-client cookbook set to configure the Windows service. If that is the case, define `post_install_action` `exec` and the Chef-run triggered after the upgrade will take care of installing the service. Alternatively you can migrate to running Chef Infra Client as a scheduled task as described below.

#### Migrating from Running Chef Infra Client as a Windows Service to Running as a Scheduled Task During the Upgrade

If you run Chef Infra Client as a service, but want to upgrade to a version of the client with an MSI unstaller that supports running as a scheduled task (any Chef Infra Client >= 12.18) it is now possible with the `install_command_options` property (added in version 3.8.0 of the chef_client_updater cookbook). This property accepts a Hash of key/value pairs, with {daemon: 'task'} the necessary pair to notify the MSI Installer to install Chef Infra Client as a scheduled task.

### Upgrading from Chef Infra Client 11

Moving from Chef Infra Client 11 has a few challenges when we are dealing with public update sources. Chef Infra Client 11 ships with a very old `cacert.pem`. To work through this, we need to get a more current `cacert.pem` file and point OpenSSL to it. Unfortunately, for this to work consistently on Windows, we'll need to reboot. Chef Infra Client 11 does not have the reboot resource, so this isn't a graceful process. However, on the next Chef run after the reboot, things will be back on track and the upgrade will perform as on other platforms.

Below is an example of a recipe that can set up Chef Infra Client 11 to work using public update sources.

```ruby
if platform_family?('windows') && (Chef::VERSION < '12')
  new_cert_file = File.join(ENV['USERPROFILE'], 'cacert.pem')

  remote_file new_cert_file do
    source 'https://curl.haxx.se/ca/cacert.pem'
    action :create
  end

  powershell_script 'restart' do
    code <<-EOH
    restart-computer -force
    EOH
    action :nothing
  end

  env 'SSL_CERT_FILE' do
    value new_cert_file
    notifies :run, 'powershell_script[restart]', :immediately
  end
end

chef_client_updater 'Install latest Chef' do
  post_install_action 'kill'
end
```

## Chef EULA

Set the `node['chef_client']['chef_license']` attribute to `accept` or `accept-no-persist` to accept the Chef EULA
when upgrading to Chef Infra Client 15 or higher.

## Resources

### chef_client_updater

Installs the mixlib-install/mixlib-install gems and upgrades the Chef Infra Client.

#### properties

- `channel` - The chef channel you fetch the Chef Infra Client from. `stable` contains all officially released Chef Infra Client builds where as `current` contains unreleased builds. Default: `stable`
- `prevent_downgrade` - Don't allow this cookbook to downgrade the Chef Infra Client version. Default: false
- `version` - The version of the Chef Infra Client to install. Default :latest
- `post_install_action` - After installing the Chef Infra Client what should we do. `exec` to exec the new client or `kill` to kill the client and rely on the init system to start up the new version. Default: `kill`
- `exec_command` - The chef-client command. default: $PROGRAM_NAME.split(' ').first. You can also enter a custom post-action command.
- `exec_args` - An array of arguments to exec the Chef Infra Client with. default: ARGV
- `download_url_override` - The direct URL for the Chef Infra Client package.
- `checksum` - The SHA-256 checksum of the Chef Infra Client package from the direct URL.
- `install_timeout` - The install timeout for non-windows systems. The default is 600, slow machines may need to extend this.
- `upgrade_delay` - The delay in seconds before the scheduled task to upgrade Chef Infra Client runs on windows. default: 61. Lowering this limit is not recommended.
- `product_name` - The name of the product to upgrade. This can be `chef` or `chefdk` default: chef
- 'install_command_options' - A Hash of additional options that will be passed to the Mixlib::Install instance responsible for installing the given product_name. To install Chef Infra Client as a scheduled task on windows, one can pass {daemon: 'task'}. Default: {}
- `rubygems_url` - The location to source rubygems. Replaces the default https://www.rubygems.org.
- `handle_zip_download_url` - Url to the Handle zip archive used by Windows. Used to override the default in airgapped environments. default: https://download.sysinternals.com/files/Handle.zip (Note that you can also override the `default['chef_client_updater']['handle_exe_path']` attribute if you already have that binary somewhere on your system)

#### examples

```ruby
chef_client_updater 'Install latest'
```

```ruby
chef_client_updater 'Install latest Chef Infra Client 16.x' do
  version '16'
end
```

```ruby
chef_client_updater 'Install 12.13.36 and kill' do
  version '12.13.36'
  post_install_action 'kill'
end
```

#### Test Kitchen Testing

In order to test this cookbook it will be necessary to change the `post_install_action` to `exec` from `kill`. While `kill` is better in most actual production use cases as it terminates the chef-client run along with cleaning up the parent process, the use of `kill` under test kitchen will fail the chef-client run and fail the test-kitchen run. The use of `exec` allows test-kitchen to complete and then re-runs the recipe to validate that the cookbook does not attempt to re-update the chef-client and will succeed with the new chef-client. This, however, means that it is not possible to exactly test the config which will be running in production. The best practice advice for this cookbook will be to ignore common best practices and not worry about that. If you change your production config to use `exec` in order to run what you test in test-kitchen, then you will find sharp edge cases where your production upgrades will hang and/or fail, which testing will not replicate. In order to test you should most likely test upgrades on your full-scale integration environment (not under test-kitchen) before rolling out to production and not use test-kitchen at all. If you think that there's a rule that you must test absolutely everything you run under test-kitchen, you should probably [read this](http://labs.ig.com/code-coverage-100-percent-tragedy) or [this](https://coderanger.net/overtesting/).

In order to test that your recipes work under the new chef-client codebase, you should simply test your cookbooks against the new version of chef-client that you wish to deploy in "isolation" from the upgrade process. If your recipes all work on the old client, and all work on the new client, and the upgrader works, then the sum of the parts should work as well (and again, if you really deeply care about the edge conditions where that might not work -- then test on real production-like images and not with test-kitchen).

#### Use of 'exec' in production

This is highly discouraged since the exec will not clean up the supervising process. You're very likely to see it upgrade successfully and then see the old chef-client process continue to run and fork off copies of the old chef-client to run again. Or for the upgrade process to hang, or for other issues to occur causing failed upgrades.

You can use 'exec' in production if you are running from cron or some other process manager and firing off single-shot `--no-fork` chef-client processes without using the `--interval` option. This will have the advantage that the new chef-client kicks off immediately after the upgrade giving fast feedback on any failures under the new chef-client. The utility of this approach is most likely is not enough to justify the hassle.

## A note about purpose

While this cookbook supports running on Chef Infra Client versions back to 11/12, the supported behavior of the cookbook is to upgrade those versions to 13/14 or newer. It is not intended that users would maintain old Chef-11/12 versions with this cookbook. The latest released version of Chef Infra Client 12 (12.22.1 or later) is still be supported as a target. Older versions of Chef Infra Client will have their embedded rubygems force upgraded by this cookbook to avoid having to regression test against 5+ years of rubygems bugs and establish a stable basis for the cookbook to use.

## License

```text
Copyright:: 2016-2020, Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
