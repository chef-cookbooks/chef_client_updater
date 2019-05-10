# TAS50: cookbook will break with the standard Gemfile, will break
# testing with the latest version of kitchen-dokken in chef-dk
source 'https://rubygems.org'

gem 'community_cookbook_releaser'
gem 'stove'
# TODO switch back to gem after https://github.com/test-kitchen/test-kitchen/pull/1551 released
gem 'test-kitchen', git: "https://github.com/test-kitchen/test-kitchen.git"
# testing in this cookbook will current fail with kitchen-dokken 2.x
gem 'berkshelf'
gem 'json'
gem 'kitchen-dokken', '< 2.0'
gem 'kitchen-inspec'
gem 'kitchen-vagrant'
