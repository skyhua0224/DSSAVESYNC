#!/bin/bash
# Death Stranding 存档双向同步脚本 - Mac 端
# 日期: 2025-03-18
# 修改日期: 2025-03-18

# 防止未定义变量
set -u

# 颜色定义
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BRIGHT_GREEN="\033[1;32m"
GREEN="\033[0;32m"
RED="\033[0;31m"
WHITE="\033[0;37m"
GRAY="\033[0;90m"
BLUE="\033[0;34m"
NC="\033[0m"
BOLD="\033[1m"
ARROW="→"

# 设置变量
MAC_USERNAME=$(whoami)
MAC_SAVE_PATH="/Users/$MAC_USERNAME/Library/Mobile Documents/iCloud~com~505games~deathstranding"
SYNC_FOLDER="/Users/$MAC_USERNAME/DSSAVESYNC"
WINDOWS_SAVES_FOLDER="$SYNC_FOLDER/Windows/Saves"
MAC_SAVES_FOLDER="$SYNC_FOLDER/macOS/Saves"
LOG_FILE="$SYNC_FOLDER/macOS/sync_log.txt"
TEMP_DIR="/tmp/ds_sync_temp"

# 表格样式
TABLE_WIDTH=95
HEADER_STYLE="${BOLD}${CYAN}"
CELL_PADDING=2

# 获取设备型号（优化版本）
get_device_model() {
    local model
    if model=$(sysctl -n hw.model 2>/dev/null); then
        echo "$model"
        return
    fi
    echo "Mac"
}

DEVICE_NAME=$(get_device_model)

# 语言选择 (Language Selection)
echo "Please select your language / 请选择您的语言:"
echo "1) English"
echo "2) 中文 (Chinese)"
read -r lang_choice

language="en" # Default to English

case "$lang_choice" in
1) language="en" ;;
2) language="zh" ;;
*)
    echo "Invalid choice. Defaulting to English."
    language="en"
    ;;
esac

