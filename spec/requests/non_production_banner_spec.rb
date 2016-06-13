require 'spec_helper'

describe 'Staging banner', type: :request do
  it 'gets displayed' do
    get '/'
    follow_redirect! # since we're not logged in
    expect(response.body).to include 'This is not the live Parliamentary Questions Tracker environment'
  end
end
