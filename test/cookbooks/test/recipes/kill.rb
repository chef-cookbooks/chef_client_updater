chef_client_updater "Install Chef #{node['chef_client_updater']['version']}" do
  channel 'current'
  verison node['chef_client_updater']['version']
  post_install_action 'kill'
end
