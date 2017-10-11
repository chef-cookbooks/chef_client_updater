describe command('chef-client -v') do
  its('stdout') { should match '^Chef: 13.6.0' }
end
