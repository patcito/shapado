require 'digest/sha1'

class User
  include MongoMapper::Document

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  ROLES = %w[user admin]

  key :_id,                       String
  key :login,                     String, :limit => 40, :index => true
  key :name,                      String, :limit => 100, :default => '', :null => true
  key :bio,                       String, :limit => 200
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

  key :notification_opts,         Hash, :default => {"new_answer"=>"1", "give_advice" => "1",
                                                     "activities" => "1", "reports" => "1"}

  key :language,                  String, :default => "en"
  key :timezone,                  String
  key :reputation,                Hash, :default => {}

  key :ip,                        String
  key :country_code,              String
  key :country_name,              String, :default => "unknown"

  key :votes_up,                  Hash
  key :votes_down,                Hash
  key :default_subtab,            Hash

  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :badges, :dependent => :destroy

  has_many :memberships, :class_name => "Member", :foreign_key => "user_id"
  has_many :favorites, :class_name => "Favorite", :foreign_key => "user_id"

  key :friend_list_id, String
  belongs_to :friend_list, :dependent => :destroy

  before_create :create_friend_list

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

  attr_accessor :password, :password_confirmation, :roles
  before_validation :add_email_validation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = User.first(:login => login.downcase) # need to get the salt
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

  def self.find_experts(tags, langs = AVAILABLE_LANGUAGES)
    opts = {}
    opts[:limit] = 15
    opts[:select] = [:user_id]
    user_ids = UserStat.all(opts.merge({:answer_tags => {:$in => tags}})).map do |s|
      s.user_id
    end

    u=User.find(user_ids, "notification_opts.give_advice" => {:$in => ["1", true]}, :select => [:email, :login, :name, :language], :preferred_languages => langs)
    u ? u : []
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
    self.collection.update({:_id => self._id}, {:$set => {"preferred_tags.#{group.id}" => t}},
                           :upsert => true)
  end

  def add_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    t = t - preferred_tags[group.id] if preferred_tags[group.id]
    self.collection.update({:_id => self._id, "preferred_tags.#{group.id}" =>  {:$nin => t}}, {:$pushAll => {"preferred_tags.#{group.id}" => t}},
                           :upsert => true, :safe => true)
  end

  def remove_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.collection.update({:_id => self._id}, {:$pullAll => {"preferred_tags.#{group.id}" => t}},
                           :upsert => true)
  end

  def is_preferred_tag?(group, *tags)
    ptags = self.preferred_tags[group.id] || []
    tags.detect { |t| ptags.include?(t) }
  end

  def admin?
    self.role == "admin"
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

    default_opts = {:conditions => {:_id => {:$in => groups_ids}}}
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
    @roles ||= {}

    return @roles[group.id] if @roles[group.id]

    if membership = Member.first(:group_id => group.id, :user_id => self.id)
      return @roles[group.id] = membership.role
    end
    "none"
  end

  def owner_of?(group)
    admin? || group.owner_id == self.id || role_on(group) == "owner"
  end

  def mod_of?(group)
    owner_of?(group) || role_on(group) == "moderator"
  end

  def user_of?(group)
    mod_of?(group) || role_on(group) == "user"
  end

  def main_language
    @main_language ||= self.language.split("-").first
  end

  def openid_login?
    !identity_url.blank?
  end

  def has_voted?(voteable)
    !vote_on(voteable).nil?
  end

  def vote_on(voteable)
    Vote.first(:voteable_type => voteable.class.to_s,
               :voteable_id => voteable._id,
               :user_id     => self._id )
  end

  def favorite?(question)
    !favorite(question).nil?
  end

  def favorite(question)
    self.favorites.first(:question_id => question._id, :user_id => self._id )
  end

  def logged!
    now = Time.now

    if new?
      self.last_logged_at = now
    else
      self.collection.update({:_id => self._id}, {:$set => {:last_logged_at => now}},
                                                 :upsert => true)
    end
  end

  def on_activity(activity, group)
    if !self.last_logged_at.today?
      self.collection.update({:_id => self._id}, {:$set => {:last_logged_at => Time.now}},
                                                  :upsert => true)
    end
    self.stats(:last_activity_at, :user_id).activity_on(group, Time.now)
    self.update_reputation(activity, group)
  end

  def upvote!(group, v = 1.0)
    self.collection.update({:_id => self._id}, {:$inc => {"votes_up.#{group.id}" => v.to_f}}, :upsert => true)
  end

  def downvote!(group, v = 1.0)
    self.collection.update({:_id => self._id}, {:$inc => {"votes_down.#{group.id}" => v.to_f}}, :upsert => true)
  end

  def update_reputation(key, group)
    value = group.reputation_rewards[key.to_s].to_i
    Rails.logger.info "#{self.login} received #{value} points of karma by #{key} on #{group.name}"
    value = key if key.kind_of?(Integer)
    if value
      User.collection.update({:_id => self._id},
                             {:$inc => {"reputation.#{group.id}" => value}},
                             :upsert => true,
                             :safe => true)
    end
  end

  def localize(ip)
    l = Localize.country(ip)
    self.ip = ip
    if l
      self.country_code = l[2]
      self.country_name = l[4]
    end
    save
  end

  def preferred_tags_on(group)
    @group_preferred_tags ||= (self.preferred_tags[group.id] || []).to_a
  end

  def reputation_on(group)
    self.reputation.fetch(group.id, 0.0 ).to_i
  end

  def stats(*extra_fields)
    fields = [:_id]
    UserStat.find_or_create_by_user_id(self._id, :select => fields+extra_fields)
  end

  def badges_on(group, opts = {})
    self.badges.all(opts.merge(:group_id => group.id, :order => "created_at desc"))
  end

  def find_badge_on(group, token, opts = {})
    self.badges.first(opts.merge(:token => token, :group_id => group.id))
  end

  # self follows user
  def add_friend(user)
    return false if user == self
    FriendList.push_uniq(self.friend_list_id, :following_ids => user.id)
    FriendList.push_uniq(user.friend_list_id, :follower_ids => self.id)
    true
  end

  def remove_friend(user)
    return false if user == self
    FriendList.pull(self.friend_list_id, :following_ids => user.id)
    FriendList.pull(user.friend_list_id, :follower_ids => self.id)
    true
  end

  def followers
    self.friend_list.followers
  end

  def following
    self.friend_list.following
  end

  def following?(user)
    friend_list(:select => [:following_ids]).following_ids.include?(user.id)
  end

  def method_missing(method, *args, &block)
    if !args.empty? && method.to_s =~ /can_(\w*)\_on?/
      key = $1
      group = args.first
      if group.reputation_constrains.include?(key.to_s)
        if group.has_reputation_constrains
          return self.owner_of?(group) || (self.reputation_on(group) >= group.reputation_constrains[key].to_i)
        else
          return true
        end
      end
    end
    super(method, *args, &block)
  end

  protected
  def add_email_validation
    if !self.email.blank?
      doc = User.first(:email => self.email)
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

  def create_friend_list
    if !self.friend_list.present?
      self.friend_list = FriendList.new
    end
  end
end

