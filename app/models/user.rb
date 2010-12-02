require 'digest/sha1'

class User
  include MongoMapper::Document
  devise :database_authenticatable, :http_authenticatable, :recoverable, :registerable, :rememberable,
         :lockable, :token_authenticatable

  ROLES = %w[user moderator admin]
  LANGUAGE_FILTERS = %w[any user] + AVAILABLE_LANGUAGES
  LOGGED_OUT_LANGUAGE_FILTERS = %w[any] + AVAILABLE_LANGUAGES

  key :_id,                       String
  key :login,                     String, :limit => 40, :index => true
  key :name,                      String, :limit => 100, :default => '', :null => true

  key :bio,                       String, :limit => 200
  key :website,                   String, :limit => 200
  key :location,                  String, :limit => 200
  key :birthday,                  Time

  key :identity_url,              String, :index => true
  key :role,                      String, :default => "user"
  key :last_logged_at,            Time

  key :preferred_languages,       Array, :default => []

  key :notification_opts,         NotificationConfig

  key :language,                  String, :default => "en", :index => true
  key :timezone,                  String
  key :language_filter,           String, :default => "user", :in => LANGUAGE_FILTERS

  key :ip,                        String
  key :country_code,              String
  key :country_name,              String, :default => "unknown"
  key :hide_country,              Boolean, :default => false

  key :default_subtab,            Hash

  key :followers_count,           Integer, :default => 0
  key :following_count,           Integer, :default => 0

  key :membership_list,           MembershipList

  key :facebook_id,               String
  key :facebook_token,            String
  key :facebook_profile,          String

  key :twitter_token,             String
  key :twitter_secret,            String
  key :twitter_login,             String

  key :feed_token,                String

  key :anonymous,                 Boolean, :default => false, :index => true

  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :badges, :dependent => :destroy

  has_many :favorites, :class_name => "Favorite", :foreign_key => "user_id"

  key :friend_list_id, String
  belongs_to :friend_list, :dependent => :destroy

  before_create :create_friend_list
  before_create :generate_uuid
  after_create :update_anonymous_user

  timestamps!

  validates_inclusion_of :language, :within => AVAILABLE_LOCALES
  validates_inclusion_of :role,  :within => ROLES

  with_options :if => lambda { |e| !e.anonymous } do |v|
    v.validates_presence_of     :login
    v.validates_length_of       :login,    :within => 3..40
    v.validates_uniqueness_of   :login
    v.validates_format_of       :login,    :with => /\w+/
  end

  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email,    :if => lambda { |e| !e.openid_login? && !e.twitter_login? }
  validates_uniqueness_of   :email,    :if => lambda { |e| e.anonymous || (!e.openid_login? && !e.twitter_login?) }
  validates_length_of       :email,    :within => 6..100, :allow_nil => true, :if => lambda { |e| !e.email.blank? }
  validates_format_of       :email,    :with => Devise::EMAIL_REGEX, :allow_blank => true

  with_options :if => :password_required? do |v|
    v.validates_presence_of     :password
    v.validates_confirmation_of :password
    v.validates_length_of       :password, :within => 6..20, :allow_blank => true
  end

  before_save :update_languages
  before_create :logged!

  def self.find_for_authentication(conditions={})
    first(conditions) || first(:login => conditions["email"])
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def self.find_by_login_or_id(login, conds = {})
    first(conds.merge(:login => login)) || first(conds.merge(:_id => login))
  end

  def self.find_experts(tags, langs = AVAILABLE_LANGUAGES, options = {})
    opts = {}
    opts[:limit] = 15
    opts[:select] = [:user_id]
    if except = options[:except]
      except = [except] unless except.is_a? Array
      opts[:user_id] = {:$nin => except}
    end

    user_ids = UserStat.all(opts.merge({:answer_tags => {:$in => tags}})).map(&:user_id)

    conditions = {"notification_opts.give_advice" => {:$in => ["1", true]},
                  :preferred_languages => langs}

    if group_id = options[:group_id]
      conditions["membership_list.#{group_id}"] = {:$exists => true}
    end

    u = User.all(conditions.merge(:_id => user_ids, :select => [:email, :login, :name, :language]))
    u ? u : []
  end

  def to_param
    if self.login.blank? || !self.login.match(/^\w[\w\s]*$/)
      self.id
    else
      self.login
    end
  end

  def add_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.collection.update({:_id => self._id, "membership_list.#{group.id}.preferred_tags" =>  {:$nin => t}},
                    {:$pushAll => {"membership_list.#{group.id}.preferred_tags" => t}})
  end

  def remove_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.class.pull_all({:_id => self._id}, {"membership_list.#{group.id}.preferred_tags" => t})
  end

  def preferred_tags_on(group)
    @group_preferred_tags ||= (config_for(group, false).preferred_tags || []).to_a
  end

  def update_language_filter(filter)
    if LANGUAGE_FILTERS.include? filter
      User.set({:_id => self.id}, {:language_filter => filter})
      true
    else
      false
    end
  end

  def languages_to_filter
    @languages_to_filter ||= begin
      languages = nil
      case self.language_filter
      when "any"
        languages = AVAILABLE_LANGUAGES
      when "user"
        languages = (self.preferred_languages.empty?) ? AVAILABLE_LANGUAGES : self.preferred_languages
      else
        languages = [self.language_filter]
      end
      languages
    end
  end

  def is_preferred_tag?(group, *tags)
    ptags = config_for(group, false).preferred_tags
    tags.detect { |t| ptags.include?(t) }
  end

  def admin?
    self.role == "admin"
  end

  def age
    return if self.birthday.blank?

    Time.zone.now.year - self.birthday.year - (self.birthday.to_time.change(:year => Time.zone.now.year) >
Time.zone.now ? 1 : 0)
  end

  def can_modify?(model)
    return false unless model.respond_to?(:user)
    self.admin? || self == model.user
  end

  def groups(options = {})
    options[:order] ||= "activity_rate desc"
    self.membership_list.groups(options)
  end

  def member_of?(group)
    if group.kind_of?(Group)
      group = group.id
    end

    self.membership_list.has_key?(group)
  end

  def role_on(group)
    config_for(group, false).role
  end

  def owner_of?(group)
    admin? || group.owner_id == self.id || role_on(group) == "owner"
  end

  def mod_of?(group)
    owner_of?(group) || role_on(group) == "moderator" || self.reputation_on(group) >= group.reputation_constrains["moderate"].to_i
  end

  def editor_of?(group)
    if c = config_for(group, false)
      c.is_editor
    else
      false
    end
  end

  def user_of?(group)
    mod_of?(group) || self.membership_list.has_key?(group.id)
  end

  def main_language
    @main_language ||= self.language.split("-").first
  end

  def openid_login?
    !identity_url.blank? || (AppConfig.enable_facebook_auth && !facebook_id.blank?)
  end

  def twitter_login?
    !twitter_token.blank? && !twitter_secret.blank?
  end

  def has_voted?(voteable)
    !vote_on(voteable).nil?
  end

  def vote_on(voteable)
    Vote.first(:voteable_type => voteable.class.to_s,
               :voteable_id => voteable.id,
               :user_id     => self.id )
  end

  def favorite?(question)
    !favorite(question).nil?
  end

  def favorite(question)
    self.favorites.first(:question_id => question._id, :user_id => self._id )
  end

  def logged!(group = nil)
    now = Time.zone.now

    if new?
      self.last_logged_at = now
    elsif group && (member_of?(group) || !group.private)
      on_activity(:login, group)
    end
  end

  def on_activity(activity, group)
    if activity == :login
      self.last_logged_at ||= Time.now
      if !self.last_logged_at.today?
        self.set( {:last_logged_at => Time.zone.now.utc} )
      end
    else
      self.update_reputation(activity, group) if activity != :login
    end
    activity_on(group, Time.zone.now)
  end

  def activity_on(group, date)
    day = date.utc.at_beginning_of_day
    last_day = config_for(group, false).last_activity_at

    if last_day != day
      self.set({"membership_list.#{group.id}.last_activity_at" => day})
      if last_day
        if last_day.utc.between?(day.yesterday - 12.hours, day.tomorrow)
          self.increment({"membership_list.#{group.id}.activity_days" => 1})
          Magent.push("actors.judge", :on_activity, group.id, self.id)
        elsif !last_day.utc.today? && (last_day.utc != Time.now.utc.yesterday)
          Rails.logger.info ">> Resetting act days!! last known day: #{last_day}"
          reset_activity_days!(group)
        end
      end
    end
  end

  def reset_activity_days!(group)
    self.set({"membership_list.#{group.id}.activity_days" => 0})
  end

  def upvote!(group, v = 1.0)
    self.increment({"membership_list.#{group.id}.votes_up" => v.to_f})
  end

  def downvote!(group, v = 1.0)
    self.increment({"membership_list.#{group.id}.votes_down" => v.to_f})
  end

  def update_reputation(key, group)
    value = group.reputation_rewards[key.to_s].to_i
    value = key if key.kind_of?(Integer)
    Rails.logger.info "#{self.login} received #{value} points of karma by #{key} on #{group.name}"
    current_reputation = config_for(group, false).reputation

    if value
      self.increment({"membership_list.#{group.id}.reputation" => value})
    end

    stats = self.reputation_stats(group, { :select => [:_id] })
    stats.save if stats.new?

    event = ReputationEvent.new(:time => Time.now, :event => key,
                                :reputation => current_reputation,
                                :delta => value )
    ReputationStat.collection.update({:_id => stats.id}, {:$addToSet => {:events => event.attributes}})
  end

  def localize(ip)
    self.ip = ip
    if !defined?(Localize)
      return self.save
    end

    l = Localize.country(ip)
    if l
      self.country_code = l[2]
      self.country_name = l[4]
    end
    save
  end

  def reputation_on(group)
    config_for(group, false).reputation.to_i
  end

  def stats(*extra_fields)
    fields = [:_id]
    UserStat.find_or_create_by_user_id(self._id, :select => fields+extra_fields)
  end

  def badges_count_on(group)
    config = config_for(group, false)
    [config.bronze_badges_count, config.silver_badges_count, config.gold_badges_count]
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

    User.increment(self.id, :following_count => 1)
    User.increment(user.id, :followers_count => 1)
    true
  end

  def remove_friend(user)
    return false if user == self
    FriendList.pull(self.friend_list_id, :following_ids => user.id)
    FriendList.pull(user.friend_list_id, :follower_ids => self.id)

    User.decrement(self.id, :following_count => 1)
    User.decrement(user.id, :followers_count => 1)

    true
  end

  def followers(scope = {})
    conditions = {}
    conditions[:preferred_languages] = {:$in => scope[:languages]}  if scope[:languages]
    conditions["membership_list.#{scope[:group_id]}"] = {:$exists => true} if scope[:group_id]
    self.friend_list.followers.all(conditions)
  end

  def following
    self.friend_list.following
  end

  def following?(user)
    friend_list(:select => [:following_ids]).following_ids.include?(user.id)
  end

  def viewed_on!(group)
    self.increment("membership_list.#{group.id}.views_count" => 1.0)
  end

  def method_missing(method, *args, &block)
    if !args.empty? && method.to_s =~ /can_(\w*)\_on?/
      key = $1
      group = args.first
      if group.reputation_constrains.include?(key.to_s)
        if group.has_reputation_constrains
          return self.owner_of?(group) || self.mod_of?(group) || (self.reputation_on(group) >= group.reputation_constrains[key].to_i)
        else
          return true
        end
      end
    end
    super(method, *args, &block)
  end

  def config_for(group, init = true)
    if group.kind_of?(Group)
      group = group.id
    end

    config = self.membership_list[group]
    if config.nil?
      if init
        config = self.membership_list[group] = Membership.new(:group_id => group)
      else
        config = Membership.new(:group_id => group)
      end
    end
    config
  end

  def reputation_stats(group, options = {})
    if group.kind_of?(Group)
      group = group.id
    end
    default_options = { :user_id => self.id,
                        :group_id => group}
    stats = ReputationStat.first(default_options.merge(options)) ||
            ReputationStat.new(default_options)
  end

  def has_flagged?(flaggeable)
    flaggeable.flags.detect do |flag|
      flag.user_id == self.id
    end
  end

  def has_requested_to_close?(question)
    question.close_requests.detect do |close_request|
      close_request.user_id == self.id
    end
  end

  def has_requested_to_open?(question)
    question.open_requests.detect do |open_request|
      open_request.user_id == self.id
    end
  end

  def generate_uuid
    self.feed_token = UUIDTools::UUID.random_create.hexdigest
  end

  def merge_user(user)
    [Question, Answer, Comment, Vote, Badge, UserStat].each do |m|
      m.set({:user_id => user.id}, {:user_id => self.id})
    end
    user
  end

  protected
  def update_languages
    self.preferred_languages = self.preferred_languages.map { |e| e.split("-").first }
  end

  def password_required?
    return false if openid_login? || twitter_login? || self.anonymous

    (encrypted_password.blank? || !password.blank?)
  end

  def create_friend_list
    if !self.friend_list.present?
      self.friend_list = FriendList.new
    end
    if !self.notification_opts
      self.notification_opts = NotificationConfig.new
    end
  end

  def update_anonymous_user
    return if self.anonymous

    user = User.first(:email => self.email, :anonymous => true)
    if user.present?
      Rails.logger.info "Merging #{self.email}(#{self.id}) into #{user.email}(#{user.id})"
      merge_user(user)
      self.membership_list = user.membership_list

      user.destroy
    end
  end
end

