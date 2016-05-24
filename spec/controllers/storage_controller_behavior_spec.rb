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
        expect(subject.send(:get_proxy_client)).to be_kind_of(HydraDAM::StorageProxyClient)
      end
    end

  end

  describe 'when signed in' do
    before { sign_in depositor }
    before { sip.ingest! }

    describe '#show' do

      it "redirects_to :action => :show" do
        #get :show, id: sip.access_copy.id, next_action: 'stage'
        #expect(subject).to redirect_to :action => :show, :id => sip.access_copy.id
      end
      context 'params[:next_action] eq file_status' do
        it 'stores a JSON response from the storage proxy' do
          get :show, id: sip.access_copy.id, next_action: 'file_status'
          expect(JSON.parse(assigns(:file_status_resp))["name"]).to eq File.basename(sip.access_copy.filename)
        end
      end
      context 'params[:next_action] eq stage' do
        it 'stores a JSON response from the storage proxy' do
          get :show, id: sip.access_copy.id, next_action: 'stage'
          expect(JSON.parse(assigns(:file_status_resp))["type"]).to eq 'stage'
        end
      end
      context 'params[:next_action] eq unstage' do
        it 'stores a JSON response from the storage proxy' do
          get :show, id: sip.access_copy.id, next_action: 'unstage'
          expect(JSON.parse(assigns(:file_status_resp))["type"]).to eq 'unstage'
        end
      end

    end

    describe '#file_status' do

      it "redirects_to :action => :show" do
        #get :show, id: sip.access_copy.id, next_action: 'file_status'
        #expect(subject).to redirect_to :action => :show, :id => sip.access_copy.id
      end
      it 'stores a JSON response from the storage proxy' do
        #get :file_status, id: sip.access_copy.id
        #expect(assigns(:file_status_resp)).to eq 'some valid JSON'
      end
    end

    describe 'GET #stage_curation_concerns_file_set' do

    end

    describe 'GET #unstage_curation_concerns_file_set' do

    end
  end

end