# 翻译 (Translations)
get_translation() {
    local key="$1"
    case "$language" in
    "en")
        case "$key" in
        "title") echo "Death Stranding Save Sync Tool" ;;
        "device") printf "Current Device: %s" "$DEVICE_NAME" ;;
        "save_type") echo "Save Type" ;;
        "local_save") echo "Local Save" ;;
        "mac_sync") echo "Mac Sync" ;;
        "win_sync") echo "Windows Sync" ;;
        "no_save") echo "No Save" ;;
        "file_name") echo "└─File Name" ;;
        "manual_save") echo "Manual Save" ;;
        "auto_save") echo "Auto Save" ;;
        "quick_save") echo "Quick Save" ;;
        "import_win_title") echo "Select Windows save type to import:" ;;
        "import_manual") echo "1) Import Manual Save" ;;
        "import_auto") echo "2) Import Auto Save" ;;
        "import_quick") echo "3) Import Quick Save" ;;
        "import_all") echo "4) Import All Windows Saves" ;;
        "return_menu") echo "5) Return to Main Menu" ;;
        "invalid_choice") echo "Invalid choice" ;;
        "import_all_prep") echo "Preparing to import all types of Windows saves..." ;;
        "processing") echo "====== Processing %s (%d/%d) ======" ;;
        "import_success") echo "✓ %s import successful" ;;
        "import_failed") echo "✗ %s import failed" ;;
        "batch_import_complete") echo "Batch import complete: Successfully imported %d/%d save types" ;;
        "import_single_prep") echo "Preparing to import Windows %s save..." ;;
        "step_1") echo "[Step %d/%d] Checking Windows save..." ;;
        "step_2") echo "[Step %d/%d] Preparing to back up existing save..." ;;
        "step_3") echo "[Step %d/%d] Creating new save package..." ;;
        "step_4") echo "[Step %d/%d] Importing save file..." ;;
        "step_5") echo "[Step %d/%d] Verifying import result..." ;;
        "import_complete") echo "Import complete! Save has been successfully imported." ;;
        "import_fail_msg") echo "Import failed! Please check error messages." ;;
        "export_mac_title") echo "Select Mac save type to export:" ;;
        "export_manual") echo "1) Export Manual Save" ;;
        "export_auto") echo "2) Export Auto Save" ;;
        "export_quick") echo "3) Export Quick Save" ;;
        "export_all") echo "4) Export All Mac Saves" ;;
        "no_mac_save") echo "No available Mac save found" ;;
        "export_success") echo "Successfully exported Mac save package: %s" ;;
        "press_enter") echo "Press Enter to continue..." ;;
        "sync_warning") echo "Warning: One-click sync may result in save loss, are you sure you want to continue? (Y/N): " ;;
        "sync_start") echo "Starting one-click sync of latest saves..." ;;
        "menu_title") echo "Available Operations:" ;;
        "menu_import") echo "1) Import Windows Save" ;;
        "menu_export") echo "2) Export Mac Save" ;;
        "menu_sync") echo "3) One-Click Sync Latest Save (Not Recommended)" ;;
        "menu_exit") echo "4) Exit Program" ;;
        "menu_prompt") echo "Select an operation (1-4): " ;;
        "program_exit") echo "Program exited" ;;
        "progress_title") echo "Import Progress:" ;;
        "local_newer_warn") echo "Warning: Local %s save is newer than Windows save!" ;;
        "local_time") echo "Local save time:" ;;
        "win_time") echo "Windows save time:" ;;
        "confirm_overwrite") echo "Are you sure you want to overwrite the newer local save with the older Windows save?" ;;
        "backup_log") echo "Backed up current %s save to: %s" ;;
        "import_log") echo "Imported Windows %s save: %s" ;;

        esac
        ;;
    "zh")
        case "$key" in
        "title") echo "Death Stranding 存档同步工具" ;;
        "device") printf "当前设备: %s" "$DEVICE_NAME" ;;
        "save_type") echo "存档类型" ;;
        "local_save") echo "本地存档" ;;
        "mac_sync") echo "Mac同步" ;;
        "win_sync") echo "Windows同步" ;;
        "no_save") echo "无存档" ;;
        "file_name") echo "└─文件名" ;;
        "manual_save") echo "手动存档" ;;
        "auto_save") echo "自动存档" ;;
        "quick_save") echo "快速存档" ;;
        "import_win_title") echo "请选择要导入的Windows存档类型：" ;;
        "import_manual") echo "1) 导入手动存档" ;;
        "import_auto") echo "2) 导入自动存档" ;;
        "import_quick") echo "3) 导入快速存档" ;;
        "import_all") echo "4) 导入全部Windows存档" ;;
        "return_menu") echo "5) 返回主菜单" ;;
        "invalid_choice") echo "无效的选择" ;;
        "import_all_prep") echo "准备导入所有类型的Windows存档..." ;;
        "processing") echo "====== 正在处理%s (%d/%d) ======" ;;
        "import_success") echo "✓ %s导入成功" ;;
        "import_failed") echo "✗ %s导入失败" ;;
        "batch_import_complete") echo "批量导入完成：成功导入 %d/%d 种类型的存档" ;;
        "import_single_prep") echo "准备导入Windows %s 存档..." ;;
        "step_1") echo "[步骤 %d/%d] 检查Windows存档..." ;;
        "step_2") echo "[步骤 %d/%d] 准备备份现有存档..." ;;
        "step_3") echo "[步骤 %d/%d] 创建新存档包..." ;;
        "step_4") echo "[步骤 %d/%d] 导入存档文件..." ;;
        "step_5") echo "[步骤 %d/%d] 验证导入结果..." ;;
        "import_complete") echo "导入完成！存档已成功导入。" ;;
        "import_fail_msg") echo "导入失败！请检查错误信息。" ;;
        "export_mac_title") echo "请选择要导出的Mac存档类型：" ;;
        "export_manual") echo "1) 导出手动存档" ;;
        "export_auto") echo "2) 导出自动存档" ;;
        "export_quick") echo "3) 导出快速存档" ;;
        "export_all") echo "4) 导出全部Mac存档" ;;
        "no_mac_save") echo "未找到可用的Mac存档" ;;
        "export_success") echo "已导出Mac存档包: %s" ;;
        "press_enter") echo "按Enter键继续..." ;;
        "sync_warning") echo "警告：一键同步可能导致存档丢失，确定要继续吗？(Y/N): " ;;
        "sync_start") echo "开始一键同步最新存档..." ;;
        "menu_title") echo "可用操作：" ;;
        "menu_import") echo "1) 导入Windows存档" ;;
        "menu_export") echo "2) 导出Mac存档" ;;
        "menu_sync") echo "3) 一键同步最新存档（不推荐）" ;;
        "menu_exit") echo "4) 退出程序" ;;
        "menu_prompt") echo "请选择操作 (1-4): " ;;
        "program_exit") echo "程序退出" ;;
        "progress_title") echo "导入进度:" ;;
        "local_newer_warn") echo "警告：本地%s存档比Windows存档新！" ;;
        "local_time") echo "本地存档时间：" ;;
        "win_time") echo "Windows存档时间：" ;;
        "confirm_overwrite") echo "确定要用旧的Windows存档覆盖较新的本地存档吗？" ;;
        "backup_log") echo "已备份当前%s存档: %s" ;;
        "import_log") echo "已导入Windows %s存档: %s" ;;

        esac
        ;;
    esac
}

