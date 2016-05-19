require 'hydradam/storage_proxy_client'
require 'rspec'
require 'rails_helper'
require 'webmock/rspec'


describe 'HydraDAM::StorageProxyClient' do

  before(:each) do
    WebMock.disable_net_connect!
    WebMock.stub_request(:get, "http://localhost:3001/caches/SDADisk/files/staged_file.mp4").
        with(:headers => {'Accept'=>'*/*'}).
        to_return(:status => 200, :body => '{"id":1,"name":"staged_file.mp4","status":"staged"}',
                  :headers => {"content-type":'application/json'})
    WebMock.stub_request(:get, "http://localhost:3001/caches/SDADisk/files/unstaged_file.mp4").
        with(:headers => {'Accept'=>'*/*'}).
        to_return(:status => 404, :body => "", :headers => {})
    WebMock.stub_request(:get, "http://localhost:3001/bar").
        with(:headers => {'Accept'=>'*/*'}).
        to_return(:status => 200, :body => "", :headers => {})
  end
  after(:each) do
    WebMock.allow_net_connect!
  end

  shared_examples 'a successful request' do |response|
    it 'returns an OK (200) status code' do
      expect(response.status).to be_in([200, 404])
    end
  end

  shared_examples 'a valid response' do |response|
    it "returns a valid JSON response" do
      expect(response.headers["content-type"]).to include("application/json")
    end
  end

  shared_examples 'an invalid file in a store' do |response|
    it 'returns invalid file status'
  end

  subject do
    HydraDAM::StorageProxyClient.new
  end

  it 'provides methods for invoking proxy interactions' do
    expect(subject).to respond_to :status
    expect(subject).to respond_to :stage
    expect(subject).to respond_to :unstage
    expect(subject).to respond_to :fixity
    expect(subject).to respond_to :available_actions
  end

  describe 'provides a connection to a proxy server for interactions' do
    context 'when connection to the proxy service does not exist' do
      let(:response) do
        subject.host = 'http://foo'
        subject.configure
        conn = subject.get_conn
        conn.get '/bar'
      end
      it 'raises Faraday::ConnectionFailed error' do
        # Disable WebMock for this test so we can cause a real error
        WebMock.allow_net_connect!
        expect(response).to
      end
    end
    context 'when valid connection to the proxy server exists' do
      let(:response) do
        conn = subject.get_conn
        conn.get '/bar'
      end
      it 'returns valid connection status' do
        expect(response.status).to be_in([200, 404])
      end
    end
  end

  describe "#status" do
    context "when a file is in the cache" do
      let(:response) do
        subject.filename = 'staged_file.mp4'
        subject.status
      end
      it 'receives a status of staged' do
        expect(response.status).to be_in([200, 404])
        expect(response.headers["content-type"]).to include("application/json")
        expect(JSON.parse(response.body)["name"]).to eq(subject.filename)
        expect(JSON.parse(response.body)["status"]).to eq("staged")
      end
      # TODO: Figure out where/how to use behaves_like with response from let so I can use the shared example
      #it_behaves_like 'a successful request', response
      #it_behaves_like 'a valid response', response
    end
    context "when a file is not in the cache" do
      let(:response) do
        subject.filename = 'unstaged_file.mp4'
        subject.status
      end
      it 'receives a status code of 404' do
        expect(response.status).to eq(404)
      end
      # TODO: Figure out where/how to use behaves_like with response from let so I can use the shared example
      #it_behaves_like 'a successful request', response
    end
  end

  describe "#stage" do
    context "when a file is not a valid file in a store" do
      it_behaves_like 'an invalid file in a store'
      #it_behaves_like 'a successful request'
    end
    context "when a file is not in the cache" do
      it 'can post a job to have to it staged'
      #it_behaves_like 'a successful request'
    end
  end

  describe "#unstage" do
    context "when a file is in the cache" do
      it 'can post a job to have to have it unstaged'
      #it_behaves_like 'a successful request'
    end
  end

  describe "#fixity" do
    context "when a file is not a valid file in a store" do
      it_behaves_like 'an invalid file in a store'
      #it_behaves_like 'a successful request'
    end
    context "when a file does not have current fixity value" do
      it 'can post a job to have to begin a fixity check'
      #it_behaves_like 'a successful request'
    end
  end

  describe "#available_actions" do

  end


end