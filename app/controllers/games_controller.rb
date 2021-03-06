class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_and_authorize_resource, only: [:show, :edit, :update, :destroy, :complete, :cancel]
  before_action :authorize_resource, except: [:show, :edit, :update, :destroy, :complete, :cancel]

  # GET /games
  # GET /games.json
  def index
    @games = policy_scope(Game).order(time: :desc).page(params[:page])
  end

  # GET /games/1
  # GET /games/1.json
  def show
    @team = @game.team
    @comments = @game.comments.includes(:commenter)
    @attendance = UserAttendance.find_by(game: @game, team: @team, user: current_user)
    @starting_attendances = @team.attendance_records.where(user_id: @team.starters.ids, game: @game)
    @alternate_attendances = @team.attendance_records.where(user_id: @team.alternates.ids, game: @game)
  end

  # GET /games/new
  def new
    @game = Game.new
  end

  # GET /games/1/edit
  def edit
    @time = @game.time.localtime
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(resource_params)
    @game.created_by = current_user
    time_hash = resource_params.slice('time(1i)', 'time(2i)', 'time(3i)', 'time(4i)', 'time(5i)').to_h
    @game.time = DateTime.new(*time_hash.values.map(&:to_i))

    respond_to do |format|
      if @game.save
        @game.user_attendances.includes(user: :preference).each do |attendance|
          user = attendance.user
          preferred_email_time = user.preference.game_email_reminder.change(month: @game.time.month, day: @game.time.day, year: @game.time.year)
          # preferred_email_time = 15.seconds.from_now
          attendance.generate_token!
          attending_link = set_user_attendance_url(token: attendance.token, attending: true)
          absent_link = set_user_attendance_url(token: attendance.token, attending: false)
          GameMailer.game_reminder(user, attending_link, absent_link, @game).deliver_later(wait_until: preferred_email_time)
        end
        format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    th = resource_params.slice('time(1i)', 'time(2i)', 'time(3i)', 'time(4i)', 'time(5i)').to_h
    @game.assign_attributes resource_params
    @game.time = Time.parse("#{th['time(1i)']}-#{th['time(2i)']}-#{th['time(3i)']} #{th['time(4i)']}:#{th['time(5i)']} ")

    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def complete
    if %w(win draw loss).include?(params[:status])
      @game.update(status: params[:status])
      redirect_to @game
    else
      recirect_to @game, alert: 'Error: invalid game status'
    end
  end

  def cancel
    @game.canceled!
    redirect_to @game
  end

  private

  def set_and_authorize_resource
    authorize @game = Game.find(params[:id])
  end

  def resource_params
    params.require(:game).permit(:name, :notes, :time, :location, :team_id)
  end
end
