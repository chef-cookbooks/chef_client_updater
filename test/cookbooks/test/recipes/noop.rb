chef_client_updater "Install Chef #{node['chef_client_updater']['version']}" do
  channel 'current'
  version '12.13.37'
  post_install_action 'kill'
end
