require "faker"
require "random_data"

namespace :redmine do
  desc "Add a set of demo data"
  task :demo_data => [:environment, "demo_data:users", "demo_data:projects", "demo_data:issues", "demo_data:time_entries"] do
    # no op
  end

  namespace :demo_data do
    desc "Add up to 5 random projects"
    task :projects => :environment do
      (1..5).each do
        project = Project.create(
          :name => Faker::Company.catch_phrase[0..29],
          :description => Faker::Company.bs,
          :homepage => Faker::Internet.domain_name,
          :identifier => Faker::Internet.domain_word,
        )
        project.trackers = Tracker.all
        project.save
      end

      puts "#{Project.count} projects total"
    end

  desc "Add up to 25 random users with membership"
    task :users => :environment do
      status = [User::STATUS_ACTIVE, User::STATUS_REGISTERED, User::STATUS_LOCKED]
      projects = Project.all      
      roles = Role.givable.to_a
          25.times do
    user = User.new(
      :firstname => Faker::Name.first_name,
      :lastname => Faker::Name.last_name,
      :mail => Faker::Internet.email,
      :status => User::STATUS_ACTIVE,
    )

    user.login = Faker::Internet.user_name
    user.password = "demodemo3#!"
    user.password_confirmation = "demodemo3#!"
    user.save

    # Add membership to random projects
    (1..5).each do
        project = projects.sample
        role = roles.sample

        next if project.nil? || role.nil?
        membership = Member.new(project: project, user: user)
        membership.roles = [role]
        membership.save!
    end
  end

  puts "#{User.count} users total"
end

desc "Add up to 250 random issues"
task :issues => :environment do
  projects = Project.includes(:trackers, :members => :user).to_a
  statuses = IssueStatus.all.to_a
  priorities = IssuePriority.all.to_a

  created = 0
  failed = 0

  250.times do
    project = projects.sample
    next if project.nil?

    tracker = project.trackers.first || Tracker.first
    author = project.members.map(&:user).select { |u| u && u.active? }.sample || User.active.first
    assignee = project.members.map(&:user).select { |u| u && u.active? }.sample

    issue = Issue.new(
      :tracker => tracker,
      :project => project,
      :subject => Faker::Company.catch_phrase,
      :description => Random.paragraphs(3),
      :status => statuses.sample,
      :priority => priorities.sample,
      :author => author,
      :assigned_to => assignee
    )

    if issue.save
      created += 1
    else
      failed += 1
      puts "Issue failed: #{issue.errors.full_messages.join(', ')}"
    end
  end

  puts "#{Issue.count} issues total"
  puts "#{created} issues created in this run, #{failed} failed"
end


desc "Add up to 250 random time entries"
    task :time_entries => :environment do
        issues = Issue.includes(:project, :author).to_a
  activities = TimeEntryActivity.where(active: true).to_a

  created = 0
  failed = 0

  250.times do
    issue = issues.sample
    next if issue.nil?

    project = issue.project
    next if project.nil?

    users = project.members.includes(:user).map(&:user).select do |u| u && u.active? && u.allowed_to?(:log_time, project)
    end

    if users.empty?
    failed += 1
    puts "Time entry skipped for issue=#{issue.id}, project=#{project.identifier}: no project member can log time"
    next
    end

user = users.sample

    activity = activities.sample || TimeEntryActivity.first

    time_entry = TimeEntry.new
    time_entry.project = project
    time_entry.issue = issue
    time_entry.user = user
    time_entry.activity = activity
    time_entry.hours = rand(1..8)
    time_entry.spent_on = rand(90).days.ago.to_date
    time_entry.comments = Faker::Lorem.sentence

    if time_entry.save
      created += 1
    else
      failed += 1
      puts "Time entry failed for issue=#{issue.id}, project=#{project.identifier}, user=#{user&.login}, activity=#{activity&.name}: #{time_entry.errors.full_messages.join(', ')}"
    end
  end

  puts "#{TimeEntry.count} time entries total"
  puts "#{created} time entries created in this run, #{failed} failed"

  end
end
end
