# frozen_string_literal: true

class SubgroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :set_subgroup, only: %i[show edit update destroy]
  before_action :check_admin_access, only: %i[new create edit update destroy]
  before_action :check_show_access, only: [:show]

  # GET /groups/:group_id/subgroups/:id
  def show
    @members_in_subgroup = @subgroup.group_members.includes(:user)
    @members_not_in_subgroup = @group.group_members.member
                                     .where.not(id: @subgroup.group_member_ids)
                                     .includes(:user)
  end

  # GET /groups/:group_id/subgroups/new
  def new
    @subgroup = @group.subgroups.new
  end

  # GET /groups/:group_id/subgroups/:id/edit
  def edit; end

  # POST /groups/:group_id/subgroups
  def create
    @subgroup = @group.subgroups.new(subgroup_params)

    if @subgroup.save
      redirect_to group_subgroup_path(@group, @subgroup),
                  notice: "Subgroup was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /groups/:group_id/subgroups/:id
  def update
    if @subgroup.update(subgroup_params)
      redirect_to group_subgroup_path(@group, @subgroup),
                  notice: "Subgroup was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /groups/:group_id/subgroups/:id
  def destroy
    @subgroup.destroy
    redirect_to group_path(@group),
                notice: "Subgroup was successfully deleted."
  end

  # POST /groups/:group_id/subgroups/:id/add_member
  def add_member
    @subgroup = @group.subgroups.find(params[:id])
    authorize @subgroup, :add_member?

    group_member = @group.group_members.member.joins(:user).find_by(users: { email: params[:email] })

    if group_member.nil?
      redirect_to group_subgroup_path(@group, @subgroup),
                  alert: "Member not found in this group."
      return
    end

    subgroup_member = @subgroup.subgroup_members.new(group_member: group_member)

    if subgroup_member.save
      redirect_to group_subgroup_path(@group, @subgroup),
                  notice: "#{group_member.user.name} was added to the subgroup."
    else
      redirect_to group_subgroup_path(@group, @subgroup),
                  alert: subgroup_member.errors.full_messages.to_sentence
    end
  end

  # DELETE /groups/:group_id/subgroups/:id/remove_member
  def remove_member
    @subgroup = @group.subgroups.find(params[:id])
    authorize @subgroup, :remove_member?

    group_member = @group.group_members.find_by(id: params[:group_member_id])

    if group_member.nil?
      redirect_to group_subgroup_path(@group, @subgroup),
                  alert: "Member not found in this group."
      return
    end

    subgroup_member = @subgroup.subgroup_members.find_by(group_member: group_member)

    if subgroup_member&.destroy
      redirect_to group_subgroup_path(@group, @subgroup),
                  notice: "#{group_member.user.name} was removed from the subgroup."
    else
      redirect_to group_subgroup_path(@group, @subgroup),
                  alert: "Member could not be removed."
    end
  end

  private

    def set_group
      @group = Group.find(params[:group_id])
    end

    def set_subgroup
      @subgroup = @group.subgroups.find(params[:id])
    end

    def subgroup_params
      params.expect(subgroup: [:name])
    end

    def check_admin_access
      authorize (@subgroup || @group.subgroups.new), :create?
    end

    def check_show_access
      authorize @subgroup, :show?
    end
end
