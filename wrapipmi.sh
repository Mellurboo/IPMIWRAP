#
#       Myles "Mellurboo" Wilson
#               Built for DELL PowerEdge r630 in mind
#

# FORMATTING
OK="\e[32m"
ERROR="\e[31m"
WARNING="\e[33m"
PRIMARY="\e[95m"                        # Light Magenta
SECONDARY="\e[35m"                      # Magenta
RESET="\e[0m"

# IPMI LOGIN / CONNECTION
USERNAME=""
PASSWORD=""
HTMLURL=""

# LOGGING
LOGGING="N"
LOGNAME=""

# SYSINFO
FRU_DATA=""
PRODUCT_OEM=""
PRODUCT_NAME=""

query_logger () {
        local content="$1"
        local verbose="$2"
        if [ "${LOGGING}" = "Y" ]; then
                echo "${content}" >> "${LOGNAME}"
                if [ "${verbose}" = "v" ]; then
                        echo "${content}"
                fi
        else
                echo "${content}"
        fi
}

pause () {
        echo "${SECONDARY}Press enter to continue${RESET}"; read await;
}

boot_behavour () {
        OPTION=""
        clear
        echo "${PRIMARY}"
        echo "===================================="
        echo "==> Boot Device for next Restart <=="
        echo "====================================${RESET}"
        echo "${SECONDARY}type 'exit' or hit ctrl+c to exit"
        echo "[1] PXE"
        echo "[2] DISK"
        echo "[3] SAFE MODE"
        echo "[4] Diagnostic Parition"
        echo "[5] CD/DVD"
        echo "[6] Enter Firmware Settings"

        read -p "$(echo "${SECONDARY}: ${RESET}")" OPTION

        if [ "${OPTION}" = "exit" ]; then
                main_menu
        fi

        case $OPTION in
                1)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis bootdev pxe)" "v"
                        ;;
                2)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis bootdev disk)" "v"
                        ;;
                3)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis bootdev safe)" "v"
                        ;;
                4)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis bootdev diag)" "v"
                        ;;
                5)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis bootdev cdrom)" "v"
                        ;;
                6)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis bootdev bios)" "v"
                        ;;
                *)
                        echo "${ERROR}Invalid option"
                        pause
                        boot_behavour
        esac

}

custom_command () {
        CMD=""
        clear
        echo "${PRIMARY}"
        echo "================================================"
        echo "===> ISSUE COMMAND TO $HTMLURL AS ${SECONDARY}$USERNAME <==="
        echo "================================================${RESET}"
        echo "${SECONDARY}type 'exit' or hit ctrl+c to exit"
        read -p "$(echo "${SECONDARY}ipmitool -I lanplus ${HTMLURL} as ${USERNAME}: ${RESET}")" CMD
        if [ "${CMD}" = "exit" ]; 
                then main_menu
        else
                query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD ${CMD})"
        fi
        pause
        custom_command
}

power_controller () {
        CHOICE=""
        clear
        echo "${PRIMARY}"
        echo "==============================="
        echo "===> IPMI POWER CONTROLLER <==="
        echo "===============================${Reset}"
        echo "${SECONDARY}"
        echo "[1] Power ON"
        echo "[2] Power OFF"
        echo "[3] Power Reset"
        echo "[4] Power Status"
        echo "[5] Power Cycle"
        echo "[6] Chassis Status"
        echo "[7] Soft Reset"
        echo "[0] Go Back"
        echo "${RESET}"

        read -p "$(echo "${SECONDARY}: ${RESET}")" CHOICE
        case $CHOICE in
                1)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis power on)" "v"
                        ;;
                2)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis power off)" "v"
                        ;;
                3)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis power reset)" "v"
                        ;;
                4)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis power status)" "v"
                        ;;
                5)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis power cycle)" "v"
                        ;;
                6)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis status | awk -F ': ' '{printf "%-30s: %s\n", $1, $2}')" "v"
                        ;;
                7)
                        query_logger "$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD chassis power soft)" "v"
                        ;;
                0)
                        main_menu
                        ;;
                *)
                        echo "${ERROR}Bad Command :/${RESET}"
                        pause
                        main_menu
        esac

        pause
        power_controller
}

