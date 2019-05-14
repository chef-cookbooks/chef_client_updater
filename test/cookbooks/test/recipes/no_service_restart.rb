chef_client_updater "Install Chef #{node['chef_client_updater']['version']}" do
  channel 'stable'
  version node['chef_client_updater']['version']
  event_log_service_restart false
  post_install_action 'kill'
end
