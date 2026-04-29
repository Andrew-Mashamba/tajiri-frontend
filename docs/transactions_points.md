1) Transaction Entry Points (categorized)
Category	Entry point (file + function)	Exact service/API call	Direction
Business invoices
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/create_invoice_page.dart _save()
BusinessService.createInvoice -> POST /business/{bizId}/invoices (or /business/invoices)
Outgoing (issue receivable)
Business invoices
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/invoice_detail_page.dart payment dialog handler
BusinessService.recordInvoicePayment -> POST /business/invoices/{invoiceId}/payments
Incoming (collect money)
Business invoices
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/invoice_pay_page.dart _pay()
BusinessService.recordInvoicePayment -> POST /business/invoices/{invoiceId}/payments
Outgoing (payer view)
Business invoices
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/invoices_page.dart _markPaid()
BusinessService.markInvoicePaid -> POST /business/invoices/{invoiceId}/paid
Incoming confirmation
Credit notes
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/credit_note_page.dart submit handler
BusinessService.createCreditNote -> POST /business/invoices/{invoiceId}/credit-notes
Outgoing (reduce receivable/refund adjustment)
Recurring invoices
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/create_invoice_page.dart _save()
BusinessService.createRecurringInvoice -> POST /business/{businessId}/recurring-invoices
Outgoing schedule
Recurring invoices
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/invoices/pages/recurring_invoices_page.dart create flow
BusinessService.createRecurringInvoice -> POST /business/{businessId}/recurring-invoices
Outgoing schedule
VFD fiscalization
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/vfd/pages/vfd_receipts_page.dart _createAndFiscalize() / _submit()
BusinessService.createInvoice + BusinessService.issueFiscalReceipt -> POST /business/invoices/{invoiceId}/fiscal-receipt
Incoming confirmation + tax receipt
Debts
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/debts_page.dart add debt dialog handler
BusinessService.createDebt -> POST /business/debts
Incoming (AR creation)
Debts
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/debts_page.dart debt pay handler
BusinessService.recordDebtPayment -> POST /business/debts/{debtId}/pay
Incoming (collection)
Expenses
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/add_expense_page.dart _save()
BusinessService.addExpense -> POST /business/{businessId}/expenses
Outgoing
Purchase orders
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/purchase_orders_page.dart PO create dialog
BusinessService.createPurchaseOrder -> POST /business/{businessId}/purchase-orders
Outgoing commitment
Payroll
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/payroll_page.dart _calculateViaApi()
BusinessService.calculatePayroll -> POST /business/{businessId}/payroll/calculate
Outgoing preparation
Payroll
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/payroll_page.dart _approvePayroll()
BusinessService.approvePayroll -> POST /business/payroll/{payrollId}/approve
Outgoing confirmation
Category	Entry point (file + function)	Exact service/API call	Direction
Wallet deposit/topup
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/my_wallet/pages/deposit_page.dart _submit()
WalletService.deposit -> POST /wallet/{userId}/deposit
Incoming
Wallet withdrawal
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/my_wallet/pages/withdraw_page.dart _submit()
WalletService.withdraw -> POST /wallet/{userId}/withdraw
Outgoing
Wallet transfer
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/my_wallet/pages/transfer_page.dart _submit()
WalletService.transfer -> POST /wallet/{userId}/transfer
Outgoing
Wallet payment requests (pay)
Service exists; UI buttons still TODO in payment_requests_page.dart
WalletService.payRequest -> POST /wallet/payment-requests/{requestId}/pay
Outgoing
Wallet payment requests (create)
Service exists; no active UI invocation found in scan
WalletService.createPaymentRequest -> POST /wallet/payment-requests
Incoming (request receivable)
Creator subscription
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/wallet/subscribe_to_creator_screen.dart _subscribe()
SubscriptionService.subscribe -> POST /subscriptions/subscribe
Outgoing
Creator tips
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/wallet/send_tip_screen.dart _sendTip()
SubscriptionService.sendTip -> POST /subscriptions/tips
Outgoing
Creator payout request
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/wallet/payout_request_screen.dart _submitRequest()
SubscriptionService.requestPayout -> POST /subscriptions/payouts
Incoming (cash-out to creator)
Subscription cancel
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/wallet/subscription_detail_screen.dart cancel handler
SubscriptionService.cancelSubscription -> POST /subscriptions/{id}/cancel
Outgoing stop
Category	Entry point (file + function)	Exact service/API call	Direction
Shop single order
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/shop/checkout_screen.dart _processMpesaPayment() / _processPayment()
ShopService.createOrder -> POST /shop/orders
Outgoing
Shop cart checkout
same file/functions
ShopService.checkout -> POST /shop/checkout
Outgoing
Shop add cart intent
/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/shop/shop_screen.dart _onAddToCart() and product_detail_page.dart _addToCart()
ShopService.addToCart -> POST /shop/cart/items
Pre-transaction
Shop seller fulfillment
/Volumes/.../lib/screens/shop/seller_orders_screen.dart _confirmOrder() / _shipOrder() / _bulkUpdateStatus()
ShopService.updateOrderStatus -> POST /shop/orders/{orderId}/status
Incoming confirmation/settlement stage
Shop cancel
same + order_detail_screen.dart _cancelOrder()
ShopService.cancelOrder -> POST /shop/orders/{orderId}/cancel
Reversal
Shop return/refund request
/Volumes/.../lib/screens/shop/order_detail_screen.dart _showReturnDialog()
ShopService.requestReturn -> POST /shop/orders/{orderId}/return
Reversal flow
Food checkout
/Volumes/.../lib/food/pages/cart_page.dart _placeOrder()
FoodService.placeOrder -> POST /food/orders
Outgoing
Pharmacy checkout
/Volumes/.../lib/pharmacy/pages/cart_page.dart _placeOrder()
PharmacyService.placeOrder -> POST /pharmacy/orders
Outgoing
Fuel delivery order
/Volumes/.../lib/fuel_delivery/pages/order_fuel_page.dart _placeOrder()
FuelDeliveryService.placeOrder -> POST /fuel-delivery/orders
Outgoing
Spare-parts order API (dormant UI in scan)
service only
SparePartsService.createOrder -> POST /spare-parts/orders
Outgoing
Category	Entry point (file + function)	Exact service/API call	Direction
Campaign donation (Michango)
/Volumes/.../lib/screens/campaigns/donate_to_campaign_screen.dart _performDonate()
ContributionService.donateToCampaign -> POST /campaigns/{id}/donate
Outgoing
Campaign withdrawal
/Volumes/.../lib/screens/campaigns/campaign_withdraw_screen.dart _submitWithdrawal()
ContributionService.requestWithdrawal -> POST /campaigns/{id}/withdrawals
Incoming (cash-out)
Event Michango manual cash record
/Volumes/.../lib/events/pages/contribution_dashboard_page.dart _showRecordDialog()
EventContributionService.recordContribution -> POST /events/{eventId}/michango
Incoming confirmation/manual
Event Michango pledge payment
service method (no direct UI hit in scan)
EventContributionService.recordPayment -> POST /michango/{contributionId}/pay
Incoming
Category	Entry point (file + function)	Exact service/API call	Direction
TANESCO token purchase
/Volumes/.../lib/tanesco/pages/buy_tokens_page.dart _buy()
TanescoService.buyTokens -> POST /tanesco/tokens
Outgoing
TANESCO bill pay
/Volumes/.../lib/tanesco/pages/bills_page.dart pay action in bill tile
TanescoService.payBill -> POST /tanesco/bills/{billId}/pay
Outgoing
DAWASCO bill pay
/Volumes/.../lib/dawasco/pages/pay_bill_page.dart _pay()
DawascoService.payBill -> POST /dawasco/bills/{billId}/pay
Outgoing
NHIF premium
/Volumes/.../lib/nhif/pages/pay_premium_page.dart _pay()
NhifService.payPremium -> POST /nhif/payments
Outgoing
NSSF voluntary payment (service available)
no direct page trigger found
NssfService.payVoluntary -> POST /nssf/payments
Outgoing
Insurance purchase
/Volumes/.../lib/insurance/pages/product_detail_page.dart _purchase()
InsuranceService.purchasePolicy -> POST /insurance/purchase
Outgoing
Car insurance quote purchase
/Volumes/.../lib/car_insurance/pages/get_quotes_page.dart quote buy handler
CarInsuranceService.purchasePolicy (API in service)
Outgoing
Category	Entry point (file + function)	Exact service/API call	Direction
Event organizer payout
/Volumes/.../lib/events/pages/organizer/payout_page.dart _requestPayout()
EventOrganizerService.requestPayout -> POST /events/{eventId}/payout
Incoming (cash-out)
Tajirika partner payout
/Volumes/.../lib/tajirika/pages/earnings_overview_page.dart withdraw dialog flow
TajirikaService.requestPayout -> POST /tajirika/payouts
Incoming (cash-out)
Ad balance top-up
/Volumes/.../lib/screens/biashara/deposit_ad_balance_screen.dart submit handler
AdService.depositAdBalance -> POST /biashara/balance/deposit
Outgoing
Category	Entry point (file + function)	Exact service/API call	Direction
Kikoba loan/top-up
/Volumes/.../lib/kikoba/selectPaymentMethod.dart payment submit
HttpService.topuploanPaymentIntentMNO -> POST {baseUrl}loan
Outgoing
Kikoba loan request
/Volumes/.../lib/kikoba/loanRequest.dart request flow
HttpService.loanRequestHttp -> POST {baseUrl}loan
Incoming (disbursement requested)
Kikoba topup request
/Volumes/.../lib/kikoba/loanRequest.dart topup flow
HttpService.topupRequestHttp -> POST {baseUrl}loan
Outgoing
Kikoba expense request
/Volumes/.../lib/kikoba/pages/UongoziPage.dart approval flow
HttpService.createExpenseRequest -> POST /expense-requests
Outgoing
Kikoba mark expense paid
service method available
HttpService.markExpensePaid -> POST /expense-requests/{requestId}/pay
Outgoing confirmation
Kikoba akiba withdrawal
/Volumes/.../lib/kikoba/AkibaTable.dart withdraw request flow
HttpService.createAkibaWithdrawalRequest -> wraps POST /api/akiba/withdrawal
Incoming (cash-out)
Kikoba guarantee withdrawal
/Volumes/.../lib/kikoba/pages/UdhaminiWaMikopo.dart action
LoanService.withdrawGuarantee -> HttpService.withdrawGuarantee -> POST /loan-applications/{id}/withdraw-guarantee
Reversal/uncommit
2) Centralized recorder hook (before + after backend call)
Recommended single pattern to cover http + dio + legacy static services:

