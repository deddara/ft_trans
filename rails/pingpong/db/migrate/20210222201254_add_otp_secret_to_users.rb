class AddOtpSecretToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_attempt, :string
    add_column :users, :otp_required, :boolean, default: false
    add_column :users, :last_otp_at, :integer
  end
end
