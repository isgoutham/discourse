# frozen_string_literal: true

class UserNotificationSchedule < ActiveRecord::Base
  belongs_to :user

  DEFAULT = -> {
    attrs = { enabled: false }
    7.times do |n|
      attrs["day_#{n}_start_time".to_sym] = 480
      attrs["day_#{n}_end_time".to_sym] = 1020
    end
    attrs
  }.call

  validate :has_valid_times
  validates :enabled, inclusion: { in: [ true, false ] }

  scope :enabled, -> { where(enabled: true) }

  def create_do_not_disturb_timings(delete_existing: false)
    user.do_not_disturb_timings.where(scheduled: true).destroy_all if delete_existing
    UserNotificationScheduleProcessor.create_do_not_disturb_timings_for(self)
  end

  private

  def has_valid_times
    7.times do |n|
      start_key = "day_#{n}_start_time"
      end_key = "day_#{n}_end_time"

      if self[start_key].nil? || self[start_key] > 1410 || self[start_key] < -1
        errors.add(start_key, "is invalid")
      end

      if self[end_key].nil? || self[end_key] > 1440
        errors.add(end_key, "is invalid")
      end

      if self[start_key] && self[end_key] && self[start_key] > self[end_key]
        errors.add(start_key, "is after end time")
      end
    end
  end
end
