require 'feature_helper'

feature "Parli-branch manages trim link" , js: true do
  def add_trim_link
    click_link 'Trim link'
    attach_file('pq[trim_link_attributes][file]', Rails.root.join('spec/fixtures/trimlink.tr5'))
    click_button 'Save'
    click_link 'Trim link'
  end

  before(:each) do
    DBHelpers.load_feature_fixtures
    create_pq_session
    @pq, _ = PQA::QuestionLoader.new.load_and_import
  end

  feature 'from the details view' do
    scenario 'adding a trim link' do
      visit pq_path(@pq.uin)
      expect(page).not_to have_link 'Open trim link'
      add_trim_link
      expect(page).to have_link 'Open trim link'
    end

    scenario 'change a trim link' do
      visit pq_path(@pq.uin)
      add_trim_link
      expect(page).to have_content 'Change trim link'
      attach_file('pq[trim_link_attributes][file]', Rails.root.join('spec/fixtures/another_trimlink.tr5'))
      click_button 'Save'
      pq = Pq.find_by(uin: @pq.uin)
      expect(pq.trim_link.filename).to eq('another_trimlink.tr5')
    end

    scenario 'remove a trim link' do
      visit pq_path(@pq.uin)
      add_trim_link
      save_screenshot('out.png')
      click_button 'Delete'
      save_screenshot('out.png')
      click_link 'Trim link'
      expect(page).not_to have_link 'Open trim link'
    end

    scenario 'undo a removed trim link' do
      visit pq_path(@pq.uin)
      add_trim_link
      click_button 'Delete'
      click_link 'Trim link'
      expect(page).to have_content 'Trim link deleted'
      click_button 'Undo'
      click_link 'Trim link'
      expect(page).to have_link 'Open trim link'
    end

    scenario 'invalid trim link retains other changed fields and previous trim link' do
      visit pq_path(@pq.uin)
      add_trim_link
      click_link 'PQ Details'
      fill_in 'Date for answer back to Parliament', with: '01/01/2001'
      click_link 'Trim link'
      attach_file('pq[trim_link_attributes][file]', Rails.root.join('spec/fixtures/invalid_trimlink.tr5'))
      click_button 'Save'
      expect(page).to have_content 'Missing or invalid trim link file'
      expect(page).to have_field 'Date for answer back to Parliament', with: '01/01/2001'
    end
  end

  feature 'Parli-branch manages trim-links from the dashboard' do
    let(:ao1)      { ActionOfficer.find_by(email: 'ao1@pq.com') }
    let(:minister) { Minister.first                             }
    include Features::PqHelpers

    scenario "uploading a valid trim file" do
      visit dashboard_path
      commission_question(@pq.uin, [ao1], minister)
      visit dashboard_path
      attach_file('Choose Trim file', Rails.root.join('spec/fixtures/trimlink.tr5'))

      within_pq(@pq.uin) do
        save_screenshot('out.png')
        click_on "Upload"
      end
      expect(page).to have_text('Happy friday!')
    end
  end
end
