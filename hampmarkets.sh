#!/bin/bash

# Function to display the asset data in a table format
display_asset() {
  printf "%-10s %-20s %-20s %-20s %-20s %-20s\n" "$1" "$2" "$3" "$4" "$5" "$6"
}

# Function to retrieve and display asset data
display_data() {
  # Retrieve the JSON data from the REST endpoint
  json_data=$(curl -s "https://api.hampterfi.com/marketdata")

  # Clear the screen
  clear

  # Display the table header
  printf "%-10s %-20s %-20s %-20s %-20s %-20s\n" "Asset" "Pyth Price" "EMA Trend" "Momentum 5min" "24h % Change" "7d % Change"
  printf "%-10s %-20s %-20s %-20s %-20s %-20s\n" "----------" "--------------------" "--------------------" "--------------------" "--------------------" "--------------------"

  # Display all assets by default
  if [ -z "$selected_assets" ]; then
    # Loop through each asset in the JSON data
    while IFS= read -r line; do
      asset=$(echo "$line" | sed 's/.*"asset":"\([^"]*\)".*/\1/')
      pyth_price=$(echo "$line" | sed 's/.*"pyth_price":\([^,]*\).*/\1/')
      pyth_ema_trend=$(echo "$line" | sed 's/.*"pyth_ema_trend":\([^,]*\).*/\1/')
      std_dev_5min=$(echo "$line" | sed 's/.*"std_dev_5min":\([^,]*\).*/\1/')
      close_24_hours=$(echo "$line" | sed 's/.*"close_24_hours":\([^,]*\).*/\1/')
      avg_close_7_days=$(echo "$line" | sed 's/.*"avg_close_7_days":\([^,]*\).*/\1/')

      percent_change_24h=$(awk "BEGIN {printf \"%.2f\", (($pyth_price - $close_24_hours) / $close_24_hours) * 100}")
      percent_change_7d=$(awk "BEGIN {printf \"%.2f\", (($pyth_price - $avg_close_7_days) / $avg_close_7_days) * 100}")

      display_asset "$asset" "$pyth_price" "$pyth_ema_trend" "$std_dev_5min" "$percent_change_24h%" "$percent_change_7d%"
    done <<< "$(echo "$json_data" | sed 's/\[{/\n{/g' | sed 's/},{/}\n{/g')"

  else
    # Display selected assets
    # Loop through each selected asset
    for asset in $selected_assets; do
      # Check if the asset exists in the JSON data
      if echo "$json_data" | grep -q "\"asset\":\"$asset\""; then
        line=$(echo "$json_data" | sed 's/\[{/\n{/g' | sed 's/},{/}\n{/g' | grep "\"asset\":\"$asset\"")
        pyth_price=$(echo "$line" | sed 's/.*"pyth_price":\([^,]*\).*/\1/')
        pyth_ema_trend=$(echo "$line" | sed 's/.*"pyth_ema_trend":\([^,]*\).*/\1/')
        std_dev_5min=$(echo "$line" | sed 's/.*"std_dev_5min":\([^,]*\).*/\1/')
        close_24_hours=$(echo "$line" | sed 's/.*"close_24_hours":\([^,]*\).*/\1/')
        avg_close_7_days=$(echo "$line" | sed 's/.*"avg_close_7_days":\([^,]*\).*/\1/')

        percent_change_24h=$(awk "BEGIN {printf \"%.2f\", (($pyth_price - $close_24_hours) / $close_24_hours) * 100}")
        percent_change_7d=$(awk "BEGIN {printf \"%.2f\", (($pyth_price - $avg_close_7_days) / $avg_close_7_days) * 100}")

        display_asset "$asset" "$pyth_price" "$pyth_ema_trend" "$std_dev_5min" "$percent_change_24h%" "$percent_change_7d%"
      else
        echo "Asset '$asset' not found"
      fi
    done
  fi
}

# Set the default timer interval (in seconds)
timer_interval=5

# Check if a timer interval is provided as an argument
if [ $# -ge 1 ]; then
  timer_interval=$1
  shift
fi

# Get the selected assets from the remaining arguments
selected_assets=$@

# Continuously update the asset data
while true; do
  display_data
  sleep $timer_interval
done
