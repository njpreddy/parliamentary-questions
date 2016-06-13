require 'feature_helper'


feature 'Non-production banner' do
  scenario 'is shown' do
    visit '/'
    expect(page).to have_selector '#wrapper .staging_banner'
  end
end

