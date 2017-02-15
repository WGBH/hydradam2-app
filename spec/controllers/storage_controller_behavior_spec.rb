require 'rails_helper'
require 'hydradam/storage_proxy_client'

describe  CurationConcerns::FileSetsController, type: :controller do

  let(:depositor) do
    User.create(
        email: 'file_set.admin@hydradam.org',
        guest: false,
        password: 'password'
    )
  end

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
      it "routes get fixity" do
        expect(:get => "/concern/file_sets/bar/fixity").
            to route_to(:controller => "curation_concerns/file_sets", :action => "fixity", :id => "bar")
      end
    end

    describe 'configures a StorageProxyClient' do
      it 'can get StorageProxyClient connection' do
        expect(subject.send(:storage_proxy)).to be_kind_of(HydraDAM::StorageProxyClient)
      end
    end

  end

  # FIXME: rewrite for new preingest/ingest framework
  skip 'when signed in' do
    before { sign_in depositor }
    before { sip.ingest! }

    describe '#stage' do
      it "redirects_to :action => :show" do
        get :stage, id: sip.access_copy.id
        expect(subject).to redirect_to("/concern/file_sets/#{sip.access_copy.id}")
      end
      xit 'stores a JSON response from the storage proxy' do
        get :stage, id: sip.access_copy.id
        expect(JSON.parse(session['file_status_resp'])["type"]).to eq 'stage'
      end
    end

    describe '#unstage' do
      it "redirects_to :action => :show" do
        get :unstage, id: sip.access_copy.id
        expect(subject).to redirect_to("/concern/file_sets/#{sip.access_copy.id}")
      end
      xit 'stores a JSON response from the storage proxy' do
        get :unstage, id: sip.access_copy.id
        expect(JSON.parse(session['file_status_resp'])["type"]).to eq 'unstage'
      end
    end

    describe '#fixity' do
      it "redirects_to :action => :show" do
        get :fixity, id: sip.access_copy.id
        expect(subject).to redirect_to("/concern/file_sets/#{sip.access_copy.id}")
      end
      xit 'stores a JSON response from the storage proxy' do
        get :fixity, id: sip.access_copy.id
        expect(JSON.parse(session['file_status_resp'])["type"]).to eq 'fixity'
      end
      xit 'can set an optional type of checksum to request' do
        get :fixity, id: sip.access_copy.id, fixity_type: 'sha-1'
        expect(JSON.parse(session['file_status_resp'])["fixity_type"]).to eq 'sha-1'
      end
    end

  end

end
