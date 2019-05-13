describe command('chef-client -v') do
  target_version = '15'
  its('stdout') { should match "^Chef Infra Client: #{target_version}" }
end
