class Group
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Storage
  timestamps!

  key :_id, String
  key :name, String, :required => true
  slug_key :name, :unique => true
  key :subdomain, String
  key :domain, String
  key :legend, String
  key :description, String
  key :default_tags, Array
  key :has_custom_ads, Boolean, :default => true
  key :state, String, :default => "pending" #pending, active, closed
  key :isolate, Boolean, :default => false
  key :private, Boolean, :default => false
  key :theme, String, :default => "shapado"
  key :owner_id, String
  key :analytics_id, String
  key :analytics_vendor, String
  key :has_custom_analytics, Boolean, :default => true
  key :language, String
  key :activity_rate, Float, :default => 0.0
  key :logo_ext, String, :default => 'png'

  file_key :logo
  file_key :custom_css
  file_key :custom_favicon

  key :has_reputation_constrains, Boolean, :default => true
  key :reputation_rewards, Hash, :default => REPUTATION_REWARDS
  key :reputation_constrains, Hash, :default => REPUTATION_CONSTRAINS

  #custom html
  key :_question_prompt, Hash, :default => {"en" => "what's your question? be descriptive.",
                                           "es" => "¿cual es tu pregunta? por favor se descriptivo.",
                                           "fr" => "quelle est votre question? soyez descriptif.",
                                           "pt" => "qual é a sua pergunta? seja descritivo."}
  key :_question_help, Hash, :default => {
"en" => "Provide as much details as possible so that it will have more
chance to be answered instead of being endlessly discussed.
Try to be clear and simple.",
"es" => "Sobre que es tu pregunta?
provee tantos detalles como puedas para tener más suerte
de conseguir una respuesta y no una discusion sin fin.
intenta ser claro y simple",
"fr" => "Sur quoi porte votre question?
Donnez autants de détails que possible afin d'avoir plus de chance
d'obtenir une réponse et non une discussion sans fin. Éssayer d'être clair et simple.",
"pt" => ""}

  key :_head, Hash, :default => { }
  key :has_custom_html, Boolean, :default => true
  key :has_custom_js, Boolean, :default => true
  key :footer, String

  key :head_tag, String

  has_many :memberships, :class_name => "Member",
                         :foreign_key => "group_id",
                         :dependent => :destroy
  has_many :ads, :dependent => :destroy
  has_many :widgets, :dependent => :destroy, :order => "position asc", :polymorphic => true
  has_many :badges, :dependent => :destroy
  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :votes, :dependent => :destroy

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
  before_save :disallow_javascript
  before_save :downcase_domain
  validate :check_reputation_configs

  def downcase_domain
    domain.downcase!
    subdomain.downcase!
  end

  def check_domain
    if domain.blank?
      self[:domain] = "#{subdomain}.#{AppConfig.domain}"
    end
  end

  def disallow_javascript
    unless self.has_custom_js
       %w[footer _head _question_help _question_prompt head_tag].each do |key|
         value = self[key]
         if value.kind_of?(Hash)
           value.each do |k,v|
             value[k] = v.gsub(/<*.?script.*?>/, "")
           end
         elsif value.kind_of?(String)
           value = value.gsub(/<*.?script.*?>/, "")
         end
         self[key] = value
       end
    end
  end

  def question_prompt
    self._question_prompt[I18n.locale.to_s.split("-").first] || ""
  end

  def question_help
    self._question_help[I18n.locale.to_s.split("-").first] || ""
  end

  def head
    self._head[I18n.locale.to_s.split("-").first] || ""
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
    if !user.reputation[self.id]
      User.set(user.id, {"reputation.#{self.id}" => 5})
    end

    member = Member.new( :group_id => self._id,
                         :user_id => user._id,
                         :role => role)
    member.save
    member
  end

  def users
    User.all("reputation.#{self.id}" => {:$exists => true})
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
