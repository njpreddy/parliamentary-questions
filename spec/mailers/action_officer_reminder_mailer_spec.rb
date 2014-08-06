require 'spec_helper'

describe 'ActionOfficerReminderMailer' do

  let(:ao) { create(:action_officer,  name: 'ao name 1', email: 'ao@ao.gov') }
  let(:minister_1) { create(:minister, name: 'Mr Name1 for Test') }

  before(:each) do
    @pq = create(:Pq, uin: 'HL789', question: 'test question?', member_name:'Asking MP', minister_id: minister_1.id, house_name: 'House of Lords')
    @ao_pq = ActionOfficersPq.new(action_officer_id: ao.id, pq_id: @pq.id)

    @template = Hash.new
    @template[:name] = ao.name
    @template[:email] = ao.emails
    @template[:uin] = @pq.uin
    @template[:question] = @pq.question
    @template[:member_name] = @pq.member_name
    @template[:house] = @pq.house_name
  end

  describe 'draft reminder' do
    describe 'deliver' do
      it 'should include house, member name and uin from PQ and AO name' do
        ActionOfficerReminderMailer.remind_accept_reject_email(@template).deliver

        mail = ActionMailer::Base.deliveries.first

        mail.html_part.body.should include @pq.member_name
        mail.html_part.body.should include @pq.house_name
        mail.html_part.body.should include @pq.uin
        mail.html_part.body.should include ao.name

        mail.text_part.body.should include @pq.member_name
        mail.text_part.body.should include @pq.house_name
        mail.text_part.body.should include @pq.uin
        mail.text_part.body.should include ao.name
      end
    end
  end
end