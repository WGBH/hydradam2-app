require 'rails_helper'
require 'hydradam/file_set_behavior/has_ffprobe'

describe HydraDAM::FileSetBehavior::HasFfprobe, :requires_fedora do

  before :all do
    class TestClass < ActiveFedora::Base
      include HydraDAM::FileSetBehavior::HasFfprobe
    end
  end

  after :all do
    Object.send :remove_const, :TestClass
    # Unused class?
    # Object.send :remove_const, :DoesNotExtendActiveFedoraBase
  end

  let(:fake_user) { User.new(email: "test_user@hydradam.org", password: "password", guest: false) }

  subject do
    TestClass.new.tap do |obj|
      obj.apply_depositor_metadata fake_user
      obj.save!
    end
  end

  after(:all) do
    subject.delete rescue nil
  end

 # it 'exposes accessors #ffprobe and #ffprobe=' do
 #   expect(subject).to respond_to :ffprobe
 #   expect(subject).to respond_to :"ffprobe="
 # end

 context 'when the including class does not inherit from ActiveFedora::Base' do
    let(:class_with_missing_dependency) do
      # An anonymous class that includes the HydraDAM::FileSetBehavior::HasFfprobe
      # module but does not inherity from ActiveFedora::Base like it should
      Class.new do
        include HydraDAM::FileSetBehavior::HasFfprobe
      end
    end

    it 'raises an error' do
      expect{ class_with_missing_dependency }.to raise_error DependsOn::MissingDependencies
    end
  end
end
