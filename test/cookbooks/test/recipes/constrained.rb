chef_client_updater 'Install constrained version' do
  version '12.22.5'
  post_install_action 'exec'
end