fan_controller () {
        RESULT=""
        SPEED=""
        HEX_SPEED=""
        clear
        echo "${PRIMARY}"
        echo "============================="
        echo "===> IPMI FAN CONTROLLER <==="
        echo "============================="
        echo "${RESET}"
        echo "${SECONDARY}Enter x to disable manual fan control${RESET}"
        read -p "$(echo "${SECONDARY}Fan Speed [0-100]: ${RESET}")" SPEED

        if [ "${SPEED}" = "x" ]; then
                ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x01 # Disable Manual Ctrl
        else
                if [ "$SPEED" -ge 75 ]; then
                        echo "${WARNING}"
                        echo "Setting the fan speed 75 or above may increase power use and it may be very loud"
                        read -p "Do you still want to continue? (y/n): " confirm
                        echo "${RESET}"
                        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                                HEX_SPEED=$(printf "0x%02X" "$SPEED")
                        else
                                echo "${WARNING}==> COMMAND ABORTED <=="
                                pause
                                main_menu
                        fi
                elif [ "$SPEED" -lt 5 ]; then
                        echo "${WARNING}"
                        echo "Less than 5% fan speed is danagerous under load and may cause physical damage to the machine"
                        read -p "Do you still wish to continue? (y/n): " confirmLow
                        echo "${RESET}"
                        if [ "$confirmLow" = "y" ] || [ "$confirmLow" = "Y" ]; then
                                HEX_SPEED=$(printf "0x%02X" "$SPEED")
                        else
                                echo "${WARNING}==> COMMAND ABORTED <=="
                                pause
                                main_menu
                        fi
                else
                        HEX_SPEED=$(printf "0x%02X" "$SPEED")
                fi
        fi

        ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x01 0x00 # Enable Manual Control
        ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD raw 0x30 0x30 0x02 0xff $HEX_SPEED # Edit Speed

        RESULT="$(echo $?)"

        if [ "${RESULT}" != "0" ]; then
                echo "${ERROR}There was an unexpected error. ${RESULT}${RESET}"
                pasue
                main_menu
        else
                echo "${OK}The command has completed!"
                if [ "${SPEED}" = "x" ]; then 
                        echo "(${OK}Manual Control Disabled${RESET})"; fi
                if [ -n "${HEX_SPEED}" ]; then 
                        echo "${OK} Fan Speed Set to ${SPEED}% (${HEX_SPEED})${RESET}"
                        query_logger "`echo Fan Speed Set to ${SPEED}% (${HEX_SPEED})`"
                fi
                pause
                main_menu
        fi
}

print_menu () {
        clear
        echo "${PRIMARY}"
        echo "============================"
        echo "===> IPMIWRAP MAIN MENU <==="
        echo "============================"
        echo "${PRODUCT_OEM} ${PRODUCT_NAME} as $USERNAME"
        if [ ${LOGGING} = "Y" ]; then echo "[Logging Enabled]"; else echo "${ERROR}[Logging Disabled]${SECONDARY}"; fi
        echo "${SECONDARY}"
        echo "[0] Exit"
        echo "[1] Fan Controller"
        echo "[2] Power Controller"
        echo "[3] Issue Custom Command"
        echo "[4] Server Boot Behavour"
        echo "[5] Display Sensor List"
        echo " "
        echo "[l] Toggle Logging"
        echo "[x] Clear Log Files"
        echo "${RESET}"
}

main_menu () {
        if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$HTMLURL" ]; then
                echo "${ERROR}You must fill out all fields with valid information!${RESET}"
                pause
                start
        else
                FRU_DATA=$(ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD fru)
                PRODUCT_OEM=$(echo "$FRU_DATA" | grep "Product Manufacturer" | awk -F ': ' '{print $2}')
                PRODUCT_NAME=$(echo "$FRU_DATA" | grep "Product Name" | awk -F ': ' '{print $2}')
                print_menu
                read -p "$(echo "${SECONDARY}: ${RESET}")" CHOICE

                case $CHOICE in
                        0)
                                exit
                                ;;

                        1)
                                fan_controller
                                ;;
                        2)
                                power_controller
                                ;;
                        3)
                                custom_command
                                ;;
                        4)
                                boot_behavour
                                ;;
                        5)
                                ipmitool -I lanplus -H $HTMLURL -U $USERNAME -P $PASSWORD sensor list
                                pause
                                main_menu
                                ;;
                        l)
                                if [ ${LOGGING} = "N" ]; then
                                        LOGGING="Y"
                                else
                                        LOGGING="N"
                                fi
                                echo "${PRIMARY}Logging Toggled ${LOGGING}"
                                main_menu
                                ;;
                        x)
                                rm -rf /etc/ipmiwrap/
                                main_menu
                                ;;
                        *)
                                echo "Invalid Option ${CHOICE}."
                                pause
                                main_menu
                                ;;
                esac
        fi
}

login_loop () {
        CHOICE=""
        clear
        echo "${PRIMARY}Interface Information${RESET}"
        read -p "$(echo "${SECONDARY}Remote access controller URL: ${RESET}")" HTMLURL
        read -p "$(echo "${SECONDARY}Please enter your username: ${RESET}")" USERNAME
        read -p "$(echo "${SECONDARY}Please enter your password: ${RESET}")" PASSWORD

        if curl --output /dev/null --silent --head --fail "${HTMLURL}"; then
                main_menu
        else
                echo "${ERROR}URL Invalid or Unreachable. Check your connection status.${RESET}"
                pause
                exit
        fi
}

if [ "$(whoami)" != "root" ]; then
        echo "${ERROR}IPMIWRAP must be run as sudo${RESET}"
        exit 1
else
        mkdir -p /etc/ipmiwrap/
        LOGNAME="/etc/ipmiwrap/LOG-$(date "+%F-%T").txt"
        echo "${PRIMARY}IPMIWRAP (the IPMI helper tool)${RESET}"
        login_loop
fi