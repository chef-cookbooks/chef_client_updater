node.override['chef_client']['chef_license'] = 'accept'

chef_client_updater 'Install Chef Infra Client 15' do
  channel 'stable'
  version '15'
  post_install_action 'exec'
  install_timeout 599
end
