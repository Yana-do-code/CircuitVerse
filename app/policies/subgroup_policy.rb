# frozen_string_literal: true

class SubgroupPolicy < ApplicationPolicy
  attr_reader :user, :subgroup

  def initialize(user, subgroup)
    @user = user
    @subgroup = subgroup
  end

  # Any group member (including mentors) can view subgroups
  def show?
    group_member_or_admin?
  end

  # Only primary mentor or admin can create subgroups
  def create?
    admin_access?
  end

  # Only primary mentor or admin can update subgroups
  def update?
    admin_access?
  end

  # Only primary mentor or admin can destroy subgroups
  def destroy?
    admin_access?
  end

  # Only primary mentor or admin can manage subgroup membership
  def add_member?
    admin_access?
  end

  def remove_member?
    admin_access?
  end

  private

    def admin_access?
      subgroup.group.primary_mentor_id == user.id || user.admin?
    end

    def group_member_or_admin?
      admin_access? || subgroup.group.group_members.exists?(user_id: user.id)
    end
end
