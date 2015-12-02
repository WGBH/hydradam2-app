# Generated via
#  `rails generate curation_concerns:work Asset`
require 'rails_helper'
require 'fixtures'
require 'pry'

describe Asset, :requires_fedora do

  describe "#assign_properties_from_pbcore_file" do
    let(:xml_file_containing_malformed_xml) { XMLFile.new.tap { |pcdm_file| pcdm_file.content = rand(999999) } }

    # TODO: Tests are too tightly coupled to fixtures. Create a factory form making PBCore XML?
    let(:xml_file_containing_pbcore) { XMLFile.new.tap { |pcdm_file| pcdm_file.content = Fixtures.read('pbcore/pbcore_2_0.xml') } }
    let(:pbcore_fixture_titles) { ["Abiyoyo", "Teachers' Domain", "Between the Lions"] }


    context "when it does not have an associated PBCore file" do
      before { subject.assign_properties_from_pbcore_file }

      it "does not assign properties from a PBCore file" do
        pbcore_fixture_titles.each do |pbcore_fixture_title|
          expect(subject.title).to_not include pbcore_fixture_title
        end
      end
    end

    context "when it contains a file that is not valid PBCore" do
      before { subject.pbcore = xml_file_containing_malformed_xml }

      it 'raises an error' do
        expect { subject.assign_properties_from_pbcore_file }.to raise_error Asset::InvalidPBCore
      end
      
    end

    context "when it has an associated PBCore file" do
      before do
        subject.pbcore = xml_file_containing_pbcore
        subject.assign_properties_from_pbcore_file
      end

      it "gets titles from PBCore" do
        pbcore_fixture_titles.each do |title|
          expect(subject.title).to include title
        end
      end

      it "gets legacy Artesia UOI_ID from PBCore" do
        expect(subject.artesia_uoi_id).to include "1239bc73be2a2d4b6e9e81092e0793d8608899ef"
      end

      # TODO: be more descriptive in this tests
      it "gets other fields from PBCore" do
        expect(subject.file_size).to include "1141680000"
        expect(subject.filename).to include "BTL07_vid_abiyoyo.dv"
        expect(subject.lto_path).to include "barcode339795/aapb_001b63a401f3_20140131172021/1239bc73be2a2d4b6e9e81092e0793d8608899ef/BTL07_vid_abiyoyo.dv"
        expect(subject.dimension_annotation).to include "(Video Track 1) width/height/depth : 720 / 480 / 24 "
        expect(subject.description).to include "This video segment from Between the Lions stars Theo the Lion reading aloud the story of Abiyoyo, a South African tale packed with suspense, heroic characters, and new words."
      end
    end
  end
end