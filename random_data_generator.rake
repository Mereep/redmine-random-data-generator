# If you need another amount of data being created just search for (number..number).each or number.times entries in the file and increase the values

require "faker"
require "random_data"

namespace :redmine do
  desc "Will execute all commands in a row for generating test data"
  task :"random-data" => [
    :environment,
    "random-data:projects",
    "random-data:users",
    "random-data:issues",
    "random-data:assignments",
    "random-data:time_entries"
  ] do
    # just execute
  end

  namespace :"random-data" do
    desc "Add random projects"
    task :projects => :environment do
      (1..5).each do
        project = Project.create(
          :name => Faker::Company.catch_phrase[0..29],
          :description => Faker::Company.bs,
          :homepage => Faker::Internet.domain_name,
          :identifier => Faker::Internet.domain_word,
        )

        project.trackers = Tracker.all
        project.save!
      end

      puts "#{Project.count} projects total"
    end

    desc "Add random users with membership"
    task :users => :environment do
      projects = Project.all.to_a
      roles = Role.givable.to_a

      25.times do
        user = User.new(
          :firstname => Faker::Name.first_name,
          :lastname => Faker::Name.last_name,
          :mail => Faker::Internet.unique.email,
          :status => User::STATUS_ACTIVE,
        )

        user.login = Faker::Internet.unique.user_name
        user.password = "demodemo3#!"
        user.password_confirmation = "demodemo3#!"
        user.save!

        projects.sample(5).each do |project|
          role = roles.sample
          next if project.nil? || role.nil?
          next if Member.exists?(:project_id => project.id, :user_id => user.id)

          membership = Member.new(:project => project, :user => user)
          membership.roles = [role]
          membership.save!
        end
      end

      puts "#{User.count} users total"
      puts "#{Member.count} memberships total"
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

    desc "Randomly assign existing issues to active project members"
    task :assignments => :environment do
      issues = Issue.includes(:project).to_a
      roles = Role.givable.to_a
      active_users = User.active.to_a

      assigned = 0
      memberships_created = 0
      skipped = 0
      failed = 0

      issues.each do |issue|
        project = issue.project

        if project.nil?
          skipped += 1
          puts "Assignment skipped for issue=#{issue.id}: no project"
          next
        end

        users = project.members.includes(:user).map(&:user).select do |u|
          u && u.active?
        end

        # If the project has no active members, add some.
        if users.empty?
          role = roles.sample

          if active_users.empty? || role.nil?
            skipped += 1
            puts "Assignment skipped for issue=#{issue.id}, project=#{project.identifier}: no active users or no assignable roles"
            next
          end

          active_users.sample(5).each do |user|
            next if Member.exists?(:project_id => project.id, :user_id => user.id)

            member = Member.new(:project => project, :user => user)
            member.roles = [role]

            if member.save
              memberships_created += 1
            else
              puts "Membership failed for project=#{project.identifier}, user=#{user.login}: #{member.errors.full_messages.join(', ')}"
            end
          end

          users = project.members.reload.includes(:user).map(&:user).select do |u|
            u && u.active?
          end
        end

        if users.empty?
          skipped += 1
          puts "Assignment skipped for issue=#{issue.id}, project=#{project.identifier}: still no active project members"
          next
        end

        assignee = users.sample
        issue.assigned_to = assignee

        if issue.save
          assigned += 1
        else
          failed += 1
          puts "Assignment failed for issue=#{issue.id}, project=#{project.identifier}, assignee=#{assignee&.login}: #{issue.errors.full_messages.join(', ')}"
        end
      end

      puts "#{Issue.where.not(:assigned_to_id => nil).count} issues assigned total"
      puts "#{assigned} issues assigned in this run"
      puts "#{memberships_created} memberships created in this run"
      puts "#{skipped} skipped, #{failed} failed"
    end

    desc "Add random time entries"
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

        users = project.members.includes(:user).map(&:user).select do |u|
          u && u.active? && u.allowed_to?(:log_time, project)
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
