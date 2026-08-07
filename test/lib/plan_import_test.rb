require "test_helper"
require "plan_import"

class PlanImportTest < ActiveSupport::TestCase
  test "creates a plan per valid row" do
    csv = <<~CSV
      名前,月額料金,表示優先度,表示順
      プレミアムプラン,50000,2,1
    CSV

    result = PlanImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_empty result.error_rows
    plan = Plan.find_by(name: "プレミアムプラン")
    assert_equal 50000, plan.monthly_fee
    assert_equal 2, plan.priority_weight
  end

  test "skips rows missing a required field and reports the line number" do
    csv = <<~CSV
      名前,月額料金,表示優先度,表示順
      ,50000,2,1
      正常プラン,30000,1,2
    CSV

    result = PlanImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_equal 1, result.error_rows.size
    assert_equal 2, result.error_rows.first[:line]
    assert Plan.exists?(name: "正常プラン")
  end

  test "exports plans as a CSV that round-trips through the importer" do
    plan = Plan.create!(name: "プレミアムプラン", monthly_fee: 50000, priority_weight: 2, position: 1)

    csv = PlanImport.export(Plan.where(id: plan.id))

    rows = CSV.parse(csv, headers: true)
    assert_equal ["プレミアムプラン", "50000", "2", "1"], rows.first.fields
  end
end
