require 'spec_helper'
require_relative '../../../libraries/chef_client_updater_helper'

describe ChefClientUpdaterHelper do
  let(:provider) { Object.new.extend(ChefClientUpdaterHelper) }
  let(:product_name) { 'chef-client' }
  let(:channel) { 'stable' }
  let(:product_version) { 'latest' }
  let(:install_command_options) { { option1: 'value1', option2: 'value2' } }
  let(:download_url_override) { 'https://my-url' }
  let(:checksum) { 12345 }
  let(:resource) do
    double('Chef::Resource::ChefClientUpdater',
                          product_name: product_name, channel: channel, version: product_version, install_command_options: install_command_options,
                          download_url_override: download_url_override, checksum: checksum)
  end
  let(:platform) { 'aix' }
  let(:platform_version) { '4.5' }
  let(:architecture) { 'x86' }
  let(:detected_platform) { { platform: 'aix', platform_version: '4.5', architecture: 'x86' } }
  let(:mixlib) { double('Mixlib::Install', new: true, detect_platform: detected_platform) }
  let(:options) do
    {
      product_name: product_name,
      platform_version_compatibility_mode: true,
      platform: platform,
      platform_version: platform_version,
      architecture: architecture,
      channel: channel.to_sym,
      product_version: product_version.to_sym,
      install_command_options: install_command_options,
    }
  end

  before do
    stub_const('::Mixlib::Install', mixlib)
    allow(provider).to receive(:new_resource).and_return(resource)
  end

  describe '#mixlib_install' do
    before do
      allow(provider).to receive(:load_mixlib_install)
      allow(Chef::Log).to receive(:debug).and_call_original
      allow(Chef::Log).to receive(:debug).with('Platform detected as aix by mixlib_install')
    end

    it 'calls add_download_url_options with the expected options Hash' do
      expect(provider).to receive(:add_download_url_override_options).with(options)
      provider.mixlib_install
    end

    it 'calls Mixlib::Install.new with the correct options hash' do
      allow(provider).to receive(:add_download_url_override_options).with(options).and_return(options)
      expect(Mixlib::Install).to receive(:new).with(options)
      provider.mixlib_install
    end
  end

  describe '#add_download_url_override_options' do
    # download_url_override nil default is never false so this is never true unless resource attribute is set to nil explicitly
    context 'when download_url_override is false' do
      before do
        allow(resource).to receive(:download_url_override).and_return(false)
      end

      it 'never raises an error' do
        expect { provider.add_download_url_override_options(options) }.to_not raise_error
      end

      it 'does not call new_resource.checksum' do
        expect(resource).to_not receive(:checksum)
        provider.add_download_url_override_options(options)
      end

      it 'does not add download url override key value pair' do
        expect(provider.add_download_url_override_options(options)[:install_command_options].key?(:download_url_override)).to be false
      end
    end

    context 'when new_resource.download_url_override is not false' do
      # checksum nil default is never false so this is never true unless resource.checksum is set to nil explicitly
      context 'when new_resource.checksum is false' do
        before do
          allow(resource).to receive(:checksum).and_return(false)
        end

        it 'raises an error that checksum must be set if download_url_override is set' do
          expect { provider.add_download_url_override_options(options) }.to raise_error('Using download_url_override in the chef_client_updater resource requires also setting checksum property!')
        end
      end

      context 'when new_resource.checksum is not false' do
        it 'does not raise an error' do
          expect { provider.add_download_url_override_options(options) }.not_to raise_error
        end

        it 'logs a debug message to Chef log' do
          expect(Chef::Log).to receive(:debug).with("Passing download_url_override of #{download_url_override} and checksum of #{checksum} to mixlib_install")
          provider.add_download_url_override_options(options)
        end

        it 'sets the options variable hash to include the download_url_override and checksum as key value pairs' do
          provider.add_download_url_override_options(options)
          expect(options[:install_command_options][:download_url_override]).to eq(download_url_override)
          expect(options[:install_command_options][:checksum]).to eq(checksum)
        end
      end
    end
  end
end
