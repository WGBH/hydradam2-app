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

  let(:tarball) { './spec/fixtures/IU/40000000542243_20160222-232108.tar' }

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
      expect(sip.access_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-02_prod/MDPI_40000000542243.downloading/data/MDPI_40000000542243_01_access.mp4'
      expect(sip.access_copy.file_size).to eq [680347561]
    end

    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.access_copy.original_checksum).to eq ['d13be45c49cd966fb4a7e0bd02a757ba']
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
      expect(sip.mezzanine_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-02_prod/MDPI_40000000542243.downloading/data/MDPI_40000000542243_01_mezz.mov'
      expect(sip.mezzanine_copy.file_size).to eq [12776066312]
    end

    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.mezzanine_copy.original_checksum).to eq ['34c57239b79ed6e16a428852af1f758b']
    end

    it 'stores its quality level' do
      expect(sip.mezzanine_copy.quality_level.to_s).to eq 'mezzanine'
    end
  end
  
  describe '#pres_copy' do
    it 'returns a FileSet object' do
      expect(sip.pres_copy).to be_a FileSet
    end
    
    it 'has properties from the pres copy ffprobe xml from the SIP' do
       expect(sip.pres_copy.filename).to eq '/srv/scratch/transcoder_workspace_xcode-03_prod/MDPI_40000000054496.downloading/data/MDPI_40000000054496_01_pres.wav'
       expect(sip.pres_copy.file_size).to eq [1352884274]
    end
    
    it 'gets its value for #original_checksum from the SIP checksum manifest' do
      expect(sip.pres_copy.original_checksum).to eq ['a0f9e4c05b1307788734229c3023f191']
    end
    
    it 'stores its quality level' do
      expect(sip.pres_copy.quality_level.to_s).to eq 'pres'
    end
  end
  
  describe '#prod_copy' do
    it 'returns a FileSet object' do
      expect(sip.prod_copy).to be_a FileSet
    end
    
    it 'stores its quality level' do
      expect(sip.prod_copy.quality_level.to_s).to eq 'prod'
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
      
      it 'does not have an associated pres copy' do
        expect(sip.work.pres_copy).to be nil
      end
      
      it 'does not have an associated prod copy' do
        expect(sip.work.prod_copy).to be nil
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

      it 'has an assocaited mezzanine copy' do
        expect(sip.work.mezzanine_copy).to be_a FileSet
      end
      
      it 'has an assocaited pres copy' do
        expect(sip.work.pres_copy).to be_a FileSet
      end
      
      it 'has an assocaited prod copy' do
        expect(sip.work.prod_copy).to be_a FileSet
      end

      it 'has an associated MDPI xml file' do
        expect(sip.work.mdpi_xml).to be_a XMLFile
      end

      it 'has date values from MDPI xml file' do
        expect(sip.work.mdpi_date).to eq DateTime.parse('2016-01-15')
      end
    end
  end
end
