![status](https://secure.travis-ci.org/mockdeep/better.png?branch=master)
[![Code Climate](https://codeclimate.com/github/mockdeep/better.png)](https://codeclimate.com/github/mockdeep/better)
[![Dependency Status](https://gemnasium.com/mockdeep/better.png)](https://gemnasium.com/mockdeep/better)

live server hosted at: https://better.boon.gl

*** Use at your own risk!!! There are likely to be vulnerabilities in this
app!!! ***

Pre-requisites
--------------

I recommend using rvm to manage your ruby versions: https://rvm.io/

```sh
# install ruby:
rvm install 1.8.7-p374

# set the rubygems version:
rvm rubygems 1.8.25

# install postgres:
brew install postgres

# Imagemagick is also a dependency:
brew install imagemagick
# see here for errors installing rmagick: http://stackoverflow.com/a/13967303/372479
```

Getting started
---------------

First fork the repo using the link above, then:

```sh
# clone your copy:
git clone git@github.com:<your username>/better.git
cd better/

# Add this copy as upstream:
git remote add upstream https://github.com/mockdeep/better.git

# now install gems:
bundle install

# set up database config:
mv config/database.yml.example config/database.yml

# set up database:
rake db:create:all && rake db:schema:load

# seed data into the database:
rake db:seed

# set up the test database:
rake db:test:prepare

# and run the tests:
rake spec

# if all passes, then you should be good to go. Please open an issue if you
# have any problems. You can boot up your server on localhost with:
script/server
```

Production
----------

You'll need to set up the following in order to run on production. If you're
deploying to Heroku you can push environment variables using
`heroku config:add MY_VAR=whatevs`. Locally you can put them in a `local_env.rb`
file like `ENV['MY_VAR'] = 'my secret key'`.

* A honeybadger.io API key: `BETTER_HONEYBADGER_API_KEY=<your key here>`
* S3 access keys:
  - `S3_ACCESS_KEY_ID=<your AWS S3 access key id>`
  - `S3_SECRET_ACCESS_KEY=<your AWS S3 secret access key`
* Sendgrid credentials:
  - `SENDGRID_DOMAIN=<the domain of your app>`
  - `SENDGRID_PASSWORD=<your sendgrid password>`
  - `SENDGRID_USERNAME=<your sendgrid username>`

Dev notes
---------

We're looking to get spec and heckle coverage up to 100%. You will find methods
throughout the code base tagged with `spec_me`, `cover_me`, and `heckle_me`.
These tags represent three levels of test quality in order of increasing
difficulty. Search through the codebase for places you can help like
`git grep spec_me`.

When the following conditions are met the tag can be removed:

### spec_me

This is pretty basic. All we need is a unit test hitting the method. For the
following method:

```ruby
class MyClass
  def some_method
    if awesome?
      'awesome!'
    else
      'not awesome :('
    end
  end
end
```

You might write a spec that looks like:

```ruby
describe MyClass, '#some_method' do
  it 'returns "awesome!"' do
    MyClass.new.some_method.should == 'awesome!'
  end
end
```

### cover_me

For code coverage you would need to expand the above test to include both
branches:

```ruby
describe MyClass, '#some_method' do
  context 'when awesome' do
    it 'returns "awesome!"' do
      MyClass.new.some_method.should == 'awesome!'
    end
  end

  context 'when not awesome' do
    it 'returns "not awesome :("' do
      awesome = false
      MyClass.new.some_method.should == 'not awesome :('
    end
  end
end
```

You can check the coverage of tests by running `rake spec:rcov`. It generates
a coverage directory. Open `coverage/index.html` in your browser to view the
output.

### heckle_me

Heckle coverage is the hardest. Not only do you need cover the code, you need to
check for various permutations within it.
[Heckle](https://github.com/seattlerb/heckle) is a gem that performs mutations
on your code and runs your tests against the mutated code. If your tests don't
fail then your tests still need some work. Heckle lists out the changes it made
that did not cause your tests to fail.

You can run heckle like this:

```sh
spec spec/models/role/name_translation_key_spec.rb --heckle Role#name_translation_key
```

Translating
-----------

You can find language specific translation groups at:
https://www.transifex.net/projects/p/better/

Known issues
------------

Attachments doesn't work in dev environment

License and legalese
--------------------

This codebase is based largely on the project Bettermeans, which was itself
based on Redmine. Both Bettermeans and Redmine are open source and released
under the terms of the GNU General Public License v2 (GPL). Better is also
GPLv2.

All Redmine code is Copyright (C) 2006-2011  Jean-Philippe Lang
All Bettermeans code is Copyright (C) Shereef Bishay
All Better code is Copyright (C) Robert Fletcher
