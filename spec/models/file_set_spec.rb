require 'rails_helper'

describe FileSet, :requires_fedora do

  before do
    subject.apply_depositor_metadata 'test@example.com'
    subject.save!
  end

  describe '#technical_metadata=' do
    it 'accepts a class of type XMLFile' do
      expect{ subject.technical_metadata = XMLFile.new }.to_not raise_error
    end
  end
end