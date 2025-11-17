#!/bin/bash

# Generic Welcome Script for All Users
# This script displays system information and useful details

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to get user's full name if available
get_user_full_name() {
    local full_name=$(getent passwd $(whoami) | cut -d: -f5 | cut -d, -f1)
    if [ -n "$full_name" ] && [ "$full_name" != "" ]; then
        echo "$full_name"
    else
        echo "$(whoami)"
    fi
}

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print info with color
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to get system role (root, sudo user, regular user)
get_user_role() {
    if [ $(id -u) -eq 0 ]; then
        echo "root (Administrator)"
    elif groups $(whoami) | grep -q '\bsudo\b'; then
        echo "$(whoami) (Sudo User)"
    else
        echo "$(whoami) (Regular User)"
    fi
}

# Clear screen and display welcome message
clear
echo -e "${PURPLE}"
cat << "EOF"
__        __   _                           
\ \      / /__| | ___ ___  _ __ ___   ___ 
 \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \
  \ V  V /  __/ | (_| (_) | | | | | |  __/
   \_/\_/ \___|_|\___\___/|_| |_| |_|\___|
EOF
echo -e "${NC}"

USER_NAME=$(get_user_full_name)
USER_ROLE=$(get_user_role)

echo -e "${CYAN}Hello $USER_NAME! Welcome to $(hostname) - here's your system information:${NC}"
echo -e "${YELLOW}User Role: $USER_ROLE${NC}"

# ===== DATE & TIME INFORMATION =====
print_section "Date & Time Information"

# Current date and time with timezone
print_info "Current Date: $(date '+%A, %B %d, %Y')"
print_info "Current Time: $(date '+%H:%M:%S %Z')"
print_info "Timezone: $(timedatectl show --property=Timezone --value 2>/dev/null || date '+%Z')"

# Check if ntp is active
if systemctl is-active --quiet systemd-timesyncd; then
    print_info "Time Sync: Active (systemd-timesyncd)"
else
    print_warning "Time Sync: Not active"
fi

# ===== SYSTEM INFORMATION =====
print_section "System Information"

# OS information
if [ -f /etc/os-release ]; then
    source /etc/os-release
    print_info "Operating System: $PRETTY_NAME"
else
    print_info "Operating System: $(uname -o)"
fi

# Kernel information
print_info "Kernel Version: $(uname -r)"
print_info "System Architecture: $(uname -m)"

# Host information
print_info "Hostname: $(hostname)"
print_info "Domain: $(hostname -d 2>/dev/null || echo "Not configured")"

# ===== USER INFORMATION =====
print_section "User Information"

print_info "Username: $(whoami)"
print_info "User ID: $(id -u)"
print_info "Primary Group: $(id -gn)"
print_info "Home Directory: $HOME"
print_info "User Role: $USER_ROLE"

# Login information
print_info "Current Shell: $SHELL"
print_info "Login Time: $(who -u | grep "$(whoami)" | awk '{print $3, $4}' | head -1)"

# Check if user has sudo privileges without password
if sudo -n true 2>/dev/null; then
    print_info "Sudo: Password-free access enabled"
elif groups $(whoami) | grep -q '\bsudo\b'; then
    print_info "Sudo: Available (requires password)"
else
    print_info "Sudo: Not available for this user"
fi

# ===== HARDWARE INFORMATION =====
print_section "Hardware Information"

# CPU information
if command -v lscpu &> /dev/null; then
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    CPU_CORES=$(nproc)
    print_info "CPU: $CPU_MODEL"
    print_info "CPU Cores: $CPU_CORES"
else
    print_info "CPU Cores: $(nproc)"
fi

# Memory information
if command -v free &> /dev/null; then
    TOTAL_MEM=$(free -h 2>/dev/null | grep Mem: | awk '{print $2}')
    AVAILABLE_MEM=$(free -h 2>/dev/null | grep Mem: | awk '{print $7}')
    print_info "Total Memory: $TOTAL_MEM"
    print_info "Available Memory: $AVAILABLE_MEM"
fi

# Disk information
if command -v df &> /dev/null; then
    print_info "Disk Usage:"
    df -h / 2>/dev/null | awk 'NR==2 {printf "  - Root FS: %s used, %s available (Total: %s)\n", $5, $4, $2}'
fi

# ===== NETWORK INFORMATION =====
print_section "Network Information"

# IP addresses
HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -n "$HOST_IP" ]; then
    print_info "IP Address: $HOST_IP"
else
    print_info "IP Address: Not available"
fi

# Public IP (if internet available)
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    PUBLIC_IP=$(curl -s https://ipinfo.io/ip --connect-timeout 3 2>/dev/null)
    if [ -n "$PUBLIC_IP" ]; then
        print_info "Public IP: $PUBLIC_IP"
    fi
    print_info "Internet: Connected ✓"
else
    print_warning "Internet: Not connected"
fi

# ===== SYSTEM STATUS =====
print_section "System Status"

# Uptime
if command -v uptime &> /dev/null; then
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | sed 's/.*up //')
    print_info "System Uptime: $UPTIME"
    
    # Load average
    LOAD_AVG=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}')
    if [ -n "$LOAD_AVG" ]; then
        print_info "Load Average: $LOAD_AVG"
    fi
fi

# Logged in users
USER_COUNT=$(who 2>/dev/null | wc -l)
print_info "Users Logged In: $USER_COUNT"

