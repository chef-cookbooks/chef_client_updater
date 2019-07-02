# For the noop suite, currently-installed and target Chef versions are equal.
gem_path = '/opt/chef/embedded/bin/gem'
chef_version = Gem::Version.new(ENV['CHEF_VERSION'] || '12.22.5')

describe command("#{gem_path} -v") do
  # First version of Chef with bundled Rubygems >= 2.0.0.
  min_chef_version = '11.18.0'

  min_rubygems_version = '2.0.0'
  target_rubygems_version = '2.6.11'

  if Gem::Requirement.new(">= #{min_chef_version}").satisfied_by?(chef_version)
    its('stdout') { should cmp >= min_rubygems_version }
  else
    # Old Chef versions should upgrade old Rubygems to the target version.
    its('stdout') { should match target_rubygems_version }
  end
end

describe gem('mixlib-install', gem_path) do
  it { should be_installed }
end

describe gem('mixlib-versioning', gem_path) do
  it { should be_installed }
end
