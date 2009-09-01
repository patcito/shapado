require 'digest/sha1'

class User
  include MongoMapper::Document
  ensure_index :login

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  key :login,                     String, :limit => 40
  key :name,                      String, :limit => 100, :default => '', :null => true
  key :email,                     String, :limit => 100
  key :identity_url,              String
  key :crypted_password,          String, :limit => 40
  key :salt,                      String, :limit => 40
  key :created_at,                Time
  key :updated_at,                Time
  key :remember_token,            String, :limit => 40
  key :remember_token_expires_at, Time
  key :admin,                     Boolean, :default => false
  key :last_logged_at,            Time

  key :preferred_tags,            Array, :default => []
  key :preferred_languages,       Array
  key :language,                      String, :default => "en"
  key :timezone,                      String
  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :votes, :dependent => :destroy

  validates_inclusion_of :language, :within => AVAILABLE_LOCALES

  timestamps!

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
    u = find(:first, :conditions => {:login => login.downcase}) # need to get the salt
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

  def preferred_tags=(t)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self[:preferred_tags] = t
  end

  def admin?
    self.admin
  end

  def can_modify?(model)
    return false unless model.respond_to?(:user)
    self.admin? || self == model.user
  end

  def main_language
    @main_language ||= self.language.split("-").first
  end

  def openid_login?
    !identity_url.blank?
  end

  def has_voted?(voteable)
    vote = Vote.find(:first, {:limit => 1,
                              :conditions => {
                                :voteable_type => voteable.class.to_s,
                                :voteable_id => voteable.id,
                                :user_id     => self.id}
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

  protected
  def add_email_validation
    if !self.email.blank?
      doc = User.find(:first, :conditions => {:email => self.email}, :limit => 1)
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

