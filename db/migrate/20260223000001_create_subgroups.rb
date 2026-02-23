# frozen_string_literal: true

class CreateSubgroups < ActiveRecord::Migration[8.0]
  def change
    create_table :subgroups do |t|
      t.string :name, null: false
      t.references :group, null: false, foreign_key: true, index: true

      t.timestamps
    end

    create_table :subgroup_members do |t|
      t.references :subgroup, null: false, foreign_key: true, index: true
      t.references :group_member, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :subgroup_members, %i[subgroup_id group_member_id], unique: true,
                                                                   name: "index_subgroup_members_uniqueness"
  end

  def down
    remove_index :subgroup_members, name: "index_subgroup_members_uniqueness"
    drop_table :subgroup_members
    drop_table :subgroups
  end
end
