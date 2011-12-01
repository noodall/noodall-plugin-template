append_file 'Gemfile', do
  <<-RUBY
gem "noodall-ui"
gem 'bson_ext'
gem "dragonfly"

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'cucumber-rails'
  gem 'launchy'    # So you can do Then show me the page
  gem 'factory_girl_rails'
  gem 'fakerama'
end
  RUBY
end

create_file 'test/dummy/app/models/user.rb', do
  <<-RUBY
class User
  include MongoMapper::Document
  include Canable::Cans

  key :email, String
  key :full_name, String
  key :groups, Array

  cattr_accessor :editor_groups

  def admin?
    groups.include?('website administrator')
  end

  def editor?
    return true if self.class.editor_groups.blank?
    admin? or (self.class.editor_groups & groups).size > 0
  end

end
  RUBY
end

create_file 'test/dummy/config/mongo.yml' do
  <<-YAML
development:
  database: noodall-articles_development
test:
  database: noodall-articles_test
production:
  database: noodall-articles_production
  YAML
end

remove_file 'test/dummy/config/routes.rb'
create_file 'test/dummy/config/routes.rb' do
  <<-RUBY
require 'noodall/routes'

Noodall::Routes.draw(Dummy::Application)
  RUBY
end

inject_into_class 'test/dummy/app/controllers/application_controller.rb', 'ApplicationController' do
  <<-RUBY
  @@current_user = User.find_or_create_by_full_name("Demo User")

  def self.current_user=(user)
    @@current_user = user
  end

  def current_user
    @@current_user
  end
  helper_method :current_user

  def destroy_user_session_path
    ''
  end
  helper_method :destroy_user_session_path

  def authenticate_user!
    true
  end

  def anybody_signed_in?
    true
  end
  RUBY
end

generate 'cucumber:install'

prepend_file 'features/support/env.rb', 'ENV["RAILS_ROOT"] ||= File.expand_path(File.dirname(__FILE__) + "/../../test/dummy")'

gsub_file 'features/support/env.rb', ':transaction', ':truncation'
