# chef_client_updater Cookbook CHANGELOG

This file is used to list changes made in each version of the chef_client_updater cookbook.

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
