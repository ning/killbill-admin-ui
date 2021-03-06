require 'active_model'

class Kaui::Invoice < Kaui::Base
  define_attr :amount
  define_attr :balance
  define_attr :invoice_id
  define_attr :account_id
  define_attr :invoice_number
  define_attr :payment_amount
  define_attr :refund_adjustment
  define_attr :credit_balance_adjustment
  define_attr :credit_adjustment
  define_attr :invoice_date
  define_attr :payment_dt
  define_attr :target_date
  define_attr :bundle_keys

  has_many :items, Kaui::InvoiceItem
  has_many :audit_logs, Kaui::AuditLog

  def initialize(data = {})
    super(:account_id => data['accountId'],
          :amount => data['amount'],
          :balance => data['balance'],
          :credit_balance_adjustment => data['cba'],
          :credit_adjustment => data['creditAdj'],
          :invoice_date => data['invoiceDate'],
          :invoice_id => data['invoiceId'],
          :invoice_number => data['invoiceNumber'],
          :refund_adjustment => data['refundAdj'],
          :target_date => data['targetDate'],
          :items => data['items'] || [],
          :bundle_keys => data['bundleKeys'],
          :audit_logs => data['auditLogs'])
  end

  # TODO - fix invoice json to return the currency

  def amount_to_money(currency)
    Kaui::Base.to_money(amount, currency)
  end

  def balance_to_money(currency)
    Kaui::Base.to_money(balance, currency)
  end

  def payment_amount_to_money(currency)
    Kaui::Base.to_money(payment_amount, currency)
  end

  def refund_adjustment_to_money(currency)
    Kaui::Base.to_money(refund_adjustment, currency)
  end

  def credit_balance_adjustment_to_money(currency)
    Kaui::Base.to_money(credit_balance_adjustment, currency)
  end

  def credit_adjustment_to_money(currency)
    Kaui::Base.to_money(credit_adjustment, currency)
  end
end