require 'spec_helper_acceptance'

test_name 'hirs_provisioner class'

describe 'hirs_provisioner class' do

  #create a local repo with the necessary HIRS rpms
  #this can be replaced later when the packages are signed and added to the extras repo
  def create_local_repo(hirs)
    #hirs.each { |hirs| hirs.install_package('createrepo') }
    #hosts.each { |hirs| hirs.install_package('createrepo') }
    hirs.install_package('createrepo')
    on hirs, 'mkdir /usr/local/repo'
    on hirs, 'cd /usr/local/repo; curl -L -O https://github.com/nsacyber/HIRS/releases/download/v1.0.2/HIRS_Provisioner_TPM_2_0-1.0.2-1541093721.d1bdf9.el7.x86_64.rpm'
    on hirs, 'cd /usr/local/repo; curl -L -O https://github.com/nsacyber/HIRS/releases/download/v1.0.2/HIRS_Provisioner_TPM_1_2-1.0.2-1541093721.d1bdf9.el6.noarch.rpm'
    on hirs, 'cd /usr/local/repo; curl -L -O https://github.com/nsacyber/HIRS/releases/download/v1.0.2/HIRS_Provisioner_TPM_1_2-1.0.2-1541093721.d1bdf9.el7.noarch.rpm'
    on hirs, 'cd /usr/local/repo; curl -L -O https://github.com/nsacyber/HIRS/releases/download/v1.0.2/tpm_module-1.0.2-1541093721.d1bdf9.x86_64.rpm'
    on hirs, 'cd /usr/local/repo; curl -L -O https://github.com/nsacyber/paccor/releases/download/v1.0.6r3/paccor-1.0.6-3.noarch.rpm'
    on hirs, 'createrepo /usr/local/repo'
    on hirs, 'printf "[local.repo]\nname=local\nbaseurl=file:///usr/local/repo\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/local.repo'
  end

  #install an aca for the provisioners to talk to
  def setup_aca(aca)
    on aca, 'curl -L -O https://github.com/nsacyber/HIRS/releases/download/v1.0.2/HIRS_AttestationCA-1.0.2-1541093721.d1bdf9.el7.noarch.rpm'
    on aca, 'yum install -y mariadb-server openssl tomcat java-1.8.0 rpmdevtools coreutils initscripts chkconfig sed grep firewalld policycoreutils'
    on aca, 'yum localinstall -y HIRS_AttestationCA-1.0.2-1541093721.d1bdf9.el7.noarch.rpm'
  end



  let(:manifest) {
    <<-EOS
      include 'hirs_provisioner'
    EOS
  }

  let(:hieradata) {
    <<-EOS
---
hirs_provisioner::config::aca_fqdn: aca
    EOS
  }

  context 'set up aca' do
#    before { setup_aca(aca) }
    it 'should start the aca server' do
#begin
#require 'pry'; binding.pry
      aca_host = only_host_with_role( hosts, 'aca' )
      setup_aca(aca_host)
#rescue Exception => e
#require 'pry'; binding.pry
#end
    end
  end

  context 'with a tpm' do
    hosts_with_role(hosts, 'hirs').each do |hirs_host|

      it 'should work with no errors' do
        set_hieradata_on(hirs_host, hieradata)
        create_local_repo(hirs_host)
        apply_manifest_on(hirs_host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(hirs_host, manifest, :catch_changes => true)
      end

      describe package('HIRS_Provisioner_TPM_1_2') do
        it { is_expected.to be_installed }
      end

    end
  end
end
