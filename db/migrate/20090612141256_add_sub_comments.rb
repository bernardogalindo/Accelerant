class AddSubComments < ActiveRecord::Migration
  def self.up
    create_table :subcomments do |t|
      t.column :content,                   :text
      t.column :comment_id,                :integer
      t.column :user_id,                   :integer
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.timestamps
    end
  end

  def self.down
    drop_table :subcomments
  end
end
