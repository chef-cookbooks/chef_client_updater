chef_client_updater "Install Chef #{node['chef_client_updater']['version']}" do
  channel 'stable'
  version node['chef_client_updater']['version']
  post_install_action 'exec'
  install_timeout 599
end
