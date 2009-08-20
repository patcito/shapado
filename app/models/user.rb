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
  key :crypted_password,          String, :limit => 40
  key :salt,                      String, :limit => 40
  key :created_at,                Time
  key :updated_at,                Time
  key :remember_token,            String, :limit => 40
  key :remember_token_expires_at, Time
  key :admin,                     Boolean, :default => false

  key :preferred_tags,            Array, :default => []
  key :lang,                      String, :default => "en"
  key :timezone,                      String
  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy

  timestamps!

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => /\w+/, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  attr_accessor :password, :password_confirmation



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

  def admin?
    self.admin
  end

  def can_modify?(model)
    return false unless model.respond_to?(:user)
    self.admin? || self == model.user
  end

  protected
end
