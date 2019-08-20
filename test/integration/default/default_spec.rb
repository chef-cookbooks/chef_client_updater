describe command('chef-client -v') do
  target_version = ['chef_client_updater']['version']
  its('stdout') { should match "^(Chef: \d+\.)(\d+\.)(\d+)|(Chef Infra Client: \d+\.)(\d+\.)(\d+)" }
end

describe command('/opt/chef/embedded/bin/gem -v') do
  its('stdout') { should cmp >= '2.6.11' }
end
