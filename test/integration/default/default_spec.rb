describe command('chef-client -v') do
  target_version = ENV['OMNIBUS_CHEF_VERSION'] || '13.6.0'
  its('stdout') { should match "^Chef: #{target_version}" }
end

describe command('/opt/chef/embedded/bin/gem -v') do
  its('stdout') { should cmp >= '2.6.11' }
end
