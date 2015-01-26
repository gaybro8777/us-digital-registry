# == Schema Information
#
# Table name: agencies
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  shortname       :string(255)
#  info_url        :string(255)
#  mongo_id        :string(255)
#  parent_mongo_id :string(255)
#  parent_id       :integer
#

class Agency < ActiveRecord::Base
  #handles logging of activity
  include PublicActivity::Model
  tracked owner: Proc.new{ |controller, model| controller.current_user }

  #handles versioning
  has_paper_trail
  #attr_accessible :name, :shortname, :info_url, :agency_contact_ids
  
  has_many :sponsorships
  has_many :outlets, :through => :sponsorships
  has_many :agency_contacts
  
  has_many :users
  
  belongs_to :parent, :class_name => "Agency"
  has_many :children, :foreign_key => "parent_id", :class_name => "Agency"

  validates :name, :presence => true
  # validates :shortname, :presence => true
  
  paginates_per 200

  def to_s
    self.name
  end
  
  def contact_emails(options = {})
    agency_contacts.where("email != ?", options[:excluding]).map do |contact|
      contact.email
    end
  end
  
  def name_with_count
    "#{name} (#{outlets_count} #{outlets_count == 1 ? 'account' : 'accounts'})"
  end
  
  def outlets_count
    Rails.cache.fetch(outlets_count_key, :expires_in => 1.hour) do
      outlets.count
    end
  end
  
  def clear_outlets_count
    Rails.cache.delete(outlets_count_key)
  end
  
  def outlets_count_key
    "agency/#{id}/outlets_count"
  end

  def history
    @versions = PaperTrail::Agencies.order('created_at DESC')
  end
end
