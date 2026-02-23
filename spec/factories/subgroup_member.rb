# frozen_string_literal: true

FactoryBot.define do
  factory :subgroup_member do
    association :subgroup
    association :group_member
  end
end
