# Generated via
#  `rails generate curation_concerns:work Work`
require 'rails_helper'

describe Work do
  subject do
    Work.new
  end
  it "has loaded IU behavior" do
    expect(subject).to respond_to :mdpi_xml
  end
end
