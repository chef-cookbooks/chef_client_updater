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
    begin
      artifact = Array(mixlib_install.artifact_info).first
      unless artifact
        raise "Unable to retrieve package information for #{new_resource.product_name} version #{new_resource.version}"
      end

      if artifact.url.nil? || artifact.url.empty?
        raise "No download URL available for #{new_resource.product_name} version #{new_resource.version}"
      end

      Chef::Log.info("Package validation: #{new_resource.product_name} #{artifact.version} will be downloaded from #{artifact.url.split('?').first}")

      if windows?
        validate_windows_package_availability(artifact)
      end
    rescue => e
      Chef::Log.error("Package validation failed: #{e.message}")
      raise "Pre-upgrade package validation failed. This prevents destructive upgrade operations. Error: #{e.message}"
    end
  end

  def validate_windows_package_availability(artifact)
    max_retries = 3
    retry_count = 0
    wait_time = 2.0

    loop do
      begin
        require 'net/http'
        uri = URI.parse(artifact.url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = 5
        http.read_timeout = 5

        request = Net::HTTP::Head.new(uri.request_uri)
        response = http.request(request)

        if response.code.to_i >= 200 && response.code.to_i < 300
          Chef::Log.debug("Package availability verified: HTTP #{response.code}")
          return
        elsif response.code.to_i == 404
          raise "Package not found (404) at #{artifact.url.split('?').first}"
        else
          raise "HTTP #{response.code} #{response.message}"
        end
      rescue StandardError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
        retry_count += 1

        if retry_count > max_retries
          Chef::Log.warn "Package availability check failed after #{max_retries} retries: #{e.message}"
          raise "Package #{artifact.version} not available at expected URL after #{max_retries} retries. " \
                "This may indicate a CDN propagation delay or package availability issue. Error: #{e.message}"
        end

        Chef::Log.debug("Package availability check attempt #{retry_count} failed, retrying in #{wait_time}s: #{e.message}")
        sleep(wait_time)
        wait_time = wait_time * 2
      end
    end
  end
end
