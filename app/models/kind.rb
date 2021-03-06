class Kind < ActiveRecord::Base
  has_many :puzzles, :order => 'name', :dependent => :destroy

  validates_presence_of :name
  validates_length_of :name, :maximum => 64
  validates_length_of :short_name, :maximum => 10
  validates_uniqueness_of :name, :short_name

  def self.all
    find :all, :include => :puzzles
  end
end
