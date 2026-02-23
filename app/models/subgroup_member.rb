# frozen_string_literal: true

class SubgroupMember < ApplicationRecord
  belongs_to :subgroup
  belongs_to :group_member

  # Ensure the group_member actually belongs to the same group as the subgroup
  validate :group_member_belongs_to_subgroup_group

  private

    def group_member_belongs_to_subgroup_group
      return unless group_member.present? && subgroup.present?

      unless group_member.group_id == subgroup.group_id
        errors.add(:group_member, "must belong to the same group as the subgroup")
      end
    end
end
