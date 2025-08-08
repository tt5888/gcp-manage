#!/bin/bash

# ==============================================================================
# GCP Billing Switcher - 互動式批次切換計費帳戶腳本
# Version: 2.6
# Change:
# - 在步驟 3 中，強化了對輸入檔案存在性的檢查與提示。
# ==============================================================================

# 設定顏色變數讓輸出更易讀
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- 函式定義 ---

# 檢查 gcloud 指令是否存在
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        echo -e "${C_RED}錯誤: 'gcloud' 指令未找到。請先安裝 Google Cloud SDK 並確保其在您的 PATH 中。${C_RESET}"
        exit 1
    fi
}

# 1. 檢查擁有的計費帳戶
list_billing_accounts() {
    clear
    echo -e "${C_BLUE}--- 步驟 1: 查詢您可存取的計費帳戶 ---${C_RESET}"
    echo -e "${C_YELLOW}正在查詢【啟用中 (OPEN: True)】的計費帳戶...${C_RESET}"
    
    gcloud beta billing accounts list --filter="open=true"
    
    echo -e "\n以上是您有權限查看的【啟用中】計費帳戶。"
    echo "請從中找到您要使用的【來源】與【目標】計費帳戶，並記下它們的 BILLING_ACCOUNT_ID。"
    echo ""
    read -n 1 -s -r -p "按任意鍵返回主選單..."
}

# 2. 匯出專案清單
export_project_list() {
    clear
    echo -e "${C_BLUE}--- 步驟 2: 匯出專案清單 ---${C_RESET}"
    echo "此功能會將連結到某個「來源」計費帳戶的所有專案 ID 匯出至一個檔案。"
    
    read -p "請輸入您要匯出專案的【來源】計費帳戶 ID (格式 XXXXXX-XXXXXX-XXXXXX): " SOURCE_BILLING_ID
    if [[ -z "$SOURCE_BILLING_ID" ]]; then
        echo -e "${C_RED}錯誤：未輸入來源計費帳戶 ID。${C_RESET}"
        return
    fi

    read -p "請輸入要儲存清單的檔案名稱 (預設: projects_to_switch.txt): " FILENAME
    FILENAME=${FILENAME:-"projects_to_switch.txt"}

    echo -e "\n${C_YELLOW}正在從計費帳戶 ${SOURCE_BILLING_ID} 獲取專案清單...${C_RESET}"
    
    if gcloud beta billing projects list --billing-account="$SOURCE_BILLING_ID" --format="value(projectId)" > "$FILENAME"; then
        PROJECT_COUNT=$(wc -l < "$FILENAME" | tr -d ' ')
        
        if [[ $PROJECT_COUNT -eq 0 ]]; then
             echo -e "${C_GREEN}成功！但此計費帳戶下未找到任何專案。${C_RESET}"
        else
            echo -e "${C_GREEN}成功！ 共找到 ${PROJECT_COUNT} 個專案，清單已儲存至檔案: ${FILENAME}${C_RESET}"
            
            echo -e "${C_YELLOW}\n--- 清單預覽 (前 5 個專案) ---${C_RESET}"
            head -n 5 "$FILENAME"
            echo "---------------------------------"
            echo "請檢查以上專案是否符合您的預期。"
        fi
    else
        echo -e "${C_RED}錯誤：無法從該計費帳戶獲取專案清單。請檢查 ID 是否正確以及您是否有足夠的權限。${C_RESET}"
    fi
    echo ""
    read -n 1 -s -r -p "按任意鍵返回主選單..."
}

