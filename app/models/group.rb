class Group
  include MongoMapper::Document
  include Support::Sluggizer
  include MongoMapperExt::Storage
  timestamps!

  key :_id, String
  slug_key :name
  key :name, String, :required => true
  key :subdomain, String
  key :domain, String
  key :legend, String
  key :description, String
  key :categories, Array
  key :default_tags, Array
  key :has_custom_ads, Boolean, :default => false
  key :state, String, :default => "pending" #pending, active, closed
  key :isolate, Boolean, :default => false
  key :private, Boolean, :default => false
  key :theme, String, :default => "shapado"
  key :owner_id, String
  key :analytics_id, String
  key :analytics_vendor, String
  key :has_custom_analytics, Boolean, :default => false
  key :language, String
  key :activity_rate, Float, :default => 0.0
  file_key :custom_css

  key :has_reputation_constrains, Boolean, :default => true
  key :reputation_rewards, Hash, :default => REPUTATION_REWARDS
  key :reputation_constrains, Hash, :default => REPUTATION_CONSTRAINS

  has_many :memberships, :class_name => "Member",
                         :foreign_key => "group_id",
                         :dependent => :destroy
  has_many :ads, :dependent => :destroy
  has_many :widgets, :dependent => :destroy, :order => "position asc", :polymorphic => true
  has_many :badges, :dependent => :destroy
  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy

  belongs_to :owner, :class_name => "User"
  has_many :comments, :as => "commentable", :dependent => :destroy

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..400
  validates_length_of       :legend,         :maximum => 40
  validates_length_of       :default_tags,   :within => 0..15,
      :message =>  I18n.t('activerecord.models.default_tags_message')
  validates_uniqueness_of   :name
  validates_uniqueness_of   :subdomain
  validates_presence_of     :subdomain
  validates_format_of       :subdomain, :with => /^[a-z0-9\-]+$/i
  validates_length_of       :subdomain, :within => 3..32

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES, :allow_nil => true
  validates_inclusion_of :theme, :within => AVAILABLE_THEMES

  before_validation_on_create :check_domain
  validate :check_reputation_configs

  def check_domain
    if domain.blank?
      self[:domain] = "#{subdomain}.#{AppConfig.domain}"
    end
  end

  def context_panel_ads
    if has_custom_ads == true
      ads = []
      Ad.find_all_by_group_id_and_position(id,'context_panel').each do |ad|
        ads << ad.code
      end
      return ads.join
    end
    "<!--Ad Bard advertisement snippet, begin -->
      <script type='text/javascript'>
      var ab_h = '#{AppConfig.adbard_host_id}';
      var ab_s = '#{AppConfig.adbard_site_key}';
      </script>
      <script type='text/javascript' src='http://cdn1.adbard.net/js/ab1.js'></script>
      <!--Ad Bard, end -->"
  end

  def header_ads
    if has_custom_ads
      ads = []
      Ad.find_all_by_group_id_and_position(id,'header').each do |ad|
        ads << ad.code
      end
      return ads.join
    end
  end

  def content_ads
    if has_custom_ads
      ads = []
      Ad.find_all_by_group_id_and_position(id,'content').each do |ad|
        ads << ad.code
      end
      return ads.join
    end
  end

  def footer_ads
    if has_custom_ads
      ads = []
      Ad.find_all_by_group_id_and_position(id,'footer').each do |ad|
        ads << ad.code
      end
      return ads.join
    end
  end

  def default_tags=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:default_tags] = c
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

  def pending?
    state == "pending"
  end

  def on_activity(action)
    value = 0
    case action
      when :ask_question
        value = 0.1
      when :answer_question
        value = 0.3
    end

    self.collection.update({:_id => self._id}, {:$inc => {:activity_rate => value}},
                                                               :upsert => true)
  end

  def has_custom_css?
    metaclass.keys.has_key?(:_custom_css)
  end

  def language=(lang)
    if lang != "none"
      self[:language] = lang
    else
      self[:language] = nil
    end
  end

  def self.humanize_reputation_constrain(key)
    I18n.t("groups.shared.reputation_constrains.#{key}", :default => key.humanize)
  end

  def self.humanize_reputation_rewards(key)
    I18n.t("groups.shared.reputation_rewards.#{key}", :default => key.humanize)
  end

  def check_reputation_configs
    self.reputation_constrains.each do |k,v|
      self.reputation_constrains[k] = v.to_i
      if !REPUTATION_CONSTRAINS.has_key?(k)
        self.errors.add(:reputation_constrains, "Invalid key")
        return false
      end
    end

    self.reputation_rewards.each do |k,v|
      self.reputation_rewards[k] = v.to_i
      if !REPUTATION_REWARDS.has_key?(k)
        self.errors.add(:reputation_rewards, "Invalid key")
        return false
      end
    end

    return true
  end
end
