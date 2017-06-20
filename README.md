# chef_client_updater

[![Build Status](https://travis-ci.org/chef-cookbooks/chef_client_updater.svg?branch=master)](https://travis-ci.org/chef-cookbooks/chef_client_updater) [![Cookbook Version](https://img.shields.io/cookbook/v/chef_client_updater.svg)](https://supermarket.chef.io/cookbooks/chef_client_updater)

This cookbook updates the chef-client

## Requirements

### Platforms

- All platforms with a chef-client package on downloads.chef.io

### Chef

- Chef 11.6.2+

## Usage

This cookbook provides both a custom resource and a default recipe. The default recipe simply uses the custom resource with a set of attributes. You can add chef_client_updater::default to your run list or use the custom resource in a wrapper cookbook.

### Init System Caveats

When Chef runs as a service under a system init daemon such as Sys-V or systemd each chef run forks off from the main chef-client process being managed by the init system. For a chef-client upgrade to occur the running chef-client as well as the parent process must be killed, and a new chef-client must start using the updated binaries. This cookbook handles killing the chef-client, but your init system must properly handle starting the service back up. For systemd and upstart this can be handled via configuration, and chef-client cookbook 8.1.1 or later handles this by default. This functionality is not available in sys-v (RHEL 6, Debian 7, and others), so you will need to employ a secondary process such as a monitoring system to start the chef-client service.

### Updating Windows Nodes

There are a couple of considerations on Windows that have to be dealt with. The Chef Client installer uses a custom component to speed up the installation. This component does not gracefully handle open file handles the way the MSI installer does. To work around this, the resource moves the currently installed Chef Client to a staging directory and that clears the way for the newer installer to run. At the end of that installation process though, that Chef Client run must exit or it will fail trying to find files that do not exist in their expected locations. The next run of the Chef Client will use the newly installed version.

#### Running Chef Client as a Scheduled Task

If you run as a scheduled task, then this will work smoothly. The path to the newly installed Chef Client will be the same and the scheduled task will launch it. Part of this resource's job on the next run is to make sure the staging directory with the older client is removed.

#### Running Chef Client As A Windows Service

If you run Chef Client as a service, things get a tiny bit more complicated. When the new installer runs, the service is removed. This isn't a big deal if you've got the chef-client cookbook set to configure the Windows service. If that is the case, we can register a scheduled task to run shortly after the `chef_client_updater` terminates the current chef run. An example recipe might look like:

```ruby
if Chef::VERSION < node['my_update_cookbook']['desired_version']
  run_chef_task_in_ten_minutes = Time.now + 600

  windows_task 'chef-client-upgrade' do
    cwd 'C:\\opscode\\chef\\bin'
    command 'chef-client'
    run_level :highest
    frequency :once
    start_time "#{run_chef_task_in_ten_minutes.hour}:#{run_chef_task_in_ten_minutes.min}"
    action :create
  end
else
  windows_task 'chef-client-upgrade' do
    cwd 'C:\\opscode\\chef\\bin'
    command 'chef-client'
    run_level :highest
    frequency :once
    start_time "#{run_chef_task_in_ten_minutes.hour}:#{run_chef_task_in_ten_minutes.min}"
    action :delete
  end
end

chef_client_updater 'Install latest Chef' do
  post_install_action 'kill'
end
```

### Upgrading from Chef 11

Moving from Chef 11 has a few challenges when we are dealing with public update sources. Chef 11 ships with a very old `cacert.pem`. To work through this, we need to get a more current `cacert.pem` file and point OpenSSL to it. Unfortunately, for this to work consistently on Windows, we'll need to reboot. Chef 11 does not have the reboot resource, so this isn't a graceful process. However, on the next Chef run after the reboot, things will be back on track and the upgrade will perform as on other platforms.

Below is an example of a recipe that can set up Chef 11 to work using public update sources.

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

## Resources

### chef_client_updater

Installs the mixlib-install/mixlib-install gems and upgrades the chef-client.

#### properties

- `channel` - The chef channel you fetch the chef client from. `stable` contains all officially released chef-client builds where as `current` contains unreleased builds. Default: `stable`
- `prevent_downgrade` - Don't allow this cookbook to downgrade the chef-client version. Default: false
- `version` - The version of the chef-client to install. Default :latest
- `post_install_action` - After installing the chef-client what should we do. `exec` to exec the new client or `kill` to kill the client and rely on the init system to start up the new version. Default: `exec`
- `exec_command` - The chef-client command. default: $PROGRAM_NAME.split(' ').first
- `exec_args` - An array of arguments to exec the chef-client with. default: ARGV
- `download_url_override` - The direct URL for the chef-client package.
- `checksum` - The SHA-256 checksum of the chef-client package from the direct URL.

#### examples

```ruby
chef_client_updater 'Install latest'
```

```ruby
chef_client_updater 'Install latest Chef 13.x' do
  version '13'
end
```

```ruby
chef_client_updater 'Install 12.13.36 and kill' do
  version '12.13.36'
  post_install_action 'kill'
end
```

## License & Authors

- Author: Tim Smith ([tsmith@chef.io](mailto:tsmith@chef.io))

```text
Copyright:: 2016-2017, Chef Software, Inc

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