# 3. 切換計費帳戶 
switch_project_billing() {
    clear
    echo -e "${C_BLUE}--- 步驟 3: 執行批次切換作業 ---${C_RESET}"
    
    read -p "請輸入您要切換過去的【目標】計費帳戶 ID: " TARGET_BILLING_ID
    if [[ -z "$TARGET_BILLING_ID" ]]; then
        echo -e "${C_RED}錯誤：未輸入目標計費帳戶 ID。${C_RESET}"
        read -n 1 -s -r -p "按任意鍵返回主選單..."
        return
    fi
    
    read -p "請輸入包含專案 ID 的清單檔案名稱 (預設: projects_to_switch.txt): " PROJECT_FILE
    PROJECT_FILE=${PROJECT_FILE:-"projects_to_switch.txt"}

    # ******** 強化檔案存在性檢查 ********
    if [ ! -f "$PROJECT_FILE" ]; then
        echo -e "\n${C_RED}錯誤：找不到檔案 '${PROJECT_FILE}'！${C_RESET}"
        echo "請確認檔名是否正確，或執行步驟 2 來產生清單檔案。"
        echo "操作已取消。"
        read -n 1 -s -r -p "按任意鍵返回主選單..."
        return
    fi

    PROJECT_COUNT=$(wc -l < "$PROJECT_FILE" | tr -d ' ')
    
    echo -e "\n${C_YELLOW}=== 安全確認 ===${C_RESET}"
    echo "WARNING: Changing the billing account linked to a project could disable and result in data loss for any partner-managed services purchased through GCP Marketplace. To avoid service disruption and data loss with the new billing account, make sure that you have purchased the Cloud Marketplace products using the new account prior to changing the billing account."
    echo "即將把以下列表中的所有專案，切換至新的計費帳戶。"
    echo ""
    echo -e "${C_BLUE}--- 將要切換的專案列表 (來源: ${PROJECT_FILE}) ---${C_RESET}"
    cat "${PROJECT_FILE}"
    echo -e "${C_BLUE}--------------------------------------------------${C_RESET}"
    echo ""
    
    echo -e "目標計費帳戶 ID: ${C_GREEN}${TARGET_BILLING_ID}${C_RESET}"
    echo -e "專案總數:         ${C_GREEN}${PROJECT_COUNT}${C_RESET}"
    
    echo ""
    echo -e "${C_RED}這個操作無法輕易復原，請仔細核對以上列表！${C_RESET}"
    read -p "您確定要繼續嗎？ (輸入 'yes' 以繼續): " CONFIRMATION

    if [[ "$CONFIRMATION" != "yes" ]]; then
        echo "操作已取消。"
        read -n 1 -s -r -p "按任意鍵返回主選單..."
        return
    fi

    echo -e "\n${C_YELLOW}開始執行切換作業...${C_RESET}"
    echo "========================================================"

    SUCCESS_COUNT=0
    FAIL_COUNT=0
    while IFS= read -r project_id || [[ -n "$project_id" ]]; do
        if [[ -z "$project_id" ]]; then
            continue
        fi
        echo "正在處理專案: ${project_id} ..."
        if gcloud billing projects link "${project_id}" --billing-account="${TARGET_BILLING_ID}"; then
            echo -e "${C_GREEN} -> 成功!${C_RESET}"
            ((SUCCESS_COUNT++))
        else
            echo -e "${C_RED} -> 失敗! 請檢查權限或專案狀態。${C_RESET}"
            ((FAIL_COUNT++))
        fi
        echo "--------------------------------------------------------"
    done < "$PROJECT_FILE"

    echo "========================================================"
    echo -e "${C_GREEN}所有專案處理完畢。${C_RESET}"
    echo -e "成功: ${C_GREEN}${SUCCESS_COUNT}${C_RESET} 個"
    echo -e "失敗: ${C_RED}${FAIL_COUNT}${C_RESET} 個"
    echo ""
    read -n 1 -s -r -p "按任意鍵返回主選單..."
}

# --- 主程式迴圈 ---

check_gcloud

while true; do
    clear
    echo -e "${C_BLUE}==============================================${C_RESET}"
    echo -e "${C_BLUE}   GCP 專案計費帳戶批次切換工具 v2.6    ${C_RESET}"
    echo -e "${C_BLUE}==============================================${C_RESET}"
    echo "建議操作順序: 1 -> 2 -> 3"
    echo ""
    echo "  1. 查詢可用的 Billing Accounts (僅限啟用中)"
    echo "  2. 匯出專案清單 (從來源 Billing Account)"
    echo "  3. 執行批次切換 (至目標 Billing Account)"
    echo ""
    echo "  4. 離開 (Exit)"
    echo ""
    read -p "請輸入選項 [1-4]: " choice

    case $choice in
        1)
            list_billing_accounts
            ;;
        2)
            export_project_list
            ;;
        3)
            switch_project_billing
            ;;
        4 | [qQ] | [eE][xX][iI][tT])
            echo "感謝使用，再見！"
            break
            ;;
        *)
            echo -e "${C_RED}無效的選項，請重新輸入。${C_RESET}"
            sleep 1
            ;;
    esac
done
