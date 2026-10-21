require 'spec_helper'

# NOTE: The Windows upgrade path in execute_install_script (the powershell_script resource
# rendered via .run_action(:run)) cannot be meaningfully unit tested here because ChefSpec
# does not intercept immediate run_action calls. Behavioral coverage for the Windows
# $LASTEXITCODE exit-code check and rollback path requires a Windows Test Kitchen suite
# that converges with a mock install script that exits non-zero and then asserts the
# backup directory was restored. See kitchen.yml for the existing Linux suites.

describe 'chef_client_updater provider' do
  platform 'ubuntu', '22.04'

  context 'when product_name is chef-ice' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '22.04', step_into: ['chef_client_updater']) do |node|
        node.normal['chef_client_updater']['product_name'] = 'chef-ice'
        node.normal['chef_client_updater']['version'] = '18.0.0'
      end
    end

    it 'raises an error about unsupported product' do
      expect { chef_run.converge('chef_client_updater::default') }.to raise_error(RuntimeError, /Unsupported product: chef-ice/)
    end

    it 'includes error message stating cookbook only supports Chef 18 and below' do
      expect { chef_run.converge('chef_client_updater::default') }.to raise_error(RuntimeError, /only supports omnibus versions of Chef Infra Client 18 and below/)
    end
  end

  # For 'does not raise' contexts we set matching current/desired versions (both 18.0.0)
  # and populate node.automatic['chef_packages'] so current_version works without ohai.
  # With no license_id, desired_version uses the X.Y.Z fast path (no API call needed).
  context 'when product_name is chef' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '22.04', step_into: ['chef_client_updater']) do |node|
        node.normal['chef_client_updater']['product_name'] = 'chef'
        node.normal['chef_client_updater']['version'] = '18.0.0'
        node.automatic['chef_packages'] = { 'chef' => { 'version' => '18.0.0' } }
      end
    end

    it 'does not raise an error' do
      expect { chef_run.converge('chef_client_updater::default') }.not_to raise_error
    end
  end

  context 'license_id warning' do
    let(:product_name) { 'chef' }
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '22.04', step_into: ['chef_client_updater']) do |node|
        node.normal['chef_client_updater']['product_name'] = product_name
        node.normal['chef_client_updater']['version'] = '18.0.0'
        node.automatic['chef_packages'] = { 'chef' => { 'version' => '18.0.0' } }
      end
    end

    before { allow(Chef::Log).to receive(:warn).and_call_original }

    it 'warns when no license_id is set for chef' do
      chef_run.converge('chef_client_updater::default')
      expect(Chef::Log).to have_received(:warn).with(/No license_id specified/)
    end

    %w(cinc angrycinc).each do |cinc_product|
      context "when product_name is #{cinc_product}" do
        let(:product_name) { cinc_product }

        it 'does not warn about license_id' do
          chef_run.converge('chef_client_updater::default')
          expect(Chef::Log).not_to have_received(:warn).with(/No license_id specified/)
        end
      end
    end
  end

  context 'when product_name is not set (defaults to chef)' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '22.04', step_into: ['chef_client_updater']) do |node|
        node.normal['chef_client_updater']['version'] = '18.0.0'
        node.automatic['chef_packages'] = { 'chef' => { 'version' => '18.0.0' } }
      end
    end

    it 'does not raise an error' do
      expect { chef_run.converge('chef_client_updater::default') }.not_to raise_error
    end
  end
end
