var posTransactionTimer = 0;
var formPayment = 0;
var posTransactionSucceeded = 0;

function callSvcApi(data, callbacks) {
    $.post('/cgi-bin/koha/svc/pos_terminal', data, function( response ) {
        if (callbacks.success) {
            callbacks.success(response);
        }
    })
        .fail(function(response) {
            if (callbacks.fail) {
                callbacks.fail(response);
            }
        })
        .always(function(response) {
            if (callbacks.always) {
                callbacks.always(response);
            }
        });
}

function showMessage(status) {
    var msg = "";

    if (status == "new") {
        msg = MSG_POS_IN_PROGRESS;
    }
    else if (status == "success") {
        msg = MSG_POS_SUCESS;
    }
    else if (status == "init") {
        msg = MSG_POS_INIT;
    }
    else if (status == "request-payment") {
        msg = MSG_POS_REQUEST_PAYMENT;
    }
    else if (status == "request-refund") {
        msg = MSG_POS_REQUEST_REFUND;
    }
    else if (status == "sent-request") {
        msg = MSG_POS_SENT_REQUEST;
    }
    else if (status == "received-message") {
        msg = MSG_POS_RECEIVED_MESSAGE;
    }
    else if (status == "received-response") {
        msg = MSG_POS_RECEIVED_RESPONSE;
    }
    else if (status == "sent-confirmation") {
        msg = MSG_POS_SENT_CONFIRMATION;
    }
    else if (status == "activity-message") {
        msg = MSG_POS_ACTIVITY_MESSAGE;
    }
    else if (status == "disconnected") {
        msg = MSG_POS_DISCONNECTED;
    }
    else if (status == "connection-error") {
        msg = "Connection error.";
    }
    else if (status == "ERR_TRANSACTION_REJECTED") {
        msg = MSG_POS_ERR_TRANSACTION_REJECTED;
    }
    else if (status == "ERR_REQUEST_REJECTED") {
        msg = MSG_POS_ERR_REQUEST_REJECTED;
    }
    else if (status == "ERR_CONNECTION_FAILED") {
        msg = MSG_POS_ERR_CONNECTION_FAILED;
    }
    else if (status.lastIndexOf("ERR_") === 0) {
        msg = MSG_POS_ERR + " " + status + ". " + MSG_POS_ERR_CONNECTION_ABORTED;
    }
    else if (status == "expired") {
        msg = MSG_POS_ERR_EXPIRED
    }
    else {
        msg = status;
    }

    $("#card_payment_dialog .transaction-message").text(msg);
}

function checkStatus(transaction_id) {
    callSvcApi(
        {transaction_id: transaction_id, action: "status"},
        {
            success: function(xml) {
                var status = $(xml).find('status').first().text();
                showMessage(status);
                if ((status.lastIndexOf("ERR_") === 0) || (status == "success") || (status == "expired")) {
                    formPayment = (status == "success") ? formPayment : 0;
                    posTransactionSucceeded = (status == "success");
                    $("#card_payment_dialog button").prop("disabled", false);
                }
                else {
                    posTransactionTimer = setTimeout(function() { checkStatus(transaction_id); }, 5000);
                }
            }
        }
    );
}

// ---------------- payments
function requestPayment(transaction_id) {
    showMessage("request-payment");
    callSvcApi(
        {
            transaction_id: transaction_id,
            action: "request-payment",
            paid: parseInt($('#paid').val())
        },
        { }
    );
}

function startPaymentTransaction(accountlines_id) {
    showMessage('init');
    $("#card_payment_dialog button").click(closePaymentTransaction);
    $("#card_payment_dialog button").prop("disabled", true);
    $("#card_payment_dialog").modal({
        backdrop: 'static',
        keyboard: false
    });
    callSvcApi(
        {accountlines_id: accountlines_id},
        {
            success: function(xml) {
                var transaction_id = $(xml).find('transaction_id').first().text();
                posTransactionTimer = setTimeout(function() { checkStatus(transaction_id); }, 5000);
                requestPayment(transaction_id);
            },
            fail: function(xml) { alert(MSG_POS_ERR + " " + $(xml).find('status').first().text()); },
        }
    );
}

function closePaymentTransaction() {
    clearTimeout(posTransactionTimer);
    if (formPayment && posTransactionSucceeded) {
        formPayment.submit();
    }
    else {
        $("body, form input[type='submit'], form button[type='submit'], form a").removeClass('waiting');
    }
}

function makePayment(form) {
    if ($("#bycard").is(':checked')) {
        formPayment = form;
        startPaymentTransaction($("#accountlines_id").val())
    }
    else {
        formPayment = 0;
        form.submit();
    }

    return false;   // always return false not to submit the form automatically
}

// ---------------- refund
function refundPayment(href, accountlines_id, amount) {
    showMessage('init');
    $("#card_payment_dialog button").click((function() { closeRefundTransaction(href); }));
    $("#card_payment_dialog button").prop("disabled", true);
    $("#card_payment_dialog").modal({
        backdrop: 'static',
        keyboard: false
    });
    callSvcApi(
        {accountlines_id: accountlines_id},
        {
            success: function(xml) {
                var transaction_id = $(xml).find('transaction_id').first().text();
                $("#card_payment_dialog button").click((function() { closeRefundTransaction(href, transaction_id); }));
                posTransactionTimer = setTimeout(function() { checkStatus(transaction_id); }, 5000);
                requestRefund(transaction_id, amount);
            },
            fail: function(xml) { alert(MSG_POS_ERR + " " + $(xml).find('status').first().text()); },
        }
    );
}

function requestRefund(transaction_id, amount) {
    showMessage("request-refund");
    callSvcApi(
        {
            transaction_id: transaction_id,
            action: "request-refund",
            paid: amount
        },
        { }
    );
}

function closeRefundTransaction(href, transaction_id) {
    clearTimeout(posTransactionTimer);
    if (posTransactionSucceeded) {
        window.location.href = href;
    }
    else {
        $("body, form input[type='submit'], form button[type='submit'], form a").removeClass('waiting');
    }
    posTransactionSucceeded = 0;
}
