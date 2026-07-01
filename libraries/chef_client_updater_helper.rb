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

    options[:license_id] = new_resource.license_id if new_resource.license_id

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

  def log_download_url
    begin
      artifact = Array(mixlib_install.artifact_info).first
      if artifact && artifact.url
        Chef::Log.info("Package will be downloaded from: #{artifact.url.split('?').first}")
      end
    rescue => e
      Chef::Log.debug("Unable to retrieve download URL: #{e.message}")
    end
  end

  def validate_package_availability
    artifact = Array(mixlib_install.artifact_info).first
    unless artifact
      Chef::Log.warn("Unable to retrieve package information for #{new_resource.product_name} version #{new_resource.version}. Skipping upgrade.")
      return false
    end

    download_url = artifact.url.to_s
    if download_url.empty?
      Chef::Log.warn("No download URL available for #{new_resource.product_name} version #{new_resource.version}. Skipping upgrade.")
      return false
    end

    Chef::Log.info("Package validation: #{new_resource.product_name} #{artifact.version} will be downloaded from #{download_url.split('?').first}")

    windows? ? validate_windows_package_availability(artifact) : true
  rescue => e
    Chef::Log.warn("Package validation failed: #{e.message}. Skipping upgrade.")
    false
  end

  def validate_windows_package_availability(artifact)
    Chef::HTTP::Simple.new(artifact.url).head('')
    Chef::Log.debug("Package availability verified: #{artifact.url.split('?').first}")
    true
  rescue => e
    Chef::Log.warn("Package availability check failed, skipping upgrade: #{e.message}")
    false
  end
end
