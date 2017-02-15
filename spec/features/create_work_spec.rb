require 'rails_helper'

RSpec.feature 'Creating a new Work' do
  let(:user) { create(:user) }

  before do
    login_as user, scope: :user
  end
end