# 记录日志函数
write_log() {
    local message="$1"
    local type="${2:-info}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "%s - %s\n" "$timestamp" "$message" >>"$LOG_FILE"

    case "$type" in
    "success")
        printf "${BRIGHT_GREEN}%s${NC}\n" "$message"
        ;;
    "warning")
        printf "${YELLOW}%s${NC}\n" "$message"
        ;;
    "error")
        printf "${RED}%s${NC}\n" "$message"
        ;;
    *)
        printf "${WHITE}%s${NC}\n" "$message"
        ;;
    esac
}

# 获取用户确认
get_confirmation() {
    local prompt="$1"
    printf "\n${YELLOW}%s (Y/N): ${NC}" "$prompt"
    read -r response </dev/tty
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

# 选择存档类型 (Not used directly, kept for potential future use)
select_save_type() {
    local context="$1"

    if [ "$context" = "import" ]; then
        printf "\n${YELLOW}$(get_translation import_win_title)${NC}\n"
        printf "${WHITE}1)${NC} $(get_translation import_manual)\n"
        printf "${WHITE}2)${NC} $(get_translation import_auto)\n"
        printf "${WHITE}3)${NC} $(get_translation import_quick)\n"
        printf "${WHITE}4)${NC} $(get_translation import_all)\n"
        printf "${WHITE}5)${NC} $(get_translation return_menu)\n"
    elif [ "$context" = "export" ]; then
        printf "\n${YELLOW}$(get_translation export_mac_title)${NC}\n"
        printf "${WHITE}1)${NC} $(get_translation export_manual)\n"
        printf "${WHITE}2)${NC} $(get_translation export_auto)\n"
        printf "${WHITE}3)${NC} $(get_translation export_quick)\n"
        printf "${WHITE}4)${NC} $(get_translation export_all)\n"
        printf "${WHITE}5)${NC} $(get_translation return_menu)\n"

    else
        printf "\n${RED}错误：未知的上下文 - select_save_type${NC}\n"
        return 1
    fi

    while true; do
        printf "\n${YELLOW}$(get_translation menu_prompt) ${NC}"
        read -r choice </dev/tty

        case "$choice" in
        1)
            echo "manualsave"
            break
            ;;
        2)
            echo "autosave"
            break
            ;;
        3)
            echo "quicksave"
            break
            ;;
        4)
            echo "all"
            break
            ;;
        5)
            echo "cancel"
            break
            ;;
        *)
            printf "\n${RED}$(get_translation invalid_choice)，请输入1-5之间的数字${NC}\n"
            sleep 0.5
            ;;
        esac
    done
}

