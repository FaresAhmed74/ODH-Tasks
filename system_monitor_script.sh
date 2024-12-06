#!/bin/bash
# This is system Monitor Script
# check Disk , Cpu , Memory Usage and if > threshold send report

# Declaration
THRESHOLD=80
RECIPIENT_EMAIL="fcismarket404@gmail.com"
LOG_FILE="/var/log/system_monitor.log"

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOWW=$(tput seta 3)
RESET=$(tput sgr0)

# get opt
while getopts ":t:f:" opt;
do
 case ${opt} in

     t )
             THRESHOLD=$OPTARG
             ;;
     f )
             LOG_FILE=$OPTARG
             ;;

     \? )
             echo "Invalid option" 1>&2
             exit 1
             ;;

      : )
             echo "argument is required" 1>&2
             exit 1
             ;;

  esac
done

# Disk Usage
check_disk_usage() {
    local disk_report=$(df -h | awk 'NR>1 {print $1, $2, $3, $4, $5, $6}')
    local warning_flag=0

    echo -e "\n${YELLOW}Disk Usage:${RESET}"
    echo "$disk_report" | while read -r filesystem size used avail percent mountpoint; do
        # Remove the % sign and compare
        usage_percent=${percent%\%}
        if [[ $usage_percent -gt $THRESHOLD ]]; then
            echo -e "${RED}Warning: $filesystem is $percent full (Threshold: $THRESHOLD%)${RESET}"
            warning_flag=1
        fi
        echo "$filesystem $size $used $avail $percent $mountpoint"
    done

    return $warning_flag
}

# Cpu Usage
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo -e "\n${YELLOW}CPU Usage:${RESET}"
    echo "Current CPU Usage: ${cpu_usage}%"
  i
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo -e "${RED}High CPU Usage Warning${RESET}"
        return 1
    fi
    return 0
}
# Memory Usage
check_memory_usage() {
    local memory_info=$(free -h)
    echo -e "\n${YELLOW}Memory Usage:${RESET}"
    echo "$memory_info"

    local used_percent=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
    if [[ $used_percent -gt $THRESHOLD ]]; then
        echo -e "${RED}Warning: Memory usage is ${used_percent}% (Threshold: $THRESHOLD%)${RESET}"
        return 1
    fi
    return 0
}
# processes Usage
check_processes() {
    echo -e "\n${YELLOW}Top 5 Memory-Consuming Processes:${RESET}"
    ps aux --sort=-%mem | head -n 6
}

#Main function
monitor_system() {
    local warning_flag=0
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "System Monitoring Report - $timestamp"
        echo "======================================="

        check_disk_usage || ((warning_flag++))
        check_cpu_usage || ((warning_flag++))
        check_memory_usage || ((warning_flag++))
        check_processes
    } > "$LOG_FILE"

    # Send email if any warnings detected
    if [[ $warning_flag -gt 0 ]]; then
        sendmail $RECIPIENT_EMAIL
        To: $RECIPIENT_EMAIL
        Subject: System Monitoring Alert
        echo "$LOG_FILE"
    fi

    # Print log to console
    cat "$LOG_FILE"
}
monitor_system

exit 0

