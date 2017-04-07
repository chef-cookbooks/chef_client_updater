if defined?(ChefSpec)
  ChefSpec.define_matcher(:chef_client_updater)

  def update_chef_client_updater(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:chef_client_updater, :update, resource_name)
  end
end
