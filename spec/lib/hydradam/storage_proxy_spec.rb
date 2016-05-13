require 'hydradam/storage_proxy'
require 'rspec'

describe 'HydraDAM::StorageProxy' do

  subject do
    HydraDAM::StorageProxy.new
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
      it 'raises a MissingStorageProxyConnection'
    end
    context 'when valid connection to the proxy server exists' do
      it 'returns valid connection status'
    end
  end

  describe "#status" do
    context "when a file is in the cache" do
      it 'receives a status of staged'
    end
    context "when a file is not in the cache" do
      it 'receives a status of unstaged'
    end
  end

  describe "#stage" do
    context "when a file is not a valid file in a store" do
      it 'receives a status of invalid file'
    end
    context "when a file is not in the cache" do
      it 'can post a job to have to it staged'
    end
  end

  describe "#unstage" do
    context "when a file is in the cache" do
      it 'can post a job to have to have it unstaged'
    end
  end

  describe "#fixity" do
    context "when a file is not a valid file in a store" do
      it 'receives a status of invalid file'
    end
    context "when a file does not have current fixity value" do
      it 'can post a job to have to begin a fixity check'
    end
  end

  describe "#available_actions" do

  end


end