require 'digest/sha1'

class User
  include MongoMapper::Document
  ensure_index :login

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  ROLES = %w[user moderator admin]

  key :login,                     String, :limit => 40
  key :name,                      String, :limit => 100, :default => '', :null => true
  key :email,                     String, :limit => 100
  key :identity_url,              String
  key :crypted_password,          String, :limit => 40
  key :salt,                      String, :limit => 40
  key :remember_token,            String, :limit => 40
  key :remember_token_expires_at, Time
  key :role,                      String, :default => "user"
  key :last_logged_at,            Time

  key :preferred_tags,            Hash, :default => {} #by group
  key :preferred_languages,       Array

  key :notification_opts,         Hash, :default => {"new_answer"=>"1"}

  key :language,                  String, :default => "en"
  key :timezone,                  String
  key :reputation,                Hash, :default => {}

  key :ip,                        String
  key :country_code,              String
  key :country_name,              String, :default => "unknown"

  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :votes, :dependent => :destroy

  has_many :memberships, :class_name => "Member", :foreign_key => "user_id"

  timestamps!

  validates_inclusion_of :language, :within => AVAILABLE_LOCALES
  validates_inclusion_of :role,  :within => ROLES

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => /\w+/, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email, :if => lambda { |e| !e.openid_login? }
  validates_length_of       :email,    :within => 6..100, :allow_nil => true, :if => lambda { |e| !e.email.blank? } #r@a.wk
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message, :allow_nil => true, :if => lambda { |e| !e.email.blank? }

  before_save :update_languages
  before_create :logged!

  attr_accessor :password, :password_confirmation
  before_validation :add_email_validation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find(:first, :login => login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def self.find_by_login_or_id(login)
    find_by_login(login) || find_by_id(login)
  end

  def to_param
    if self.login.blank? || self.login.match(/\W/)
      self.id
    else
      self.login
    end
  end

  def set_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.collection.update({:_id => self.id}, {:$set => {"preferred_tags.#{group.id}" => t}},
                           :upsert => true)
  end

  def add_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    if preferred_tags[group.id]
      self.collection.update({:_id => self.id}, {:$pushAll => {"preferred_tags.#{group.id}" => t}},
                             :upsert => true, :safe => true)
    else
      set_preferred_tags(t, group)
    end
  end

  def remove_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.collection.update({:_id => self.id}, {:$pullAll => {"preferred_tags.#{group.id}" => t}},
                           :upsert => true)
  end

  def admin?
    self.role == "admin"
  end

  def moderator?
    admin? || self.role == "moderator"
  end

  def can_modify?(model)
    return false unless model.respond_to?(:user)
    self.admin? || self == model.user
  end

  def groups(options = {})
    groups_ids = memberships(:fields => "id" ).map do |member|
      member.group_id
    end

    if groups_ids.empty?
      page = MongoMapper::Pagination::PaginationProxy.new(0, 1, 25);
      page.subject = []
      return page
    end

    default_opts = {:conditions => {:_id => {:$in => spaces_ids}}}
    Group.paginate(options.merge(default_opts))
  end

  def member_of?(group)
    if group.kind_of?(Group)
      group.is_member?(self)
    else
      false
    end
  end

  def role_on(group)
    memberships.find(:group_id => group.id).role
  end

  def main_language
    @main_language ||= self.language.split("-").first
  end

  def openid_login?
    !identity_url.blank?
  end

  def has_voted?(voteable)
    vote = Vote.find(:first, {:limit => 1,
                              :voteable_type => voteable.class.to_s,
                              :voteable_id => voteable.id,
                              :user_id     => self.id
                             })
    !vote.nil?
  end

  def logged!
    now = Time.now
    if new?
      self.last_logged_at = now
    else
      self.collection.update({:_id => self.id}, {:$set => {:last_logged_at => now}},
                                                 :upsert => true)
    end
  end

  def on_activity(activity, group)
    self.collection.update({:_id => self.id}, {:$set => {:last_logged_at => Time.now}},
                                               :upsert => true)
    self.update_reputation(activity, group)
  end

  def update_reputation(key, group)
    value = REPUTATION_CONF[key.to_s]
    Rails.logger.info "#{self.login} receive #{value} points of karma by #{key} on #{group.name}"
    value = key if value.nil? && key.kind_of?(Integer)
    if value
      User.collection.update({:_id => self.id},
                             {:$inc => {"reputation.#{group.id}" => value}},
                             :upsert => true,
                             :safe => true)
    end
  end

  def localize(ip)
    l = Localize.country(ip)
    self.ip = ip
    self.country_code = l[2]
    self.country_name = l[4]
    save
  end

  def preferred_tags_on(group)
    @group_preferred_tags ||= (self.preferred_tags[group.id] || []).to_a
  end

  def reputation_on(group)
    self.reputation.fetch(group.id, 1.0 ).to_i
  end

  protected
  def add_email_validation
    if !self.email.blank?
      doc = User.find(:first, :email => self.email, :limit => 1)
      valid = doc.nil? || self.id == doc.id
      if !valid
        self.errors.add(:email, 'Email has already been taken')
      end
    end
  end

  def update_languages
    self.preferred_languages = self.preferred_languages.map { |e| e.split("-").first }
  end

  def password_required?
    return false if openid_login?

    (crypted_password.blank? || !password.blank?)
  end
end

