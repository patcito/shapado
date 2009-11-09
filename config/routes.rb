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

  map.resources :users, :member => { :change_preferred_tags => :any }
  map.resource :session

  map.resources :questions, :path_prefix => '/:category',
                            :collection => {:tags => :get,
                                            :unanswered => :get},
                            :member => {:solve => :get,
                                        :unsolve => :get,
                                        :flag => :get} do |questions|
    questions.resources :answers, :member => {:flag => :get}
  end

  map.resources :questions do |questions|
    questions.resources :answers
  end


  map.resources :groups, :member => {:accept => :get,
                                     :close => :get,
                                     :logo => :get}

  map.resources :votes
  map.resources :flags

  map.search '/search', :controller => "welcome", :action => "search"
  map.root :controller => "welcome"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
