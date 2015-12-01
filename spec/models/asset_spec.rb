# Generated via
#  `rails generate curation_concerns:work Asset`
require 'rails_helper'
require 'fixtures'
require 'pry'

describe Asset, :requires_fedora do


  let(:xml_file_containing_malformed_xml) { XMLFile.new.tap { |pcdm_file| pcdm_file.content = rand(999999) } }
  let(:xml_file_containing_pbcore) { XMLFile.new.tap { |pcdm_file| pcdm_file.content = Fixtures.read('pbcore/pbcore_2_0.xml') } }

  describe "#assign_properties_from_pbcore_file" do
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

      it "assigns titles from an uploaded PBCore file" do
        pbcore_fixture_titles.each do |pbcore_fixture_title|
          expect(subject.title).to include pbcore_fixture_title
        end
      end
    end
  end
end
