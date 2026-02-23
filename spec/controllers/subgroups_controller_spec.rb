# frozen_string_literal: true

require "rails_helper"

describe SubgroupsController, type: :request do
  before do
    @primary_mentor = FactoryBot.create(:user)
    @member_user    = FactoryBot.create(:user)
    @group          = FactoryBot.create(:group, primary_mentor: @primary_mentor)
    @group_member   = FactoryBot.create(:group_member, group: @group, user: @member_user)
  end

  # ---------------------------------------------------------------------------
  # CREATE
  # ---------------------------------------------------------------------------
  describe "#create" do
    let(:valid_params) { { subgroup: { name: "Team Alpha" } } }

    context "when primary mentor is signed in" do
      before { sign_in @primary_mentor }

      it "creates a subgroup" do
        expect do
          post group_subgroups_path(@group), params: valid_params
        end.to change(Subgroup, :count).by(1)
      end

      it "redirects to the subgroup show page" do
        post group_subgroups_path(@group), params: valid_params
        expect(response).to redirect_to(group_subgroup_path(@group, Subgroup.last))
      end
    end

    context "when a regular group member is signed in" do
      before { sign_in @member_user }

      it "does not create a subgroup" do
        expect do
          post group_subgroups_path(@group), params: valid_params
        end.not_to change(Subgroup, :count)
      end

      it "returns not authorized" do
        post group_subgroups_path(@group), params: valid_params
        check_not_authorized(response)
      end
    end

    context "when a random user is signed in" do
      it "returns not authorized" do
        sign_in_random_user
        post group_subgroups_path(@group), params: valid_params
        check_not_authorized(response)
      end
    end

    context "with invalid params (blank name)" do
      before { sign_in @primary_mentor }

      it "does not create a subgroup" do
        expect do
          post group_subgroups_path(@group), params: { subgroup: { name: "" } }
        end.not_to change(Subgroup, :count)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------
  describe "#show" do
    before { @subgroup = FactoryBot.create(:subgroup, group: @group) }

    context "when primary mentor is signed in" do
      it "renders successfully" do
        sign_in @primary_mentor
        get group_subgroup_path(@group, @subgroup)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when a group member is signed in" do
      it "renders successfully" do
        sign_in @member_user
        get group_subgroup_path(@group, @subgroup)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when a random user is signed in" do
      it "returns not authorized" do
        sign_in_random_user
        get group_subgroup_path(@group, @subgroup)
        check_not_authorized(response)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # UPDATE
  # ---------------------------------------------------------------------------
  describe "#update" do
    before { @subgroup = FactoryBot.create(:subgroup, name: "Old Name", group: @group) }

    context "when primary mentor is signed in" do
      before { sign_in @primary_mentor }

      it "updates the subgroup name" do
        patch group_subgroup_path(@group, @subgroup),
              params: { subgroup: { name: "New Name" } }
        expect(@subgroup.reload.name).to eq("New Name")
      end

      it "redirects to subgroup show" do
        patch group_subgroup_path(@group, @subgroup),
              params: { subgroup: { name: "New Name" } }
        expect(response).to redirect_to(group_subgroup_path(@group, @subgroup))
      end
    end

    context "when a group member is signed in" do
      it "returns not authorized" do
        sign_in @member_user
        patch group_subgroup_path(@group, @subgroup),
              params: { subgroup: { name: "New Name" } }
        check_not_authorized(response)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DESTROY
  # ---------------------------------------------------------------------------
  describe "#destroy" do
    before { @subgroup = FactoryBot.create(:subgroup, group: @group) }

    context "when primary mentor is signed in" do
      before { sign_in @primary_mentor }

      it "destroys the subgroup" do
        expect do
          delete group_subgroup_path(@group, @subgroup)
        end.to change(Subgroup, :count).by(-1)
      end

      it "redirects to the group page" do
        delete group_subgroup_path(@group, @subgroup)
        expect(response).to redirect_to(group_path(@group))
      end
    end

    context "when a group member is signed in" do
      it "returns not authorized" do
        sign_in @member_user
        expect do
          delete group_subgroup_path(@group, @subgroup)
        end.not_to change(Subgroup, :count)
        check_not_authorized(response)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # ADD MEMBER
  # ---------------------------------------------------------------------------
  describe "#add_member" do
    before do
      @subgroup        = FactoryBot.create(:subgroup, group: @group)
      @other_member    = FactoryBot.create(:user)
      @other_gm        = FactoryBot.create(:group_member, group: @group, user: @other_member)
    end

    context "when primary mentor adds an eligible member" do
      before { sign_in @primary_mentor }

      it "adds the member to the subgroup" do
        expect do
          post add_member_group_subgroup_path(@group, @subgroup),
               params: { group_member_id: @other_gm.id }
        end.to change(SubgroupMember, :count).by(1)
      end
    end

    context "when primary mentor uses a group_member_id from a different group" do
      before do
        @foreign_group = FactoryBot.create(:group, primary_mentor: @primary_mentor)
        @foreign_gm = FactoryBot.create(:group_member,
                                         group: @foreign_group,
                                         user: FactoryBot.create(:user))
        sign_in @primary_mentor
      end

      it "redirects with an alert and does not add member" do
        expect do
          post add_member_group_subgroup_path(@group, @subgroup),
               params: { group_member_id: @foreign_gm.id }
        end.not_to change(SubgroupMember, :count)
      end
    end

    context "when a regular member tries to add" do
      it "returns not authorized" do
        sign_in @member_user
        post add_member_group_subgroup_path(@group, @subgroup),
             params: { group_member_id: @other_gm.id }
        check_not_authorized(response)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # REMOVE MEMBER
  # ---------------------------------------------------------------------------
  describe "#remove_member" do
    before do
      @subgroup = FactoryBot.create(:subgroup, group: @group)
      SubgroupMember.create!(subgroup: @subgroup, group_member: @group_member)
    end

    context "when primary mentor removes a member" do
      before { sign_in @primary_mentor }

      it "removes the member from the subgroup" do
        expect do
          delete remove_member_group_subgroup_path(@group, @subgroup),
                 params: { group_member_id: @group_member.id }
        end.to change(SubgroupMember, :count).by(-1)
      end
    end

    context "when a regular member tries to remove" do
      it "returns not authorized" do
        sign_in @member_user
        delete remove_member_group_subgroup_path(@group, @subgroup),
               params: { group_member_id: @group_member.id }
        check_not_authorized(response)
      end
    end
  end
end
