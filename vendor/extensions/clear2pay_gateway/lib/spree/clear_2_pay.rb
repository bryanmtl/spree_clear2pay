module Spree::Clear2Pay
  # include ActiveMerchant::Billing
  
  
  def clearpay
       load_object
       # setup_response = clear2pay_gateway.setup_purchase(@order.total*100,
       #            :ip                => request.remote_ip,
       #            :return_url        => url_for(:action => 'confirm', :id => @order, :only_path => false),
       #            :cancel_return_url => url_for(:action => 'edit', :id => @order, :only_path => false)
       #          )
       #          redirect_to clear2pay_gateway.redirect_url_for(setup_response.token)
     end
     
     
     def confirm
       redirect_to edit_order_url(@order) unless params[:token]
       details_response = clear2pay_gateway.details_for(params[:token])
       
       #build the address
       @address = details_response.address
       @user = current_user ||= User.create(:email => details_response.email)
       @ship_address = Address.new
       begin
         @ship_address.firstname, @ship_address.lastname = @address['name'].split(' ')
       rescue
         @ship_address.firstname = @address['name']
         @ship_address.lastname = @address['name']
       end
       @ship_address.address1 = @address['address1']
       @ship_address.address2 = @address['address2']
       @ship_address.city = @address['city']
       @ship_address.country = Country.find_by_iso(@address['country']) rescue nil
       @ship_address.phone = 'not available'
       @ship_address.zipcode = @address['zip']
       @ship_address.state = State.find(:first, :conditions => ['name = ? or abbr = ?', @address['state'], @address['state']])
       @ship_address.state_name = @address['state']
       @ship_address.save
       @order.checkout.bill_address = @ship_address
       @order.checkout.shipment.address = @ship_address
       # or current user
       @order.checkout.email = details_response.email
       @order.checkout.ip_address = request.env['REMOTE_ADDR']
       @order.checkout.save
       
       #shipping rates
       
       fake_shipment = Shipment.new :order => @order, :address => @order.ship_address
       @rates = @order.shipping_methods.collect do |ship_method|
         this_rate =  ship_method.calculate_cost(fake_shipment)
         { :id   => ship_method.id, 
           :name => ship_method.name, 
           :rate_as_integer => this_rate,
           :rate => (this_rate) }
       end
       
        @rates =  @rates.sort_by { |rate| rate[:rate_as_integer] }
    
        return @rates
          
       
       if !details_response.success?
         @message = details_response.message
         render :action => 'error'
         return
       end
       
       
     end
     
     
     def complete
       
       @order = Order.find_by_number(params[:id])
       @order.checkout.shipment.shipping_method_id = params[:method_id]
       # @order.checkout.update_charges
       #     @order.update_totals
       @order.checkout.save
       @order.save
       # debugger
       
       
       purchase = clear2pay_gateway.purchase((@order.total*100),
         :ip       => request.remote_ip,
         :payer_id => params[:payer_id],
         :token    => params[:token],
         :currency => Spree::Config[:paypal_express_currency] || 'USD'
       )
       
       if !purchase.success?
         @message = "We're sorry, your order couldn't be processed. Please make sure you have the necessary funding options within your paypal account."
         # session[:order_id] = nil
         render :action => 'error'
         return
         
       else
       
       
       
       @order.completed_at = Time.now
       
       
    
       
       
       # record a payment
       
       
       fake_card = Creditcard.new :checkout       => @order.checkout, 
                                  :cc_type        => "visa",   # hands are tied
                                  :month          => Time.now.month, 
                                  :year           => Time.now.year, 
                                  :first_name     => @order.ship_address.firstname, 
                                  :last_name      => @order.ship_address.lastname,
                                  :display_number => "paypal:" + params[:payer_id]
       payment = @order.paypal_payments.create(:amount => @order.total, 
                                              :creditcard => fake_card)
    
       # query - need 0 in amount for an auth? see main code
       transaction = CreditcardTxn.new( :amount => @order.total,
                                        :response_code => purchase.authorization,
                                        :txn_type => CreditcardTxn::TxnType::AUTHORIZE)
       payment.creditcard_txns << transaction
    
       #@order.save!
       @order.user = current_user if current_user
       @order.complete  # get return of status? throw of problems??? else weak go-ahead
    
       
       @order.state_events.create(:name => t('paypal_pay'), :user => current_user, :previous_state => @order.state)
       @order.update_attribute(:state, 'paid')
       
       session[:order_id] = nil
       
       
       end
    
       
     end
   
  
  
  private
  def clear2pay_gateway
    @gateway ||= Gateway.find_by_name_and_environment('Clear2Pay', RAILS_ENV)
  end
  
  
end