Create one recorder contract, e.g. MoneyTxnRecorder.before(requestCtx) and MoneyTxnRecorder.after(resultCtx).
Wrap all money-moving calls with one helper:
recordedCall(ctx, () async => serviceCall())
ctx fields: module, action, direction, amount, currency, entityId, userId, idempotencyKey.
before hook:
Generate tx_trace_id
Persist status=pending, request metadata, timestamp
Attach trace id header (X-Txn-Trace-Id) where possible.
after hook:
On success: persist status=success, backend reference (payment_id, order_id, etc), latency.
On failure: persist status=failed, error code/message, retryable flag.
Hook points in this repo:
http calls: wrap inside each service method (WalletService, BusinessService, SubscriptionService, ShopService, etc.).
dio calls: add global interceptor in AuthenticatedDio.instance to auto-fire before/after for matched endpoints.
Legacy Kikoba HttpService: wrap high-risk methods first (loan, expense-requests/*/pay, akiba/withdrawal, withdraw-guarantee).
Minimal classification map to auto-detect direction:

Outgoing: depositAdBalance, withdraw, transfer, checkout, createOrder, payBill, payPremium, buyTokens, purchasePolicy, donate, subscribe, sendTip, addExpense.
Incoming: recordInvoicePayment, recordDebtPayment, requestPayout, campaign withdrawal, tajirika payout, event payout, wallet deposit.
Reversal/adjustment: cancelOrder, requestReturn, createCreditNote, withdrawGuarantee, subscription cancel.
3) Important gaps found during scan
WalletService.createPaymentRequest/payRequest/declineRequest exist, but payment_requests_page.dart pay/decline buttons are still TODO (no live trigger).
NssfService.payVoluntary exists but no clear page entrypoint in current UI scan.
PaymentService.requestPayout exists but active trigger not found; newer flows use SubscriptionService.requestPayout / TajirikaService.requestPayout / EventOrganizerService.requestPayout.
Kikoba money flows are split between LoanService and very large legacy HttpService.dart; central recorder should prioritize this file early.