# 获取存档时间戳
get_save_time() {
    local file="$1"
    if [ -e "$file" ]; then
        stat -f "%m" "$file"
    else
        echo "0"
    fi
}

# 获取最新存档信息并检查错误
get_save_info() {
    local save_type="$1"
    local pattern="$2"
    local dir="$3"
    local latest_time=0
    local latest_name=""

    while IFS= read -r file; do
        if [ -e "$file" ]; then
            if [ -d "$file" ] && [ -f "$file/data" ]; then
                local time
                time=$(get_save_time "$file/data")
                time=${time:-0}
                if [ "$time" -gt "$latest_time" ]; then
                    latest_time=$time
                    latest_name=$(basename "$file")
                fi
            elif [ -f "$file" ]; then
                local time
                time=$(get_save_time "$file")
                time=${time:-0}
                if [ "$time" -gt "$latest_time" ]; then
                    latest_time=$time
                    latest_name=$(basename "$file")
                fi
            fi
        fi
    done < <(find "$dir" -name "$pattern" 2>/dev/null || echo "")

    printf "%s:%s" "${latest_name:-NONE}" "${latest_time:-0}"
}

# 格式化时间带颜色
format_time_colored() {
    local timestamp="$1"
    local max_time="$2"
    timestamp=${timestamp:-0}
    max_time=${max_time:-0}

    if [ "$timestamp" -eq 0 ]; then
        printf "${RED}$(get_translation no_save)${NC}"
    elif [ "$timestamp" -eq "$max_time" ]; then
        printf "${BRIGHT_GREEN}%s${NC}" "$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S")"
    else
        printf "${YELLOW}%s${NC}" "$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S")"
    fi
}

# 比较时间显示箭头
show_sync_arrow() {
    local time1="${1:-0}"
    local time2="${2:-0}"
    local direction="$3"

    if [ "$time1" -eq 0 ] || [ "$time2" -eq 0 ]; then
        printf "   "
        return
    fi

    if [ "$time1" -gt "$time2" ]; then
        if [ "$direction" = "right" ]; then
            printf "${YELLOW} ${ARROW} ${NC}"
        else
            printf "   "
        fi
    elif [ "$time1" -lt "$time2" ]; then
        if [ "$direction" = "left" ]; then
            printf "${YELLOW} ${ARROW} ${NC}"
        else
            printf "   "
        fi
    else
        printf "   "
    fi
}

# 绘制分隔线
draw_line() {
    local char="${1:-─}"
    local line
    printf -v line "%${TABLE_WIDTH}s" ""
    printf "${BLUE}%s${NC}\n" "${line// /$char}"
}

