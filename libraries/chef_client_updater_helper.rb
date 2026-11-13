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
    # the user supplied the package URL and checksum, so there is nothing to look up (#266)
    if new_resource.download_url_override
      Chef::Log.info("#{new_resource}: Package validation skipped: using download_url_override #{new_resource.download_url_override.split('?').first}")
      return true
    end

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

  # The version we WANT TO INSTALL. If the user specifies a version in X.Y.Z format
  # we use that without looking it up — UNLESS license_id is set, in which case the
  # Trial API silently overrides any specific version to 'latest'. In that case we must
  # resolve through artifact_info so desired_version reflects what will actually be
  # installed (preventing an infinite update loop on subsequent runs).
  # If :latest or a non-X.Y.Z format version, we look it up with mixlib-install.
  # @return Mixlib::Versioning::Format::PartialSemVer
  def desired_version
    load_mixlib_versioning
    if new_resource.version.to_sym == :latest
      version = Mixlib::Versioning.parse(mixlib_install.available_versions.last)
      Chef::Log.debug("User specified version of :latest. Looking up using mixlib-install. Value maps to #{version}.")
    elsif new_resource.download_url_override
      version = Mixlib::Versioning.parse(new_resource.version)
      Chef::Log.debug("download_url_override specified. Using specified version of #{version}")
    elsif new_resource.version.split('.').count == 3 && !new_resource.license_id
      Chef::Log.debug("User specified version of #{new_resource.version}. No need check this against Chef servers.")
      version = Mixlib::Versioning.parse(new_resource.version)
    else
      artifact = Array(mixlib_install.artifact_info).first
      version = Mixlib::Versioning.parse(artifact.version)
      Chef::Log.debug("User specified version of #{new_resource.version}. Looking up using mixlib-install. Value maps to #{version}.")
    end
    version
  end
end
