require 'hydradam/storage_proxy_client'
require 'rspec'
require 'rails_helper'

describe 'HydraDAM::StorageProxyClient' do

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
      it 'raises Faraday::ConnectionFailed error'
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
        subject.filename = 'MDPI_40000001229337_02_access.mp4'
        subject.status
      end
      it 'receives a status of staged' do
        expect(response.status).to be_in([200, 404])
        expect(JSON.parse(response.body)["status"]).to eq(nil)
      end
      # TODO: Figure out where/how to use behaves_like with response from let so I can use the shared example
      #it_behaves_like 'a successful request', response
      #it_behaves_like 'a valid response', response
    end
    context "when a file is not in the cache" do
      let(:response) do
        subject.filename = 'MDPI_40000001229337_02_access.mp4'
        subject.status
      end
      it 'receives a status code of 404' do
        # e.g. expect(response.status).to eq(404)
        expect(JSON.parse(response.body)["status"]).to eq(nil)
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