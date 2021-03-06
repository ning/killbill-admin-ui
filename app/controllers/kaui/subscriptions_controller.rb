require 'kaui/product'

class Kaui::SubscriptionsController < Kaui::EngineController
  def index
    if params[:subscription_id].present?
      redirect_to kaui_engine.subscription_path(params[:subscription_id])
    end
  end

  def show
    begin
      @subscription = Kaui::KillbillHelper.get_subscription(params[:id])
      unless @subscription.present?
        flash[:error] = "No subscription id given or subscription not found"
        redirect_to :back
      end

      @account = Kaui::KillbillHelper::get_account_by_bundle_id(@subscription.bundle_id)
      unless @account.present?
        flash[:error] = "Unable to retrieve account for bundle #{@subscription.bundle_id}"
        redirect_to :back
      end
    rescue => e
      flash[:error] = "Error while getting subscription information: #{as_string(e)}"
    end
  end

  def new
    bundle_id = params[:bundle_id]
    @base_subscription = params[:base_subscription]
    begin
      @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)

      if @base_subscription.present?
        @catalog = Kaui::KillbillHelper::get_available_addons(@base_subscription)
      else
        @catalog = Kaui::KillbillHelper::get_available_base_plans()
      end
    rescue => e
      flash[:error] = "Error while trying to start new subscription creation: #{as_string(e)}"
    end
    @subscription = Kaui::Subscription.new("bundleId" => bundle_id)
  end

  def create
    @base_subscription = params[:base_subscription]
    @plan_name = params[:plan_name]

    begin
      @subscription = Kaui::Subscription.new(params[:subscription])
      @bundle = Kaui::KillbillHelper::get_bundle(@subscription.bundle_id)
      if @base_subscription.present?
        @catalog = Kaui::KillbillHelper::get_available_addons(@base_subscription)
        @subscription.product_category = "ADD_ON"
      else
        @catalog = Kaui::KillbillHelper::get_available_base_plans()
        @subscription.product_category = "BASE"
      end

      plan = @catalog[@plan_name]
      @subscription.billing_period = plan["billingPeriod"]
      @subscription.product_name = plan["productName"]
      @subscription.price_list = plan["priceListName"]

      Kaui::KillbillHelper::create_subscription(@subscription, current_user)
      redirect_to Kaui.bundle_home_path.call(@bundle.bundle_id)
    rescue => e
      flash[:error] = "Error while creating the new subscription: #{as_string(e)}"
      render :new
    end
  end

  def add_addon
    @base_product_name = params[:base_product_name]

    @bundle_id = params[:bundle_id]
    @product_name = params[:product_name]
    @product_category = params[:product_category]
    @billing_period = params[:billing_period]
    @price_list = params[:price_list]

    begin
      @subscription = Kaui::Subscription.new(:bundle_id => @bundle_id,
                                             :product_name => @product_name,
                                             :product_category => @product_category,
                                             :billing_period => @billing_period,
                                             :price_list => @price_list)

      @bundle = Kaui::KillbillHelper.get_bundle(subscription.bundle_id)
      @available_plans = Kaui::KillbillHelper.get_available_addons(params[:base_product_name])
    rescue => e
      flash[:error] = "Error while adding an addon: #{as_string(e)}"
    end
  end

  def edit
    begin
      @subscription = Kaui::KillbillHelper.get_subscription(params[:id])

      if @subscription.present?
        @bundle = Kaui::KillbillHelper::get_bundle(@subscription.bundle_id)
        @account = Kaui::KillbillHelper::get_account(@bundle.account_id)
        @catalog = Kaui::KillbillHelper::get_available_base_plans

        @current_plan = "#{@subscription.product_name} #{@subscription.billing_period}".humanize

        if @subscription.price_list != "DEFAULT"
          @current_plan += " (price list #{@subscription.price_list})"
        end
      else
        flash[:error] = "No subscription id given or subscription not found"
        redirect_to :back
      end
    rescue => e
      flash[:error] = "Error while editing subscription: #{as_string(e)}"
    end
  end

  def update
    if params.has_key?(:subscription) && params[:subscription].has_key?(:subscription_id)

      begin
        subscription = Kaui::KillbillHelper::get_subscription(params[:subscription][:subscription_id])
        bundle = Kaui::KillbillHelper::get_bundle(subscription.bundle_id)
        catalog = Kaui::KillbillHelper::get_available_base_plans

        plan = catalog[params[:plan_name]]
        requested_date = params[:requested_date]
        policy = params[:policy]

        subscription.billing_period = plan["billingPeriod"]
        subscription.product_category = plan["productCategory"]
        subscription.product_name = plan["productName"]
        subscription.price_list = plan["priceListName"]
        subscription.subscription_id = params[:subscription][:subscription_id]

        Kaui::KillbillHelper::update_subscription(subscription, requested_date, policy, current_user)
      rescue => e
        flash[:error] = "Error while updating subscription: #{as_string(e)}"
      end
    else
      flash[:error] = "No subscription given"
    end
    redirect_to Kaui.bundle_home_path.call(bundle.bundle_id)
  end

  def reinstate
    subscription_id = params[:id]
    if subscription_id.present?
      begin
        Kaui::KillbillHelper::reinstate_subscription(subscription_id, current_user)
        flash[:info] = "Subscription reinstated"
      rescue => e
        flash[:error] = "Error while reinstating subscription: #{as_string(e)}"
      end
    else
      flash[:error] = "No subscription id given"
    end
    redirect_to :back
  end

  def destroy
    subscription_id = params[:id]
    if subscription_id.present?
      begin
        Kaui::KillbillHelper::delete_subscription(subscription_id, params[:policy], params[:ctd], params[:billing_period], current_user)
      rescue => e
        flash[:error] = "Error while canceling subscription: #{as_string(e)}"
      end
    else
      flash[:error] = "No subscription id given"
    end
    redirect_to :back
  end
end