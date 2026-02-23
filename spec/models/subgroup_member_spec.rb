# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubgroupMember, type: :model do
  let(:primary_mentor) { FactoryBot.create(:user) }
  let(:group) { FactoryBot.create(:group, primary_mentor: primary_mentor) }
  let(:other_group) { FactoryBot.create(:group, primary_mentor: primary_mentor) }
  let(:subgroup) { FactoryBot.create(:subgroup, group: group) }
  let(:student) { FactoryBot.create(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:subgroup) }
    it { is_expected.to belong_to(:group_member) }
  end

  describe "validations" do
    context "when group_member belongs to the same group as the subgroup" do
      it "is valid" do
        group_member = FactoryBot.create(:group_member, group: group, user: student)
        subgroup_member = SubgroupMember.new(subgroup: subgroup, group_member: group_member)
        expect(subgroup_member).to be_valid
      end
    end

    context "when group_member belongs to a different group" do
      it "is invalid" do
        group_member = FactoryBot.create(:group_member, group: other_group, user: student)
        subgroup_member = SubgroupMember.new(subgroup: subgroup, group_member: group_member)
        expect(subgroup_member).not_to be_valid
        expect(subgroup_member.errors[:group_member]).to include(
          "must belong to the same group as the subgroup"
        )
      end
    end
  end
end
