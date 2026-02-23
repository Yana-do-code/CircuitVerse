# frozen_string_literal: true

FactoryBot.define do
  factory :subgroup do
    sequence(:name) { |n| "Subgroup #{n}" }
    association :group
  end
end
