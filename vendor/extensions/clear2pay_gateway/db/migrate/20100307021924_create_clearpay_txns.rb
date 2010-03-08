class CreateClearpayTxns < ActiveRecord::Migration
  def self.up
    add_column :transactions, :payment_status, :string
    add_column :transactions, :message, :string
    add_column :transactions, :pending_reason, :string
    add_column :transactions, :transaction_id, :string
    add_column :transactions, :transaction_type, :string
    add_column :transactions, :payment_type, :string
    add_column :transactions, :token, :string
  end

  def self.down
    remove_column :transactions, :payment_status
    remove_column :transactions, :message
    remove_column :transactions, :pending_reason
    remove_column :transactions, :transaction_id
    remove_column :transactions, :transaction_type
    remove_column :transactions, :payment_type
    remove_column :transactions, :token
  end
end
