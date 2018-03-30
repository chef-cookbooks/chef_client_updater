if platform?('amazon')
  include_recipe 'chef_client_updater::amazon'
else
  include_recipe 'chef_client_updater::others'
end