# 显示存档状态表格
show_save_status() {
    clear
    echo
    printf "${HEADER_STYLE}╔════ $(get_translation title) ════╗${NC}\n"
    printf "${HEADER_STYLE}║          $(get_translation device) ║${NC}\n"
    printf "${HEADER_STYLE}╚════════════════════════════════════╝${NC}\n"
    echo

    # 表格头部
    local header_format="%-15s %-25s %-3s %-25s %-3s %-25s\n"
    printf "${HEADER_STYLE}$header_format" "$(get_translation save_type)" "$(get_translation local_save)" " " "$(get_translation mac_sync)" " " "$(get_translation win_sync)"
    draw_line "═"

    # 遍历存档类型
    local save_types=("$(get_translation manual_save)" "$(get_translation auto_save)" "$(get_translation quick_save)")
    local save_patterns=("manualsave*.checkpoint.dat.bundle" "autosave*.checkpoint.dat.bundle" "quicksave*.checkpoint.dat.bundle")
    local save_prefixes=("manualsave" "autosave" "quicksave")

    for i in "${!save_types[@]}"; do
        # 获取存档信息
        local mac_local_info
        local mac_sync_info
        local win_sync_info
        mac_local_info=$(get_save_info "${save_prefixes[$i]}" "${save_patterns[$i]}" "$MAC_SAVE_PATH")
        mac_sync_info=$(get_save_info "${save_prefixes[$i]}" "${save_prefixes[$i]}*_mac.dat" "$MAC_SAVES_FOLDER")
        win_sync_info=$(get_save_info "${save_prefixes[$i]}" "${save_prefixes[$i]}*_win.dat" "$WINDOWS_SAVES_FOLDER")

        # 提取时间戳
        local mac_local_time
        local mac_sync_time
        local win_sync_time
        mac_local_time=$(echo "$mac_local_info" | cut -d: -f2)
        mac_sync_time=$(echo "$mac_sync_info" | cut -d: -f2)
        win_sync_time=$(echo "$win_sync_info" | cut -d: -f2)

        # 找出最新时间
        local max_time
        max_time=$(printf "%s\n%s\n%s\n" "${mac_local_time:-0}" "${mac_sync_time:-0}" "${win_sync_time:-0}" | sort -rn | head -n1)

        # 提取文件名
        local mac_local_name
        local mac_sync_name
        local win_sync_name
        mac_local_name=$(echo "$mac_local_info" | cut -d: -f1)
        mac_sync_name=$(echo "$mac_sync_info" | cut -d: -f1)
        win_sync_name=$(echo "$win_sync_info" | cut -d: -f1)

        # 显示箭头
        local arrow1
        local arrow2
        arrow1=$(show_sync_arrow "${mac_local_time:-0}" "${mac_sync_time:-0}" "right")
        arrow2=$(show_sync_arrow "${win_sync_time:-0}" "${mac_sync_time:-0}" "left")

        # 显示时间
        printf "${WHITE}%-15s${NC} " "${save_types[$i]}"
        printf "%-25s %3s %-25s %3s %-25s\n" \
            "$(format_time_colored "${mac_local_time:-0}" "$max_time")" \
            "$arrow1" \
            "$(format_time_colored "${mac_sync_time:-0}" "$max_time")" \
            "$arrow2" \
            "$(format_time_colored "${win_sync_time:-0}" "$max_time")"

        # 显示文件名（如果存在）
        if [ "$mac_local_name" != "NONE" ] || [ "$mac_sync_name" != "NONE" ] || [ "$win_sync_name" != "NONE" ]; then
            printf "${GRAY}%-15s${NC} " "$(get_translation file_name)"
            printf "%-25s %3s %-25s %3s %-25s\n" \
                "${mac_local_name}" " " "${mac_sync_name}" " " "${win_sync_name}"
        fi

        # 在最后一行之前添加分隔线
        if [ $i -lt $((${#save_types[@]} - 1)) ]; then
            draw_line "─"
        fi
    done

    draw_line "═"
}

# 创建metadata文件
create_metadata() {
    local output_file="$1"
    local mod_date="$2"

    # 创建临时plist文件
    local temp_plist="$TEMP_DIR/temp.plist"
    cat >"$temp_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>deviceName</key>
    <string>$DEVICE_NAME</string>
    <key>modificationDate</key>
    <date>$mod_date</date>
</dict>
</plist>
EOF

    plutil -convert binary1 "$temp_plist" -o "$output_file"
    rm -f "$temp_plist"
}

# 显示进度条
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local completed=$((percent / 2))
    local remaining=$((50 - completed))

    printf "\r${GREEN}$(get_translation progress_title)["
    for ((i = 0; i < completed; i++)); do
        printf "="
    done

    if [ $current -lt $total ]; then
        printf ">"
        remaining=$((remaining - 1))
    fi

    for ((i = 0; i < remaining; i++)); do
        printf " "
    done

    printf "] %d%%${NC}" $percent

    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

# 导入单个Windows存档
import_single_save() {
    local save_type="$1"
    local show_progress_bar="${2:-true}"

    # 翻译存档类型
    local translated_save_type
    case "$save_type" in
    "manualsave") translated_save_type=$(get_translation manual_save) ;;
    "autosave") translated_save_type=$(get_translation auto_save) ;;
    "quicksave") translated_save_type=$(get_translation quick_save) ;;
    esac

    # 检查Windows存档
    local win_sync_info
    win_sync_info=$(get_save_info "$save_type" "${save_type}*_win.dat" "$WINDOWS_SAVES_FOLDER")
    local win_sync_time
    win_sync_time=$(echo "$win_sync_info" | cut -d: -f2)

    if [ "${win_sync_time:-0}" -eq 0 ]; then
        write_log "$(get_translation no_win_save) ${translated_save_type} $(get_translation save)" "warning"
        return 1
    fi

    # 检查本地存档
    local mac_local_info
    mac_local_info=$(get_save_info "$save_type" "${save_type}*.checkpoint.dat.bundle" "$MAC_SAVE_PATH")
    local mac_local_time
    mac_local_time=$(echo "$mac_local_info" | cut -d: -f2)

    # 获取Windows存档文件
    local win_sync_name
    win_sync_name=$(echo "$win_sync_info" | cut -d: -f1)
    local win_dat="$WINDOWS_SAVES_FOLDER/${win_sync_name}"
    local bundle_name="${win_sync_name%_win.dat}.checkpoint.dat.bundle"
    local bundle_path="$MAC_SAVE_PATH/$bundle_name"

    # 如果本地存档较新，提示确认
    if [ "${mac_local_time:-0}" -gt "${win_sync_time:-0}" ]; then
        printf "\n${YELLOW}$(get_translation local_newer_warn -f "$translated_save_type")${NC}\n"
        printf "${WHITE}$(get_translation local_time)${NC}$(date -r "$mac_local_time" "+%Y-%m-%d %H:%M:%S")\n"
        printf "${WHITE}$(get_translation win_time)${NC}$(date -r "$win_sync_time" "+%Y-%m-%d %H:%M:%S")\n"

        if ! get_confirmation "$(get_translation confirm_overwrite)"; then
            return 2
        fi
    fi

    # 备份现有存档
    if [ -d "$bundle_path" ]; then
        mkdir -p "$MAC_SAVES_FOLDER/backups"
        local backup_path="$MAC_SAVES_FOLDER/backups/backup_${bundle_name}_$(date +%Y%m%d_%H%M%S)"
        cp -R "$bundle_path" "$backup_path"
        if [ "$show_progress_bar" = true ]; then
            write_log "$(get_translation backup_log -f "$translated_save_type" "$backup_path")"
        fi
    fi

    # 创建新bundle
    local temp_bundle="$TEMP_DIR/new_bundle"
    rm -rf "$temp_bundle"
    mkdir -p "$temp_bundle"

    # 复制数据并创建metadata
    cp "$win_dat" "$temp_bundle/data"
    chmod 644 "$temp_bundle/data"
    create_metadata "$temp_bundle/metadata" "$(date -u -r "$win_sync_time" "+%Y-%m-%dT%H:%M:%SZ")"
    chmod 644 "$temp_bundle/metadata"

    # 部署bundle
    rm -rf "$bundle_path"
    mv "$temp_bundle" "$bundle_path"
    chmod 755 "$bundle_path"

    if [ "$show_progress_bar" = true ]; then
        write_log "$(get_translation import_log -f "$translated_save_type" "$bundle_name")"
    fi
    return 0
}

# 导入Windows存档
import_windows_save() {
    # 创建临时目录
    mkdir -p "$TEMP_DIR"

    # 显示Windows存档导入选项
    printf "\n${YELLOW}$(get_translation import_win_title)${NC}\n"
    printf "${WHITE}1)${NC} $(get_translation import_manual)\n"
    printf "${WHITE}2)${NC} $(get_translation import_auto)\n"
    printf "${WHITE}3)${NC} $(get_translation import_quick)\n"
    printf "${WHITE}4)${NC} $(get_translation import_all)\n"
    printf "${WHITE}5)${NC} $(get_translation return_menu)\n"
    printf "\n${YELLOW}$(get_translation menu_prompt) ${NC}"
    read -r choice </dev/tty

    case $choice in
    1) save_type="manualsave" ;;
    2) save_type="autosave" ;;
    3) save_type="quicksave" ;;
    4) save_type="all" ;;
    5) return ;;
    *)
        write_log "$(get_translation invalid_choice)" "error"
        return
        ;;
    esac

    # 根据选择进行导入
    if [ "$save_type" = "all" ]; then
        # 导入全部存档
        printf "\n${CYAN}$(get_translation import_all_prep)${NC}\n"

        local save_types=("manualsave" "autosave" "quicksave")
        local save_names=("$(get_translation manual_save)" "$(get_translation auto_save)" "$(get_translation quick_save)")
        local success_count=0
        local total_count=${#save_types[@]}

        for i in "${!save_types[@]}"; do
            printf "\n${CYAN}$(get_translation processing -f "${save_names[$i]}" "$((i + 1))" "$total_count")${NC}\n"
            if import_single_save "${save_types[$i]}" true; then
                success_count=$((success_count + 1))
                printf "${BRIGHT_GREEN}$(get_translation import_success -f "${save_names[$i]}") ${NC}\n"
            else
                printf "${RED}$(get_translation import_failed -f "${save_names[$i]}") ${NC}\n"
            fi
            show_progress $((i + 1)) $total_count
            echo
        done

        printf "\n${BRIGHT_GREEN}$(get_translation batch_import_complete -f "$success_count" "$total_count")${NC}\n"
    else
        # 导入单个类型存档

        # 翻译存档类型
        local translated_save_type
        case "$save_type" in
        "manualsave") translated_save_type=$(get_translation manual_save) ;;
        "autosave") translated_save_type=$(get_translation auto_save) ;;
        "quicksave") translated_save_type=$(get_translation quick_save) ;;
        esac
        printf "\n${CYAN}$(get_translation import_single_prep -f "$translated_save_type")${NC}\n"

        local step=1
        local steps=5

        # 步骤1：检查Windows存档
        printf "${CYAN}$(get_translation step_1 -f "$step" "$steps")${NC}\n"
        show_progress $step $steps
        sleep 0.5

        # 步骤2：准备备份
        step=$((step + 1))
        printf "\n${CYAN}$(get_translation step_2 -f "$step" "$steps")${NC}\n"
        show_progress $step $steps
        sleep 0.5

        # 步骤3：创建新存档包
        step=$((step + 1))
        printf "\n${CYAN}$(get_translation step_3 -f "$step" "$steps")${NC}\n"
        show_progress $step $steps
        sleep 0.5

        # 步骤4：导入存档
        step=$((step + 1))
        printf "\n${CYAN}$(get_translation step_4 -f "$step" "$steps")${NC}\n"

        if import_single_save "$save_type" true; then
            show_progress $step $steps
            sleep 0.5

            # 步骤5：完成
            step=$((step + 1))
            printf "\n${CYAN}$(get_translation step_5 -f "$step" "$steps")${NC}\n"
            show_progress $step $steps
            sleep 0.5
            printf "\n${BRIGHT_GREEN}$(get_translation import_complete)${NC}\n"
        else
            printf "\n${RED}$(get_translation import_fail_msg)${NC}\n"
        fi
    fi

    # 清理临时文件夹
    rm -rf "$TEMP_DIR"

    printf "\n${YELLOW}$(get_translation press_enter)${NC}"
    read -r </dev/tty
}

