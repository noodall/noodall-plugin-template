rvmrc = "rvm 1.9.2@#{app_path} --create"
create_file '.rvmrc', rvmrc

append_file 'Gemfile', do
  <<-RUBY
gem "mm-versionable", '0.2.5'
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
  database: #{app_path}_development
test:
  database: #{app_path}_test
production:
  database: #{app_path}_production
  YAML
end

remove_file 'test/dummy/config/routes.rb'
create_file 'test/dummy/config/routes.rb' do
  <<-RUBY
require 'noodall/routes'

Noodall::Routes.draw(Dummy::Application)
  RUBY
end

create_file 'test/dummy/config/initializers/noodall.rb' do
  <<-RUBY
# Add your Noodall:Node slots here
#
#   Noodall::Node.slot :<slot name>, <component name>
#
# For example:
#
#   Noodall::Node.slot :carousel, Carousel
  RUBY
end

create_file 'test/dummy/config/initializers/noodall_dragonfly.rb' do
  <<-RUBY
# Configuration for processing and encoding
app = Dragonfly::App[:noodall_assets]
app.configure_with(:imagemagick)
app.configure_with(:rails)
app.datastore = Dragonfly::DataStorage::MongoDataStore.new :db => MongoMapper.database

# For more info about Dragonfly configuration please visit
# http://markevans.github.com/dragonfly/
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

create_file 'features/step_definitions/component_steps.rb' do
  <<-'RUBY'
Given /^I am editing content$/ do
  @_content = Factory(:content_page)
  visit noodall_admin_node_path(@_content)
end

Given /^place a "([^"]*)" component in a slot$/ do |component_name|
  slot_name = case component_name
  when 'Carousel'
    'Carousel Slot'
  else
    'Large Slot'
  end
  within('ol#slot-list') do
    click_link slot_name
  end
  within "#fancybox-content" do
    select component_name, :from => 'Select the type of component'
  end
end

When /^I view the content$/ do
  # If we haven't saved the component yet do so
  if page.find('#fancybox-content').visible?
    within "#fancybox-content" do
      click_button 'Save'
    end
    sleep 2
    click_button 'Publish'
  end
  visit node_path(@_content)
end
  RUBY
end

create_file 'features/support/noodall.rb' do
  <<-RUBY
# Load Noodall specific stuff
require 'noodall/permalinks'
World(Noodall::Permalinks)
  RUBY
end

create_file 'factories/asset.rb' do
  <<-'RUBY'
Factory.define :asset do |asset|
  asset.tags { Faker::Lorem.words(4) }
  asset.title { "Image asset" }
  asset.description { "The asset description" }
  asset.file { Fakerama::Asset::Photo.landscape }
end

Factory.define :txt_asset, :parent => :asset do |asset|
  asset.title { "A text file asset" }
  asset.description { "The text file asset description" }
  asset.file { Fakerama::Asset::Document.txt }
end

Factory.define :zip_asset, :parent => :asset do |asset|
  asset.title { "A zip file asset" }
  asset.description { "The zip file asset description" }
  asset.file {File.new(File.expand_path("../../files/test.zip",  __FILE__))}
end

Factory.define :document_asset, :parent => :asset do |asset|
  asset.title { "Document asset" }
  asset.file { File.new("#{Rails.root}/spec/files/test.pdf") }
end
  RUBY
end

create_file 'factories/content_page.rb' do
  <<-RUBY
Factory.define :content_page do |content_page|
  content_page.title { Faker::Lorem.words(3).join(' ') }
  content_page.body { Faker::Lorem.paragraphs(6) }
  content_page.published_at { Time.now }
  content_page.publish true
end
  RUBY
end

create_file 'features/support/factory_girl.rb' do
  <<-RUBY
require 'factory_girl'
require 'fakerama'
FactoryGirl.definition_file_paths = [
  File.expand_path(File.dirname(__FILE__) + '/../../factories')
]
FactoryGirl.find_definitions
  RUBY
end

