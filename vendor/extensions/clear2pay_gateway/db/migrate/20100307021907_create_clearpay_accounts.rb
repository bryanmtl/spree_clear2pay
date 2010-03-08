class CreateClearpayAccounts < ActiveRecord::Migration
  def self.up
    create_table :clearpay_accounts do |t|
      t.string :email
      t.string :payer_id
      t.string :payer_country
      t.string :payer_status
      t.timestamps
    end
  end

  def self.down
    drop_table :clearpay_accounts
  end
end
