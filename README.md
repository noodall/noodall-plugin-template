Creating a New Noodall Component
================================
Instructions for extracting/creating a Noodall component gem

Setup
-----
Generate a new component/plugin template

  * `rails plugin new noodall-components-<name> --full -Om https://raw.github.com/noodall/noodall-plugin-template/master/template.rb`

We're using the naming convention `noodall-components-<name>` for new components.

This generates a Rails Engine and applies our customisations.

Process
-------
* Copy/create models in `app/models`

* Copy/create views in `app/views/admin/components` and `app/views/components`

* Setup slots for the new component under `test/dummy/config/initializers/noodall.rb`

* Add new slots to `test/dummy/app/models/content_page.rb`

* Add the new component slot to `test/dummy/app/views/nodes/content_page.html.erb`

* Add cucumber tests and/or unit tests

* Setup factories in `/factories`

* Fill in the `*.gemspec` file

Testing
-------
The easiest way to test a new component is add a gem entry in your `Gemfile` pointing to a local path.

  `gem '<gem name here>', :path => "/path/to/noodall/component/here"`

Then do a `bundle install`