require 'rails_helper'
require 'IU/ingest/sip'

describe IU::Ingest::SIP do

  let(:depositor) do
    User.new(
      email: 'test.admin@hydradam.org',
      guest: false,
      password: 'password'
    )
  end

  let(:tarball) { './spec/fixtures/IU/40000000300048_20160213-082926.tar' }

  let(:sip) { IU::Ingest::SIP.new(depositor: depositor, tarball: tarball) }

  let(:sip_with_invalid_tarball) { IU::Ingest::SIP.new(depositor: depositor, tarball: 'this is not a valid tarball') }


  describe '#initialize' do
    context 'when the :tarball is not valid,' do
      it 'raises an InvalidTarfile error' do
        expect { sip_with_invalid_tarball }.to raise_error IU::Ingest::InvalidTarball
      end
    end
  end

  describe '#access_copy' do
    it 'returns a FileSet object' do
      expect(sip.access_copy).to be_a FileSet
    end

    it 'has properties from the access copy ffprobe xml from the SIP' do
      expect(sip.access_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-03_prod/MDPI_40000000300048.downloading/data/MDPI_40000000300048_01_access.mp4'
      expect(sip.access_copy.file_size).to eq [1240942508]
    end

    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.access_copy.original_checksum).to eq ['2e779723fdf58b5b2a60d2f71e7f2fe7']
    end

    it 'stores its quality level' do
      expect(sip.access_copy.quality_level.to_s).to eq 'access'
    end
  end

  describe '#mezzanine_copy' do
    it 'returns an FileSet object' do
      expect(sip.mezzanine_copy).to be_a FileSet
    end

    it 'has properties from the access copy ffprobe xml from the SIP' do
      expect(sip.mezzanine_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-03_prod/MDPI_40000000300048.downloading/data/MDPI_40000000300048_01_mezz.mov'
      expect(sip.mezzanine_copy.file_size).to eq [20716987011]
    end

    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.mezzanine_copy.original_checksum).to eq ['e5059f5b149f1688d39d0cf4c3d2a143']
    end

    it 'stores its quality level' do
      expect(sip.mezzanine_copy.quality_level.to_s).to eq 'mezzanine'
    end
  end

  describe '#work,' do
    context 'before running #ingest!,' do
      it 'does not have an associated access copy' do
        expect(sip.work.access_copy).to be nil
      end

      it 'does not have an associated mezzanine copy' do
        expect(sip.work.mezzanine_copy).to be nil
      end
    end

    context 'after running #ingest!' do

      before { sip.ingest! }

      it 'has been saved' do
        expect(sip.work.persisted?).to eq true
      end

      it 'has an assocaited access copy' do
        expect(sip.work.access_copy).to be_a FileSet
      end

      it 'has an assocaited access copy' do
        expect(sip.work.mezzanine_copy).to be_a FileSet
      end

      it 'has an associated MDPI xml file' do
        expect(sip.work.mdpi_xml).to be_a XMLFile
      end

      it 'has date values from MDPI xml file' do
        expect(sip.work.mdpi_date).to eq DateTime.parse('2015-11-17')
      end
    end
  end
end
