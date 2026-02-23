# frozen_string_literal: true

class Subgroup < ApplicationRecord
  belongs_to :group
  has_many :subgroup_members, dependent: :destroy
  has_many :group_members, through: :subgroup_members
  has_many :users, through: :group_members

  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :name, uniqueness: { scope: :group_id,
                                 message: "must be unique within the group" }

  # Returns only group_members who are students (not mentors)
  def student_members
    group_members.merge(GroupMember.member)
  end
end
