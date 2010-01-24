class CreateGatewayClear2pays < ActiveRecord::Migration
  def self.up
    create_table :gateway_clear2pays do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :gateway_clear2pays
  end
end
