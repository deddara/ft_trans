class Game < ApplicationRecord
	has_one_attached :bg_image

    enum status: [ :pending, :ended, :times_up ]
    enum game_type: [ :open, :rating, :close, :wartime, :tournament ]
    belongs_to :p1, class_name: "User", foreign_key: "p1_id"
    belongs_to :p2, class_name: "User", foreign_key: "p2_id", optional: true
    belongs_to :winner, class_name: "User", foreign_key: "winner_id", optional: true
    belongs_to :loser, class_name: "User", foreign_key: "loser_id", optional: true

    validates  :name, presence: true, length: { maximum: 15, minimum: 4 }, if: -> { self.wartime? &&  self.tournament? }
    validate_enum_attribute :game_type, message: "Wrong game type!"
    validates  :game_type, presence: true, inclusion: { in: %w[open rating close], message: "Wrong game type!"}, unless: :p2
    validates  :passcode, presence: true, length: { maximum: 4, minimum: 4 }, if: -> { self.game_type == 'close' }
    validates  :bg_image, attached: true, content_type: [:png, :jpg, :jpeg], size: { less_than: 10.megabytes , message: 'filesize to big' }, allow_blank: true
    validates  :ball_color, format: { with: /\A#[a-f0-9]{6}\z/, message: "Wrong color format!" }
    validates  :bg_color, format: { with: /\A#[a-f0-9]{6}\z/, message: "Wrong color format!" }
    validates  :random_mode, presence: true, allow_blank: true
    validates  :paddle_color, format: { with: /\A#[a-f0-9]{6}\z/, message: "Wrong color format!" }
    validates  :ball_size, presence: true, :inclusion => 0.5..2.0
    validates  :speed_rate, presence: true, :inclusion => 0.5..2.0

    # basic game logic and methods

    attr_accessor   :canvas_width,
                    :canvas_height,
                    :grid,
                    :speed,
                    :max_paddle_y,
                    :min_paddle_y,
                    :paddle_height,
                    :paddle_R,
                    :paddle_L,
                    :max_speed,
                    :ball_down_rate,
                    :ball,
                    :ball_down_rate,
                    :score,
                    :wt_end_time,
                    :times_up_game

    after_initialize :set_params

    def start
        self.update(:started => DateTime.now)
        GameStateHash.instance.add_kv("paddle_p1_#{self.id}", 0)
        GameStateHash.instance.add_kv("paddle_p2_#{self.id}", 0)
        while true
            render()
            return if check_game_state?()
            unless (game_active?())
                sleep(0.2)
                next
            end
            check_collision()
            paddle_motion()
            if @ball[:reset]
                update_game_condition()
                reset_games()
                sleep(2)
            else
                sleep(0.03)
            end
        end
    end

    private
    def set_params
        @canvas_width = 1064
        @canvas_height = 514
        @grid = 20
        @speed = 15 * self.speed_rate
        @max_speed = 6
        @paddle_height = @grid * 6
        @min_paddle_y = @grid
        @max_paddle_y = @canvas_height - @grid - @paddle_height
        @ball_down_rate = 0.05
        @times_up_game = false
        @score = {
            p1: 0,
            p2: 0
        }

        @paddle_R = {
            x: @canvas_width - @grid * 1.5,
            y: @canvas_height / 2 - @paddle_height / 2,
            width: @grid,
            height: @paddle_height,
            dy: 0
        }

        @paddle_L = {
            x: @grid / 2,
            y: @canvas_height / 2 - @paddle_height / 2,
            width: @grid,
            height: @paddle_height,
            dy: 0
        }

        @ball = {
            x: @canvas_width / 2 - ((@grid * self.ball_size) / 2),
            y: @canvas_height / 2 -  ((@grid * self.ball_size) / 2),
            radius: @grid * self.ball_size,
            resset: false,
            dx: @speed,
            dy: -@speed
        }
        if self.game_type == "wartime" && self.p1.guild.war_active
            @wt_end_time = self.p1.guild.war_active.time_to_wait
        end

    end

    def render
        data = {
            "paddle_color": self.paddle_color,
            "ball_color": self.ball_color,
            "ball_size": self.ball_size,
            "ball_x": self.ball[:x],
            "ball_y":  self.ball[:y],
            "ball_radius": self.ball[:radius],
            "paddle_p1_y": self.paddle_L[:y],
            "paddle_p2_y": self.paddle_R[:y],
            "p1_score": self.score[:p1],
            "p2_score": self.score[:p2],
            "p1_nickname": GameStateHash.instance.return_value("p1_nickname_#{self.id}"),
            "p2_nickname": GameStateHash.instance.return_value("p2_nickname_#{self.id}"),
            "p1_status": GameStateHash.instance.return_value("p1_status_#{self.id}"),
            "p2_status": GameStateHash.instance.return_value("p2_status_#{self.id}"),
            "game_status": GameStateHash.instance.return_value("status_#{self.id}"),
            "winner": GameStateHash.instance.return_value("winner_#{self.id}"),
            "ended_at": time_left()
        }
        GameChannel.broadcast_to self, data
    end

    def game_active?
        if  GameStateHash.instance.return_value("p1_status_#{self.id}") == 'lags' ||
            GameStateHash.instance.return_value("p2_status_#{self.id}") == 'lags'
            if GameStateHash.instance.return_value("p1_status_#{self.id}") == 'lags' &&
                (GameStateHash.instance.return_value("p1_lagtime_#{self.id}") + 2.minute < DateTime.now)
                GameStateHash.instance.add_kv("p2_status_#{self.id}", "ready")
                GameStateHash.instance.add_kv("p1_status_#{self.id}", "leave")
                GameStateHash.instance.add_kv("status_#{self.id}", "active")
                return true
            elsif GameStateHash.instance.return_value("p2_status_#{self.id}") == 'lags' &&
                (GameStateHash.instance.return_value("p2_lagtime_#{self.id}") + 2.minute < DateTime.now)
                GameStateHash.instance.add_kv("p1_status_#{self.id}", "ready")
                GameStateHash.instance.add_kv("p2_status_#{self.id}", "leave")
                GameStateHash.instance.add_kv("status_#{self.id}", "active")
                return true
            end
            GameStateHash.instance.add_kv("status_#{self.id}", "paused")
            return false
        elsif   (GameStateHash.instance.return_value("status_#{self.id}") == 'active' &&
                (GameStateHash.instance.return_value("p1_status_#{self.id}") == 'not ready' ||
                GameStateHash.instance.return_value("p2_status_#{self.id}") == 'not ready'))
            GameStateHash.instance.add_kv("status_#{self.id}", "paused")
            return false
        elsif GameStateHash.instance.return_value("status_#{self.id}") == 'paused' &&
                (GameStateHash.instance.return_value("pause_time_#{self.id}") + 3.minute < DateTime.now || @times_up_game)
            @times_up_game = false
            GameStateHash.instance.add_kv("p1_status_#{self.id}", "ready")
            GameStateHash.instance.add_kv("p2_status_#{self.id}", "ready")
            GameStateHash.instance.add_kv("status_#{self.id}", "active")
            return true
        elsif GameStateHash.instance.return_value("status_#{self.id}") == 'active'
            return true
        else
            return false
        end
    end

    def check_collision
        @ball[:y] += @ball[:dy]
        @ball[:x] += @ball[:dx]
        if (@ball[:x] <= 0 ||
            @ball[:x] + @ball[:radius] >= @canvas_width)
            @ball[:reset] = true;
        end

        if (@ball[:y] + @ball[:dy] - @ball[:radius] <= 0 ||
            (@ball[:y] + @ball[:radius]) + @ball[:dy] + @ball[:radius] >= @canvas_height)
            @ball[:dy] = -1 * @ball[:dy];
        end

        if (collides(@ball, @paddle_L) || collides(@ball, @paddle_R))
            if (self.ball_speedup_mode && @ball[:dx].abs() < @max_speed)
                @ball[:dx] = -1 * (@ball[:dx] + (@ball[:dx] * self.speed_rate));
            else
                @ball[:dx] = -1 * @ball[:dx];
            end
            if (self.random_mode)
                @ball[:dy] = rand(-25..25);
            end
            if (self.ball_down_mode)
                @ball[:radius] = @ball[:radius] - (@ball[:radius] * self.ball_down_rate)
            end
        end

    end

    def collides(obj_1, obj_2)
		left_x = obj_1[:x]
		right_x = obj_1[:x] + obj_1[:radius]
		if ((left_x - 10 >= obj_2[:x] && left_x -10 <= obj_2[:x] + obj_2[:width]) &&
			((obj_1[:y] >= obj_2[:y] && obj_1[:y] <= obj_2[:y] + obj_2[:height]) || 
            (obj_1[:y] + obj_1[:radius] >= obj_2[:y] &&
            obj_1[:y] + obj_1[:radius] <= obj_2[:y] + obj_2[:height])))
                obj_1[:x] = obj_2[:x] + obj_2[:width]
			    return true
        elsif ((right_x - 10 >= obj_2[:x] && right_x -10 <= obj_2[:x] + obj_2[:width]) &&
            ((obj_1[:y] >= obj_2[:y] && obj_1[:y] <= obj_2[:y] + obj_2[:height]) || 
            (obj_1[:y] + obj_1[:radius] >= obj_2[:y] &&
            obj_1[:y] + obj_1[:radius] <= obj_2[:y] + obj_2[:height])))
			    obj_1[:x] = obj_2[:x] - obj_1[:radius]
			    return true
        end
		return false
    end
    
    def paddle_motion

        @paddle_L[:y] += GameStateHash.instance.return_value("paddle_p1_#{self.id}")
        if (@paddle_L[:y] > @max_paddle_y)
            @paddle_L[:y] = @max_paddle_y
        end
        if (@paddle_L[:y] < @min_paddle_y)
            @paddle_L[:y] = @min_paddle_y
        end
        @paddle_R[:y] += GameStateHash.instance.return_value("paddle_p2_#{self.id}")
        if (@paddle_R[:y] > @max_paddle_y)
            @paddle_R[:y] = @max_paddle_y
        end
        if (@paddle_R[:y] < @min_paddle_y)
            @paddle_R[:y] = @min_paddle_y
        end
    end

    def update_game_condition
        if (@ball[:reset])
			if ((@ball[:x] + @ball[:radius]) + @ball[:dx] >= @canvas_width)
				@score[:p1] += 1
			else
                @score[:p2] += 1;
            end
			return true
        end
		return false
    end
    
    def reset_games
        @ball[:radius] = @grid * self.ball_size
        @ball[:x] = @canvas_width / 2 - (@ball[:radius] / 2)
        @ball[:y] = @canvas_height / 2 - (@ball[:radius] / 2)
        @ball[:reset] = false
        @ball[:dx] = @speed
        @ball[:dy] = -@speed
    end

    def check_game_state?
        if GameStateHash.instance.return_value("status_#{self.id}") == "canceled"
            return true
        end
        if @score[:p1] == 21 || @score[:p2] == 21 || GameStateHash.instance.return_value("p1_status_#{self.id}") == 'leave' || 
                                                     GameStateHash.instance.return_value("p2_status_#{self.id}") == 'leave' || 
                                                     (self.wartime? && (GameStateHash.instance.return_value("p2_activate_game_#{self.id}") == "no") && 
                                                     (self.created_at + @wt_end_time.minutes < DateTime.now)) ||
                                                     (self.created_at + self.time_to_game.minutes < DateTime.now)
            self.reload
            if (self.created_at + self.time_to_game.minutes < DateTime.now)
                if !times_up()
                    return false
                end
            elsif @score[:p1] == 21 || GameStateHash.instance.return_value("p2_status_#{self.id}") == 'leave' ||
                (self.wartime? && (GameStateHash.instance.return_value("p2_activate_game_#{self.id}") == "no") && (self.created_at + @wt_end_time.minutes < DateTime.now))
                GameStateHash.instance.add_kv("winner_#{self.id}", "p1")
                calculate_points(self.p1, self.p2)
                self.status = "ended"
            else
                GameStateHash.instance.add_kv("winner_#{self.id}", "p2")
                calculate_points(self.p2, self.p1)
                self.status = "ended"
            end
            GameStateHash.instance.add_kv("status_#{self.id}", "ended")
            GameStateHash.instance.delete_key("paddle_p2_#{self.id}")
            GameStateHash.instance.delete_key("paddle_p1_#{self.id}")
            GameStateHash.instance.delete_key("p2_activate_game_#{self.id}")
            self.p1_score = @score[:p1]
            self.p2_score = @score[:p2]
            self.ended = DateTime.now
            self.save
            render()
        end
        return GameStateHash.instance.return_value("status_#{self.id}") == 'ended'
    end

    def calculate_points(winner, loser)
        self.winner = winner
        self.loser = loser
        if self.rating?
            winner.update_attribute(:score, winner.score + 25)
            loser.update_attribute(:score, loser.score - 25)
        end
        if self.tournament?
            tournamentPair = TournamentPair.find_by(game: self.id)
            tournamentPair.update_attribute(:played, true)
            tournament = tournamentPair.tournament
            player = tournament.tournament_players.find_by(player: winner)
            player.update_attribute(:score, player.score + 1)
        end
        if winner.guild
            if self.rating?
                winner.guild.update_attribute(:points, winner.guild.points + 100)
            elsif winner.guild != loser.guild
                winner.guild.update_attribute(:points, winner.guild.points + 25)
                if self.wartime? && winner.guild.in_war?(loser.guild)
                    if winner.guild.war_active.initiator == winner.guild
                        winner.guild.war_active.update_attribute(:initiator_score, winner.guild.war_active.initiator_score + 1)
                        if GameStateHash.instance.return_value("p2_activate_game_#{self.id}") == "no"
                            winner.guild.war_active.update_attribute(:recipient_unanswered, winner.guild.war_active.recipient_unanswered + 1)
                        end
                    else
                        winner.guild.war_active.update_attribute(:recipient_score, winner.guild.war_active.recipient_score + 1)
                        if GameStateHash.instance.return_value("p2_activate_game_#{self.id}") == "no"
                            winner.guild.war_active.update_attribute(:initiator_unanswered, winner.guild.war_active.initiator_unanswered + 1)
                        end
                    end
                    wartime = Wartime.find_by(game: self.id)
                    wartime.winner = winner.guild
                    wartime.active = false
                    wartime.save
                end
            end
        end
    end
    
    def times_up
        if @score[:p1] > @score[:p2]
            self.winner = self.p1
            self.loser = self.p2
            if self.tournament?
                tournamentPair = TournamentPair.find_by(game: self.id)
                tournamentPair.update_attribute(:played, true)
                tournament = tournamentPair.tournament
                player = tournament.tournament_players.find_by(player: self.p1)
                player.update_attribute(:score, player.score + 1)
            end
            self.status = "ended"
            GameStateHash.instance.add_kv("winner_#{self.id}", "p1")
            return true
        elsif @score[:p1] < @score[:p2]
            self.winner = self.p2
            self.loser = self.p1
            if self.tournament?
                tournamentPair = TournamentPair.find_by(game: self.id)
                tournamentPair.update_attribute(:played, true)
                tournament = tournamentPair.tournament
                player = tournament.tournament_players.find_by(player: self.p2)
                player.update_attribute(:score, player.score + 1)
            end
            self.status = "ended"
            GameStateHash.instance.add_kv("winner_#{self.id}", "p2")
            return true
        elsif @score[:p2] == 0 && @score[:p1] == 0
            if self.tournament?
                tournamentPair = TournamentPair.find_by(game: self.id)
                tournamentPair.update_attribute(:played, true)
                tournament = tournamentPair.tournament
                player1 = tournament.tournament_players.find_by(player: self.p2)
                player2 = tournament.tournament_players.find_by(player: self.p2)
                player1.update_attribute(:score, player1.score - 1)
                player2.update_attribute(:score, player2.score - 1)
            end
            self.status = 'times_up'
            return true
        else
            @times_up_game = true
            return false
        end
    end

    def time_left
        time1 = DateTime.now
        time2 = self.created_at + self.time_to_game.minutes
        diff = (time2 - time1).to_i
        if diff < 0
            return "00:00"
        else
            return "#{diff / 60}:#{diff % 60}"
        end
    end
end
