require 'spec_helper'

describe 'test::default' do
  platform 'ubuntu', '18.04'

  it 'converges successfully' do
    expect { :chef_run }.to_not raise_error
  end
end
