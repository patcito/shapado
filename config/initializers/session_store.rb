# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_stackopenflow_session',
  :secret      => '9ac4fd97a52153070a0bd47467c00eded1badf526f145827384ddfde45ac0bfd3f0230c961ddfb9ef84d490b3d889e0169de8eee3ef7b7ed114262824f8aa8aa'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
