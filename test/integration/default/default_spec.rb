describe command('chef-client -v') do
  target_version = '18.10.17'
  its('stdout') { should match "^Chef Infra Client: #{target_version}" }
end

describe command('/opt/chef/embedded/bin/gem -v') do
  its('stdout') { should cmp >= '2.6.11' }
end