# 导出Mac存档
export_mac_save() {
    # 显示Mac存档导出菜单
    printf "\n${YELLOW}$(get_translation export_mac_title)${NC}\n"
    printf "${WHITE}1)${NC} $(get_translation export_manual)\n"
    printf "${WHITE}2)${NC} $(get_translation export_auto)\n"
    printf "${WHITE}3)${NC} $(get_translation export_quick)\n"
    printf "${WHITE}4)${NC} $(get_translation export_all)\n"
    printf "${WHITE}5)${NC} $(get_translation return_menu)\n"
    printf "\n${YELLOW}$(get_translation menu_prompt) ${NC}"
    read -r choice </dev/tty

    case $choice in
    1) save_type="manualsave" ;;
    2) save_type="autosave" ;;
    3) save_type="quicksave" ;;
    4) save_type="all" ;;
    5) return ;;
    *)
        write_log "$(get_translation invalid_choice)" "error"
        return
        ;;
    esac
    # 翻译存档类型
    local translated_save_type
    case "$save_type" in
    "manualsave") translated_save_type=$(get_translation manual_save) ;;
    "autosave") translated_save_type=$(get_translation auto_save) ;;
    "quicksave") translated_save_type=$(get_translation quick_save) ;;
    esac
    # 检查Mac存档
    local mac_local_info
    mac_local_info=$(get_save_info "$save_type" "${save_type}*.checkpoint.dat.bundle" "$MAC_SAVE_PATH")
    local mac_local_time
    mac_local_time=$(echo "$mac_local_info" | cut -d: -f2)

    if [ "${mac_local_time:-0}" -eq 0 ]; then
        write_log "$(get_translation no_mac_save)" "error"
        return
    fi

    # 获取Mac存档信息
    local mac_local_name
    mac_local_name=$(echo "$mac_local_info" | cut -d: -f1)
    local bundle_path="$MAC_SAVE_PATH/$mac_local_name"
    local export_name="${mac_local_name%.checkpoint.dat.bundle}_mac.dat.bundle"

    # 直接复制data文件到同步目录
    local export_name="${mac_local_name%.checkpoint.dat.bundle}_mac.dat"
    mkdir -p "$MAC_SAVES_FOLDER"
    cp "$bundle_path/data" "$MAC_SAVES_FOLDER/$export_name"
    chmod 644 "$MAC_SAVES_FOLDER/$export_name"

    write_log "$(get_translation export_success -f "$export_name")" "success"

    printf "\n${YELLOW}$(get_translation press_enter)${NC}"
    read -r </dev/tty
}

# 一键同步最新存档
sync_latest_save() {
    if ! get_confirmation "$(get_translation sync_warning)"; then
        return
    fi
    write_log "$(get_translation sync_start)" "warning"
    printf "\n${YELLOW}$(get_translation press_enter)${NC}"
    read -r </dev/tty

}

# 显示操作菜单
show_menu() {
    echo
    printf "${YELLOW}$(get_translation menu_title)${NC}\n"
    printf "${GREEN}1) $(get_translation menu_import)${NC}\n"
    printf "${GREEN}2) $(get_translation menu_export)${NC}\n"
    printf "${YELLOW}3) $(get_translation menu_sync)${NC}\n"
    printf "${RED}4) $(get_translation menu_exit)${NC}\n"
    echo
    printf "${YELLOW}$(get_translation menu_prompt)${NC}"
    read -r choice

    case $choice in
    1)
        import_windows_save
        ;;
    2)
        export_mac_save
        ;;
    3)
        sync_latest_save
        ;;
    4)
        write_log "$(get_translation program_exit)" "info"
        exit 0
        ;;
    *)
        write_log "$(get_translation invalid_choice)" "error"
        ;;
    esac
}

# 主程序开始
while true; do
    show_save_status
    show_menu
done
