module Spree::ClearPay
  include ERB::Util
  # include ActiveMerchant::RequiresParameters

  def clearpay_payment
    load_object
    
    @gateway = payment_method
    
  end
  
  def payment_success
    load_object
    @gateway = payment_method
    
    # record a payment
      
    fake_card = Creditcard.new :cc_type        => "visa",   # hands are tied
                               :month          => Time.now.month, 
                               :year           => Time.now.year, 
                               :first_name     => @order.bill_address.firstname, 
                               :last_name      => @order.bill_address.lastname,
                               :verification_value => 'clearpay',
                               :number => "clearpay"
                               
    payment = @order.checkout.payments.create(:amount => @order.total, 
                                           :source => fake_card,
                                           :payment_method_id => params[:payment_method_id])

    # query - need 0 in amount for an auth? see main code
    transaction = CreditcardTxn.new( :amount => @order.total,
                                     :response_code => 'success',
                                     :txn_type => CreditcardTxn::TxnType::PURCHASE)
    # payment.creditcard_txns << transaction  



    @order.save!
    @checkout.reload
    #need to force checkout to complete state
    until @checkout.state == "complete"
      @checkout.next!
    end
    complete_checkout
    payment.finalize!

  end


  def payment_failure
    load_object
    @gateway = payment_method
  end

  

  def paypal_finish
    load_object

    opts = { :token => params[:token], :payer_id => params[:PayerID] }.merge all_opts(@order, params[:payment_method_id], 'checkout' )
    gateway = paypal_gateway

    if Spree::Config[:auto_capture]
      ppx_auth_response = gateway.purchase((@order.total*100).to_i, opts)
      txn_type = PaypalTxn::TxnType::CAPTURE
    else
      ppx_auth_response = gateway.authorize((@order.total*100).to_i, opts)
      txn_type = PaypalTxn::TxnType::AUTHORIZE
    end

    if ppx_auth_response.success?
      paypal_account = PaypalAccount.find_by_payer_id(params[:PayerID])

      payment = @order.checkout.payments.create(:amount => ppx_auth_response.params["gross_amount"].to_f,
                                                :source => paypal_account,
                                                :payment_method_id => params[:payment_method_id])

      PaypalTxn.create(:payment => payment,
                       :txn_type => txn_type,
                       :amount => ppx_auth_response.params["gross_amount"].to_f,
                       :message => ppx_auth_response.params["message"],
                       :payment_status => ppx_auth_response.params["payment_status"],
                       :pending_reason => ppx_auth_response.params["pending_reason"],
                       :transaction_id => ppx_auth_response.params["transaction_id"],
                       :transaction_type => ppx_auth_response.params["transaction_type"],
                       :payment_type => ppx_auth_response.params["payment_type"],
                       :response_code => ppx_auth_response.params["ack"],
                       :token => ppx_auth_response.params["token"],
                       :avs_response => ppx_auth_response.avs_result["code"],
                       :cvv_response => ppx_auth_response.cvv_result["code"])


      @order.save!
      @checkout.reload
      #need to force checkout to complete state
      until @checkout.state == "complete"
        @checkout.next!
      end
      complete_checkout

      if Spree::Config[:auto_capture]
        payment.finalize!
      end

    else
      order_params = {}
      gateway_error(ppx_auth_response)
    end
  end

  private
  def fixed_opts
    if Spree::Config[:paypal_express_local_confirm].nil?
      user_action = "continue"
    else
      user_action = Spree::Config[:paypal_express_local_confirm] == "t" ? "continue" : "commit"
    end

    { :description             => "Goods from #{Spree::Config[:site_name]}", # site details...

      #:page_style             => "foobar", # merchant account can set named config
      :header_image            => "https://" + Spree::Config[:site_url] + "/images/logo.png",
      :background_color        => "ffffff",  # must be hex only, six chars
      :header_background_color => "ffffff",
      :header_border_color     => "ffffff",

      :allow_note              => true,
      :locale                  => Spree::Config[:default_locale],
      :notify_url              => 'to be done',                 # this is a callback, not tried it yet

      :req_confirm_shipping    => false,   # for security, might make an option later
      :user_action             => user_action

      # WARNING -- don't use :ship_discount, :insurance_offered, :insurance since
      # they've not been tested and may trigger some paypal bugs, eg not showing order
      # see http://www.pdncommunity.com/t5/PayPal-Developer-Blog/Displaying-Order-Details-in-Express-Checkout/bc-p/92902#C851
    }
  end
  
  


  

  # create the gateway from the supplied options
  def payment_method
    PaymentMethod.find(params[:payment_method_id])
  end

  def clearpay_gateway
    payment_method.provider
  end
  
  
end
