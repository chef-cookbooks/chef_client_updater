module ChefClientUpdaterHelper
  def mixlib_install
    load_mixlib_install
    detected_platform = Mixlib::Install.detect_platform
    Chef::Log.debug("Platform detected as #{detected_platform} by mixlib_install")
    options = {
      product_name: new_resource.product_name,
      platform_version_compatibility_mode: true,
      platform: detected_platform[:platform],
      platform_version: detected_platform[:platform_version],
      architecture: detected_platform[:architecture],
      channel: new_resource.channel.to_sym,
      product_version: new_resource.version == 'latest' ? :latest : new_resource.version,
      install_command_options: new_resource.install_command_options,
    }
    options = add_download_url_override_options(options)

    Chef::Log.debug("Passing options to mixlib-install: #{options}")
    Mixlib::Install.new(options)
  end

  def add_download_url_override_options(options)
    if new_resource.download_url_override
      raise('Using download_url_override in the chef_client_updater resource requires also setting checksum property!') unless new_resource.checksum
      Chef::Log.debug("Passing download_url_override of #{new_resource.download_url_override} and checksum of #{new_resource.checksum} to mixlib_install")
      options[:install_command_options] = options[:install_command_options].merge(download_url_override: new_resource.download_url_override, checksum: new_resource.checksum)
    end
    options
  end
end
