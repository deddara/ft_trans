class GamesController < ApplicationController

	before_action :check_game_not_exist, only: [:show, :join_player]
	before_action :check_user_pending_game_exist, only: [:create, :join_player]
	before_action :check_game_is_ended, only: [:show, :join_player, :leave_games]
	before_action :check_game_allready_have_p2, only: [:join_player]
	before_action :check_passcode_wrong, only: [:join_player]

	def index
		@games = Game.all
	end

	def new
		@game = Game.new
	end

	def create
		game = Game.new(game_params)
		game.p1 = current_user
		if game.save
			GameStateHash.instance.add_kv("p1_status_#{game.id}", "not ready")
			GameStateHash.instance.add_kv("status_#{game.id}", "waiting")
			GameStateHash.instance.add_kv("p1_nickname_#{game.id}", game.p1.nickname)
			redirect_to game_path(game), success: "Game was created!"
			
		else
			redirect_to new_game_path, alert: game.errors.full_messages.join("; ")
		end
	end

	def show
		@game = Game.find(params[:id])
	end

	def join_player
		game = Game.find(params[:id])
        game.p2 = current_user
        unless game.save
            redirect_to games_path, alert: game.errors.full_messages.join("; ")
        else
			GameStateHash.instance.add_kv("p2_status_#{game.id}", "not ready")
			GameStateHash.instance.add_kv("p2_nickname_#{game.id}", game.p2.nickname)
			redirect_to game_path(game), success: "success!"
        end
	end

	def leave_player
		game = Game.find(params[:id])
		if current_user == game.p1
			if GameStateHash.instance.return_value("status_#{game.id}") == 'waiting'
            	game.destroy
				redirect_to games_path, notice: "Game has been destroyed!"
			else
				GameStateHash.instance.add_kv("p1_status_#{game.id}", "leave")
				redirect_to game_path(game), success: "You leave!"
			end
		elsif current_user == game.p2
			if (GameStateHash.instance.return_value("status_#{game.id}") == 'waiting')
				GameStateHash.instance.delete("p2_nickname_#{game.id}")
				game.p2 = nil
				game.save
			else
				GameStateHash.instance.add_kv("p2_status_#{game.id}", "leave")
			end
			redirect_to game_path(game), success: "You leave!"
        end
	end

	def switch_ready
		game = Game.find(params[:id])
		if current_user == game.p1
			string = "p1"
		else
			string = "p2"
		end
		status = GameStateHash.instance.return_value("#{string}_status_#{game.id}")
		if status == "not ready" || status == "lags"
			GameStateHash.instance.add_kv("#{string}_status_#{game.id}", "ready")
			p string
		elsif status == "ready"
			GameStateHash.instance.add_kv("#{string}_status_#{game.id}", "not ready")
		end
	end

	private
	def game_params
		params.require(:game).permit(	:name, :private, :rating, :passcode, :bg_color,
										:paddle_color, :ball_color, :ball_down_mode,
										:ball_speedup_mode, :random_mode, :ball_size,
										:speed_rate, :bg_image );
	end

	def check_game_not_exist
		game = Game.find_by(id: params[:id])
		redirect_to games_path, alert: "Game not found!" unless game
	end

	def check_user_pending_game_exist
		redirect_to games_path, alert: "You allready have a game" if current_user.pending_games?
	end

	def check_game_is_ended
		game = Game.find_by(id: params[:id])
		redirect_to games_path, alert: "Game has been ended!" if game.status == "ended"
	end

	def check_game_allready_have_p2
		game = Game.find_by(id: params[:id])
		redirect_to game_path(game), alert: "Game is full" if game.p2
	end

	def check_passcode_wrong
		game = Game.find_by(id: params[:id])
		redirect_to game_path(game), alert: "Wrong passcode" if game.private &&
												game.passcode != params[:passcode]
	end
end
