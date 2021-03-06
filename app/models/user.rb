# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  first_name             :string
#  last_name              :string
#  username               :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  role                   :integer
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_type        :string
#  invited_by_id          :integer
#  invitations_count      :integer          default(0)
#  phone                  :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invitations_count     (invitations_count)
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ApplicationRecord
  has_many :created_games, class_name: 'Game'
  has_many :created_teams, class_name: 'Team'
  has_many :captained_teams, class_name: 'Team', foreign_key: 'captain_id'

  has_many :members, dependent: :destroy
  has_many :starting_memberships, -> { where(role: 'starter') }, class_name: 'Member'
  has_many :alternate_memberships, -> { where(role: 'alternate') }, class_name: 'Member'
  has_many :teams, through: :members
  has_many :starting_teams, through: :starting_memberships, source: :team
  has_many :alternate_teams, through: :alternate_memberships, source: :team

  has_many :attendance_records, class_name: 'UserAttendance', dependent: :destroy
  has_many :games, through: :attendance_records

  has_one :preference

  enum role: [:user, :vip, :admin]
  after_initialize :set_default_role, if: :new_record?

  validates_presence_of :role, :first_name, :last_name, :username # email is validated by devise
  validates_uniqueness_of :username # email is validated by devise

  after_create do
    self.create_preference!(game_email_reminder: '9am'.to_time.utc)
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  def set_default_role
    self.role ||= :user
  end

  def display_name
    [first_name, last_name].all?(&:present?) ? "#{first_name} #{last_name}" : nil
  end

  def captain?
    captained_teams.present?
  end
end
