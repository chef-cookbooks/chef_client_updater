describe command('chef-client -v') do
  its('stdout') { should match '^Chef: 13.6.0' }
end

describe command('/opt/chef/embedded/bin/gem -v') do
  its('stdout') { should cmp >= '2.6.11' }
end
