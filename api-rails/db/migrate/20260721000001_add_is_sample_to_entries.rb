class AddIsSampleToEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :is_sample, :boolean, default: false, null: false
  end
end