# ===== DEVELOPMENT ENVIRONMENT =====
print_section "Development Environment"

# Check for programming languages
LANGUAGES=("java" "python3" "python" "node" "npm" "ruby" "go" "php" "rustc" "cargo")
INSTALLED_LANGS=()

for lang in "${LANGUAGES[@]}"; do
    if command -v $lang &> /dev/null; then
        case $lang in
            "java")
                VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
                INSTALLED_LANGS+=("Java: $VERSION")
                ;;
            "python3"|"python")
                VERSION=$($lang --version 2>&1)
                INSTALLED_LANGS+=("Python: $VERSION")
                ;;
            "node")
                VERSION=$(node --version 2>&1)
                INSTALLED_LANGS+=("Node.js: $VERSION")
                ;;
            "npm")
                VERSION=$(npm --version 2>&1)
                INSTALLED_LANGS+=("NPM: $VERSION")
                ;;
            "ruby")
                VERSION=$(ruby --version 2>&1 | cut -d' ' -f2)
                INSTALLED_LANGS+=("Ruby: $VERSION")
                ;;
            "go")
                VERSION=$(go version 2>&1 | cut -d' ' -f3)
                INSTALLED_LANGS+=("Go: $VERSION")
                ;;
            "php")
                VERSION=$(php --version 2>&1 | head -n1 | cut -d' ' -f2)
                INSTALLED_LANGS+=("PHP: $VERSION")
                ;;
            "rustc")
                VERSION=$(rustc --version 2>&1 | cut -d' ' -f2)
                INSTALLED_LANGS+=("Rust: $VERSION")
                ;;
        esac
    fi
done

if [ ${#INSTALLED_LANGS[@]} -gt 0 ]; then
    for lang_info in "${INSTALLED_LANGS[@]}"; do
        print_info "$lang_info"
    done
else
    print_warning "No development languages detected"
fi

# Development tools
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>&1)
    print_info "Git: $GIT_VERSION"
fi

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>&1)
    print_info "Docker: $DOCKER_VERSION"
fi

if command -v code &> /dev/null; then
    print_info "VS Code: Installed"
fi

# ===== RECOMMENDATIONS & SECURITY =====
print_section "System Health & Recommendations"

# Check disk space
if command -v df &> /dev/null; then
    DISK_PERCENT=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ -n "$DISK_PERCENT" ]; then
        if [ "$DISK_PERCENT" -gt 90 ]; then
            print_error "Warning: Root filesystem is ${DISK_PERCENT}% full!"
        elif [ "$DISK_PERCENT" -gt 80 ]; then
            print_warning "Notice: Root filesystem is ${DISK_PERCENT}% full"
        else
            print_info "Disk space: Healthy (${DISK_PERCENT}% used)"
        fi
    fi
fi

# Check for updates
if command -v apt &> /dev/null && [ $(id -u) -eq 0 ]; then
    UPDATE_COUNT=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ "$UPDATE_COUNT" -gt 1 ]; then
        print_warning "System updates available: $((UPDATE_COUNT-1)) packages"
    else
        print_info "System: Up to date"
    fi
elif command -v apt &> /dev/null; then
    print_info "Run 'sudo apt update' to check for updates"
fi

# Security check - world-writable files in home directory
WW_FILES=$(find ~ -perm -o+w -type f 2>/dev/null | wc -l)
if [ "$WW_FILES" -gt 0 ]; then
    print_warning "Security: $WW_FILES world-writable files in home directory"
fi

# ===== QUICK COMMANDS =====
print_section "Quick Commands"

echo -e "${YELLOW}Useful commands for $(whoami):${NC}"
echo -e "  • ${GREEN}systemctl status${NC} - Check system services"
echo -e "  • ${GREEN}journalctl -xe${NC} - View system logs"
echo -e "  • ${GREEN}df -h${NC} - Check disk space"
echo -e "  • ${GREEN}free -h${NC} - Check memory usage"
echo -e "  • ${GREEN}top${NC} - Monitor system processes"

if groups $(whoami) | grep -q '\bsudo\b'; then
    echo -e "  • ${GREEN}sudo apt update && sudo apt upgrade${NC} - Update system"
fi

# ===== FUN FACTS =====
print_section "Did You Know?"

FACTS=(
    "Your home directory contains approximately $(find ~ -type f 2>/dev/null | wc -l) files"
    "Today is day $(date +%j) of $(date +%Y) ($((365 - $(date +%j))) days remaining)"
    "Your shell history has $(history | wc -l) commands"
    "You're using $(du -sh ~ 2>/dev/null | awk '{print $1}') of space in your home directory"
    "There are $(ls -1 ~ | wc -l) visible items in your home directory"
)

RANDOM_FACT=${FACTS[$RANDOM % ${#FACTS[@]}]}
echo -e "${YELLOW}✨ ${RANDOM_FACT}${NC}"

# ===== FINAL MESSAGE =====
echo -e "\n${CYAN}Have a productive day $USER_NAME!${NC}"
echo -e "${PURPLE}Report generated on: $(date '+%A, %B %d, %Y at %H:%M:%S %Z')${NC}"
echo -e "${BLUE}System: $(hostname) | User: $(whoami) | Role: $(echo $USER_ROLE | cut -d' ' -f1)${NC}\n"
