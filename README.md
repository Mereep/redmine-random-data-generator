# redmine-random-data-generator
Generates Random Data into Redmine for Testing purposes. Creates `projects`, `users`, `issues` and `time entries`.

## Usage 
Following: `redmine_base` is the directory where redmine resides, contains directories like `app`, `bin` etc.; e.g., `/usr/src/redmine` <-- default redmine docker container directory

### Preconditions:
  - Redmine installed
  - Environment set correctly (Database connection is working, App is able to Bootup etc.)
    - Make sure you have `SECRET_KEY_BASE=whateveryourpasswordis set`
      - Hint: if following the installation guides in `https://hub.docker.com/_/redmine` make sure you extend the environment variables for this
        
### Run:
  - Switch Working Dir: `cd [redmine_base]` 
  - If not done already, spawn the Redmine default data
    -  `bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=en`
  - Install Dependencies:
    - Create Dependency-File (`Gemfile.local`):
     ```bash
     cat >> Gemfile.local <<'EOF'
     gem 'faker'
     gem 'random_data'
     EOF
     ```
     (or just create a file with the two `gem ...` entries)
    - Install dependencies: `bundle install`
  - Copy the script file to `[redmine_base]/lib/tasks/random_data_generator.rake`
  - Now you can spawn the data as follows (order matters):
    - Projects: `bundle exec rake redmine:demo_data:projects RAILS_ENV=production`
    - Users: `bundle exec rake redmine:demo_data:users RAILS_ENV=production`
    - Issues: `bundle exec rake redmine:demo_data:issues RAILS_ENV=production`
    - Time Entries: `bundle exec rake redmine:demo_data:time_entries RAILS_ENV=production`


## Why
I needed a Redmine with some default data for testing purposes. However, the officiall Repo listed in the Redmine Docs does not exist (anymore):
- Redmine Doc: https://www.redmine.org/projects/redmine/wiki/Generating_demo_data
- Pointed to Repo (n/a): https://github.com/acosonic/redmine_data_generator

## Mentions
Script based on on `acsonic`s snippet: https://gist.github.com/acosonic/032467e9e1a0e7f900cc16aa27326800
--> Did not work on my Machine(tm), adapted it to a `working` state.

## Tested on
Official Redmine Docker https://hub.docker.com/_/redmine (Version Redmine: `6.1.2.stable`)
