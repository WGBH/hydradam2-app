require 'rails_helper'
require 'hydradam/storage_proxy_client'
require 'IU/ingest/sip'

describe  CurationConcerns::FileSetsController, type: :controller do

  let(:depositor) do
    User.create(
        email: 'file_set.admin@hydradam.org',
        guest: false,
        password: 'password'
    )
  end

  let(:sip) { IU::Ingest::SIP.new(depositor: depositor, tarball: './spec/fixtures/IU/sip.tar') }

  context 'including StorageControllerBehavior' do

    describe 'adds routing' do
      it "routes get file_status" do
        expect(:get => "/concern/file_sets/bar/file_status").
            to route_to(:controller => "curation_concerns/file_sets", :action => "file_status", :id => "bar")
      end
      it "routes get stage" do
        expect(:get => "/concern/file_sets/bar/stage").
            to route_to(:controller => "curation_concerns/file_sets", :action => "stage", :id => "bar")
      end
      it "routes get unstage" do
        expect(:get => "/concern/file_sets/bar/unstage").
            to route_to(:controller => "curation_concerns/file_sets", :action => "unstage", :id => "bar")
      end
    end

    describe 'configures a StorageProxyClient' do
      it 'can get StorageProxyClient connection' do
        expect(subject.send(:storage_proxy)).to be_kind_of(HydraDAM::StorageProxyClient)
      end
    end

  end

  describe 'when signed in' do
    before { sign_in depositor }
    before { sip.ingest! }

    describe '#file_status' do
      it "redirects_to :action => :show" do
        get :file_status, id: sip.access_copy.id
        expect(subject).to redirect_to("/concern/file_sets/#{sip.access_copy.id}")
      end
      it 'stores a JSON response from the storage proxy' do
        get :file_status, id: sip.access_copy.id
        expect(JSON.parse(session['file_status_resp'])["name"]).to eq File.basename(sip.access_copy.filename)
      end
    end

    describe '#stage' do
      it "redirects_to :action => :show" do
        get :stage, id: sip.access_copy.id
        expect(subject).to redirect_to("/concern/file_sets/#{sip.access_copy.id}")
      end
      it 'stores a JSON response from the storage proxy' do
        get :stage, id: sip.access_copy.id
        expect(JSON.parse(session['file_status_resp'])["type"]).to eq 'stage'
      end
    end

    describe '#unstage' do
      it "redirects_to :action => :show" do
        get :unstage, id: sip.access_copy.id
        expect(subject).to redirect_to("/concern/file_sets/#{sip.access_copy.id}")
      end
      it 'stores a JSON response from the storage proxy' do
        get :unstage, id: sip.access_copy.id
        expect(JSON.parse(session['file_status_resp'])["type"]).to eq 'unstage'
      end
    end

  end

end
