class War < ApplicationRecord
    enum status: [ :send_request, :declined, :wait_start, :in_war, :finish, :finish_draw ]

    after_save :unanswered_check

    belongs_to :initiator, class_name: :Guild, foreign_key: "initiator_id"
    belongs_to :recipient, class_name: :Guild, foreign_key: "recipient_id"
    belongs_to :winner, class_name: :Guild, foreign_key: "winner_id", required: false

    has_many   :wartimes
    has_one    :active_wartime, -> { where(active: true) }, :class_name => :Wartime
    has_many   :wartime_game, :through => :wartimes, :source => :game

    #validates  :daily_start, 
    validates  :ball_size, presence: true, :inclusion => 0.5..2.0
    validates  :speed_rate, presence: true, :inclusion => 0.5..2.0
    validates  :random_mode, presence: true, allow_blank: true
    validates  :started, presence: true
    validates  :ended, presence: true
    validates  :prize, presence: true, :inclusion => 1..100000

    validates  :daily_start, presence: true
    validates  :daily_end, presence: true
    validates  :time_to_wait, presence: true
    validates  :started, :ended, presence: true
    validate   :end_date_after_start_date, if: :validate_date
    validates  :time_to_wait, presence: true, :inclusion => 15..60
    validates  :max_unanswered, presence: true, :inclusion => 1..15

    def wartime_active?
        time_e = self.daily_start
        time_l = self.daily_end
		t = Time.now
		if time_e > time_l
			result1 = (Range.new(Time.local(t.year, t.month,t.day, time_e.hour, time_e.min, time_e.sec), Time.local(t.year,t.month,t.day + 1, 00, 00, 00)) === t)
			result2 = (Range.new(Time.local(t.year,t.month,t.day, 00, 00, 00), Time.local(t.year,t.month,t.day, time_l.hour, time_l.min, time_l.sec)) === t)
			return result1 || result2
		else
			return Range.new(Time.local(t.year,t.month,t.day, time_e.hour, time_e.min, time_e.sec), Time.local(t.year,t.month,t.day, time_l.hour, time_l.min, time_l.sec)) === t
		end
	end

    private

    def unanswered_check
        if self.status == 'in_war' && (self.max_unanswered <= self.recipient_unanswered)
            self.winner = self.initiator
            self.initiator.update_attribute(:points, self.initiator.points + (self.prize * 2))
            self.status = :finish
            self.save
        elsif self.status == 'in_war' && (self.max_unanswered <= self.initiator_unanswered)
            self.winner = self.recipient
            self.recipient.update_attribute(:points, self.recipient.points + (self.prize * 2))
            self.status = :finish
            self.save
        end
    end

    def end_date_after_start_date
        return if ended.blank? || started.blank?

        if ended.to_date < started.to_date
            errors.add(:ended, "must be after the start date")
        end
    end

    def validate_date
        return false unless ended && started && daily_end && daily_start
        begin
            date = ended.to_date
        rescue ArgumentError
            errors.add(:ended, "must be in a date format")
            return false
        end
        begin
            date = started.to_date
        rescue ArgumentError
            errors.add(:started, "must be in a date format")
            return false
        end
        begin
            date = daily_start.to_date
        rescue ArgumentError
            errors.add(:daily_start, "must be in a time format")
            return false
        end
        begin
            date = daily_end.to_date
        rescue ArgumentError
            errors.add(:daily_end, "must be in a time format")
            return false
        end
        return true
    end

    private
    def in_wt?
        self.active_wt || self.waiting_wt
    end
end