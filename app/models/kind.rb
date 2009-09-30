class Kind < ActiveRecord::Base
  has_many :puzzles, :order => 'name', :dependent => :destroy
  
  has_attached_file :image, :path => ":rails_root/public/images/:class/:id/:style/:basename.:extension",
                            :url => "/images/:class/:id/:style/:basename.:extension",
                            :styles => { :small => '12x12' }
  attr_protected :image_file_name, :image_content_type, :image_size
  
  validates_presence_of :name
  validates_length_of :name, :maximum => 64
  validates_attachment_size :image, :less_than => 10.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/png', 'image/gif']
  
  def self.all
    find :all, :include => :puzzles
  end
end