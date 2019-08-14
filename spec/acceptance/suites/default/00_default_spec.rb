require 'spec_helper_acceptance'

test_name 'hirs_provisioner class with no tpm'

describe 'hirs_provisioner class with no tpm' do

  let(:manifest) {
    <<-EOS
      include 'hirs_provisioner'
    EOS
  }

  hosts.each do |host|
    it 'should enable SIMP dependencies repo' do
      # exclude SIMP repo, as we only want the SIMP deps repo
      install_simp_repos(host, ['simp'])
    end
  end

  hosts_with_role(hosts, 'hirs').each do |hirs_host|
    # This tests that nothing bad happens when the module is applied with no TPM
    context 'default parameters' do
      # Using puppet_apply as a helper
      it 'should work with no errors' do
        if hirs_host.host_hash[:roles].include?('tpm_2_0')
          package_name = 'HIRS_Provisioner_TPM_2_0'
        else hirs_host.host_hash[:roles].include?('tpm_1_2')
          package_name = 'HIRS_Provisioner_TPM_1_2'
        end
        apply_manifest_on(hirs_host, manifest, :catch_failures => true)
        check_for_package(hirs_host, package_name).should be false
      end

      it 'should be idempotent' do
        apply_manifest_on(hirs_host, manifest, :catch_changes => true)
      end
    end
  end
end
