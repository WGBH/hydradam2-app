require 'rails_helper'

describe FileSet, :requires_fedora do

  before do
    subject.apply_depositor_metadata 'test@example.com'
    subject.save!
  end

  describe '#fits=' do
    it 'accepts a class of type XMLFile' do
      expect{ subject.fits = XMLFile.new }.to_not raise_error
    end
  end
end