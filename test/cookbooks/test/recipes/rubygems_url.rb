chef_client_updater 'Install latest Chef' do
  version '13.6.0'
  rubygems_url 'http://localhost:8808'
  post_install_action 'exec'
end
