ActionController::Routing::Routes.draw do |map|
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.moderate '/moderate', :controller => 'admin/moderate', :action => 'index'
  map.ban '/moderate/ban', :controller => 'admin/moderate', :action => 'ban'
  map.facts '/facts', :controller => 'welcome', :action => 'facts'
  map.feedback '/feedback', :controller => 'welcome', :action => 'feedback'
  map.send_feedback '/send_feedback', :controller => 'welcome', :action => 'send_feedback'
  map.settings '/settings', :controller => 'users', :action => 'edit'

  map.resources :users, :member => { :change_preferred_tags => :any},
                        :collection => {:autocomplete_for_user_login => :get}
  map.resource :session
  map.resources :ads
  map.resources :adsenses
  map.resources :adbards
  map.resources :badges

  map.resources :questions, :path_prefix => '/:language',
                            :collection => {:tags => :get,
                                            :unanswered => :get},
                            :member => {:solve => :get,
                                        :unsolve => :get,
                                        :flag => :get,
                                        :watch => :any,
                                        :unwatch => :any,
                                        :move => :get,
                                        :move_to => :put} do |questions|
    questions.resources :answers, :member => {:flag => :get, :history => :get, :rollback => :put}
    questions.resources :favorites
  end

  map.resources :questions, :collection => {:tags => :get,
                                            :unanswered => :get} do |questions|
    questions.resources :answers
  end


  map.resources :groups, :member => {:accept => :get,
                                     :close => :get,
                                     :allow_custom_ads => :get,
                                     :disallow_custom_ads => :get,
                                     :logo => :get},
                          :collection => { :autocomplete_for_group_slug => :get}

  map.resources :members

  map.resources :comments
  map.resources :votes
  map.resources :flags

  map.resources :widgets, :member => {:move => :post}, :path_prefix => "/manage"
  map.manage '/manage', :controller => 'admin/manage', :action => 'properties'
  map.members '/members', :controller => "members", :path_prefix => "/manage", :action => "index"

  map.with_options :controller => 'admin/manage', :name_prefix => "manage_",
                   :path_prefix => "/manage" do |manage|
    manage.properties '/properties', :action => 'properties'
    manage.actions '/actions', :action => 'actions'
    manage.stats '/stats', :action => 'stats'
    manage.reputation '/reputation', :action => 'reputation'
  end

  map.search '/search', :controller => "searches", :action => "index"
  map.about '/about', :controller => "groups", :action => "show"
  map.root :controller => "welcome"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
