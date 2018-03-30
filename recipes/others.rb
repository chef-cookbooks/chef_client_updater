chef_client_updater 'update chef-client' do
  channel node['chef_client_updater']['channel']
  version node['chef_client_updater']['version']
  prevent_downgrade node['chef_client_updater']['prevent_downgrade']
  post_install_action node['chef_client_updater']['post_install_action']
  download_url_override node['chef_client_updater']['download_url_override'] if node['chef_client_updater']['download_url_override']
  checksum node['chef_client_updater']['checksum'] if node['chef_client_updater']['checksum']
  upgrade_delay node['chef_client_updater']['upgrade_delay'] unless node['chef_client_updater']['upgrade_delay'].nil?
  product_name node['chef_client_updater']['product_name'] if node['chef_client_updater']['product_name']
end