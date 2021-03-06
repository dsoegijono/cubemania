require "cubing_average"
require "comparable_solve"

describe CubingAverage do
  it "saves singles" do
    singles = [stub, stub]
    CubingAverage.new(singles).singles.should == singles
  end

  it "accepts time as second attribute for .new, and caches it" do
    CubingAverage.new([stub], 40).time.should == 40
  end

  it "defaults to an empty single array" do
    CubingAverage.new.singles.should == []
  end

  it "allows more averages to be pushed in it" do
    old_single = stub
    new_single = stub
    average = CubingAverage.new([old_single])
    average << new_single
    average.singles.should == [old_single, new_single]
  end

  it "doesn't mess with the original singles array" do
    single = stub
    singles = [single]
    average = CubingAverage.new(singles)
    singles << stub
    average.singles.should == [single]
  end

  describe "#time" do
    let(:single_5) { stub :time => 5, :dnf? => false }
    let(:single_6) { stub :time => 6, :dnf? => false }
    let(:single_7) { stub :time => 7, :dnf? => false }
    let(:single_10) { stub :time => 10, :dnf? => false }
    let(:single_dnf) { stub :time => 20, :dnf? => true }

    before do
      single_5.extend(ComparableSolve)
      single_5.extend(ComparableSolve)
      single_6.extend(ComparableSolve)
      single_7.extend(ComparableSolve)
      single_10.extend(ComparableSolve)
      single_dnf.extend(ComparableSolve) # TODO omg, remove this shit by decoupling Single from ActiveRecord :)
    end

    it "actually changes if other times are pushed in" do
      average = CubingAverage.new([single_5] * 5)
      lambda {
        average << single_10
        average << single_10
      }.should change(average, :time)
    end

    it "returns nil for an empty singles array" do
      average = CubingAverage.new([])
      average.time.should == nil
    end

    context "one single" do
      it "returns the time" do
        CubingAverage.new([single_5]).time.should == 5
      end

      it "returns nil if the single is DNF" do
        CubingAverage.new([single_dnf]).time.should == nil
      end
    end

    context "five singles" do
      it "returns 10 for [10, 6, 7, 5, 5]" do
        singles = [single_10, single_6, single_7, single_5, single_5]
        CubingAverage.new(singles).time.should == 6
      end

      it "returns 5 for [dnf, 7, 6, 5, 5]" do
        singles = [single_dnf, single_7, single_6, single_5, single_5]
        CubingAverage.new(singles).time.should == 6
      end

      it "returns nil for [dnf, 5, 5, 5, dnf]" do
        singles = [single_dnf] + [single_5] * 3 + [single_dnf]
        CubingAverage.new(singles).time.should == nil
      end

      it "returns 6.67 for [7, 10, 6, 7, 5]" do
        singles = [single_7, single_10, single_6, single_7, single_5]
        ("%.2f" % CubingAverage.new(singles).time).should == "6.67"
      end
    end
  end

  describe "#dnf?" do
    it "returns true if time is nil" do
      average = CubingAverage.new
      average.stub(:time => nil)
      average.should be_dnf
    end
  end

  describe "best, worst" do
    let(:single_1) { stub :dnf? => false, :time => 40 }
    let(:single_2) { stub :dnf? => false, :time => 13 }
    let(:single_3) { stub :dnf? => false, :time => 23 }
    let(:single_dnf) { stub :dnf? => true, :time => 9 }

    before do
      single_1.extend(ComparableSolve)
      single_2.extend(ComparableSolve)
      single_3.extend(ComparableSolve)
      single_dnf.extend(ComparableSolve)
    end

    describe "#best" do
      it "returns the single with fastest time if everything's solved" do
        CubingAverage.new([single_1, single_2, single_3]).best.should == single_2
      end

      it "takes notice of dnf singles and ignores them" do
        CubingAverage.new([single_1, single_dnf]).best.should == single_1
      end

      it "chooses any single if all are dnf" do
        CubingAverage.new([single_dnf, single_dnf]).best.should == single_dnf
      end
    end

    describe "#worst" do
      it "returns the single with worst time if everything's solved" do
        CubingAverage.new([single_2, single_1, single_3]).worst.should == single_1
      end

      it "instantly chooses a dnf solve if there is any" do
        CubingAverage.new([single_1, single_dnf]).worst.should == single_dnf
      end
    end
  end

  describe "comparison" do
    def average(time, dnf = false)
      CubingAverage.new.tap do |a|
        a.stub(:time => time, :dnf? => dnf)
      end
    end

    describe "#==" do
      it "is equal if time and dnf are equal" do
        average = average 31
        other = average 31
        (average == other).should == true
      end
    end

    describe "both dnfs" do
      it "neither a < b nor a > b is true" do
        (average(12, true) < average(13, true)).should == false
        (average(12, true) > average(13, true)).should == false
      end
    end

    describe "#<" do
      context "is dnf, other is not a dnf" do
        it "is less than even if the times are greater" do
          average = average 100
          other = average 40, true
          (average < other).should ==true
        end
      end

      context "both are no dnfs" do
        it "is less than if the time is smaller" do
          average = average 100
          other = average 110
          (average < other).should == true
        end

        it "is not less than if the time is greater" do
          average = average 120
          other = average 110
          (average < other).should == false
        end
      end
    end
  end
end
