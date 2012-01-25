require 'spec_helper'

describe Average do
  describe "validations" do
    let(:competition) { create :competition, :repeat => "weekly" }
    let(:user) { create :user }

    it { should validate_presence_of :time }
    it { should validate_presence_of :user_id }
    it { should validate_presence_of :puzzle_id }
    it { should validate_presence_of :competition_id }

    it "can compete twice in a competition" do
      create :average, :competition => competition, :user => user

      Timecop.freeze(Date.today + 8) do
        average = build :average, :competition => competition, :user => user
        average.should be_valid
      end
    end

    it "cannot compete twice in the same week" do
      create :average, :competition => competition, :user => user

      average = build :average, :competition => competition, :user => user
      average.should_not be_valid
    end
  end

  it "calculates average before validation" do
    cubing_average = stub(:time => 1337, :dnf? => false)
    singles = FactoryGirl.build_list :single, 5
    CubingAverage.should_receive(:new).with(singles).and_return(cubing_average)
    average = FactoryGirl.build :average, :time => nil, :singles => singles
    average.valid?
    average.time.should == 1337
  end

  it "sets average to dnf if the " do
    cubing_average = stub(:time => nil, :dnf? => true)
    singles = FactoryGirl.build_list :single, 5
    CubingAverage.should_receive(:new).with(singles).and_return(cubing_average)
    average = Average.new(:singles => singles)
    average.valid?
    average.dnf.should == true
  end

  describe "#destroy" do
    it "removes all singles if it gets destroyed" do
      singles = create_list :single, 5
      average = create :average, :singles => singles
      lambda {
        average.destroy
      }.should change(Single, :count).by(-5)
    end
  end
end
