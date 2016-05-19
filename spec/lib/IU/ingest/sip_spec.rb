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

  let(:sip) { IU::Ingest::SIP.new(depositor: depositor, tarball: './spec/fixtures/IU/sip.tar') }
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
      expect(sip.access_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-04_prod/MDPI_40000000054496.downloading/data/MDPI_40000000054496_01_access.mp4'
      expect(sip.access_copy.file_size).to eq [183868943]
    end

    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.access_copy.original_checksum).to eq ['f4c3088d835d35d8741551cf4e8977f0']
    end

    it 'stores its quality level' do
      expect(sip.access_copy.quality_level.to_s).to eq 'access'
    end
  end

  describe '#production_copy' do

    it 'returns an FileSet object' do
      expect(sip.production_copy).to be_a FileSet
    end

    it 'has properties from the access copy ffprobe xml from the SIP' do
      expect(sip.production_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-04_prod/MDPI_40000000054496.downloading/data/MDPI_40000000054496_01_prod.wav'
      expect(sip.production_copy.file_size).to eq [1352884274]
    end

    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.production_copy.original_checksum).to eq ['7892355550c1105c0144d95ec7d3820f']
    end

    it 'stores its quality level' do
      expect(sip.production_copy.quality_level.to_s).to eq 'production'
    end

    context 'when the production file is actually suffixed with _mezz' do
      let(:sip) { IU::Ingest::SIP.new(depositor: depositor, tarball: './spec/fixtures/IU/sip_with_mezzanine.tar') }

      it 'returns an FileSet object' do
        expect(sip.production_copy).to be_a FileSet
      end

      it 'has properties from the access copy ffprobe xml from the SIP' do
        expect(sip.production_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-02_prod/MDPI_40000000542243.downloading/data/MDPI_40000000542243_01_mezz.mov'
        expect(sip.production_copy.file_size).to eq [12776066312]
      end

      it 'gets its value for #original_checksum from the SIP checksum manifest' do
        expect(sip.production_copy.original_checksum).to eq ['34c57239b79ed6e16a428852af1f758b']
      end

      it 'stores its quality level' do
        expect(sip.production_copy.quality_level.to_s).to eq 'production'
      end
    end

  end
  
  describe '#preservation_copy' do
    it 'returns a FileSet object' do
      expect(sip.preservation_copy).to be_a FileSet
    end
    
    it 'has properties from the pres copy ffprobe xml from the SIP' do
       expect(sip.preservation_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-04_prod/MDPI_40000000054496.downloading/data/MDPI_40000000054496_01_pres.wav'
       expect(sip.preservation_copy.file_size).to eq [1352884274]
    end
    
    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.preservation_copy.original_checksum).to eq ['a0f9e4c05b1307788734229c3023f191']
    end
    
    it 'stores its quality level' do
      expect(sip.preservation_copy.quality_level.to_s).to eq 'preservation'
    end
  end
  
  describe '#work,' do
    context 'before running #ingest!,' do
      it 'does not have an associated access copy' do
        expect(sip.work.access_copy).to be nil
      end
      
      it 'does not have an associated pres copy' do
        expect(sip.work.preservation_copy).to be nil
      end
      
      it 'does not have an associated prod copy' do
        expect(sip.work.production_copy).to be nil
      end
    end

    context 'after running #ingest!' do

      before { sip.ingest! }

      it 'has been saved' do
        expect(sip.work.persisted?).to eq true
      end

      it 'has an associated access copy' do
        expect(sip.work.access_copy).to be_a FileSet
      end
      
      it 'has an associated preservation copy' do
        expect(sip.work.preservation_copy).to be_a FileSet
      end
      
      it 'has an associated production copy' do
        expect(sip.work.production_copy).to be_a FileSet
      end

      it 'has an associated MDPI xml file' do
        expect(sip.work.mdpi_xml).to be_a XMLFile
      end

      it 'has date values from MDPI xml file' do
        expect(sip.work.mdpi_date).to eq DateTime.parse('2015-12-03')
      end
    end
  end
end
