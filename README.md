parliamentary-questions
=======================

[![Build Status](https://travis-ci.org/ministryofjustice/parliamentary-questions.png?branch=master)](https://travis-ci.org/ministryofjustice/parliamentary-questions)
[![Code Climate](https://codeclimate.com/github/ministryofjustice/parliamentary-questions/badges/gpa.svg)](https://codeclimate.com/github/ministryofjustice/parliamentary-questions)

# Introduction
Webapp to manage the workflow Parliamentary Questions

# System dependencies

- Ruby MRI 2.1.2
- Postgresql 9.3
- phantomjs  (tests only)
- coreutils (required by the `version_tag.sh` script)
- graphviz (required by the `bin/generate-erd` script)

To start with, make sure you have the right version of the Ruby runtime installed.
Multiple versions of Ruby can be managed on the same machine through either [rbenv](https://github.com/sstephenson/rbenv)
or [rvm](https://rvm.io/).

The Postgresql version used in production is 9.3. This can be installed via [homebrew](brew.sh):

    brew install homebrew/versions/postgresql93

# Project setup

Start by setting the [required environment variables](https://github.com/ministryofjustice/parliamentary-questions/tree/dev/config).
Then Install the app dependencies by running the following

    gem install bundler && bundle install

If you get problems installing the pg gem not being able to find libpg, try setting the architecture flag as follows:

    gem install bundler && ARCHFLAGS="-arch x86_64" bundle install

You can now procede setting up the database table layout

    bundle exec rake db:setup

And starting the app with:

    bundle exec rails s

Mock data can be automatically imported by running the following rake task:

    bundle exec rake pqa:import_dummy_data

Finally, a rake task is also provided to load PQ&A XML data into the system.

    bundle exec rake pqa:import_from_xml[path/to/question_file.xml]

# User authentication

It's done using devise and devise invitable:

* https://github.com/plataformatec/devise
* https://github.com/scambra/devise_invitable

For development you can create users with a rake task.
```
# default user
rake user:create

# specific email, password, name
rake "user:create[admin@admin.com, 123456789, admin]"
```

# Data model

![PQ entity-relations diagram](https://github.com/ministryofjustice/parliamentary-questions/blob/dev/erd.png)

An entity-relationship diagram of PQ's data model can be generated by running
the `bin/generate-erd` script. Please do re-run this script to update the graph as
the application schema evolves.

# Running tests

Unit tests can be run via `bundle exec rspec`, while end-to-end tests can
be run be executing the same command with the features folder as argument (i.e.
`bundle exec rspec features`). Please refer to the [readme](https://github.com/ministryofjustice/parliamentary-questions/tree/dev/features) in the features folder
for end-to-end tests implementation details. 
 
