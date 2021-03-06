# == Schema Information
#
# Table name: tokens
#
#  id           :integer          not null, primary key
#  path         :string(255)
#  token_digest :string(255)
#  expire       :datetime
#  entity       :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  acknowledged :string(255)
#  ack_time     :datetime
#

require 'spec_helper'

describe Token, :type => :model do

  context 'validations' do
    it { should validate_inclusion_of(:acknowledged).in_array( ['accept', 'reject', nil] ) }
  end


  describe 'accept/reject' do
    let(:token)         { FactoryBot.create :token }
    let(:frozen_time)   { Time.utc(2015, 5, 19, 12, 47, 33) }

    it 'should mark date and time it was accepted' do
      Timecop.freeze frozen_time do
        token.accept
        token.reload
        expect(token.acknowledged).to eq 'accept'
        expect(token.ack_time).to eq frozen_time
      end
    end

    it 'should mark date and time it was rejected' do
      Timecop.freeze frozen_time do
        token.reject
        token.reload
        expect(token.acknowledged).to eq 'reject'
        expect(token.ack_time).to eq frozen_time
      end
    end
  end


  describe 'acknowledged?' do
    it 'should return true if accepted' do
      t = FactoryBot.build(:token, :acknowledged => 'accept')
      expect(t.acknowledged?).to be true
    end

    it 'should return true if rejected' do
      t = FactoryBot.build(:token, :acknowledged => 'reject')
      expect(t.acknowledged?).to be true
    end

    it 'should return false if neither' do
      t = FactoryBot.build(:token)
      expect(t.acknowledged?).to be false
    end
  end


  describe '.watchlist_status' do
    let(:entity)  { "watchlist-#{Date.today.strftime('%d/%m/%Y')} 11:37" }
    let!(:token)   { FactoryBot.create :token, path: '/watchlist/dashboard', entity: entity }

    it 'should return false if the token has not been acknowledged' do
      expect(Token.watchlist_status).to be false
    end

    it 'should return true if the token has been acknowledged' do
      token.accept
      expect(Token.watchlist_status).to be true
    end
  end


  describe '.assignment_stats' do
    it 'should return the total number of assignment tokens and the number of unanswered assignment tokens' do
      start_of_day = Time.now.beginning_of_day
      FactoryBot.create :token, created_at: start_of_day + 100.minutes
      FactoryBot.create :token, created_at: start_of_day + 200.minutes
      FactoryBot.create :token, created_at: start_of_day + 300.minutes
      FactoryBot.create :token, created_at: start_of_day - 100.minutes
      FactoryBot.create :token, created_at: start_of_day - 100.minutes
      FactoryBot.create :token, created_at: start_of_day + 100.minutes
      FactoryBot.create :token, created_at: start_of_day + 200.minutes, acknowledged: 'accept', ack_time: start_of_day + 400.minutes
      FactoryBot.create :token, created_at: start_of_day + 300.minutes, acknowledged: 'accept', ack_time: start_of_day + 400.minutes
      FactoryBot.create :token, created_at: start_of_day - 100.minutes, acknowledged: 'accept', ack_time: start_of_day + 400.minutes
      FactoryBot.create :token, created_at: start_of_day - 100.minutes, acknowledged: 'reject', ack_time: start_of_day + 400.minutes

      expect(Token.assignment_stats).to eq( {total: 6, ack: 2, open: 4,  pctg: 33.33 } )
    end
  end

end
