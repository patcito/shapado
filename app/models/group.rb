class Group
  include MongoMapper::Document
  include Support::Sluggizer

  key :_id, String
  slug_key :name
  key :name, String, :required => true
  key :subdomain, String
  key :domain, String
  key :legend, String
  key :description, String
  key :categories, Array

  key :state, String, :default => "pending" #pending, active, closed

  key :owner_id, String
  belongs_to :owner, :class_name => "User"

  has_many :memberships, :class_name => "Member",
                         :foreign_key => "group_id",
                         :dependent => :destroy


  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..400
  validates_length_of       :legend,         :maximum => 40
  validates_uniqueness_of   :name
  validates_uniqueness_of   :subdomain
  validates_presence_of     :subdomain
  validates_format_of       :subdomain, :with => /^[a-z0-9\-]+$/i
  validates_length_of       :subdomain, :within => 3..32

  def categories=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:categories] = c
  end
  alias :user :owner

  def members(opts={})
    members_ids = memberships.paginate(opts.merge({:fields => "user_id"})).map do |member|
      member.user_id
    end

    if members_ids.empty?
      page = MongoMapper::Pagination::PaginationProxy.new(0, 1, 25);
      page.subject = []
      return page
    end

    default_opts = {:conditions => {:_id => {:$in => members_ids}}}
    User.paginate(opts.merge(default_opts))
  end

  def is_member?(user)
    if user.kind_of?(User)
      !memberships.first(:user_id => user.id).nil?
    else
      false
    end
  end

  def add_member(user, role)
    member = Member.new( :group_id => self._id,
                         :user_id => user._id,
                         :role => role)
    member.save
    member
  end

  def logo_data=(data)
    logo = self.logo
    if data.respond_to?(:read)
      logo.image = data.read
      ext = data.original_filename.split(".").last
      logo.ext = ext if ext
    elsif data.kind_of?(String)
      logo.image = File.read(data)
      ext = data.split(".").last
      logo.ext = ext if ext
    end
    logo.group = self

    logo.save
  end

  def logo
    @logo ||= (Logo.find(:first, :group_id => self._id) || Logo.new)
  end

end

