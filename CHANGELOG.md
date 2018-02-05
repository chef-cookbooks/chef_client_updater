# chef_client_updater Cookbook CHANGELOG

This file is used to list changes made in each version of the chef_client_updater cookbook.

## 3.2.4 (2018-02-05)

- Fix warning '/ST is earlier than current time' on Windows

## 3.2.3 (2018-01-25)

- Make product_name attribute into a real property on the resource

## 3.2.2 (2018-01-25)

- Make upgrade_delay a true resource property

## 3.2.1 (2018-01-25)

- Added new attribute 'upgrade_delay' that defines delay in seconds before upgrading Chef client.

## 3.2.0 (2018-01-22)

- Require mixlib-install 3.9 which includes initial support for proxies and support for Amazon Linux 2.0
- Add additional debug logging for the installation
- If the user provides an X.Y.Z format version don't contact Chef Inc's servers to validate the version
- error out chef run if shell update fails

## 3.1.3 (2017-12-20)

- Support custom paths to chef-client

## 3.1.2 (2017-11-22)

- Windows: Support for downgrading the Chef client

## 3.1.1 (2017-11-14)

- Windows: Bypass Powershell Execution Policy for upgrade scheduled task

## 3.1.0 (2017-11-01)

- Raise if download_url_override is set but checksum isn't
- Require a mixin-install that supports proxies
- Improve how we perform the cleanup of the previous install directory on Windows
- Remove a hardcoded path to the chef-client on Windows
- Improve how we perform the Windows upgrade by using a scheduled task to avoid failures during the upgrade

## 3.0.4 (2017-08-17)

- Fix gem install to actually install mixlib-install 3.3.4
- Fix :latest resulting in chef installing on every run

## 3.0.3 (2017-08-10)

- Add accurate logging for the rubygems upgrade to reflect that we're actually upgrading to the latest release.
- Require mixlib-install 3.3.4 to prevent failures on Windows nodes due to architecture detection failing within mixlib-install
- Add debug logging for the desired version logic
- Improve logging of the version we're upgrading to in situations where the user provides either :latest or a partial version like '12'. Show the version we're upgrading to instead of what the user passed

## 3.0.2 (2017-08-08)

- Improve logging to actually log when the upgrade occurs before we kill or exec the current chef-client run

## 3.0.1 (2017-07-14)

- adding check for gem.cmd on chef-client 13 windows

## 3.0.0 (2017-07-14)

### Breaking Changes

- The default post install action for the resource has been switched from exec to kill. We believe that kill is the most likely default that users would expect as this allows a chef-client daemon running under a modern init system to cleanly upgrade. We highly recommend you check the readme and understand the exec and kill functions to determine which makes the most sense for how you run chef-client and how you execute the upgrade.
- The prevent downgrade attribute for the default recipe has been changes from true to false as this is the default for the resource.

### Other Changes

- If chef-client is forked and the user specifies an 'exec' post install action we will now warn and then kill as exec will not worked in a forked run
- Updated the windows task example in the readme to properly set the start time
- Updated the minimum version of mixlib-install to download 3.3.1 which includes many fixes for windows clientsA
- The resource now works around situations where mixlib-install may return an Array of versions

## 2.0.3 (2017-06-27)

- Fix #31 detect centos platform correctly

## 2.0.2 (2017-06-22)

- Fix air-gapped installation regression introduced by support for partial versions

## 2.0.1 (2017-06-16)

- Add information on upgrading Windows nodes and upgrading from Chef 11 to the readme

## 2.0.0 (2017-06-15)

- The custom resource has been converted to a LWRP so that we can support Chef Client updates from chef-client 11.6.2 to current. This also removes the need for the compat_resource cookbook.
- Support for upgrading Windows clients has been added
- A potential infinite loop in the upgrade process has been fixed
- The existing /opt/chef directory will now be cleaned up before the reinstall so leftover files will not carry over during upgrades
- Full Travis testing of the cookbook has been added

## 1.1.1 (2017-05-11)

- Fix the initial load of mixlib-install failing

## 1.1.0 (2017-05-10)

- Add support for download URL overrides via new properties on the resource and attributes for the default recipe. This requires mixlib-install 3.2.1, which we now ensure we install in the updater resource.
- Update the default post_install action in the recipe to match the resource (exec).
- Remove usage of class_eval in the resource since we use compat_resource and class_eval causes issues with some later Chef 12 releases.
- Fix the solaris platform name in the metadata.rb.
- Remove disabling FC016 and FC023 Foodcritic rules as these no longer alert.
- Avoid infinite loops if trying to install the latest chef-client version from any channel.
- Add a true test recipe and remove unused inspec tests
- Add debug logging of the current vs. desired versions to help troubleshooting
- Added a blurb in the readme outlining init system issues surrounding kill and the chef-client starting back up

## 1.0.2 (2017-04-07)

- Fix Chef 13 compatibility by using Kernel.exec not exec

## 1.0.1 (2017-04-07)

- point the URLs at the new project repo
- Add ChefSpec matcher

## 1.0.0

- Initial release of chef_client_updater
