class BillingIntegration::ClearPay < BillingIntegration
  
  preference :cpid, :string
	# preference :password, :password
	preference :url, :string
	preference :currency_code, :string
	preference :redirect_success, :string
	preference :redirect_fail, :string


end