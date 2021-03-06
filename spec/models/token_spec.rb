require 'spec_helper'

describe Token do

  describe 'associations' do
    it { should belong_to(:user) }
    it { should validate_uniqueness_of(:value) }
  end

  let(:token) { Token.create!({:action => 'test'}) }
  before(:each) { token.user_id = 1 }

  describe '#before_create' do
    it "should set token value" do
      ActiveSupport::SecureRandom.stub(:hex).and_return('hex')
      token.before_create
      token.value.should == 'hex'
    end

    it "should delete previous matching tokens" do
      previous = Token.create!({:action => 'test delete_previous_tokens', :created_at => 1.hour.ago, :user_id => 2})
      Token.create!({:action => 'test delete_previous_tokens', :user_id => 2})
      Token.find_by_id(previous.id).should == nil
    end
  end

  describe '#expired?' do
    it "returns true if expired" do
      token.created_at = Time.now - 40.days
      token.should be_expired
    end

    it "returns false if not expired" do
      token.created_at = Time.now - 20.days
      token.should_not be_expired
    end
  end

  describe '.destroy_expired' do
    it "deletes expired tokens" do
      token.created_at = Time.now - 20.days
      token.save
      Token.destroy_expired
      Token.find_by_id(token.id).should == token
      token.created_at = Time.now - 40.days
      token.save
      Token.destroy_expired
      Token.find_by_id(token.id).should == nil
    end
  end
end
