# Copyright (c) 2008 Matson Systems, Inc.
# Released under the BSD license found in the file
# LICENSE included with this ActivityStreams plug-in.

# activity_stream.rb provides the model ActivityStream

class ActivityStream < ActiveRecord::Base

  # status levels, for generating activites that don't display
  VISIBLE   = 0     # Noraml visible activity
  DEBUG     = 1     # Test activity used for debugginng
  INTERNAL  = 2     # Internal system activity
  DELETED   = 3     # A deleted activity (soft delete)

  belongs_to :actor, :polymorphic => true
  belongs_to :object, :polymorphic => true
  belongs_to :indirect_object, :polymorphic => true
  belongs_to :project

  named_scope :recent, {:conditions => "activity_streams.created_at > '#{(Time.now.advance :days => Setting::DAYS_FOR_ACTIVE_MEMBERSHIP * -1).to_s}'"}

  def before_save # spec_me cover_me heckle_me
    self.is_public = self.project.is_public if self.project
    self.is_public = false if self.hidden_from_user_id > 0
  end

  def indirect_object_phrase # spec_me cover_me heckle_me
    phrase = super
    return phrase if phrase.nil? || !phrase.match(/:/)
    from, to = phrase.split(':')

    original = strong_tag(from)
    updated = strong_tag(to)
    l('issue.from_a_to_b', :original => original, :updated => updated)
  end

  # Finds the recent activities for a given actor, and honors
  # the users activity_stream_preferences.  Please see the README
  # for an example usage.
  def self.recent_actors(actor, location, limit=12) # spec_me cover_me heckle_me

    unless actor.class.name == ACTIVITY_STREAM_USER_MODEL
      find(:all, :conditions =>
        {:actor_id => actor.id,
        :actor_type => actor.class.name,
        :status => 0}, :order => "created_at DESC", :limit => limit,
        :include => [:actor, :object, :indirect_object])

    else
      # FIXME: We really want :include => [:actor, :object], however, when
      # the "p.id" => nil condition prevents polymorphic :include from working
      find(:all,
        :joins => self.preference_join(location),
        :conditions => [
          'actor_id = ? and actor_type = ? and status = ? and p.id IS NULL',
          actor.id, actor.class.name, 0 ],
        :order => "created_at DESC",
        :limit => limit)
    end
  end

  # Finds the recent activities for a given actor, and honors
  # the users activity_stream_preferences.  Please see the README
  # for a sample usage.
  def self.recent_objects(object, location, limit=12) # spec_me cover_me heckle_me
    # FIXME: We really want :include => [:actor, :object], however, when
    # the "p.id" => nil condition prevents polymorphic :include from working
    find(:all,
      :joins => self.preference_join(location),
      :conditions => [
          "object_id = ? and object_type = ? and status = ? and p.id IS NULL",
          object.id, object.class.name, 0 ],
      :order => "created_at DESC",
      :limit => limit)
  end

  def self.preference_join(location) # spec_me cover_me heckle_me
    # location is not tainted as it is a symbol from
    # the code
    "LEFT OUTER JOIN activity_stream_preferences p \
      ON #{ACTIVITY_STREAM_USER_MODEL_ID} = actor_id  \
      AND actor_type = '#{ACTIVITY_STREAM_USER_MODEL}'  \
      AND activity_streams.activity = p.activity \
      AND location = '#{location.to_s}'"
  end

  def self.fetch(user_id, project_id, with_subprojects, limit, max_created_at = nil) # spec_me cover_me heckle_me
    max_created_at = DateTime.now if max_created_at.nil? || max_created_at == ""
    length = limit  || Setting::ACTIVITY_STREAM_LENGTH

    if limit
      length = limit
    end

    with_subprojects ||= true
    project_id.nil? ? project = nil : project = Project.find(project_id)

    user = User.find(user_id) if user_id
    return [] if user && with_subprojects == "custom" && user.projects.empty?#Customized activity stream for user, but user doesn't belong to any projects


    conditions = {}
    conditions[:actor_id] = user_id unless user_id.nil? || with_subprojects == "custom"
    conditions[:project_id] = user.projects.collect{|m| m.id} if !user.nil? && with_subprojects == "custom" && !user.projects.empty? #Customized activity stream for user
    conditions[:project_id] = project.id if project && !with_subprojects
    conditions[:project_id] = project.sub_project_array_visible_to(User.current) if project && with_subprojects

    project_specified = conditions[:project_id] #temp variable for later use

    conditions = conditions.to_array_conditions

    logger.info { "conditions #{conditions.inspect}" }
    conditions[0] += " AND " unless conditions[0].empty?
    conditions[0] += " created_at >= ? AND created_at <= ?"
    conditions.push DateTime.now - 20.year
    conditions.push max_created_at

    conditions[0] += " AND hidden_from_user_id <> ?"
    conditions.push User.current.id

    unless project_specified
      conditions[0] += " AND ((is_public = true) OR (project_id in (?)))"
      conditions.push User.current.projects.collect{|m| m.id}
    end

    unless User.current.logged?
      conditions[0] += " AND (is_public = true)"
    end

    activities_by_item = ActivityStream.all(:conditions => conditions, :limit => length, :order => "created_at desc").group_by {|a| a.object_type.to_s + a.object_id.to_s}
    activities_by_item.each_pair do |key,value|
      activities_by_item[key] = value.sort_by{|i| - i[:created_at].to_i}
    end

    activities_by_item.sort_by{|g| - g[1][0][:created_at].to_i}
  end

  # Soft Delete in as some activites are necessary for site stats
  def soft_destroy # spec_me cover_me heckle_me
    self.update_attribute(:status, DELETED)
  end

  def role_key # spec_me cover_me heckle_me
    raise 'not a role' unless object_type.downcase == 'memberrole'
    "role.#{object_name.downcase.gsub(' ', '_')}"
  end

  private

  def strong_tag(key) # cover_me heckle_me
    "<strong>#{l("issue.#{key.downcase}").capitalize}</strong>"
  end

end
