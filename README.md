# chef_client_updater

[![Build Status](https://travis-ci.org/chef-cookbooks/chef_client_updater.svg?branch=master)](https://travis-ci.org/chef-cookbooks/chef_client_updater) [![Cookbook Version](https://img.shields.io/cookbook/v/chef_client_updater.svg)](https://supermarket.chef.io/cookbooks/chef_client_updater)

This cookbook updates the chef-client

## Requirements

### Platforms

- All platforms with a chef-client package on downloads.chef.io

### Chef

- Chef 12.1+

### Cookbooks

- compat_resource

## Usage

This cookbook provides both a custom resource and a default recipe. The default recipe simply uses the custom resource with a set of attributes. You can add chef_client_updater::default to your run list or use the custom resource in a wrapper cookbook.

### Init System Caveats

When Chef runs as a service under a system init daemon such as Sys-V or systemd each chef run forks off from the main chef-client process being managed by the init system. For a chef-client upgrade to occur the running chef-client as well as the parent process must be killed, and a new chef-client must start using the updated binaries. This cookbook handles killing the chef-client, but your init system must properly handle starting the service back up. For systemd and upstart this can be handled via configuration, and chef-client cookbook 8.1.1 or later handles this by default. This functionality is not available in sys-v (RHEL 6, Debian 7, and others), so you will need to employ a secondary process such as a monitoring system to start the chef-client service.

## Resources

### chef_client_updater

Installs the mixlib-install/mixlib-install gems and upgrades the chef-client.

#### properties

- `channel` - The chef channel you fetch the chef client from. `stable` contains all officially released chef-client builds where as `current` contains unreleased builds. Default: `stable`
- `prevent_downgrade` - Don't allow this cookbook to downgrade the chef-client version. Default: true
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
