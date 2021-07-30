# chef_client_updater Cookbook CHANGELOG

This file is used to list changes made in each version of the chef_client_updater cookbook.

## Unreleased

- Switch to Chef 12.5 custom resources - [@detjensrobert](https://github.com/detjensrobert)
- Enable unified_mode (if supported) - [@detjensrobert](https://github.com/detjensrobert)

## 3.12.0 (2021-04-14)

- Bump version of mixlib-install we install to 3.12 - [@gscho](https://github.com/gscho)

## 3.11.1 (2020-08-25)

- Fix license acceptance on non-windows - [@dheerajd-msys](https://github.com/dheerajd-msys)

## 3.11.0 (2020-08-12)

- #209 Fixed Windows PowerShell task reschedule by using Scheduled Task cmdlets available on PowerShell 3+ on Windows 2012+- [@jwdean](https://github.com/jwdean)
- resolved cookstyle error: providers/default.rb:314:3 convention: `Style/RedundantAssignment`

## 3.10.1 (2020-05-27)

- Catch when the windows upgrades fail and make sure we leave the C:\opscode\chef dir - [@teknofire](https://github.com/teknofire)
- Improve logging on Windows - [@teknofire](https://github.com/teknofire)
- More chef-client / chef -> Chef Infra Client - [@tas50](https://github.com/tas50)
- Improve the exit message so users realize it was a success - [@tas50](https://github.com/tas50)
- Expand testing with new platforms - [@tas50](https://github.com/tas50)

## 3.10.0 (2020-05-04)

- Disable if_respond to cop for legacy support - [@tas50](https://github.com/tas50)
- Use source parameter for chef_gem if it exists - [@ramereth](https://github.com/ramereth)
- Include cinc as an allowed product_name - [@ramereth](https://github.com/ramereth)

## 3.9.0 (2020-04-14)

- Remove #to_s conversion of attributes - [@jasonwbarnett](https://github.com/jasonwbarnett)
- More robust eventlog and dependent services restarts on Windows - [@rabidpitbull](https://github.com/rabidpitbull)

## 3.8.6 (2020-03-06)

- Fixed restart eventlog and dependent services - [@sanga1794](https://github.com/sanga1794)

## 3.8.5 (2020-03-05)

- Fix nil:NilClass error - [@dheerajd-msys](https://github.com/dheerajd-msys)

## 3.8.4 (2020-02-20)

-Fix the type for the rubygems_url property

## 3.8.3 (2020-02-20)

- Updated rubygems_url resource property default and removed attribute - [@BrandonTheMandon](https://github.com/BrandonTheMandon)

## 3.8.2 (2020-01-14)

- Remove mandatory parameters for WaitForChefClientOrRescheduleUpgradeTask - [@bdwyertech](https://github.com/bdwyertech)

## 3.8.1 (2020-01-14)

- Necessary changes in PS script to accept the chef-client license while chef client upgrade in Windows. - [@Nimesh-Msys](https://github.com/Nimesh-Msys)

## 3.8.0 (2019-12-20)

- Add install_command_options to enable installing Chef as a scheduled task on Windows when updating - [@gholtiii](https://github.com/gholtiii)
- Fix Chef_upgrade scheduled task to reschedule itself when it fails due to running ruby.exe - [@gholtiii](https://github.com/gholtiii)

## 3.7.3 (2019-12-09)

- Minor Fixes While detecting chef DK version - [@Nimesh-Msys](https://github.com/Nimesh-Msys)

## 3.7.2 (2019-11-29)

- fix windows chef install path - [@phomein](https://github.com/phomein)

## 3.7.1 (2019-11-19)

- Minor fixes while upgrading ChefDK - [@Nimesh-Msys](https://github.com/Nimesh-Msys)
- Replace hardcode value for chef_install_path on Windows with a variable - [@dheerajd-msys](https://github.com/dheerajd-msys)

## 3.7.0 (2019-11-18)

- Added noproxy support for airgapped artifact solutions [@Romascopa](https://github.com/romascopa)
- Fix for using custom rubygem server - [@dheerajd-msys](https://github.com/dheerajd-msys)
- Remove opensuse from the list of platforms we support as the correct platform is opensuseleap - [@tas50](https://github.com/tas50)
- Remove the long_description metadata that is unused - [@tas50](https://github.com/tas50)
- Disable some Cookkstyle cops that would break Chef 12 compatibility - [@tas50](https://github.com/tas50)

## 3.6.0 (2019-10-14)

- Updated provider so that EventLog is properly restarted without error during convergence
- Adding license acceptance support - [@tyler-ball](https://github.com/tyler-ball)
- Fix creation of cron error while licence acceptance - [@NAshwini](https://github.com/NAshwini)

## 3.5.3 (2019-06-11)

- Add event_log_service_restart attribute to fix issue of non chef service restart. - [@NAshwini](https://github.com/NAshwini)
- Use new ChefSpec format - [@tas50](https://github.com/tas50)
- Allow path to handle.exe to be configured - [@stefanwb](https://github.com/stefanwb)

## 3.5.2 (2019-01-30)

- Fix rubygems upgrade logic to prevent breaking older chef-client releases such as Chef 12.X

## 3.5.1 (2018-12-22)

- use --no-document for rubygems 3.0 to prevent upgrade failures - [@lamont-granquist](https://github.com/lamont-granquist)

## 3.5.0 (2018-08-31)

- Only run the cron job on *nix 5 minutes from now

## 3.4.2 (2018-08-15)

- Fix to retrieve current version for angrychef nodes

## 3.4.1 (2018-08-02)

- Allow for a configurable package install timeout. (#130)

## 3.4.0 (2018-07-23)

- Prevent failures on Chef-DK
- rubygems_url: Allow the rubygems source to be specified
- Require mixlib-install 3.11+ for Amazon Linux 2.0 support
- Attempt to move the chef install directory if it still exists before giving up to workaround failures on Windows 2008

## 3.3.5 (2018-06-20)

- Do not attempt EventLog restart on Windows 7 or Windows Server 2008 editions.

## 3.3.4 (2018-05-30)

- Improve install success rate on Windows by destroying existing Chef handles prior to upgrade.

## 3.3.3 (2018-04-26)

- Better support AIX by also restarting the chef-client service via cron on AIX

## 3.3.2 (2018-04-11)

- Improve how we handle updating rubygems:
  - Update RubyGems without shelling out
  - Don't upgrade to the very latest version unless we have to (due to old current rubygems)

## 3.3.1 (2018-04-11)

- Stop push jobs before upgrading Chef on Windows and then start it back up. This prevents failures to update.

## 3.3.0 (2018-04-10)

- Post action support on Windows
- Prevent failure when the user doesn't use the chef-client cookbook

## 3.2.9 (2018-04-05)

- Don't run cron on Windows

## 3.2.8 (2018-04-04)

- Restart chef-client with cron under sysvinit to ensure that chef-client properly restarts

## 3.2.7 (2018-03-29)

- Update log message to KILL from TERM. We updated the behavior but missed the logging

## 3.2.6 (2018-03-16)

- Added additional logic to decide if a 'kill' or 'exec' should be done post upgrade. If the chef-client isn't running with the supervsior process then we will no longer try to use kill.

## 3.2.5 (2018-02-28)

- Use KILL instead of TERM on Windows since TERM isn't always actually killing the process
- Updated the upgrade_delay value on Windows to be 60 seconds since anything less causes issues

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
