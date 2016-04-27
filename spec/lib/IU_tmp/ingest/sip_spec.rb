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

  let(:tarball) { './spec/fixtures/IU/MDPI-SIP-package2.tar' }

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
    it 'returns an IU::Models::FileSet object' do
      expect(sip.access_copy).to be_a IU::Models::FileSet
    end

    it 'has properties from the access copy ffprobe xml from the SIP' do
      expect(sip.access_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-01_prod/MDPI_40000000788093.downloading/data/MDPI_40000000788093_01_access.mp4'
    end
  end

  describe '#mezzanine_copy' do
    it 'returns an IU::Models::FileSet object' do
      expect(sip.mezzanine_copy).to be_a IU::Models::FileSet
    end

    it 'has properties from the access copy ffprobe xml from the SIP' do
      expect(sip.mezzanine_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-01_prod/MDPI_40000000788093.downloading/data/MDPI_40000000788093_01_mezz.mov'
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

      it 'does not have any MDPI xml attached' do
        expect(sip.work.mdpi_xml.content).to be nil
      end
    end

    context 'after running #ingest!' do

      before { sip.ingest! }

      it 'has been saved' do
        expect(sip.work.persisted?).to eq true
      end

      it 'has an assocaited access copy' do
        expect(sip.work.access_copy).to be_a IU::Models::FileSet
      end

      it 'has an assocaited access copy' do
        expect(sip.work.mezzanine_copy).to be_a IU::Models::FileSet
      end

      it 'has an associated MDPI xml file' do
        expect(sip.work.mdpi_xml).to be_a XMLFile
      end
    end
  end
end
