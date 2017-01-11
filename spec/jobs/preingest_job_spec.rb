# to test app/jobs/preingest_job.rb
# there also needs to be a corresponding rake task in lib/tasks; I've copied the pmp one
require 'rails_helper'

RSpec.describe PreingestJob do
  let(:user) { FactoryGirl.build(:admin) }
  shared_examples "successfully preingests" do
    it "writes the expected yaml output" do
      yaml_content = File.open(yaml_file) { |f| Psych.load(f) }
      yaml_content[:sources][0][:file] = Rails.root.join(yaml_content[:sources][0][:file]).to_s
      expect(File).to receive(:write).with(yaml_file, yaml_content.to_yaml)
      described_class.perform_now(document_class, preingest_file, user)
    end
  end

  skip "preingesting a METS file" do # FIXME: rewrite
    let(:mets_file_single) { Rails.root.join("spec", "fixtures", "pudl_mets", "pudl0001-4612596.mets").to_s }
    let(:mets_file_rtl) { Rails.root.join("spec", "fixtures", "pudl_mets", "pudl0032-ns73.mets").to_s }
    let(:mets_file_multi) { Rails.root.join("spec", "fixtures", "pudl_mets", "pudl0001-4609321-s42.mets").to_s }
    let(:yaml_file) { preingest_file.sub(/\.mets$/, '.yml') }
    let(:document_class) { PreingestableMETS }

    context "with a single-volume mets file", vcr: { cassette_name: 'bibdata-bhr9405' } do
      let(:preingest_file) { mets_file_single }
      include_examples "successfully preingests"
    end
    context "with a right-to-left mets file", vcr: { cassette_name: 'bibdata-bhr9405' } do
      let(:preingest_file) { mets_file_rtl }
      include_examples "successfully preingests"
    end
    context "preingests a multi-volume yaml file", vcr: { cassette_name: 'bibdata-bhr9405' } do
      let(:preingest_file) { mets_file_multi }
      include_examples "successfully preingests"
    end
  end
end
