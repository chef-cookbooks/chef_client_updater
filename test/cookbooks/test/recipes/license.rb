node.override['chef_client']['chef_license'] = 'accept'

chef_client_updater 'Install Chef 15' do
  # TODO: stable once this is released
  channel 'current'
  version '15'
  post_install_action 'exec'
  install_timeout 599
end
