# == Schema Information
#
# Table name: user_attendances
#
#  id         :integer          not null, primary key
#  game_id    :integer
#  team_id    :integer
#  user_id    :integer
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  token      :string
#
# Indexes
#
#  index_user_attendances_on_game_id  (game_id)
#  index_user_attendances_on_team_id  (team_id)
#  index_user_attendances_on_user_id  (user_id)
#

FactoryGirl.define do
  factory :user_attendance do
    game
    team
    user

    status { UserAttendance.statuses.values.sample }
  end
end
