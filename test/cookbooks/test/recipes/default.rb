chef_client_updater 'Install latest Chef' do
  channel 'current'
  post_install_action 'exec'
end
