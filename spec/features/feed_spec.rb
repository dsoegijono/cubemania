require "spec_helper"

describe "Activity feed" do
  let(:user) { login }
  let(:nick) { create :user, :name => "Nick" }
  let(:peter) { create :user, :name => "Peter" }

  before do
    user.follow! nick
    user.follow! peter
  end

  describe "follow activity" do
    before do
      create :follow_activity, :user => peter, :trackable => create(:following, :followee => nick)
      create :follow_activity, :user => user, :trackable => create(:following, :followee => peter)
    end

    it "displays a message for each following" do
      visit feed_path

      expect(page).to have_content "Peter started following Nick"
      expect(page).to have_content "#{user.name} started following Peter"
    end
  end

  describe "record activity" do
    before do
      create :record_activity, :user => peter, :trackable => create(:record, :puzzle => create(:cube), :amount => 1)
      create :record_activity, :user => nick, :trackable => create(:record, :puzzle => create(:cube_bld), :amount => 5)
    end

    it "displays a message for broken records" do
      visit feed_path

      expect(page).to have_content "Peter has a new 3x3x3 Single record"
      expect(page).to have_content "Nick has a new 3x3x3 BLD Average of 5 record"
    end
  end
end