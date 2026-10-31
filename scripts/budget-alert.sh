#!/usr/bin/env bash
set -euo pipefail   # stop on errors, unset vars, and failed pipes

EMAIL="${1:?Usage: ./budget-alert.sh you@example.com}"
LIMIT="6"           # USD/month (~€5)
NAME="budget5euro"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Make the script safe to run twice (idempotent)
if aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name "$NAME" >/dev/null 2>&1; then
  echo "Budget '$NAME' already exists. Nothing to do."
  exit 0
fi

aws budgets create-budget \
  --account-id "$ACCOUNT_ID" \
  --budget "{\"BudgetName\":\"$NAME\",\"BudgetLimit\":{\"Amount\":\"$LIMIT\",\"Unit\":\"USD\"},\"TimeUnit\":\"MONTHLY\",\"BudgetType\":\"COST\"}" \
  --notifications-with-subscribers "[
    {\"Notification\":{\"NotificationType\":\"ACTUAL\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":50,\"ThresholdType\":\"PERCENTAGE\"},
     \"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"$EMAIL\"}]},
    {\"Notification\":{\"NotificationType\":\"FORECASTED\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":100,\"ThresholdType\":\"PERCENTAGE\"},
     \"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"$EMAIL\"}]}
  ]"

echo "✅ Budget created: alerts at 50% actual and 100% forecast of \$$LIMIT."
