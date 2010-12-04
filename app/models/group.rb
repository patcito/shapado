class Group
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Storage
  include MongoMapperExt::Filter

  timestamps!

  BLACKLIST_GROUP_NAME = ["www", "net", "org", "admin", "ftp", "mail", "test", "blog",
                 "bug", "bugs", "dev", "ftp", "forum", "community", "mail", "email",
                 "webmail", "pop", "pop3", "imap", "smtp", "stage", "stats", "status",
                 "support", "survey", "download", "downloads", "faqs", "wiki",
                 "assets1", "assets2", "assets3", "assets4", "staging"]

  key :_id, String
  key :name, String, :required => true
  key :subdomain, String
  key :domain, String, :index => true
  key :legend, String
  key :description, String
  key :default_tags, Array
  key :has_custom_ads, Boolean, :default => true
  key :state, String, :default => "pending" #pending, active, closed
  key :isolate, Boolean, :default => false
  key :private, Boolean, :default => false
  key :theme, String, :default => "plain"
  key :owner_id, String
  key :analytics_id, String
  key :analytics_vendor, String
  key :has_custom_analytics, Boolean, :default => true
  key :language, String, :index => true
  key :activity_rate, Float, :default => 0.0
  key :openid_only, Boolean, :default => false
  key :registered_only, Boolean, :default => false
  key :has_adult_content, Boolean, :default => false

  key :wysiwyg_editor, Boolean, :default => false

  key :has_reputation_constrains, Boolean, :default => true
  key :reputation_rewards, Hash, :default => REPUTATION_REWARDS
  key :reputation_constrains, Hash, :default => REPUTATION_CONSTRAINS
  key :forum, Boolean, :default => false

  key :custom_html, CustomHtml, :default => CustomHtml.new
  key :has_custom_html, Boolean, :default => true
  key :has_custom_js, Boolean, :default => true
  key :fb_button, Boolean, :default => true

  key :enable_latex, Boolean, :default => false


  key :logo_info, Hash, :default => {"width" => 215, "height" => 60}
  key :share, Share, :default => Share.new

  file_key :logo, :max_length => 2.megabytes
  file_key :custom_css, :max_length => 256.kilobytes
  file_key :custom_favicon, :max_length => 256.kilobytes

  slug_key :name, :unique => true
  filterable_keys :name

  has_many :ads, :dependent => :destroy
  has_many :widgets, :class_name => "Widget"

  has_many :badges, :dependent => :destroy
  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :pages, :dependent => :destroy
  has_many :announcements, :dependent => :destroy

  belongs_to :owner, :class_name => "User"
  has_many :comments, :as => "commentable", :order => "created_at asc", :dependent => :destroy

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..10000, :allow_blank => true
  validates_length_of       :legend,         :maximum => 50
  validates_length_of       :default_tags,   :within => 0..15,
      :message =>  I18n.t('activerecord.models.default_tags_message')
  validates_uniqueness_of   :name
  validates_uniqueness_of   :subdomain
  validates_presence_of     :subdomain
  validates_format_of       :subdomain, :with => /^[a-z0-9\-]+$/i
  validates_length_of       :subdomain, :within => 3..32

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES, :allow_nil => true
  validates_inclusion_of :theme, :within => AVAILABLE_THEMES

  before_validation_on_create :set_subdomain
  before_validation_on_create :check_domain
  before_save :disallow_javascript
  before_save :downcase_domain
  validate :check_reputation_configs

  validates_exclusion_of      :subdomain,
                              :within => BLACKLIST_GROUP_NAME,
                              :message => "Sorry, this group subdomain is reserved by"+
                                          " our system, please choose another one"

  def downcase_domain
    domain.downcase!
    subdomain.downcase!
  end

  def set_subdomain
    self["subdomain"] = self["slug"]
  end

  def check_domain
    if domain.blank?
      self[:domain] = "#{subdomain}.#{AppConfig.domain}"
    end
  end

  # TODO: store this variable
  def has_custom_domain?
    @has_custom_domain ||= self[:domain].to_s !~ /#{AppConfig.domain}/
  end

  def disallow_javascript
    unless self.has_custom_js
       %w[footer _head _question_help _question_prompt head_tag].each do |key|
         value = self.custom_html[key]
         if value.kind_of?(Hash)
           value.each do |k,v|
             if v.kind_of?(String)
               value[k] = v.gsub(/<*.?script.*?>/, "")
             end
           end
         elsif value.kind_of?(String)
           value = value.gsub(/<*.?script.*?>/, "")
         end
         self.custom_html[key] = value
       end
    end
  end

  def question_prompt
    self.custom_html.question_prompt[I18n.locale.to_s.split("-").first] || ""
  end

  def question_help
    self.custom_html.question_help[I18n.locale.to_s.split("-").first] || ""
  end

  def head
    self.custom_html.head[I18n.locale.to_s.split("-").first] || ""
  end

  def head_tag
    self.custom_html.head_tag
  end

  def footer
    self.custom_html.footer[I18n.locale.to_s.split("-").first] || ""
  end

  def question_prompt=(value)
    self.custom_html.question_prompt[I18n.locale.to_s.split("-").first] = value
  end

  def question_help=(value)
    self.custom_html.question_help[I18n.locale.to_s.split("-").first] = value
  end

  def head=(value)
    self.custom_html.head[I18n.locale.to_s.split("-").first] = value
  end

  def head_tag=(value)
    self.custom_html.head_tag = value
  end

  def footer=(value)
    self.custom_html.footer[I18n.locale.to_s.split("-").first] = value
  end

  def tag_list
    TagList.first(:group_id => self.id) || TagList.create(:group_id => self.id)
  end

  def default_tags=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:default_tags] = c
  end
  alias :user :owner

  def is_member?(user)
    user.member_of?(self)
  end

  def add_member(user, role)
    membership = user.config_for(self.id)
    if membership.reputation < 5
      membership.reputation = 5
    end
    membership.role = role

    user.save
  end

  def users(conditions = {})
    User.paginate(conditions.merge("membership_list.#{self.id}.reputation" => {:$exists => true}))
  end
  alias_method :members, :users

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
    self.increment(:activity_rate => value)
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

  def self.find_file_from_params(params, request)
    if request.path =~ /\/(logo|css|favicon)\/([^\/\.?]+)/
      @group = Group.find_by_slug_or_id($2, :select => [:file_list])
      case $1
      when "logo"
        @group.logo
      when "css"
        if @group.has_custom_css?
          css=@group.custom_css
          css.content_type = "text/css"
          css
        end
      when "favicon"
        @group.custom_favicon if @group.has_custom_favicon?
      end
    end
  end

  def check_reputation_configs
    if self.reputation_constrains_changed?
      self.reputation_constrains.each do |k,v|
        self.reputation_constrains[k] = v.to_i
        if !REPUTATION_CONSTRAINS.has_key?(k)
          self.errors.add(:reputation_constrains, "Invalid key")
          return false
        end
      end
    end

    if self.reputation_rewards_changed?
      valid = true
      [["vote_up_question", "undo_vote_up_question"],
       ["vote_down_question", "undo_vote_down_question"],
       ["question_receives_up_vote", "question_undo_up_vote"],
       ["question_receives_down_vote", "question_undo_down_vote"],
       ["vote_up_answer", "undo_vote_up_answer"],
       ["vote_down_answer", "undo_vote_down_answer"],
       ["answer_receives_up_vote", "answer_undo_up_vote"],
       ["answer_receives_down_vote", "answer_undo_down_vote"],
       ["answer_picked_as_solution", "answer_unpicked_as_solution"]].each do |action, undo|
        if self.reputation_rewards[action].to_i > (self.reputation_rewards[undo].to_i*-1)
          valid = false
          self.errors.add(undo, "should be less than #{(self.reputation_rewards[action].to_i)*-1}")
        end
      end
      return false unless valid

      self.reputation_rewards.each do |k,v|
        self.reputation_rewards[k] = v.to_i
        if !REPUTATION_REWARDS.has_key?(k)
          self.errors.add(:reputation_rewards, "Invalid key")
          return false
        end
      end
    end

    return true
  end
end
