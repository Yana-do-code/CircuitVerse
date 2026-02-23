# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subgroup, type: :model do
  let(:primary_mentor) { FactoryBot.create(:user) }
  let(:group) { FactoryBot.create(:group, primary_mentor: primary_mentor) }

  subject(:subgroup) { FactoryBot.build(:subgroup, group: group) }

  describe "associations" do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:subgroup_members).dependent(:destroy) }
    it { is_expected.to have_many(:group_members).through(:subgroup_members) }
    it { is_expected.to have_many(:users).through(:group_members) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(255) }

    context "uniqueness of name scoped to group" do
      before { FactoryBot.create(:subgroup, name: "Team A", group: group) }

      it "does not allow duplicate names within the same group" do
        duplicate = FactoryBot.build(:subgroup, name: "Team A", group: group)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("must be unique within the group")
      end

      it "allows the same name in a different group" do
        other_group = FactoryBot.create(:group, primary_mentor: primary_mentor)
        subgroup_other = FactoryBot.build(:subgroup, name: "Team A", group: other_group)
        expect(subgroup_other).to be_valid
      end
    end
  end

  describe "#student_members" do
    let!(:mentor_member) do
      FactoryBot.create(:group_member, group: group,
                                       user: FactoryBot.create(:user), mentor: true)
    end
    let!(:student_member) do
      FactoryBot.create(:group_member, group: group,
                                       user: FactoryBot.create(:user), mentor: false)
    end

    before do
      saved_subgroup = FactoryBot.create(:subgroup, group: group)
      SubgroupMember.create!(subgroup: saved_subgroup, group_member: mentor_member)
      SubgroupMember.create!(subgroup: saved_subgroup, group_member: student_member)
      @saved_subgroup = saved_subgroup
    end

    it "returns only non-mentor group_members" do
      expect(@saved_subgroup.student_members).to include(student_member)
      expect(@saved_subgroup.student_members).not_to include(mentor_member)
    end
  end
end
